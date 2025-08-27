// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";
import "../src/interfaces/IVeriTixEvent.sol";

/**
 * @title PaymentFlowSecurityTest
 * @dev Comprehensive security testing for VeriTix payment flows
 * @notice Tests ETH handling, refund calculations, balance management, and fund drainage protection
 */
contract PaymentFlowSecurityTest is Test {
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    address public owner = makeAddr("owner");
    address public organizer = makeAddr("organizer");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public attacker = makeAddr("attacker");
    
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant MAX_RESALE_PERCENT = 120; // 120%
    uint256 public constant ORGANIZER_FEE_PERCENT = 5; // 5%
    
    event TicketMinted(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event TicketResold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, uint256 organizerFee);
    event TicketRefunded(uint256 indexed tokenId, address indexed holder, uint256 refundAmount);
    
    function setUp() public {
        vm.startPrank(owner);
        factory = new VeriTixFactory(owner);
        vm.stopPrank();
        
        // Create test event
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Test Concert",
            symbol: "TEST",
            maxSupply: MAX_SUPPLY,
            ticketPrice: TICKET_PRICE,
            baseURI: "https://test.com/",
            maxResalePercent: MAX_RESALE_PERCENT,
            organizerFeePercent: ORGANIZER_FEE_PERCENT,
            organizer: organizer
        });
        
        vm.prank(organizer);
        address eventAddress = factory.createEvent(params);
        eventContract = VeriTixEvent(eventAddress);
        
        // Fund test accounts
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(attacker, 10 ether);
    }

    // ============ ETH HANDLING IN buyTicket() TESTS ============
    
    /**
     * @dev Test exact payment validation in mintTicket()
     */
    function test_MintTicket_ExactPaymentRequired() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit TicketMinted(1, user1, TICKET_PRICE);
        
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        assertEq(tokenId, 1);
        assertEq(eventContract.ownerOf(tokenId), user1);
        assertEq(eventContract.getLastPricePaid(tokenId), TICKET_PRICE);
    }
    
    /**
     * @dev Test overpayment rejection in mintTicket()
     */
    function test_MintTicket_RejectsOverpayment() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector,
            TICKET_PRICE + 0.01 ether,
            TICKET_PRICE
        ));
        eventContract.mintTicket{value: TICKET_PRICE + 0.01 ether}();
    }
    
    /**
     * @dev Test underpayment rejection in mintTicket()
     */
    function test_MintTicket_RejectsUnderpayment() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector,
            TICKET_PRICE - 0.01 ether,
            TICKET_PRICE
        ));
        eventContract.mintTicket{value: TICKET_PRICE - 0.01 ether}();
    }
    
    /**
     * @dev Test zero payment rejection in mintTicket()
     */
    function test_MintTicket_RejectsZeroPayment() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector,
            0,
            TICKET_PRICE
        ));
        eventContract.mintTicket{value: 0}();
    }
    
    /**
     * @dev Test contract balance increases correctly after minting
     */
    function test_MintTicket_ContractBalanceIncrease() public {
        uint256 initialBalance = address(eventContract).balance;
        
        vm.prank(user1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        assertEq(address(eventContract).balance, initialBalance + TICKET_PRICE);
    }
    
    /**
     * @dev Test multiple mints accumulate balance correctly
     */
    function test_MintTicket_MultipleMintsAccumulateBalance() public {
        uint256 initialBalance = address(eventContract).balance;
        
        // Mint 3 tickets
        vm.prank(user1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user2);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user3);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        assertEq(address(eventContract).balance, initialBalance + (TICKET_PRICE * 3));
    }

    // ============ RESALE PAYMENT VALIDATION TESTS ============
    
    /**
     * @dev Test exact payment validation in resaleTicket()
     */
    function test_ResaleTicket_ExactPaymentRequired() public {
        // Mint ticket first
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 resalePrice = TICKET_PRICE + 0.02 ether;
        uint256 organizerFee = (resalePrice * ORGANIZER_FEE_PERCENT) / 100;
        
        vm.prank(user2);
        vm.expectEmit(true, true, true, true);
        emit TicketResold(tokenId, user1, user2, resalePrice, organizerFee);
        
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        assertEq(eventContract.ownerOf(tokenId), user2);
        assertEq(eventContract.getLastPricePaid(tokenId), resalePrice);
    }
    
    /**
     * @dev Test resale overpayment rejection
     */
    function test_ResaleTicket_RejectsOverpayment() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 resalePrice = TICKET_PRICE + 0.02 ether;
        
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector,
            resalePrice + 0.01 ether,
            resalePrice
        ));
        eventContract.resaleTicket{value: resalePrice + 0.01 ether}(tokenId, resalePrice);
    }
    
    /**
     * @dev Test resale underpayment rejection
     */
    function test_ResaleTicket_RejectsUnderpayment() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 resalePrice = TICKET_PRICE + 0.02 ether;
        
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector,
            resalePrice - 0.01 ether,
            resalePrice
        ));
        eventContract.resaleTicket{value: resalePrice - 0.01 ether}(tokenId, resalePrice);
    }
    
    /**
     * @dev Test resale zero payment rejection
     */
    function test_ResaleTicket_RejectsZeroPayment() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector,
            0,
            0
        ));
        eventContract.resaleTicket{value: 0}(tokenId, 0);
    }

    // ============ REFUND CALCULATION ACCURACY TESTS ============
    
    /**
     * @dev Test refund always returns face value regardless of resale price
     */
    function test_Refund_AlwaysFaceValue() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Resell at higher price (within 120% cap)
        uint256 resalePrice = (TICKET_PRICE * 115) / 100; // 115% of face value
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        // Check balance before refund
        uint256 balanceBefore = user2.balance;
        
        // Refund should be face value, not resale price
        vm.prank(user2);
        vm.expectEmit(true, true, false, true);
        emit TicketRefunded(tokenId, user2, TICKET_PRICE);
        
        eventContract.refund(tokenId);
        
        // Verify refund amount
        assertEq(user2.balance, balanceBefore + TICKET_PRICE);
        
        // Verify ticket is burned
        vm.expectRevert();
        eventContract.ownerOf(tokenId);
    }
    
    /**
     * @dev Test refund calculation with insufficient contract balance
     */
    function test_Refund_InsufficientContractBalance() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Drain contract balance by transferring it out
        uint256 contractBalance = address(eventContract).balance;
        vm.deal(address(eventContract), 0); // Simulate balance being drained
        
        // Attempt refund should fail
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.InsufficientContractBalance.selector,
            TICKET_PRICE,
            0
        ));
        eventContract.refund(tokenId);
    }
    
    /**
     * @dev Test cancel refund calculation accuracy
     */
    function test_CancelRefund_AccurateCalculation() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Cancel event
        vm.prank(organizer);
        eventContract.cancelEvent("Test cancellation");
        
        uint256 balanceBefore = user1.balance;
        
        // Process cancel refund
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit TicketRefunded(tokenId, user1, TICKET_PRICE);
        
        eventContract.cancelRefund(tokenId);
        
        // Verify refund amount
        assertEq(user1.balance, balanceBefore + TICKET_PRICE);
    }

    // ============ DOUBLE-SPENDING PREVENTION TESTS ============
    
    /**
     * @dev Test double refund prevention
     */
    function test_Refund_PreventsDoubleSpending() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // First refund should succeed
        vm.prank(user1);
        eventContract.refund(tokenId);
        
        // Second refund attempt should fail (ticket is burned)
        vm.prank(user1);
        vm.expectRevert();
        eventContract.refund(tokenId);
    }
    
    /**
     * @dev Test refund after check-in prevention
     */
    function test_Refund_PreventsAfterCheckIn() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Check in ticket
        vm.prank(organizer);
        eventContract.checkIn(tokenId);
        
        // Refund should fail
        vm.prank(user1);
        vm.expectRevert(IVeriTixEvent.TicketAlreadyUsed.selector);
        eventContract.refund(tokenId);
    }
    
    /**
     * @dev Test resale after refund prevention
     */
    function test_Resale_PreventsAfterRefund() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Refund ticket (burns it)
        vm.prank(user1);
        eventContract.refund(tokenId);
        
        // Attempt resale should fail
        vm.prank(user2);
        vm.expectRevert();
        eventContract.resaleTicket{value: TICKET_PRICE}(tokenId, TICKET_PRICE);
    }

    // ============ CONTRACT BALANCE MANAGEMENT TESTS ============
    
    /**
     * @dev Test contract balance tracking accuracy
     */
    function test_ContractBalance_AccurateTracking() public {
        uint256 initialBalance = address(eventContract).balance;
        
        // Mint 2 tickets
        vm.prank(user1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user2);
        uint256 tokenId2 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        assertEq(address(eventContract).balance, initialBalance + (TICKET_PRICE * 2));
        
        // Refund 1 ticket
        vm.prank(user2);
        eventContract.refund(tokenId2);
        
        assertEq(address(eventContract).balance, initialBalance + TICKET_PRICE);
    }
    
    /**
     * @dev Test balance management during resales
     */
    function test_ContractBalance_ResaleManagement() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 balanceAfterMint = address(eventContract).balance;
        
        // Resale at higher price (within 120% cap)
        uint256 resalePrice = (TICKET_PRICE * 115) / 100; // 115% of face value
        uint256 organizerFee = (resalePrice * ORGANIZER_FEE_PERCENT) / 100;
        
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        // Contract balance should remain the same (resale funds distributed)
        assertEq(address(eventContract).balance, balanceAfterMint);
        
        // Verify fund distribution
        assertEq(user1.balance, 10 ether - TICKET_PRICE + (resalePrice - organizerFee));
        assertEq(organizer.balance, organizerFee);
    }

    // ============ FUND DRAINAGE PROTECTION TESTS ============
    
    /**
     * @dev Test protection against unauthorized fund withdrawal
     */
    function test_FundDrainage_UnauthorizedWithdrawal() public {
        // Mint tickets to add funds
        vm.prank(user1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user2);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 contractBalance = address(eventContract).balance;
        assertGt(contractBalance, 0);
        
        // Attempt unauthorized withdrawal by attacker
        vm.prank(attacker);
        (bool success,) = address(eventContract).call{value: 0}("");
        
        // Contract balance should remain unchanged
        assertEq(address(eventContract).balance, contractBalance);
    }
    
    /**
     * @dev Test protection against reentrancy during refunds
     */
    function test_FundDrainage_ReentrancyProtection() public {
        // Deploy malicious contract
        MaliciousRefundContract malicious = new MaliciousRefundContract(eventContract);
        vm.deal(address(malicious), 1 ether);
        
        // Mint ticket to malicious contract
        vm.prank(address(malicious));
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 contractBalanceBefore = address(eventContract).balance;
        
        // Attempt reentrancy attack - should succeed but reentrancy should be blocked
        vm.prank(address(malicious));
        malicious.attemptReentrancy(tokenId);
        
        // Contract balance should decrease by only one refund (reentrancy blocked)
        assertEq(address(eventContract).balance, contractBalanceBefore - TICKET_PRICE);
    }
    
    /**
     * @dev Test fund drainage protection during batch operations
     */
    function test_FundDrainage_BatchOperationProtection() public {
        // Mint multiple tickets
        vm.prank(user1);
        uint256 tokenId1 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user2);
        uint256 tokenId2 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user3);
        uint256 tokenId3 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 contractBalance = address(eventContract).balance;
        
        // Attempt to drain through rapid refunds
        vm.prank(user1);
        eventContract.refund(tokenId1);
        
        vm.prank(user2);
        eventContract.refund(tokenId2);
        
        // Contract should still have remaining balance
        assertEq(address(eventContract).balance, contractBalance - (TICKET_PRICE * 2));
        
        // Last refund should still work
        vm.prank(user3);
        eventContract.refund(tokenId3);
        
        assertEq(address(eventContract).balance, 0);
    }

    // ============ EXCESS PAYMENT HANDLING TESTS ============
    
    /**
     * @dev Test that excess payments are rejected, not refunded
     */
    function test_ExcessPayment_RejectedNotRefunded() public {
        uint256 excessAmount = 0.05 ether;
        uint256 userBalanceBefore = user1.balance;
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector,
            TICKET_PRICE + excessAmount,
            TICKET_PRICE
        ));
        eventContract.mintTicket{value: TICKET_PRICE + excessAmount}();
        
        // User should retain their full balance (transaction reverted)
        assertEq(user1.balance, userBalanceBefore);
    }
    
    /**
     * @dev Test excess payment handling in resales
     */
    function test_ExcessPayment_ResaleRejection() public {
        // Mint ticket first
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 resalePrice = TICKET_PRICE + 0.02 ether;
        uint256 excessAmount = 0.03 ether;
        uint256 userBalanceBefore = user2.balance;
        
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector,
            resalePrice + excessAmount,
            resalePrice
        ));
        eventContract.resaleTicket{value: resalePrice + excessAmount}(tokenId, resalePrice);
        
        // User should retain their full balance
        assertEq(user2.balance, userBalanceBefore);
        
        // Ticket should still belong to original owner
        assertEq(eventContract.ownerOf(tokenId), user1);
    }

    // ============ EDGE CASE TESTS ============
    
    /**
     * @dev Test payment handling when event is sold out
     */
    function test_PaymentHandling_SoldOutEvent() public {
        // Mint tickets until sold out
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            address buyer = makeAddr(string(abi.encodePacked("buyer", i)));
            vm.deal(buyer, 1 ether);
            vm.prank(buyer);
            eventContract.mintTicket{value: TICKET_PRICE}();
        }
        
        // Attempt to mint when sold out
        vm.prank(user1);
        vm.expectRevert(IVeriTixEvent.EventSoldOut.selector);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        // User balance should be unchanged
        assertEq(user1.balance, 10 ether);
    }
    
    /**
     * @dev Test payment handling when event is cancelled
     */
    function test_PaymentHandling_CancelledEvent() public {
        // Cancel event
        vm.prank(organizer);
        eventContract.cancelEvent("Test cancellation");
        
        // Attempt to mint ticket
        vm.prank(user1);
        vm.expectRevert(IVeriTixEvent.EventIsCancelled.selector);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        // User balance should be unchanged
        assertEq(user1.balance, 10 ether);
    }
    
    /**
     * @dev Test resale price cap enforcement
     */
    function test_PaymentHandling_ResalePriceCap() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Calculate maximum allowed resale price
        uint256 maxResalePrice = (TICKET_PRICE * MAX_RESALE_PERCENT) / 100;
        uint256 excessivePrice = maxResalePrice + 0.01 ether;
        
        // Attempt resale above cap
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.ExceedsResaleCap.selector,
            excessivePrice,
            maxResalePrice
        ));
        eventContract.resaleTicket{value: excessivePrice}(tokenId, excessivePrice);
    }
    
    /**
     * @dev Test organizer fee calculation accuracy in edge cases
     */
    function test_PaymentHandling_OrganizerFeeEdgeCases() public {
        // Mint ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test with minimum resale price (face value)
        uint256 resalePrice = TICKET_PRICE;
        uint256 expectedFee = (resalePrice * ORGANIZER_FEE_PERCENT) / 100;
        
        uint256 organizerBalanceBefore = organizer.balance;
        
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        assertEq(organizer.balance, organizerBalanceBefore + expectedFee);
    }
}

/**
 * @dev Malicious contract for testing reentrancy protection
 */
contract MaliciousRefundContract {
    VeriTixEvent public eventContract;
    bool public attacking = false;
    
    constructor(VeriTixEvent _eventContract) {
        eventContract = _eventContract;
    }
    
    function attemptReentrancy(uint256 tokenId) external {
        attacking = true;
        eventContract.refund(tokenId);
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
        if (attacking && address(eventContract).balance > 0) {
            // Attempt reentrancy
            eventContract.refund(1); // This should fail
        }
    }
}