// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/interfaces/IVeriTixFactory.sol";
import "../src/libraries/VeriTixTypes.sol";

contract VeriTixFactoryTest is Test {
    VeriTixFactory public factory;
    address public owner;
    address public organizer1;
    address public organizer2;
    address public user1;
    
    // Test event parameters
    VeriTixTypes.EventCreationParams public validParams;
    
    event EventCreated(
        address indexed eventContract,
        address indexed organizer,
        string eventName,
        uint256 ticketPrice,
        uint256 maxSupply
    );
    
    event FactorySettingUpdated(string setting, uint256 oldValue, uint256 newValue);
    event FactoryPauseToggled(bool isPaused);
    
    function setUp() public {
        owner = address(this);
        organizer1 = makeAddr("organizer1");
        organizer2 = makeAddr("organizer2");
        user1 = makeAddr("user1");
        
        // Deploy factory
        factory = new VeriTixFactory(owner);
        
        // Set up valid event parameters
        validParams = VeriTixTypes.EventCreationParams({
            name: "Test Concert",
            symbol: "TCONCERT",
            maxSupply: 1000,
            ticketPrice: 0.1 ether,
            baseURI: "https://api.example.com/metadata/",
            maxResalePercent: 110,
            organizerFeePercent: 5,
            organizer: organizer1
        });
    }
    
    // ============ DEPLOYMENT TESTS ============
    
    function test_FactoryDeployment() public {
        assertEq(factory.owner(), owner);
        assertEq(factory.globalMaxResalePercent(), 120);
        assertEq(factory.defaultOrganizerFee(), 5);
        assertEq(factory.eventCreationFee(), 0);
        assertFalse(factory.factoryPaused());
        assertEq(factory.getTotalEvents(), 0);
    }
    
    function test_FactoryConfig() public {
        VeriTixTypes.FactoryConfig memory config = factory.getFactoryConfig();
        
        assertEq(config.platformOwner, owner);
        assertEq(config.globalMaxResalePercent, 120);
        assertEq(config.defaultOrganizerFee, 5);
        assertEq(config.eventCreationFee, 0);
        assertFalse(config.factoryPaused);
    }
    
    // ============ EVENT CREATION TESTS ============
    
    function test_CreateEvent_Success() public {
        vm.expectEmit(false, true, false, true);
        emit EventCreated(
            address(0), // We don't know the address beforehand
            organizer1,
            "Test Concert",
            0.1 ether,
            1000
        );
        
        address eventContract = factory.createEvent(validParams);
        
        // Verify event was created
        assertTrue(eventContract != address(0));
        assertEq(factory.getTotalEvents(), 1);
        
        // Verify registry
        VeriTixTypes.EventRegistry memory registry = factory.getEventRegistry(eventContract);
        assertEq(registry.eventContract, eventContract);
        assertEq(registry.organizer, organizer1);
        assertEq(registry.eventName, "Test Concert");
        assertEq(uint256(registry.status), uint256(VeriTixTypes.EventStatus.Active));
        assertEq(registry.ticketPrice, 0.1 ether);
        assertEq(registry.maxSupply, 1000);
        
        // Verify organizer tracking
        address[] memory organizerEvents = factory.getEventsByOrganizer(organizer1);
        assertEq(organizerEvents.length, 1);
        assertEq(organizerEvents[0], eventContract);
        
        // Verify deployed events tracking
        address[] memory deployedEvents = factory.getDeployedEvents();
        assertEq(deployedEvents.length, 1);
        assertEq(deployedEvents[0], eventContract);
        
        // Verify the deployed contract is valid
        assertTrue(factory.isValidEventContract(eventContract));
    }
    
    function test_CreateEvent_WithCreationFee() public {
        // Set creation fee
        factory.setEventCreationFee(0.01 ether);
        
        // Should fail without fee
        vm.expectRevert(
            abi.encodeWithSelector(
                IVeriTixFactory.InsufficientCreationFee.selector,
                0,
                0.01 ether
            )
        );
        factory.createEvent(validParams);
        
        // Should succeed with fee
        address eventContract = factory.createEvent{value: 0.01 ether}(validParams);
        assertTrue(eventContract != address(0));
        assertEq(address(factory).balance, 0.01 ether);
    }
    
    function test_CreateEvent_InvalidParameters() public {
        // Test empty name
        VeriTixTypes.EventCreationParams memory invalidParams = validParams;
        invalidParams.name = "";
        
        vm.expectRevert(IVeriTixFactory.InvalidEventParameters.selector);
        factory.createEvent(invalidParams);
        
        // Test zero max supply
        invalidParams = validParams;
        invalidParams.maxSupply = 0;
        
        vm.expectRevert(IVeriTixFactory.InvalidEventParameters.selector);
        factory.createEvent(invalidParams);
        
        // Test low ticket price
        invalidParams = validParams;
        invalidParams.ticketPrice = 0.0001 ether; // Below minimum
        
        vm.expectRevert(IVeriTixFactory.InvalidEventParameters.selector);
        factory.createEvent(invalidParams);
        
        // Test zero organizer
        invalidParams = validParams;
        invalidParams.organizer = address(0);
        
        vm.expectRevert(IVeriTixFactory.InvalidEventParameters.selector);
        factory.createEvent(invalidParams);
    }
    
    function test_CreateEvent_ExceedsGlobalResaleLimit() public {
        VeriTixTypes.EventCreationParams memory invalidParams = validParams;
        invalidParams.maxResalePercent = 150; // Exceeds default 120%
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IVeriTixFactory.ExceedsGlobalResaleLimit.selector,
                150,
                120
            )
        );
        factory.createEvent(invalidParams);
    }
    
    function test_CreateEvent_WhenPaused() public {
        factory.setPaused(true);
        
        vm.expectRevert(IVeriTixFactory.FactoryPaused.selector);
        factory.createEvent(validParams);
    }
    
    function test_CreateMultipleEvents() public {
        // Create first event
        address event1 = factory.createEvent(validParams);
        
        // Create second event with different organizer
        validParams.organizer = organizer2;
        validParams.name = "Second Concert";
        address event2 = factory.createEvent(validParams);
        
        // Verify both events exist
        assertEq(factory.getTotalEvents(), 2);
        
        address[] memory deployedEvents = factory.getDeployedEvents();
        assertEq(deployedEvents.length, 2);
        assertEq(deployedEvents[0], event1);
        assertEq(deployedEvents[1], event2);
        
        // Verify organizer separation
        address[] memory org1Events = factory.getEventsByOrganizer(organizer1);
        address[] memory org2Events = factory.getEventsByOrganizer(organizer2);
        
        assertEq(org1Events.length, 1);
        assertEq(org2Events.length, 1);
        assertEq(org1Events[0], event1);
        assertEq(org2Events[0], event2);
    }    
  
  // ============ BATCH CREATION TESTS ============
    
    function test_BatchCreateEvents_Success() public {
        VeriTixTypes.EventCreationParams[] memory paramsArray = 
            new VeriTixTypes.EventCreationParams[](2);
        
        paramsArray[0] = validParams;
        paramsArray[1] = VeriTixTypes.EventCreationParams({
            name: "Second Concert",
            symbol: "SCONCERT",
            maxSupply: 500,
            ticketPrice: 0.05 ether,
            baseURI: "https://api.example.com/metadata2/",
            maxResalePercent: 115,
            organizerFeePercent: 3,
            organizer: organizer2
        });
        
        address[] memory eventContracts = factory.batchCreateEvents(paramsArray);
        
        assertEq(eventContracts.length, 2);
        assertEq(factory.getTotalEvents(), 2);
        
        // Verify both events are registered
        assertTrue(factory.isValidEventContract(eventContracts[0]));
        assertTrue(factory.isValidEventContract(eventContracts[1]));
    }
    
    function test_BatchCreateEvents_EmptyArray() public {
        VeriTixTypes.EventCreationParams[] memory emptyArray = 
            new VeriTixTypes.EventCreationParams[](0);
        
        vm.expectRevert("Empty params array");
        factory.batchCreateEvents(emptyArray);
    }
    
    function test_BatchCreateEvents_TooManyEvents() public {
        VeriTixTypes.EventCreationParams[] memory largeArray = 
            new VeriTixTypes.EventCreationParams[](11);
        
        vm.expectRevert("Too many events in batch");
        factory.batchCreateEvents(largeArray);
    }
    
    // ============ GLOBAL POLICY TESTS ============
    
    function test_SetGlobalMaxResalePercent_Success() public {
        vm.expectEmit(true, true, true, true);
        emit FactorySettingUpdated("globalMaxResalePercent", 120, 150);
        
        factory.setGlobalMaxResalePercent(150);
        assertEq(factory.globalMaxResalePercent(), 150);
    }
    
    function test_SetGlobalMaxResalePercent_InvalidValues() public {
        // Test below 100%
        vm.expectRevert("Must be at least 100%");
        factory.setGlobalMaxResalePercent(99);
        
        // Test above maximum
        vm.expectRevert("Exceeds maximum allowed");
        factory.setGlobalMaxResalePercent(301);
    }
    
    function test_SetGlobalMaxResalePercent_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        factory.setGlobalMaxResalePercent(150);
    }
    
    function test_SetDefaultOrganizerFee_Success() public {
        vm.expectEmit(true, true, true, true);
        emit FactorySettingUpdated("defaultOrganizerFee", 5, 10);
        
        factory.setDefaultOrganizerFee(10);
        assertEq(factory.defaultOrganizerFee(), 10);
    }
    
    function test_SetDefaultOrganizerFee_TooHigh() public {
        vm.expectRevert("Fee too high");
        factory.setDefaultOrganizerFee(51); // Above 50% limit
    }
    
    function test_SetEventCreationFee_Success() public {
        vm.expectEmit(true, true, true, true);
        emit FactorySettingUpdated("eventCreationFee", 0, 0.01 ether);
        
        factory.setEventCreationFee(0.01 ether);
        assertEq(factory.eventCreationFee(), 0.01 ether);
    }
    
    function test_SetPaused_Success() public {
        vm.expectEmit(true, true, true, true);
        emit FactoryPauseToggled(true);
        
        factory.setPaused(true);
        assertTrue(factory.factoryPaused());
        
        vm.expectEmit(true, true, true, true);
        emit FactoryPauseToggled(false);
        
        factory.setPaused(false);
        assertFalse(factory.factoryPaused());
    }
    
    // ============ DISCOVERY TESTS ============
    
    function test_GetEventsPaginated() public {
        // Create multiple events
        for (uint256 i = 0; i < 5; i++) {
            validParams.name = string(abi.encodePacked("Event ", vm.toString(i)));
            validParams.symbol = string(abi.encodePacked("EVT", vm.toString(i)));
            factory.createEvent(validParams);
        }
        
        // Test pagination
        (VeriTixTypes.EventRegistry[] memory events, uint256 totalCount) = 
            factory.getEventsPaginated(0, 3);
        
        assertEq(totalCount, 5);
        assertEq(events.length, 3);
        
        // Test second page
        (events, totalCount) = factory.getEventsPaginated(3, 3);
        assertEq(totalCount, 5);
        assertEq(events.length, 2);
        
        // Test out of bounds
        (events, totalCount) = factory.getEventsPaginated(10, 3);
        assertEq(totalCount, 5);
        assertEq(events.length, 0);
    }
    
    function test_GetEventsByStatus() public {
        // Create an event
        address eventContract = factory.createEvent(validParams);
        
        // Test active events
        address[] memory activeEvents = factory.getEventsByStatus(VeriTixTypes.EventStatus.Active);
        assertEq(activeEvents.length, 1);
        assertEq(activeEvents[0], eventContract);
        
        // Test cancelled events (should be empty)
        address[] memory cancelledEvents = factory.getEventsByStatus(VeriTixTypes.EventStatus.Cancelled);
        assertEq(cancelledEvents.length, 0);
    }
    
    function test_GetOrganizerEventCount() public {
        assertEq(factory.getOrganizerEventCount(organizer1), 0);
        
        // Create events for organizer1
        factory.createEvent(validParams);
        assertEq(factory.getOrganizerEventCount(organizer1), 1);
        
        factory.createEvent(validParams);
        assertEq(factory.getOrganizerEventCount(organizer1), 2);
        
        // Organizer2 should still have 0
        assertEq(factory.getOrganizerEventCount(organizer2), 0);
    }
    
    // ============ ANALYTICS TESTS ============
    
    function test_GetGlobalStats() public {
        // Create some events
        factory.createEvent(validParams);
        
        validParams.organizer = organizer2;
        factory.createEvent(validParams);
        
        (uint256 totalTicketsSold, uint256 totalRevenue, uint256 totalEvents, uint256 activeEvents) = 
            factory.getGlobalStats();
        
        assertEq(totalEvents, 2);
        assertEq(activeEvents, 2);
        // Note: totalTicketsSold and totalRevenue would be 0 in this test
        // as we haven't implemented the full analytics tracking
    }
    
    // ============ OWNERSHIP TESTS ============
    
    function test_TransferOwnership_Success() public {
        factory.transferOwnership(user1);
        assertEq(factory.owner(), user1);
    }
    
    function test_TransferOwnership_ZeroAddress() public {
        vm.expectRevert("New owner cannot be zero address");
        factory.transferOwnership(address(0));
    }
    
    function test_TransferOwnership_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        factory.transferOwnership(user1);
    }
    
    // ============ FEE WITHDRAWAL TESTS ============
    
    function test_WithdrawFees_Success() public {
        // Set creation fee and create event
        factory.setEventCreationFee(0.01 ether);
        factory.createEvent{value: 0.01 ether}(validParams);
        
        assertEq(address(factory).balance, 0.01 ether);
        
        uint256 balanceBefore = address(this).balance;
        factory.withdrawFees(payable(address(this)));
        
        assertEq(address(factory).balance, 0);
        assertEq(address(this).balance, balanceBefore + 0.01 ether);
    }
    
    function test_WithdrawFees_NoFees() public {
        vm.expectRevert("No fees to withdraw");
        factory.withdrawFees(payable(address(this)));
    }
    
    function test_WithdrawFees_InvalidRecipient() public {
        factory.setEventCreationFee(0.01 ether);
        factory.createEvent{value: 0.01 ether}(validParams);
        
        vm.expectRevert("Invalid recipient");
        factory.withdrawFees(payable(address(0)));
    }
    
    function test_WithdrawFees_OnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        factory.withdrawFees(payable(user1));
    }
    
    // ============ EMERGENCY FUNCTIONS TESTS ============
    
    function test_UpdateEventStatus_Success() public {
        address eventContract = factory.createEvent(validParams);
        
        factory.updateEventStatus(eventContract, VeriTixTypes.EventStatus.Cancelled);
        
        VeriTixTypes.EventRegistry memory registry = factory.getEventRegistry(eventContract);
        assertEq(uint256(registry.status), uint256(VeriTixTypes.EventStatus.Cancelled));
    }
    
    function test_UpdateEventStatus_EventNotFound() public {
        vm.expectRevert("Event not found");
        factory.updateEventStatus(address(0x123), VeriTixTypes.EventStatus.Cancelled);
    }
    
    function test_UpdateEventStatus_OnlyOwner() public {
        address eventContract = factory.createEvent(validParams);
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        factory.updateEventStatus(eventContract, VeriTixTypes.EventStatus.Cancelled);
    }
    
    // ============ INTEGRATION TESTS ============
    
    function test_FactoryEventIntegration() public {
        // Create event through factory
        address eventContract = factory.createEvent(validParams);
        
        // Verify the deployed event contract works
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        assertEq(eventInstance.name(), "Test Concert");
        assertEq(eventInstance.symbol(), "TCONCERT");
        assertEq(eventInstance.maxSupply(), 1000);
        assertEq(eventInstance.ticketPrice(), 0.1 ether);
        assertEq(eventInstance.organizer(), organizer1);
        assertEq(eventInstance.maxResalePercent(), 110);
        assertEq(eventInstance.organizerFeePercent(), 5);
        assertEq(eventInstance.owner(), organizer1);
    }
    
    // Helper function to receive ETH
    receive() external payable {}
}