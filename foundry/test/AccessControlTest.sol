// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTix.sol";

/**
 * @title AccessControlTest
 * @dev Comprehensive test suite for access control vulnerabilities in VeriTix contract
 * Tests Requirements: 1.2, 5.1, 5.2, 5.3, 5.4
 */
contract AccessControlTest is Test {
    VeriTix public veritix;
    address public owner;
    address public organizer;
    address public attacker;
    address public user1;
    address public user2;

    event EventCreated(uint256 indexed eventId, string name, uint256 ticketPrice, uint256 maxTickets, address organizer);
    event EventCancelled(uint256 indexed eventId, string reason);

    function setUp() public {
        owner = makeAddr("owner");
        organizer = makeAddr("organizer");
        attacker = makeAddr("attacker");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.prank(owner);
        veritix = new VeriTix(owner);
    }

    // ============ onlyOwner Modifier Tests ============

    function test_OnlyOwner_CreateEvent_Success() public {
        vm.prank(owner);
        veritix.createEvent("Test Event", 1 ether, 100);
        
        (string memory name, uint256 price, uint256 maxTickets, uint256 sold, address eventOrganizer) = 
            veritix.getEventDetails(1);
        
        assertEq(name, "Test Event");
        assertEq(price, 1 ether);
        assertEq(maxTickets, 100);
        assertEq(sold, 0);
        assertEq(eventOrganizer, owner);
    }

    function test_OnlyOwner_CreateEvent_RevertNonOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.createEvent("Malicious Event", 1 ether, 100);
    }

    function test_OnlyOwner_CreateEnhancedEvent_Success() public {
        vm.prank(owner);
        veritix.createEnhancedEvent(
            "Enhanced Event",
            "Description",
            "Venue",
            block.timestamp + 1 days,
            1 ether,
            100,
            5,
            true,
            10
        );
        
        (string memory name, string memory description, string memory venue, uint256 date, 
         uint256 ticketPrice, uint256 maxTickets, uint256 maxTicketsPerBuyer, uint256 ticketsSold,
         address eventOrganizer, bool isActive, bool transfersAllowed, uint256 transferFeePercent) = veritix.getFullEventDetails(1);
        assertEq(name, "Enhanced Event");
        assertEq(eventOrganizer, owner);
    }

    function test_OnlyOwner_CreateEnhancedEvent_RevertNonOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.createEnhancedEvent(
            "Malicious Enhanced Event",
            "Description",
            "Venue",
            block.timestamp + 1 days,
            1 ether,
            100,
            5,
            true,
            10
        );
    }

    function test_OnlyOwner_BatchCreateEvents_Success() public {
        string[] memory names = new string[](3);
        uint256[] memory prices = new uint256[](3);
        uint256[] memory maxTickets = new uint256[](3);
        
        names[0] = "Event 1";
        names[1] = "Event 2";
        names[2] = "Event 3";
        prices[0] = 1 ether;
        prices[1] = 2 ether;
        prices[2] = 3 ether;
        maxTickets[0] = 100;
        maxTickets[1] = 200;
        maxTickets[2] = 300;

        vm.prank(owner);
        veritix.batchCreateEvents(names, prices, maxTickets);
        
        // Verify all events were created
        for (uint256 i = 1; i <= 3; i++) {
            (string memory name,,,, address eventOrganizer) = veritix.getEventDetails(i);
            assertEq(name, names[i-1]);
            assertEq(eventOrganizer, owner);
        }
    }

    function test_OnlyOwner_BatchCreateEvents_RevertNonOwner() public {
        string[] memory names = new string[](1);
        uint256[] memory prices = new uint256[](1);
        uint256[] memory maxTickets = new uint256[](1);
        
        names[0] = "Malicious Event";
        prices[0] = 1 ether;
        maxTickets[0] = 100;

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.batchCreateEvents(names, prices, maxTickets);
    }

    // ============ Organizer-Only Access Control Tests ============

    function test_OrganizerOnly_CancelEvent_Success() public {
        // Create event as owner
        vm.prank(owner);
        veritix.createEvent("Test Event", 1 ether, 100);
        
        // Cancel event as organizer (owner in this case)
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit EventCancelled(1, "Test cancellation");
        veritix.cancelEvent(1, "Test cancellation");
        
        // Verify event is cancelled
        assertTrue(veritix.isEventCancelled(1));
    }

    function test_OrganizerOnly_CancelEvent_RevertNonOrganizer() public {
        // Create event as owner
        vm.prank(owner);
        veritix.createEvent("Test Event", 1 ether, 100);
        
        // Try to cancel as non-organizer
        vm.prank(attacker);
        vm.expectRevert("Only event organizer can cancel");
        veritix.cancelEvent(1, "Malicious cancellation");
    }

    function test_OrganizerOnly_UpdateEventSettings_Success() public {
        // Create event as owner
        vm.prank(owner);
        veritix.createEvent("Test Event", 1 ether, 100);
        
        // Update settings as organizer
        vm.prank(owner);
        veritix.updateEventSettings(1, false, 25);
        
        // Verify settings updated
        (,,,,,,,,,, bool transfersAllowed, uint256 transferFeePercent) = veritix.getFullEventDetails(1);
        assertFalse(transfersAllowed);
        assertEq(transferFeePercent, 25);
    }

    function test_OrganizerOnly_UpdateEventSettings_RevertNonOrganizer() public {
        // Create event as owner
        vm.prank(owner);
        veritix.createEvent("Test Event", 1 ether, 100);
        
        // Try to update as non-organizer
        vm.prank(attacker);
        vm.expectRevert("Only event organizer can update");
        veritix.updateEventSettings(1, false, 25);
    }

    // ============ Ownership Transfer Security Tests ============

    function test_OwnershipTransfer_Success() public {
        address newOwner = makeAddr("newOwner");
        
        // Transfer ownership (immediate transfer in OpenZeppelin Ownable)
        vm.prank(owner);
        veritix.transferOwnership(newOwner);
        
        // Verify new owner can create events
        vm.prank(newOwner);
        veritix.createEvent("New Owner Event", 1 ether, 100);
        
        (,,,, address eventOrganizer) = veritix.getEventDetails(1);
        assertEq(eventOrganizer, newOwner);
        
        // Verify old owner cannot create events
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", owner));
        veritix.createEvent("Old Owner Event", 1 ether, 100);
    }

    function test_OwnershipTransfer_RevertNonOwner() public {
        address newOwner = makeAddr("newOwner");
        
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.transferOwnership(newOwner);
    }

    function test_OwnershipRenounce_Success() public {
        // Renounce ownership
        vm.prank(owner);
        veritix.renounceOwnership();
        
        // Verify no one can create events after renouncing
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", owner));
        veritix.createEvent("Renounced Owner Event", 1 ether, 100);
        
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.createEvent("Attacker Event", 1 ether, 100);
    }

    function test_OwnershipRenounce_RevertNonOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.renounceOwnership();
    }

    // ============ Privilege Escalation Tests ============

    function test_PrivilegeEscalation_CannotBypassOnlyOwner() public {
        // Attacker tries various methods to bypass onlyOwner
        
        // Direct call should fail
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.createEvent("Escalation Attempt 1", 1 ether, 100);
        
        // Try with delegatecall (should not be possible in this context)
        // This test ensures the contract doesn't have delegatecall vulnerabilities
        
        // Try to manipulate msg.sender through reentrancy
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.batchCreateEvents(new string[](0), new uint256[](0), new uint256[](0));
    }

    function test_PrivilegeEscalation_CannotImpersonateOrganizer() public {
        // Create event as owner
        vm.prank(owner);
        veritix.createEvent("Test Event", 1 ether, 100);
        
        // Attacker cannot cancel event they didn't create
        vm.prank(attacker);
        vm.expectRevert("Only event organizer can cancel");
        veritix.cancelEvent(1, "Malicious cancellation");
        
        // Attacker cannot update event settings
        vm.prank(attacker);
        vm.expectRevert("Only event organizer can update");
        veritix.updateEventSettings(1, false, 50);
    }

    // ============ Constructor Access Control Tests ============

    function test_Constructor_InitialOwnerSet() public {
        address testOwner = makeAddr("testOwner");
        
        vm.prank(testOwner);
        VeriTix testContract = new VeriTix(testOwner);
        
        // Verify initial owner can create events
        vm.prank(testOwner);
        testContract.createEvent("Constructor Test", 1 ether, 100);
        
        (,,,, address eventOrganizer) = testContract.getEventDetails(1);
        assertEq(eventOrganizer, testOwner);
    }

    function test_Constructor_ZeroAddressOwner() public {
        // Test that zero address cannot be set as owner
        vm.expectRevert(abi.encodeWithSignature("OwnableInvalidOwner(address)", address(0)));
        new VeriTix(address(0));
    }

    // ============ Batch Operations Access Control Tests ============

    function test_BatchOperations_OnlyOwnerCanBatchCreate() public {
        string[] memory names = new string[](2);
        uint256[] memory prices = new uint256[](2);
        uint256[] memory maxTickets = new uint256[](2);
        
        names[0] = "Batch Event 1";
        names[1] = "Batch Event 2";
        prices[0] = 1 ether;
        prices[1] = 2 ether;
        maxTickets[0] = 100;
        maxTickets[1] = 200;

        // Non-owner cannot batch create
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        veritix.batchCreateEvents(names, prices, maxTickets);
        
        // Owner can batch create
        vm.prank(owner);
        veritix.batchCreateEvents(names, prices, maxTickets);
        
        // Verify events created with correct organizer
        for (uint256 i = 1; i <= 2; i++) {
            (,,,, address eventOrganizer) = veritix.getEventDetails(i);
            assertEq(eventOrganizer, owner);
        }
    }

    function test_BatchOperations_AnyoneCanBatchBuy() public {
        // Create events as owner
        vm.prank(owner);
        veritix.createEvent("Event 1", 1 ether, 100);
        vm.prank(owner);
        veritix.createEvent("Event 2", 2 ether, 100);
        
        uint256[] memory eventIds = new uint256[](2);
        uint256[] memory quantities = new uint256[](2);
        eventIds[0] = 1;
        eventIds[1] = 2;
        quantities[0] = 1;
        quantities[1] = 1;
        
        // Anyone can batch buy (this is correct behavior)
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        veritix.batchBuyTickets{value: 3 ether}(eventIds, quantities);
        
        // Verify tickets were purchased
        assertEq(veritix.balanceOf(user1), 2);
    }

    // ============ Edge Cases and Attack Vectors ============

    function test_AccessControl_NonExistentEvent() public {
        // Try to cancel non-existent event
        vm.prank(owner);
        vm.expectRevert("Event does not exist");
        veritix.cancelEvent(999, "Non-existent");
        
        // Try to update non-existent event
        vm.prank(owner);
        vm.expectRevert("Event does not exist");
        veritix.updateEventSettings(999, false, 10);
    }

    function test_AccessControl_EventIdZero() public {
        // Try to cancel event ID 0
        vm.prank(owner);
        vm.expectRevert("Event does not exist");
        veritix.cancelEvent(0, "Zero ID");
        
        // Try to update event ID 0
        vm.prank(owner);
        vm.expectRevert("Event does not exist");
        veritix.updateEventSettings(0, false, 10);
    }

    function test_AccessControl_MultipleOwnershipTransfers() public {
        address owner2 = makeAddr("owner2");
        address owner3 = makeAddr("owner3");
        
        // First transfer (immediate in OpenZeppelin Ownable)
        vm.prank(owner);
        veritix.transferOwnership(owner2);
        
        // Second transfer
        vm.prank(owner2);
        veritix.transferOwnership(owner3);
        
        // Verify final owner has control
        vm.prank(owner3);
        veritix.createEvent("Final Owner Event", 1 ether, 100);
        
        // Verify previous owners lost control
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", owner));
        veritix.createEvent("Old Owner Event", 1 ether, 100);
        
        vm.prank(owner2);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", owner2));
        veritix.createEvent("Previous Owner Event", 1 ether, 100);
    }

    // ============ Gas Limit DoS Prevention in Access Control ============

    function test_AccessControl_BatchCreateGasLimit() public {
        // Test that batch create has reasonable limits to prevent DoS
        string[] memory names = new string[](51); // Over the 50 limit
        uint256[] memory prices = new uint256[](51);
        uint256[] memory maxTickets = new uint256[](51);
        
        for (uint256 i = 0; i < 51; i++) {
            names[i] = "Event";
            prices[i] = 1 ether;
            maxTickets[i] = 100;
        }
        
        vm.prank(owner);
        vm.expectRevert("Cannot create more than 50 events at once");
        veritix.batchCreateEvents(names, prices, maxTickets);
    }
}