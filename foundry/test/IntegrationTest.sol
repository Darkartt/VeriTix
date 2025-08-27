// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/interfaces/IVeriTixFactory.sol";
import "../src/interfaces/IVeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title IntegrationTest
 * @dev Comprehensive integration tests for complete VeriTix workflows
 * @notice Tests end-to-end scenarios across factory and event contracts
 */
contract IntegrationTest is Test {
    
    // ============ TEST CONTRACTS ============
    
    VeriTixFactory public factory;
    
    // ============ TEST ADDRESSES ============
    
    address public platformOwner;
    address public organizer1;
    address public organizer2;
    address public organizer3;
    address public buyer1;
    address public buyer2;
    address public buyer3;
    address public venue;
    
    // ============ TEST CONSTANTS ============
    
    uint256 constant TICKET_PRICE = 0.1 ether;
    uint256 constant MAX_SUPPLY = 100;
    string constant BASE_URI = "https://api.veritix.com/metadata/";
    
    // ============ EVENTS ============
    
    event TicketLifecycleCompleted(
        address indexed eventContract,
        uint256 indexed tokenId,
        address indexed finalOwner
    );
    
    // ============ SETUP ============
    
    function setUp() public {
        // Set up test addresses
        platformOwner = makeAddr("platformOwner");
        organizer1 = makeAddr("organizer1");
        organizer2 = makeAddr("organizer2");
        organizer3 = makeAddr("organizer3");
        buyer1 = makeAddr("buyer1");
        buyer2 = makeAddr("buyer2");
        buyer3 = makeAddr("buyer3");
        venue = makeAddr("venue");
        
        // Fund test addresses
        vm.deal(organizer1, 10 ether);
        vm.deal(organizer2, 10 ether);
        vm.deal(organizer3, 10 ether);
        vm.deal(buyer1, 10 ether);
        vm.deal(buyer2, 10 ether);
        vm.deal(buyer3, 10 ether);
        
        // Deploy factory
        vm.prank(platformOwner);
        factory = new VeriTixFactory(platformOwner);
    }
    
    // ============ HELPER FUNCTIONS ============
    
    function createTestEvent(
        address organizer,
        string memory name,
        string memory symbol,
        uint256 maxSupply_,
        uint256 ticketPrice_
    ) internal returns (address) {
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: name,
            symbol: symbol,
            maxSupply: maxSupply_,
            ticketPrice: ticketPrice_,
            baseURI: BASE_URI,
            maxResalePercent: 110, // 10% markup allowed
            organizerFeePercent: 5, // 5% organizer fee
            organizer: organizer
        });
        
        return factory.createEvent(params);
    }
    
    function mintTicketAs(address eventContract, address buyer) internal returns (uint256) {
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        uint256 price = eventInstance.ticketPrice();
        
        vm.prank(buyer);
        return eventInstance.mintTicket{value: price}();
    }
    
    function resaleTicketAs(
        address eventContract,
        uint256 tokenId,
        address newBuyer,
        uint256 resalePrice
    ) internal {
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        vm.prank(newBuyer);
        eventInstance.resaleTicket{value: resalePrice}(tokenId, resalePrice);
    }
    
    function checkInTicketAs(
        address eventContract,
        uint256 tokenId,
        address organizer
    ) internal {
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        vm.prank(organizer);
        eventInstance.checkIn(tokenId);
    }
    
    function cancelEventAs(address eventContract, address organizer) internal {
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        vm.prank(organizer);
        eventInstance.cancelEvent("Event cancelled for testing");
    }
    
    function refundTicketAs(address eventContract, uint256 tokenId, address owner) internal {
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        vm.prank(owner);
        eventInstance.refund(tokenId);
    }
    
    function cancelRefundAs(address eventContract, uint256 tokenId, address owner) internal {
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        vm.prank(owner);
        eventInstance.cancelRefund(tokenId);
    }
    
    // ============ COMPLETE TICKET LIFECYCLE TESTS ============
    
    /**
     * @dev Test complete ticket lifecycle: create event → mint → resale → check-in
     */
    function test_CompleteTicketLifecycle_Success() public {
        // Step 1: Create event
        address eventContract = createTestEvent(
            organizer1,
            "Concert 2024",
            "CONCERT24",
            MAX_SUPPLY,
            TICKET_PRICE
        );
        
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        // Verify event creation
        assertEq(factory.getTotalEvents(), 1);
        assertTrue(factory.isValidEventContract(eventContract));
        
        // Step 2: Primary ticket sale (mint)
        uint256 tokenId = mintTicketAs(eventContract, buyer1);
        
        // Verify minting
        assertEq(tokenId, 1);
        assertEq(eventInstance.ownerOf(tokenId), buyer1);
        assertEq(eventInstance.totalSupply(), 1);
        assertEq(eventInstance.getLastPricePaid(tokenId), TICKET_PRICE);
        assertEq(eventInstance.getOriginalPrice(tokenId), TICKET_PRICE);
        assertFalse(eventInstance.isCheckedIn(tokenId));
        
        // Step 3: Resale
        uint256 resalePrice = (TICKET_PRICE * 105) / 100; // 5% markup
        uint256 expectedOrganizerFee = (resalePrice * 5) / 100; // 5% fee
        uint256 expectedSellerProceeds = resalePrice - expectedOrganizerFee;
        
        uint256 buyer1BalanceBefore = buyer1.balance;
        uint256 organizerBalanceBefore = organizer1.balance;
        
        resaleTicketAs(eventContract, tokenId, buyer2, resalePrice);
        
        // Verify resale
        assertEq(eventInstance.ownerOf(tokenId), buyer2);
        assertEq(eventInstance.getLastPricePaid(tokenId), resalePrice);
        assertEq(eventInstance.getOriginalPrice(tokenId), TICKET_PRICE); // Original unchanged
        
        // Verify fund distribution
        assertEq(buyer1.balance, buyer1BalanceBefore + expectedSellerProceeds);
        assertEq(organizer1.balance, organizerBalanceBefore + expectedOrganizerFee);
        
        // Step 4: Check-in at venue
        checkInTicketAs(eventContract, tokenId, organizer1);
        
        // Verify check-in
        assertTrue(eventInstance.isCheckedIn(tokenId));
        
        // Step 5: Verify post-check-in restrictions
        // Should not be able to resale after check-in
        vm.expectRevert(IVeriTixEvent.TicketAlreadyUsed.selector);
        vm.prank(buyer3);
        eventInstance.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        // Should not be able to refund after check-in
        vm.expectRevert(IVeriTixEvent.TicketAlreadyUsed.selector);
        vm.prank(buyer2);
        eventInstance.refund(tokenId);
        
        // Emit completion event
        emit TicketLifecycleCompleted(eventContract, tokenId, buyer2);
    }
    
    /**
     * @dev Test multiple resales in ticket lifecycle
     */
    function test_CompleteTicketLifecycle_MultipleResales() public {
        // Create event
        address eventContract = createTestEvent(
            organizer1,
            "Multi-Resale Event",
            "MULTI",
            MAX_SUPPLY,
            TICKET_PRICE
        );
        
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        // Primary sale
        uint256 tokenId = mintTicketAs(eventContract, buyer1);
        
        // First resale: buyer1 → buyer2
        uint256 firstResalePrice = (TICKET_PRICE * 103) / 100; // 3% markup
        resaleTicketAs(eventContract, tokenId, buyer2, firstResalePrice);
        
        assertEq(eventInstance.ownerOf(tokenId), buyer2);
        assertEq(eventInstance.getLastPricePaid(tokenId), firstResalePrice);
        
        // Second resale: buyer2 → buyer3
        uint256 secondResalePrice = (TICKET_PRICE * 107) / 100; // 7% markup
        resaleTicketAs(eventContract, tokenId, buyer3, secondResalePrice);
        
        assertEq(eventInstance.ownerOf(tokenId), buyer3);
        assertEq(eventInstance.getLastPricePaid(tokenId), secondResalePrice);
        assertEq(eventInstance.getOriginalPrice(tokenId), TICKET_PRICE); // Original unchanged
        
        // Final check-in
        checkInTicketAs(eventContract, tokenId, organizer1);
        assertTrue(eventInstance.isCheckedIn(tokenId));
    }
    
    /**
     * @dev Test ticket lifecycle with refund instead of check-in
     */
    function test_CompleteTicketLifecycle_WithRefund() public {
        // Create event
        address eventContract = createTestEvent(
            organizer1,
            "Refund Event",
            "REFUND",
            MAX_SUPPLY,
            TICKET_PRICE
        );
        
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        // Primary sale
        uint256 tokenId = mintTicketAs(eventContract, buyer1);
        
        // Resale
        uint256 resalePrice = (TICKET_PRICE * 108) / 100; // 8% markup
        resaleTicketAs(eventContract, tokenId, buyer2, resalePrice);
        
        // Buyer2 decides to refund (gets original face value)
        uint256 buyer2BalanceBefore = buyer2.balance;
        
        refundTicketAs(eventContract, tokenId, buyer2);
        
        // Verify refund
        assertEq(buyer2.balance, buyer2BalanceBefore + TICKET_PRICE); // Face value refund
        assertEq(eventInstance.totalSupply(), 0); // Token burned
        
        // Verify token no longer exists
        vm.expectRevert();
        eventInstance.ownerOf(tokenId);
    }
    
    // ============ EVENT CANCELLATION AND MASS REFUND TESTS ============
    
    /**
     * @dev Test event cancellation with mass refunds
     */
    function test_EventCancellation_MassRefunds() public {
        // Create event
        address eventContract = createTestEvent(
            organizer1,
            "Cancelled Event",
            "CANCEL",
            10, // Small event for testing
            TICKET_PRICE
        );
        
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        // Multiple buyers purchase tickets
        uint256 tokenId1 = mintTicketAs(eventContract, buyer1);
        uint256 tokenId2 = mintTicketAs(eventContract, buyer2);
        uint256 tokenId3 = mintTicketAs(eventContract, buyer3);
        
        // Some resales occur
        uint256 resalePrice = (TICKET_PRICE * 105) / 100;
        resaleTicketAs(eventContract, tokenId2, buyer1, resalePrice); // buyer2 → buyer1
        
        // Verify pre-cancellation state
        assertEq(eventInstance.totalSupply(), 3);
        assertEq(eventInstance.ownerOf(tokenId1), buyer1);
        assertEq(eventInstance.ownerOf(tokenId2), buyer1); // After resale
        assertEq(eventInstance.ownerOf(tokenId3), buyer3);
        
        // Organizer cancels event
        cancelEventAs(eventContract, organizer1);
        
        // Verify cancellation
        assertTrue(eventInstance.cancelled());
        
        // Verify new ticket sales are blocked
        vm.expectRevert(IVeriTixEvent.EventIsCancelled.selector);
        vm.prank(buyer2);
        eventInstance.mintTicket{value: TICKET_PRICE}();
        
        // Verify resales are blocked
        vm.expectRevert(IVeriTixEvent.EventIsCancelled.selector);
        vm.prank(buyer2);
        eventInstance.resaleTicket{value: resalePrice}(tokenId3, resalePrice);
        
        // Process cancellation refunds
        uint256 buyer1BalanceBefore = buyer1.balance;
        uint256 buyer3BalanceBefore = buyer3.balance;
        
        // buyer1 refunds both tickets (gets face value for each)
        cancelRefundAs(eventContract, tokenId1, buyer1);
        cancelRefundAs(eventContract, tokenId2, buyer1);
        
        // buyer3 refunds their ticket
        cancelRefundAs(eventContract, tokenId3, buyer3);
        
        // Verify refunds (all at face value regardless of resale prices)
        assertEq(buyer1.balance, buyer1BalanceBefore + (2 * TICKET_PRICE));
        assertEq(buyer3.balance, buyer3BalanceBefore + TICKET_PRICE);
        
        // Verify all tokens burned
        assertEq(eventInstance.totalSupply(), 0);
    }
    
    /**
     * @dev Test partial cancellation refunds
     */
    function test_EventCancellation_PartialRefunds() public {
        // Create event
        address eventContract = createTestEvent(
            organizer1,
            "Partial Cancel Event",
            "PARTIAL",
            5,
            TICKET_PRICE
        );
        
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        // Multiple tickets sold
        uint256 tokenId1 = mintTicketAs(eventContract, buyer1);
        uint256 tokenId2 = mintTicketAs(eventContract, buyer2);
        uint256 tokenId3 = mintTicketAs(eventContract, buyer3);
        
        // One ticket gets checked in before cancellation
        checkInTicketAs(eventContract, tokenId1, organizer1);
        
        // Event gets cancelled
        cancelEventAs(eventContract, organizer1);
        
        // Checked-in ticket CAN be refunded after cancellation (business logic allows this)
        uint256 buyer1BalanceBefore = buyer1.balance;
        cancelRefundAs(eventContract, tokenId1, buyer1);
        assertEq(buyer1.balance, buyer1BalanceBefore + TICKET_PRICE);
        
        // Other tickets can be refunded
        cancelRefundAs(eventContract, tokenId2, buyer2);
        cancelRefundAs(eventContract, tokenId3, buyer3);
        
        // Verify final state - all tickets refunded
        assertEq(eventInstance.totalSupply(), 0); // All tickets refunded
    }
    
    // ============ MULTIPLE CONCURRENT EVENTS TESTS ============
    
    /**
     * @dev Test multiple concurrent events with different organizers
     */
    function test_MultipleConcurrentEvents_DifferentOrganizers() public {
        // Create multiple events with different organizers
        address event1 = createTestEvent(organizer1, "Concert A", "CONA", 50, 0.1 ether);
        address event2 = createTestEvent(organizer2, "Concert B", "CONB", 100, 0.2 ether);
        address event3 = createTestEvent(organizer3, "Concert C", "CONC", 25, 0.05 ether);
        
        // Verify factory registry
        assertEq(factory.getTotalEvents(), 3);
        
        address[] memory deployedEvents = factory.getDeployedEvents();
        assertEq(deployedEvents.length, 3);
        assertEq(deployedEvents[0], event1);
        assertEq(deployedEvents[1], event2);
        assertEq(deployedEvents[2], event3);
        
        // Verify organizer separation
        address[] memory org1Events = factory.getEventsByOrganizer(organizer1);
        address[] memory org2Events = factory.getEventsByOrganizer(organizer2);
        address[] memory org3Events = factory.getEventsByOrganizer(organizer3);
        
        assertEq(org1Events.length, 1);
        assertEq(org2Events.length, 1);
        assertEq(org3Events.length, 1);
        assertEq(org1Events[0], event1);
        assertEq(org2Events[0], event2);
        assertEq(org3Events[0], event3);
        
        // Test concurrent ticket operations
        VeriTixEvent event1Instance = VeriTixEvent(event1);
        VeriTixEvent event2Instance = VeriTixEvent(event2);
        VeriTixEvent event3Instance = VeriTixEvent(event3);
        
        // Concurrent minting across events
        uint256 token1 = mintTicketAs(event1, buyer1);
        uint256 token2 = mintTicketAs(event2, buyer2);
        uint256 token3 = mintTicketAs(event3, buyer3);
        
        // Verify isolation
        assertEq(event1Instance.ownerOf(token1), buyer1);
        assertEq(event2Instance.ownerOf(token2), buyer2);
        assertEq(event3Instance.ownerOf(token3), buyer3);
        
        assertEq(event1Instance.totalSupply(), 1);
        assertEq(event2Instance.totalSupply(), 1);
        assertEq(event3Instance.totalSupply(), 1);
        
        // Concurrent resales
        uint256 resalePrice1 = (0.1 ether * 105) / 100;
        uint256 resalePrice2 = (0.2 ether * 108) / 100;
        uint256 resalePrice3 = (0.05 ether * 110) / 100;
        
        resaleTicketAs(event1, token1, buyer2, resalePrice1);
        resaleTicketAs(event2, token2, buyer3, resalePrice2);
        resaleTicketAs(event3, token3, buyer1, resalePrice3);
        
        // Verify cross-event isolation
        assertEq(event1Instance.ownerOf(token1), buyer2);
        assertEq(event2Instance.ownerOf(token2), buyer3);
        assertEq(event3Instance.ownerOf(token3), buyer1);
        
        // One event gets cancelled, others continue
        cancelEventAs(event2, organizer2);
        assertTrue(event2Instance.cancelled());
        assertFalse(event1Instance.cancelled());
        assertFalse(event3Instance.cancelled());
        
        // Cancelled event blocks new operations
        vm.expectRevert(IVeriTixEvent.EventIsCancelled.selector);
        vm.prank(buyer1);
        event2Instance.mintTicket{value: 0.2 ether}();
        
        // Other events continue normally
        mintTicketAs(event1, buyer3);
        mintTicketAs(event3, buyer2);
        
        assertEq(event1Instance.totalSupply(), 2);
        assertEq(event3Instance.totalSupply(), 2);
    }
    
    /**
     * @dev Test single organizer with multiple events
     */
    function test_SingleOrganizer_MultipleEvents() public {
        // Single organizer creates multiple events
        address event1 = createTestEvent(organizer1, "Early Show", "EARLY", 30, 0.08 ether);
        address event2 = createTestEvent(organizer1, "Late Show", "LATE", 30, 0.12 ether);
        address event3 = createTestEvent(organizer1, "VIP Show", "VIP", 10, 0.5 ether);
        
        // Verify organizer tracking
        address[] memory org1Events = factory.getEventsByOrganizer(organizer1);
        assertEq(org1Events.length, 3);
        assertEq(org1Events[0], event1);
        assertEq(org1Events[1], event2);
        assertEq(org1Events[2], event3);
        
        assertEq(factory.getOrganizerEventCount(organizer1), 3);
        
        // Test operations across organizer's events
        VeriTixEvent event1Instance = VeriTixEvent(event1);
        VeriTixEvent event2Instance = VeriTixEvent(event2);
        VeriTixEvent event3Instance = VeriTixEvent(event3);
        
        // Different buyers for different shows
        uint256 token1 = mintTicketAs(event1, buyer1);
        uint256 token2 = mintTicketAs(event2, buyer2);
        uint256 token3 = mintTicketAs(event3, buyer3);
        
        // Organizer can manage all their events
        checkInTicketAs(event1, token1, organizer1);
        checkInTicketAs(event2, token2, organizer1);
        
        // Organizer cancels one event
        cancelEventAs(event3, organizer1);
        
        // Verify independent event states
        assertTrue(event1Instance.isCheckedIn(token1));
        assertTrue(event2Instance.isCheckedIn(token2));
        assertTrue(event3Instance.cancelled());
        
        // Cancelled event allows refunds
        cancelRefundAs(event3, token3, buyer3);
        assertEq(event3Instance.totalSupply(), 0);
    }   
 
    // ============ FACTORY REGISTRY AND DISCOVERY TESTS ============
    
    /**
     * @dev Test factory registry and discovery functionality across multiple events
     */
    function test_FactoryRegistryAndDiscovery() public {
        // Create events with different parameters
        address event1 = createTestEvent(organizer1, "Rock Concert", "ROCK", 1000, 0.15 ether);
        address event2 = createTestEvent(organizer2, "Jazz Night", "JAZZ", 200, 0.08 ether);
        address event3 = createTestEvent(organizer1, "Pop Festival", "POP", 5000, 0.25 ether);
        address event4 = createTestEvent(organizer3, "Classical", "CLASS", 500, 0.12 ether);
        
        // Test total events tracking
        assertEq(factory.getTotalEvents(), 4);
        
        // Test deployed events array
        address[] memory deployedEvents = factory.getDeployedEvents();
        assertEq(deployedEvents.length, 4);
        assertEq(deployedEvents[0], event1);
        assertEq(deployedEvents[1], event2);
        assertEq(deployedEvents[2], event3);
        assertEq(deployedEvents[3], event4);
        
        // Test organizer-specific discovery
        address[] memory org1Events = factory.getEventsByOrganizer(organizer1);
        address[] memory org2Events = factory.getEventsByOrganizer(organizer2);
        address[] memory org3Events = factory.getEventsByOrganizer(organizer3);
        
        assertEq(org1Events.length, 2);
        assertEq(org2Events.length, 1);
        assertEq(org3Events.length, 1);
        
        assertEq(org1Events[0], event1);
        assertEq(org1Events[1], event3);
        assertEq(org2Events[0], event2);
        assertEq(org3Events[0], event4);
        
        // Test event registry information
        VeriTixTypes.EventRegistry memory registry1 = factory.getEventRegistry(event1);
        assertEq(registry1.eventContract, event1);
        assertEq(registry1.organizer, organizer1);
        assertEq(registry1.eventName, "Rock Concert");
        assertEq(uint256(registry1.status), uint256(VeriTixTypes.EventStatus.Active));
        assertEq(registry1.ticketPrice, 0.15 ether);
        assertEq(registry1.maxSupply, 1000);
        
        // Test event validation
        assertTrue(factory.isValidEventContract(event1));
        assertTrue(factory.isValidEventContract(event2));
        assertTrue(factory.isValidEventContract(event3));
        assertTrue(factory.isValidEventContract(event4));
        assertFalse(factory.isValidEventContract(address(0x999)));
        
        // Test organizer event counts
        assertEq(factory.getOrganizerEventCount(organizer1), 2);
        assertEq(factory.getOrganizerEventCount(organizer2), 1);
        assertEq(factory.getOrganizerEventCount(organizer3), 1);
        assertEq(factory.getOrganizerEventCount(makeAddr("unknown")), 0);
        
        // Test paginated discovery
        (VeriTixTypes.EventRegistry[] memory events, uint256 totalCount) = 
            factory.getEventsPaginated(0, 2);
        
        assertEq(totalCount, 4);
        assertEq(events.length, 2);
        assertEq(events[0].eventContract, event1);
        assertEq(events[1].eventContract, event2);
        
        // Test second page
        (events, totalCount) = factory.getEventsPaginated(2, 2);
        assertEq(totalCount, 4);
        assertEq(events.length, 2);
        assertEq(events[0].eventContract, event3);
        assertEq(events[1].eventContract, event4);
        
        // Test status-based discovery
        address[] memory activeEvents = factory.getEventsByStatus(VeriTixTypes.EventStatus.Active);
        assertEq(activeEvents.length, 4);
        
        // Cancel one event and test status filtering
        vm.prank(organizer2);
        VeriTixEvent(event2).cancelEvent("Testing status filtering");
        vm.prank(platformOwner);
        factory.updateEventStatus(event2, VeriTixTypes.EventStatus.Cancelled);
        
        activeEvents = factory.getEventsByStatus(VeriTixTypes.EventStatus.Active);
        address[] memory cancelledEvents = factory.getEventsByStatus(VeriTixTypes.EventStatus.Cancelled);
        
        assertEq(activeEvents.length, 3);
        assertEq(cancelledEvents.length, 1);
        assertEq(cancelledEvents[0], event2);
    }
    
    /**
     * @dev Test factory discovery with ticket sales activity
     */
    function test_FactoryDiscovery_WithTicketActivity() public {
        // Create events
        address event1 = createTestEvent(organizer1, "Active Event", "ACTIVE", 100, 0.1 ether);
        address event2 = createTestEvent(organizer2, "Sold Out Event", "SOLDOUT", 2, 0.1 ether);
        address event3 = createTestEvent(organizer3, "Empty Event", "EMPTY", 100, 0.1 ether);
        
        VeriTixEvent event1Instance = VeriTixEvent(event1);
        VeriTixEvent event2Instance = VeriTixEvent(event2);
        
        // Generate ticket activity
        // Event 1: Some sales and resales
        uint256 token1 = mintTicketAs(event1, buyer1);
        mintTicketAs(event1, buyer2);
        resaleTicketAs(event1, token1, buyer3, (0.1 ether * 105) / 100);
        
        // Event 2: Sell out completely
        mintTicketAs(event2, buyer1);
        mintTicketAs(event2, buyer2);
        
        // Event 3: No activity
        
        // Verify discovery still works with activity
        assertEq(factory.getTotalEvents(), 3);
        
        address[] memory deployedEvents = factory.getDeployedEvents();
        assertEq(deployedEvents.length, 3);
        
        // Verify event states
        assertEq(event1Instance.totalSupply(), 2);
        assertEq(event2Instance.totalSupply(), 2);
        assertEq(VeriTixEvent(event3).totalSupply(), 0);
        
        // Test that sold out events are still discoverable
        VeriTixTypes.EventRegistry memory registry2 = factory.getEventRegistry(event2);
        assertEq(registry2.eventContract, event2);
        assertTrue(factory.isValidEventContract(event2));
    }
    
    // ============ COMPLEX SCENARIO TESTS ============
    
    /**
     * @dev Test complex scenario with multiple events, organizers, and operations
     */
    function test_ComplexScenario_MultipleEventsAndOperations() public {
        // Setup: Create multiple events
        address rockConcert = createTestEvent(organizer1, "Rock Concert", "ROCK", 50, 0.2 ether);
        address jazzNight = createTestEvent(organizer2, "Jazz Night", "JAZZ", 30, 0.15 ether);
        address popFest = createTestEvent(organizer1, "Pop Festival", "POP", 100, 0.3 ether);
        
        VeriTixEvent rockInstance = VeriTixEvent(rockConcert);
        VeriTixEvent jazzInstance = VeriTixEvent(jazzNight);
        VeriTixEvent popInstance = VeriTixEvent(popFest);
        
        // Phase 1: Initial ticket sales
        uint256 rockToken1 = mintTicketAs(rockConcert, buyer1);
        uint256 rockToken2 = mintTicketAs(rockConcert, buyer2);
        uint256 jazzToken1 = mintTicketAs(jazzNight, buyer1);
        uint256 jazzToken2 = mintTicketAs(jazzNight, buyer3);
        uint256 popToken1 = mintTicketAs(popFest, buyer2);
        
        // Verify initial state
        assertEq(rockInstance.totalSupply(), 2);
        assertEq(jazzInstance.totalSupply(), 2);
        assertEq(popInstance.totalSupply(), 1);
        
        // Phase 2: Resale activity
        uint256 rockResalePrice = (0.2 ether * 108) / 100;
        uint256 jazzResalePrice = (0.15 ether * 110) / 100;
        
        resaleTicketAs(rockConcert, rockToken1, buyer3, rockResalePrice);
        resaleTicketAs(jazzNight, jazzToken2, buyer2, jazzResalePrice);
        
        // Verify resales
        assertEq(rockInstance.ownerOf(rockToken1), buyer3);
        assertEq(jazzInstance.ownerOf(jazzToken2), buyer2);
        
        // Phase 3: Event day operations
        // Rock concert: Some check-ins
        checkInTicketAs(rockConcert, rockToken1, organizer1);
        checkInTicketAs(rockConcert, rockToken2, organizer1);
        
        // Jazz night: Gets cancelled
        cancelEventAs(jazzNight, organizer2);
        
        // Pop festival: More sales
        uint256 popToken2 = mintTicketAs(popFest, buyer3);
        uint256 popToken3 = mintTicketAs(popFest, buyer1);
        
        // Phase 4: Post-event cleanup
        // Jazz night refunds (cancelled event)
        cancelRefundAs(jazzNight, jazzToken1, buyer1);
        cancelRefundAs(jazzNight, jazzToken2, buyer2);
        
        // Pop festival: Some refunds (regular)
        refundTicketAs(popFest, popToken3, buyer1);
        
        // Final verification
        // Rock concert: All tickets checked in
        assertTrue(rockInstance.isCheckedIn(rockToken1));
        assertTrue(rockInstance.isCheckedIn(rockToken2));
        assertEq(rockInstance.totalSupply(), 2);
        
        // Jazz night: All tickets refunded
        assertEq(jazzInstance.totalSupply(), 0);
        assertTrue(jazzInstance.cancelled());
        
        // Pop festival: Mixed state
        assertEq(popInstance.totalSupply(), 2); // 1 refunded
        assertEq(popInstance.ownerOf(popToken1), buyer2);
        assertEq(popInstance.ownerOf(popToken2), buyer3);
        
        // Factory state verification
        assertEq(factory.getTotalEvents(), 3);
        assertEq(factory.getOrganizerEventCount(organizer1), 2);
        assertEq(factory.getOrganizerEventCount(organizer2), 1);
    }
    
    /**
     * @dev Test edge case: Event with maximum resale activity
     */
    function test_EdgeCase_MaximumResaleActivity() public {
        // Create small event for intensive testing
        address eventContract = createTestEvent(
            organizer1,
            "Resale Test Event",
            "RESALE",
            5,
            0.1 ether
        );
        
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        // Mint all tickets
        uint256[] memory tokens = new uint256[](5);
        address[] memory buyers = new address[](5);
        buyers[0] = buyer1;
        buyers[1] = buyer2;
        buyers[2] = buyer3;
        buyers[3] = makeAddr("buyer4");
        buyers[4] = makeAddr("buyer5");
        
        // Fund additional buyers
        vm.deal(buyers[3], 10 ether);
        vm.deal(buyers[4], 10 ether);
        
        for (uint256 i = 0; i < 5; i++) {
            tokens[i] = mintTicketAs(eventContract, buyers[i]);
        }
        
        // Intensive resale activity - each ticket changes hands multiple times
        for (uint256 round = 0; round < 3; round++) {
            for (uint256 i = 0; i < 5; i++) {
                address currentOwner = eventInstance.ownerOf(tokens[i]);
                address newBuyer = buyers[(i + round + 1) % 5];
                
                if (currentOwner != newBuyer) {
                    uint256 resalePrice = (0.1 ether * (105 + round * 2)) / 100;
                    resaleTicketAs(eventContract, tokens[i], newBuyer, resalePrice);
                }
            }
        }
        
        // Verify all tickets still exist and have valid owners
        assertEq(eventInstance.totalSupply(), 5);
        for (uint256 i = 0; i < 5; i++) {
            address owner = eventInstance.ownerOf(tokens[i]);
            assertTrue(owner != address(0));
            assertGt(eventInstance.getLastPricePaid(tokens[i]), 0.1 ether);
            assertEq(eventInstance.getOriginalPrice(tokens[i]), 0.1 ether);
        }
        
        // Final check-ins
        for (uint256 i = 0; i < 5; i++) {
            checkInTicketAs(eventContract, tokens[i], organizer1);
            assertTrue(eventInstance.isCheckedIn(tokens[i]));
        }
    }
    
    // ============ ERROR CONDITION INTEGRATION TESTS ============
    
    /**
     * @dev Test error conditions across integrated workflows
     */
    function test_ErrorConditions_IntegratedWorkflows() public {
        // Create event
        address eventContract = createTestEvent(
            organizer1,
            "Error Test Event",
            "ERROR",
            10,
            0.1 ether
        );
        
        VeriTixEvent eventInstance = VeriTixEvent(eventContract);
        
        // Mint some tickets
        uint256 token1 = mintTicketAs(eventContract, buyer1);
        uint256 token2 = mintTicketAs(eventContract, buyer2);
        
        // Test: Cannot resale to self
        vm.expectRevert(IVeriTixEvent.CannotBuyOwnTicket.selector);
        vm.prank(buyer1);
        eventInstance.resaleTicket{value: 0.11 ether}(token1, 0.11 ether);
        
        // Test: Cannot resale checked-in ticket
        checkInTicketAs(eventContract, token1, organizer1);
        
        vm.expectRevert(IVeriTixEvent.TicketAlreadyUsed.selector);
        vm.prank(buyer3);
        eventInstance.resaleTicket{value: 0.11 ether}(token1, 0.11 ether);
        
        // Test: Cannot refund checked-in ticket
        vm.expectRevert(IVeriTixEvent.TicketAlreadyUsed.selector);
        vm.prank(buyer1);
        eventInstance.refund(token1);
        
        // Test: Cancel event and verify restrictions
        cancelEventAs(eventContract, organizer1);
        
        // Cannot mint new tickets
        vm.expectRevert(IVeriTixEvent.EventIsCancelled.selector);
        vm.prank(buyer3);
        eventInstance.mintTicket{value: 0.1 ether}();
        
        // Cannot resale existing tickets
        vm.expectRevert(IVeriTixEvent.EventIsCancelled.selector);
        vm.prank(buyer3);
        eventInstance.resaleTicket{value: 0.11 ether}(token2, 0.11 ether);
        
        // Check-in is still allowed after cancellation (business logic allows this)
        vm.prank(organizer1);
        eventInstance.checkIn(token2);
        assertTrue(eventInstance.isCheckedIn(token2));
        
        // Can still do cancellation refunds (even for checked-in tickets)
        cancelRefundAs(eventContract, token1, buyer1);
        cancelRefundAs(eventContract, token2, buyer2);
        assertEq(eventInstance.totalSupply(), 0); // All tickets refunded
    }
    
    // ============ PERFORMANCE AND SCALABILITY TESTS ============
    
    /**
     * @dev Test performance with multiple events and operations
     */
    function test_Performance_MultipleEventsAndOperations() public {
        uint256 numEvents = 10;
        address[] memory events = new address[](numEvents);
        
        // Create multiple events
        for (uint256 i = 0; i < numEvents; i++) {
            address organizer = i % 3 == 0 ? organizer1 : (i % 3 == 1 ? organizer2 : organizer3);
            events[i] = createTestEvent(
                organizer,
                string(abi.encodePacked("Event ", vm.toString(i))),
                string(abi.encodePacked("EVT", vm.toString(i))),
                20,
                0.1 ether
            );
        }
        
        // Verify factory can handle multiple events
        assertEq(factory.getTotalEvents(), numEvents);
        
        address[] memory deployedEvents = factory.getDeployedEvents();
        assertEq(deployedEvents.length, numEvents);
        
        // Test operations across all events
        for (uint256 i = 0; i < numEvents; i++) {
            // Mint tickets in each event
            mintTicketAs(events[i], buyer1);
            mintTicketAs(events[i], buyer2);
            
            // Some resale activity
            if (i % 2 == 0) {
                resaleTicketAs(events[i], 1, buyer3, 0.105 ether);
            }
        }
        
        // Verify all events are still functional
        for (uint256 i = 0; i < numEvents; i++) {
            VeriTixEvent eventInstance = VeriTixEvent(events[i]);
            assertGe(eventInstance.totalSupply(), 2);
            assertTrue(factory.isValidEventContract(events[i]));
        }
        
        // Test organizer discovery still works
        address[] memory org1Events = factory.getEventsByOrganizer(organizer1);
        address[] memory org2Events = factory.getEventsByOrganizer(organizer2);
        address[] memory org3Events = factory.getEventsByOrganizer(organizer3);
        
        // Should have roughly equal distribution
        assertGt(org1Events.length, 0);
        assertGt(org2Events.length, 0);
        assertGt(org3Events.length, 0);
        assertEq(org1Events.length + org2Events.length + org3Events.length, numEvents);
    }
}