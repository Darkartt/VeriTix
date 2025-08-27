// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/interfaces/IVeriTixEvent.sol";
import "../src/interfaces/IVeriTixFactory.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title FactoryAccessControlTest
 * @dev Comprehensive access control tests for VeriTix factory architecture
 * Tests Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
 */
contract FactoryAccessControlTest is Test {
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    address public owner;
    address public organizer1;
    address public organizer2;
    address public user1;
    address public user2;
    address public attacker;
    
    function setUp() public {
        owner = makeAddr("owner");
        organizer1 = makeAddr("organizer1");
        organizer2 = makeAddr("organizer2");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        attacker = makeAddr("attacker");
        
        // Deploy factory
        vm.prank(owner);
        factory = new VeriTixFactory(owner);
        
        // Create a test event
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Test Event",
            symbol: "TEST",
            maxSupply: 100,
            ticketPrice: 1 ether,
            organizer: organizer1,
            baseURI: "https://test.com/",
            maxResalePercent: 110,
            organizerFeePercent: 5
        });
        
        vm.prank(organizer1);
        address eventAddr = factory.createEvent(params);
        eventContract = VeriTixEvent(eventAddr);
        
        // Fund test accounts
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(attacker, 10 ether);
    }

    // ============ FACTORY OWNER ACCESS CONTROL ============

    function testFactoryOwner_SetGlobalMaxResalePercent_Success() public {
        vm.prank(owner);
        factory.setGlobalMaxResalePercent(150);
        
        assertEq(factory.globalMaxResalePercent(), 150);
    }

    function testFactoryOwner_SetGlobalMaxResalePercent_RevertNonOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        factory.setGlobalMaxResalePercent(150);
    }

    function testFactoryOwner_SetDefaultOrganizerFee_Success() public {
        vm.prank(owner);
        factory.setDefaultOrganizerFee(10);
        
        assertEq(factory.defaultOrganizerFee(), 10);
    }

    function testFactoryOwner_SetDefaultOrganizerFee_RevertNonOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        factory.setDefaultOrganizerFee(10);
    }

    function testFactoryOwner_SetEventCreationFee_Success() public {
        vm.prank(owner);
        factory.setEventCreationFee(0.1 ether);
        
        assertEq(factory.eventCreationFee(), 0.1 ether);
    }

    function testFactoryOwner_SetEventCreationFee_RevertNonOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        factory.setEventCreationFee(0.1 ether);
    }

    function testFactoryOwner_SetPaused_Success() public {
        vm.prank(owner);
        factory.setPaused(true);
        
        assertTrue(factory.factoryPaused());
    }

    function testFactoryOwner_SetPaused_RevertNonOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        factory.setPaused(true);
    }

    function testFactoryOwner_TransferOwnership_Success() public {
        address newOwner = makeAddr("newOwner");
        
        vm.prank(owner);
        factory.transferOwnership(newOwner);
        
        // Verify new owner can perform owner functions
        vm.prank(newOwner);
        factory.setGlobalMaxResalePercent(200);
        
        assertEq(factory.globalMaxResalePercent(), 200);
    }

    function testFactoryOwner_TransferOwnership_RevertNonOwner() public {
        address newOwner = makeAddr("newOwner");
        
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        factory.transferOwnership(newOwner);
    }

    function testFactoryOwner_WithdrawFees_Success() public {
        // Set creation fee and create event to generate fees
        vm.prank(owner);
        factory.setEventCreationFee(0.1 ether);
        
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Fee Event",
            symbol: "FEE",
            maxSupply: 100,
            ticketPrice: 1 ether,
            organizer: organizer2,
            baseURI: "https://fee.com/",
            maxResalePercent: 110,
            organizerFeePercent: 5
        });
        
        // Fund organizer2 to pay creation fee
        vm.deal(organizer2, 1 ether);
        vm.prank(organizer2);
        factory.createEvent{value: 0.1 ether}(params);
        
        // Verify factory has the fee
        assertEq(address(factory).balance, 0.1 ether);
        
        // Withdraw fees
        address payable feeRecipient = payable(makeAddr("feeRecipient"));
        uint256 balanceBefore = feeRecipient.balance;
        
        vm.prank(owner);
        factory.withdrawFees(feeRecipient);
        
        assertEq(feeRecipient.balance - balanceBefore, 0.1 ether);
    }

    function testFactoryOwner_WithdrawFees_RevertNonOwner() public {
        address payable feeRecipient = payable(makeAddr("feeRecipient"));
        
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        factory.withdrawFees(feeRecipient);
    }

    function testFactoryOwner_UpdateEventStatus_Success() public {
        vm.prank(owner);
        factory.updateEventStatus(address(eventContract), VeriTixTypes.EventStatus.Cancelled);
        
        VeriTixTypes.EventRegistry memory registry = factory.getEventRegistry(address(eventContract));
        assertEq(uint256(registry.status), uint256(VeriTixTypes.EventStatus.Cancelled));
    }

    function testFactoryOwner_UpdateEventStatus_RevertNonOwner() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        factory.updateEventStatus(address(eventContract), VeriTixTypes.EventStatus.Cancelled);
    }

    // ============ EVENT ORGANIZER ACCESS CONTROL ============

    function testEventOrganizer_CheckIn_Success() public {
        // Mint a ticket first
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: 1 ether}();
        
        // Organizer can check in ticket
        vm.prank(organizer1);
        eventContract.checkIn(tokenId);
        
        assertTrue(eventContract.checkedIn(tokenId));
    }

    function testEventOrganizer_CheckIn_RevertNonOrganizer() public {
        // Mint a ticket first
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: 1 ether}();
        
        // Non-organizer cannot check in ticket
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        eventContract.checkIn(tokenId);
    }

    function testEventOrganizer_CancelEvent_Success() public {
        vm.prank(organizer1);
        eventContract.cancelEvent("Test cancellation");
        
        assertTrue(eventContract.cancelled());
    }

    function testEventOrganizer_CancelEvent_RevertNonOrganizer() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        eventContract.cancelEvent("Malicious cancellation");
    }

    function testEventOrganizer_SetBaseURI_Success() public {
        vm.prank(organizer1);
        eventContract.setBaseURI("https://newuri.com/");
        
        assertEq(eventContract.baseURI(), "https://newuri.com/");
    }

    function testEventOrganizer_SetBaseURI_RevertNonOrganizer() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        eventContract.setBaseURI("https://malicious.com/");
    }

    // ============ CROSS-EVENT ACCESS CONTROL ============

    function testCrossEvent_OrganizerCannotControlOtherEvents() public {
        // Create second event with different organizer
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Second Event",
            symbol: "SEC",
            maxSupply: 50,
            ticketPrice: 2 ether,
            organizer: organizer2,
            baseURI: "https://second.com/",
            maxResalePercent: 115,
            organizerFeePercent: 3
        });
        
        vm.prank(organizer2);
        address secondEventAddr = factory.createEvent(params);
        VeriTixEvent secondEvent = VeriTixEvent(secondEventAddr);
        
        // Mint ticket in second event
        vm.prank(user1);
        uint256 tokenId = secondEvent.mintTicket{value: 2 ether}();
        
        // Organizer1 cannot control organizer2's event
        vm.prank(organizer1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", organizer1));
        secondEvent.checkIn(tokenId);
        
        vm.prank(organizer1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", organizer1));
        secondEvent.cancelEvent("Cross-event attack");
        
        vm.prank(organizer1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", organizer1));
        secondEvent.setBaseURI("https://hijacked.com/");
    }

    // ============ TRANSFER RESTRICTION ENFORCEMENT ============

    function testTransferRestrictions_DirectTransferBlocked() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: 1 ether}();
        
        // Direct transfer should be blocked
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.TransfersDisabled.selector));
        eventContract.transferFrom(user1, user2, tokenId);
    }

    function testTransferRestrictions_SafeTransferBlocked() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: 1 ether}();
        
        // Safe transfer should be blocked
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.TransfersDisabled.selector));
        eventContract.safeTransferFrom(user1, user2, tokenId);
    }

    function testTransferRestrictions_ApprovalTransferBlocked() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: 1 ether}();
        
        // Approve another user
        vm.prank(user1);
        eventContract.approve(user2, tokenId);
        
        // Approved transfer should still be blocked
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.TransfersDisabled.selector));
        eventContract.transferFrom(user1, user2, tokenId);
    }

    function testTransferRestrictions_ResaleAllowed() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: 1 ether}();
        
        // Resale through controlled mechanism should work
        vm.prank(user2);
        eventContract.resaleTicket{value: 1.05 ether}(tokenId, 1.05 ether);
        
        // Verify ownership changed
        assertEq(eventContract.ownerOf(tokenId), user2);
    }

    // ============ PRIVILEGE ESCALATION PREVENTION ============

    function testPrivilegeEscalation_CannotBypassFactoryOwnership() public {
        // Attacker cannot create events when factory is paused
        vm.prank(owner);
        factory.setPaused(true);
        
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Bypass Event",
            symbol: "BYP",
            maxSupply: 100,
            ticketPrice: 1 ether,
            organizer: attacker,
            baseURI: "https://bypass.com/",
            maxResalePercent: 110,
            organizerFeePercent: 5
        });
        
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixFactory.FactoryPaused.selector));
        factory.createEvent(params);
    }

    function testPrivilegeEscalation_CannotBypassEventOwnership() public {
        // Attacker cannot perform organizer functions even with creative attempts
        
        // Try to check in non-existent ticket
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        eventContract.checkIn(999);
        
        // Try to cancel with empty reason
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        eventContract.cancelEvent("");
        
        // Try to set invalid base URI
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        eventContract.setBaseURI("");
    }

    // ============ BATCH OPERATION ACCESS CONTROL ============

    function testBatchOperations_OnlyValidOrganizers() public {
        VeriTixTypes.EventCreationParams[] memory paramsArray = 
            new VeriTixTypes.EventCreationParams[](2);
        
        // First event with valid organizer
        paramsArray[0] = VeriTixTypes.EventCreationParams({
            name: "Batch Event 1",
            symbol: "BATCH1",
            maxSupply: 100,
            ticketPrice: 1 ether,
            organizer: organizer1,
            baseURI: "https://batch1.com/",
            maxResalePercent: 110,
            organizerFeePercent: 5
        });
        
        // Second event with zero address organizer (should fail)
        paramsArray[1] = VeriTixTypes.EventCreationParams({
            name: "Batch Event 2",
            symbol: "BATCH2",
            maxSupply: 100,
            ticketPrice: 1 ether,
            organizer: address(0),
            baseURI: "https://batch2.com/",
            maxResalePercent: 110,
            organizerFeePercent: 5
        });
        
        // Batch creation should fail due to invalid organizer
        vm.prank(organizer1);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixFactory.InvalidOrganizerAddress.selector));
        factory.batchCreateEvents(paramsArray);
    }

    // ============ EMERGENCY FUNCTIONS ACCESS CONTROL ============

    function testEmergencyFunctions_OnlyOwnerCanUpdateEventStatus() public {
        // Only factory owner can update event status
        vm.prank(owner);
        factory.updateEventStatus(address(eventContract), VeriTixTypes.EventStatus.SoldOut);
        
        VeriTixTypes.EventRegistry memory registry = factory.getEventRegistry(address(eventContract));
        assertEq(uint256(registry.status), uint256(VeriTixTypes.EventStatus.SoldOut));
        
        // Event organizer cannot update status
        vm.prank(organizer1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", organizer1));
        factory.updateEventStatus(address(eventContract), VeriTixTypes.EventStatus.Cancelled);
    }

    function testEmergencyFunctions_OnlyOwnerCanWithdrawFees() public {
        // Set creation fee
        vm.prank(owner);
        factory.setEventCreationFee(0.1 ether);
        
        // Create event to generate fees
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Fee Event",
            symbol: "FEE",
            maxSupply: 100,
            ticketPrice: 1 ether,
            organizer: organizer1,
            baseURI: "https://fee.com/",
            maxResalePercent: 110,
            organizerFeePercent: 5
        });
        
        // Fund organizer1 to pay creation fee
        vm.deal(organizer1, 1 ether);
        vm.prank(organizer1);
        factory.createEvent{value: 0.1 ether}(params);
        
        // Only owner can withdraw fees
        address payable recipient = payable(makeAddr("recipient"));
        
        vm.prank(organizer1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", organizer1));
        factory.withdrawFees(recipient);
        
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", attacker));
        factory.withdrawFees(recipient);
    }
}