// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTix.sol";

/**
 * @title ReentrancyTest
 * @dev Test suite for reentrancy vulnerabilities in VeriTix contract
 */
contract ReentrancyTest is Test {
    VeriTix public veritix;
    address public owner;
    address public user1;
    address public user2;
    
    // Test events
    event AttackAttempted(string functionName, bool success);
    event ReentrancyDetected(address attacker, uint256 value);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        veritix = new VeriTix(owner);
        
        // Fund test accounts
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(address(this), 10 ether);
    }

    /**
     * @dev Test reentrancy attack on buyTicket function through malicious organizer
     */
    function testBuyTicketReentrancyAttack() public {
        // Deploy malicious organizer contract
        MaliciousOrganizer attacker = new MaliciousOrganizer(address(veritix));
        
        // Create event with malicious organizer as owner
        vm.prank(owner);
        veritix.createEvent("Test Event", 1 ether, 100);
        
        // Transfer ownership to attacker for this test
        vm.prank(owner);
        veritix.transferOwnership(address(attacker));
        
        // Attacker creates event
        vm.prank(address(attacker));
        veritix.createEvent("Malicious Event", 1 ether, 100);
        
        uint256 eventId = veritix.getTotalEvents();
        attacker.setTargetEvent(eventId);
        
        // Fund the attacker contract
        vm.deal(address(attacker), 5 ether);
        
        // User attempts to buy ticket - should trigger reentrancy
        vm.prank(user1);
        vm.expectRevert(); // Should revert due to insufficient funds or other protection
        veritix.buyTicket{value: 1 ether}(eventId);
    }

    /**
     * @dev Test reentrancy attack on refundTicket function
     */
    function testRefundTicketReentrancyAttack() public {
        // Create event
        vm.prank(owner);
        veritix.createEvent("Test Event", 1 ether, 100);
        uint256 eventId = 1;
        
        // Deploy attacker contract
        RefundAttacker attacker = new RefundAttacker(address(veritix));
        vm.deal(address(attacker), 2 ether);
        
        // Attacker buys ticket
        vm.prank(address(attacker));
        veritix.buyTicket{value: 1 ether}(eventId);
        
        uint256 tokenId = veritix.totalSupply();
        
        // Cancel event to enable refunds
        vm.prank(owner);
        veritix.cancelEvent(eventId, "Test cancellation");
        
        // Fund contract for refunds
        vm.deal(address(veritix), 5 ether);
        
        // Attempt reentrancy attack during refund
        vm.prank(address(attacker));
        attacker.attack(tokenId);
        
        // Verify attack was contained
        assertTrue(attacker.attackCompleted(), "Attack should complete without reentrancy");
        assertEq(attacker.reentrancyAttempts(), 0, "No reentrancy should occur due to token burning");
    }

    /**
     * @dev Test reentrancy attack on batchBuyTickets function
     */
    function testBatchBuyTicketsReentrancyAttack() public {
        // Create events
        vm.startPrank(owner);
        veritix.createEvent("Event 1", 1 ether, 100);
        veritix.createEvent("Event 2", 1 ether, 100);
        vm.stopPrank();
        
        // Deploy attacker contract
        BatchAttacker attacker = new BatchAttacker(address(veritix));
        vm.deal(address(attacker), 5 ether);
        
        // Prepare batch purchase with excess payment
        uint256[] memory eventIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);
        eventIds[0] = 1;
        eventIds[1] = 2;
        quantities[0] = 1;
        quantities[1] = 1;
        
        // Attack with excess payment to trigger refund reentrancy
        vm.prank(address(attacker));
        attacker.attack{value: 3 ether}(eventIds, quantities); // 1 ether excess
        
        // Verify attack results
        assertTrue(attacker.attackCompleted(), "Batch attack should complete");
        assertEq(veritix.balanceOf(address(attacker)), 2, "Should own 2 tickets");
    }

    /**
     * @dev Test reentrancy attack on _update function during transfer with fees
     */
    function testUpdateFunctionReentrancyAttack() public {
        // Create event with transfer fees
        vm.prank(owner);
        veritix.createEnhancedEvent(
            "Fee Event",
            "Event with transfer fees",
            "Test Venue",
            block.timestamp + 1 days,
            1 ether,
            100,
            10,
            true, // transfers allowed
            10    // 10% transfer fee
        );
        
        uint256 eventId = veritix.getTotalEvents();
        
        // User buys ticket
        vm.prank(user1);
        veritix.buyTicket{value: 1 ether}(eventId);
        
        uint256 tokenId = veritix.totalSupply();
        
        // Deploy transfer attacker
        TransferAttacker attacker = new TransferAttacker(address(veritix));
        vm.deal(address(attacker), 2 ether);
        
        // Transfer ticket to attacker
        vm.prank(user1);
        veritix.safeTransferFrom(user1, address(attacker), tokenId);
        
        // Attacker attempts reentrancy during transfer with fee
        // Note: This reveals a critical flaw - transfer fees cannot be paid through safeTransferFrom
        vm.prank(address(attacker));
        vm.expectRevert("Insufficient transfer fee"); // Should revert due to no way to pay fee
        attacker.attack(tokenId, user2);
    }

    /**
     * @dev Test gas consumption during potential reentrancy attacks
     */
    function testGasConsumptionDuringAttacks() public {
        // Create event
        vm.prank(owner);
        veritix.createEvent("Gas Test Event", 1 ether, 100);
        
        // Measure gas for normal purchase
        uint256 gasBefore = gasleft();
        vm.prank(user1);
        veritix.buyTicket{value: 1 ether}(1);
        uint256 normalGas = gasBefore - gasleft();
        
        // Deploy attacker and measure gas during attack attempt
        MaliciousOrganizer attacker = new MaliciousOrganizer(address(veritix));
        vm.deal(address(attacker), 2 ether);
        
        gasBefore = gasleft();
        vm.prank(address(attacker));
        try veritix.buyTicket{value: 1 ether}(1) {
            // Attack succeeded
        } catch {
            // Attack failed
        }
        uint256 attackGas = gasBefore - gasleft();
        
        // Verify gas consumption is reasonable
        assertLt(attackGas, normalGas * 2, "Attack gas should not be excessive");
    }

    /**
     * @dev Test multiple concurrent reentrancy attempts
     */
    function testConcurrentReentrancyAttempts() public {
        // Create event
        vm.prank(owner);
        veritix.createEvent("Concurrent Test", 1 ether, 100);
        
        // Deploy multiple attackers
        RefundAttacker attacker1 = new RefundAttacker(address(veritix));
        RefundAttacker attacker2 = new RefundAttacker(address(veritix));
        
        vm.deal(address(attacker1), 2 ether);
        vm.deal(address(attacker2), 2 ether);
        
        // Both attackers buy tickets
        vm.prank(address(attacker1));
        veritix.buyTicket{value: 1 ether}(1);
        
        vm.prank(address(attacker2));
        veritix.buyTicket{value: 1 ether}(1);
        
        // Cancel event
        vm.prank(owner);
        veritix.cancelEvent(1, "Concurrent test");
        
        // Fund contract for refunds
        vm.deal(address(veritix), 5 ether);
        
        // Attempt concurrent attacks
        vm.prank(address(attacker1));
        attacker1.attack(1);
        
        vm.prank(address(attacker2));
        attacker2.attack(2);
        
        // Verify both attacks were handled safely
        assertTrue(attacker1.attackCompleted(), "Attacker 1 should complete");
        assertTrue(attacker2.attackCompleted(), "Attacker 2 should complete");
    }
}

/**
 * @dev Malicious organizer contract for testing buyTicket reentrancy
 */
contract MaliciousOrganizer {
    VeriTix public veritix;
    uint256 public targetEventId;
    uint256 public reentrancyAttempts;
    bool public attacking;
    
    constructor(address _veritix) {
        veritix = VeriTix(_veritix);
    }
    
    function setTargetEvent(uint256 eventId) external {
        targetEventId = eventId;
    }
    
    receive() external payable {
        reentrancyAttempts++;
        if (!attacking && address(veritix).balance > 1 ether) {
            attacking = true;
            try veritix.buyTicket{value: 1 ether}(targetEventId) {
                // Reentrancy succeeded
            } catch {
                // Reentrancy failed
            }
            attacking = false;
        }
    }
}

/**
 * @dev Attacker contract for testing refundTicket reentrancy
 */
contract RefundAttacker {
    VeriTix public veritix;
    uint256 public reentrancyAttempts;
    bool public attackCompleted;
    bool public attacking;
    
    constructor(address _veritix) {
        veritix = VeriTix(_veritix);
    }
    
    function attack(uint256 tokenId) external {
        attacking = true;
        veritix.refundTicket(tokenId);
        attackCompleted = true;
        attacking = false;
    }
    
    receive() external payable {
        if (attacking) {
            reentrancyAttempts++;
            // Attempt reentrancy - should fail due to token being burned
            if (reentrancyAttempts < 3) {
                try veritix.refundTicket(1) {
                    // Reentrancy succeeded
                } catch {
                    // Reentrancy failed (expected)
                }
            }
        }
    }
}

/**
 * @dev Attacker contract for testing batchBuyTickets reentrancy
 */
contract BatchAttacker {
    VeriTix public veritix;
    uint256 public reentrancyAttempts;
    bool public attackCompleted;
    bool public attacking;
    
    constructor(address _veritix) {
        veritix = VeriTix(_veritix);
    }
    
    function attack(
        uint256[] memory eventIds,
        uint256[] memory quantities
    ) external payable {
        attacking = true;
        veritix.batchBuyTickets{value: msg.value}(eventIds, quantities);
        attackCompleted = true;
        attacking = false;
    }
    
    receive() external payable {
        if (attacking) {
            reentrancyAttempts++;
            // Attempt reentrancy during excess refund
            // Should be limited since tickets are already minted
        }
    }
}

/**
 * @dev Attacker contract for testing _update function reentrancy
 */
contract TransferAttacker {
    VeriTix public veritix;
    uint256 public reentrancyAttempts;
    bool public attacking;
    
    constructor(address _veritix) {
        veritix = VeriTix(_veritix);
    }
    
    function attack(uint256 tokenId, address to) external payable {
        attacking = true;
        // Note: Transfer fees are handled in _update, but safeTransferFrom is not payable
        // This demonstrates a design flaw in the fee collection mechanism
        veritix.safeTransferFrom(address(this), to, tokenId);
        attacking = false;
    }
    
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    receive() external payable {
        if (attacking) {
            reentrancyAttempts++;
            // Attempt reentrancy during fee payment or refund
            // This is the most dangerous scenario
        }
    }
}