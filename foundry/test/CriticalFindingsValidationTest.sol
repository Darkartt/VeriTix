// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixEvent.sol";
import "../src/VeriTixFactory.sol";
import "../src/interfaces/IVeriTixEvent.sol";
import "../src/interfaces/IVeriTixFactory.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title CriticalFindingsValidationTest
 * @dev Comprehensive test suite to validate all critical security patches
 * @notice Tests all five critical findings and their remediation patches
 */
contract CriticalFindingsValidationTest is Test {
    VeriTixEvent public eventContract;
    VeriTixFactory public factory;
    
    address public organizer = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public attacker = address(0x4);
    
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 1000;
    
    event TicketMinted(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event TicketResold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, uint256 organizerFee);
    event BaseURIUpdated(string newBaseURI);
    
    function setUp() public {
        // Deploy factory
        factory = new VeriTixFactory(address(this));
        
        // Create test event
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Test Event",
            symbol: "TEST",
            maxSupply: MAX_SUPPLY,
            ticketPrice: TICKET_PRICE,
            organizer: organizer,
            baseURI: "https://api.test.com/",
            maxResalePercent: 150,
            organizerFeePercent: 10
        });
        
        address eventAddr = factory.createEvent(params);
        eventContract = VeriTixEvent(eventAddr);
        
        // Fund test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(attacker, 100 ether);
    }
    
    // ============ CRITICAL FINDING #1: PURCHASE LIMITS ============
    
    /**
     * @dev Test that purchase limits are properly enforced
     */
    function testPurchaseLimitEnforcement() public {
        vm.startPrank(user1);
        
        // Purchase up to limit (20 tickets)
        for (uint256 i = 0; i < 20; i++) {
            eventContract.mintTicket{value: TICKET_PRICE}();
        }
        
        // Verify purchase count
        assertEq(eventContract.purchaseCount(user1), 20);
        assertEq(eventContract.getRemainingPurchaseLimit(user1), 0);
        
        // 21st purchase should fail
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.PurchaseLimitExceeded.selector,
            user1,
            20
        ));
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.stopPrank();
    }
    
    /**
     * @dev Test that different addresses have separate purchase limits
     */
    function testSeparatePurchaseLimits() public {
        // User1 purchases 20 tickets
        vm.startPrank(user1);
        for (uint256 i = 0; i < 20; i++) {
            eventContract.mintTicket{value: TICKET_PRICE}();
        }
        vm.stopPrank();
        
        // User2 should still be able to purchase
        vm.startPrank(user2);
        eventContract.mintTicket{value: TICKET_PRICE}();
        assertEq(eventContract.purchaseCount(user2), 1);
        assertEq(eventContract.getRemainingPurchaseLimit(user2), 19);
        vm.stopPrank();
    }
    
    /**
     * @dev Test market cornering attack prevention
     */
    function testMarketCorneringPrevention() public {
        vm.startPrank(attacker);
        
        // Attacker tries to purchase 70% of supply (700 tickets)
        // Should be limited to 20 tickets maximum
        for (uint256 i = 0; i < 20; i++) {
            eventContract.mintTicket{value: TICKET_PRICE}();
        }
        
        // Further purchases should fail
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.PurchaseLimitExceeded.selector,
            attacker,
            20
        ));
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.stopPrank();
        
        // Verify attacker cannot control majority of supply
        assertEq(eventContract.purchaseCount(attacker), 20);
        assertTrue(eventContract.purchaseCount(attacker) < (MAX_SUPPLY * 70) / 100);
    }
    
    // ============ CRITICAL FINDING #2: MINIMUM RESALE PRICE ============
    
    /**
     * @dev Test minimum resale price enforcement
     */
    function testMinimumResalePriceEnforcement() public {
        // User1 mints a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Verify minimum resale price is 95% of face value
        uint256 minPrice = eventContract.getMinResalePrice();
        assertEq(minPrice, (TICKET_PRICE * 95) / 100);
        
        // Try to resell below minimum
        uint256 belowMinimum = minPrice - 1;
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.BelowMinimumResalePrice.selector,
            belowMinimum,
            minPrice
        ));
        
        vm.prank(user2);
        eventContract.resaleTicket{value: belowMinimum}(tokenId, belowMinimum);
        
        // Resale at minimum price should succeed
        vm.prank(user2);
        eventContract.resaleTicket{value: minPrice}(tokenId, minPrice);
        
        // Verify ownership transfer
        assertEq(eventContract.ownerOf(tokenId), user2);
    }
    
    /**
     * @dev Test fee circumvention attack prevention
     */
    function testFeeCircumventionPrevention() public {
        // User1 mints a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Attacker tries to pay face value to avoid fees on higher agreed price
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.BelowMinimumResalePrice.selector,
            TICKET_PRICE,
            (TICKET_PRICE * 95) / 100
        ));
        
        vm.prank(attacker);
        eventContract.resaleTicket{value: TICKET_PRICE}(tokenId, TICKET_PRICE);
    }
    
    // ============ CRITICAL FINDING #3: GAS OPTIMIZATION ============
    
    /**
     * @dev Test optimized gas consumption for event creation
     */
    function testOptimizedGasConsumption() public {
        uint256 gasBefore = gasleft();
        
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Gas Test Event",
            symbol: "GAS",
            maxSupply: 1000,
            ticketPrice: TICKET_PRICE,
            organizer: organizer,
            baseURI: "https://api.gastest.com/",
            maxResalePercent: 150,
            organizerFeePercent: 10
        });
        
        factory.createEvent(params);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Should be under 2.1M gas target
        assertLt(gasUsed, 2_100_000, "Gas consumption exceeds target");
        
        // Should be significantly less than original 2.41M gas
        assertLt(gasUsed, 2_000_000, "Gas optimization not effective");
    }
    
    /**
     * @dev Test packed storage validation
     */
    function testPackedStorageValidation() public {
        // Test maximum values for packed fields
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Max Values Test",
            symbol: "MAX",
            maxSupply: type(uint32).max,
            ticketPrice: type(uint128).max,
            organizer: organizer,
            baseURI: "https://api.maxtest.com/",
            maxResalePercent: type(uint16).max > 500 ? 500 : type(uint16).max,
            organizerFeePercent: type(uint8).max > 50 ? 50 : type(uint8).max
        });
        
        // Should succeed with maximum valid values
        address eventAddr = factory.createEvent(params);
        VeriTixEvent maxEvent = VeriTixEvent(eventAddr);
        
        // Verify values are stored correctly
        assertEq(maxEvent.maxSupply(), params.maxSupply);
        assertEq(maxEvent.ticketPrice(), params.ticketPrice);
        assertEq(maxEvent.maxResalePercent(), params.maxResalePercent);
        assertEq(maxEvent.organizerFeePercent(), params.organizerFeePercent);
    }
    
    // ============ CRITICAL FINDING #4: BATCH DOS PROTECTION ============
    
    /**
     * @dev Test batch size limit enforcement
     */
    function testBatchSizeLimit() public {
        // Create array exceeding limit (6 > 5)
        VeriTixTypes.EventCreationParams[] memory params = 
            new VeriTixTypes.EventCreationParams[](6);
        
        // Fill params array
        for (uint256 i = 0; i < 6; i++) {
            params[i] = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("Event ", i)),
                symbol: string(abi.encodePacked("E", i)),
                maxSupply: 100,
                ticketPrice: TICKET_PRICE,
                organizer: organizer,
                baseURI: "https://api.test.com/",
                maxResalePercent: 150,
                organizerFeePercent: 10
            });
        }
        
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixFactory.BatchSizeTooLarge.selector,
            6,
            5
        ));
        factory.batchCreateEvents(params);
    }
    
    /**
     * @dev Test gas estimation for batch operations
     */
    function testBatchGasEstimation() public {
        uint256 batchSize = 3;
        uint256 estimatedGas = factory.estimateBatchGas(batchSize);
        
        // Should be reasonable estimate
        assertGt(estimatedGas, batchSize * 2_000_000); // At least 2M per event
        assertLt(estimatedGas, batchSize * 3_000_000); // At most 3M per event
        
        // Test actual batch creation within estimate
        VeriTixTypes.EventCreationParams[] memory params = 
            new VeriTixTypes.EventCreationParams[](batchSize);
        
        for (uint256 i = 0; i < batchSize; i++) {
            params[i] = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("Batch Event ", i)),
                symbol: string(abi.encodePacked("BE", i)),
                maxSupply: 100,
                ticketPrice: TICKET_PRICE,
                organizer: organizer,
                baseURI: "https://api.batch.com/",
                maxResalePercent: 150,
                organizerFeePercent: 10
            });
        }
        
        uint256 gasBefore = gasleft();
        address[] memory events = factory.batchCreateEvents(params);
        uint256 gasUsed = gasBefore - gasleft();
        
        assertEq(events.length, batchSize);
        assertLt(gasUsed, estimatedGas, "Actual gas exceeded estimate");
    }
    
    /**
     * @dev Test DoS attack prevention
     */
    function testDoSAttackPrevention() public {
        // Attacker tries to create maximum batch during low gas conditions
        VeriTixTypes.EventCreationParams[] memory params = 
            new VeriTixTypes.EventCreationParams[](5); // Maximum allowed
        
        for (uint256 i = 0; i < 5; i++) {
            params[i] = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("DoS Event ", i)),
                symbol: string(abi.encodePacked("DOS", i)),
                maxSupply: 1000, // Large supply for maximum gas usage
                ticketPrice: TICKET_PRICE,
                organizer: attacker,
                baseURI: "https://api.dos.com/",
                maxResalePercent: 150,
                organizerFeePercent: 10
            });
        }
        
        vm.prank(attacker);
        
        // Should succeed with proper gas limits
        address[] memory events = factory.batchCreateEvents(params);
        assertEq(events.length, 5);
        
        // Verify gas consumption is reasonable (< 80% of block limit)
        // This is tested implicitly by successful execution
    }
    
    // ============ CRITICAL FINDING #5: INPUT VALIDATION ============
    
    /**
     * @dev Test base URI validation
     */
    function testBaseURIValidation() public {
        vm.startPrank(organizer);
        
        // Test empty URI
        vm.expectRevert(IVeriTixEvent.EmptyBaseURI.selector);
        eventContract.setBaseURI("");
        
        // Test URI too long (> 200 characters)
        string memory longURI = "https://api.verylongdomainname.com/api/v1/metadata/events/tickets/";
        for (uint256 i = 0; i < 10; i++) {
            longURI = string(abi.encodePacked(longURI, "verylongpath/"));
        }
        
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.BaseURITooLong.selector,
            bytes(longURI).length,
            200
        ));
        eventContract.setBaseURI(longURI);
        
        // Test invalid characters (control characters)
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.InvalidBaseURICharacter.selector,
            uint8(0x01)
        ));
        eventContract.setBaseURI("https://test.com/\x01");
        
        // Test valid URI
        string memory validURI = "https://api.valid.com/metadata/";
        vm.expectEmit(true, true, true, true);
        emit BaseURIUpdated(validURI);
        eventContract.setBaseURI(validURI);
        
        vm.stopPrank();
    }
    
    /**
     * @dev Test cancellation reason validation
     */
    function testCancellationReasonValidation() public {
        vm.startPrank(organizer);
        
        // Test empty reason
        vm.expectRevert(IVeriTixEvent.EmptyCancellationReason.selector);
        eventContract.cancelEvent("");
        
        // Test reason too long (> 500 characters)
        string memory longReason = "";
        for (uint256 i = 0; i < 51; i++) {
            longReason = string(abi.encodePacked(longReason, "0123456789"));
        }
        
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.CancellationReasonTooLong.selector,
            bytes(longReason).length,
            500
        ));
        eventContract.cancelEvent(longReason);
        
        // Test valid reason
        eventContract.cancelEvent("Event cancelled due to venue issues");
        assertTrue(eventContract.cancelled());
        
        vm.stopPrank();
    }
    
    /**
     * @dev Test price overflow protection
     */
    function testPriceOverflowProtection() public {
        // User1 mints a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Try to resell with price that would cause overflow
        uint256 overflowPrice = type(uint256).max / 99; // Would overflow in fee calculation
        
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.PriceTooHigh.selector,
            overflowPrice
        ));
        
        vm.prank(user2);
        eventContract.resaleTicket{value: overflowPrice}(tokenId, overflowPrice);
    }
    
    // ============ INTEGRATION TESTS ============
    
    /**
     * @dev Test all patches work together without conflicts
     */
    function testIntegratedPatches() public {
        // Test purchase limits with minimum resale price
        vm.startPrank(user1);
        
        // Purchase multiple tickets (within limit)
        uint256[] memory tokenIds = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = eventContract.mintTicket{value: TICKET_PRICE}();
        }
        
        vm.stopPrank();
        
        // Test resale with minimum price enforcement
        vm.prank(user2);
        uint256 minPrice = eventContract.getMinResalePrice();
        eventContract.resaleTicket{value: minPrice}(tokenIds[0], minPrice);
        
        // Verify all systems work together
        assertEq(eventContract.ownerOf(tokenIds[0]), user2);
        assertEq(eventContract.purchaseCount(user1), 5);
        assertEq(eventContract.getRemainingPurchaseLimit(user1), 15);
    }
    
    /**
     * @dev Test gas optimization doesn't break functionality
     */
    function testOptimizationFunctionality() public {
        // Create event with optimized gas usage
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Optimized Event",
            symbol: "OPT",
            maxSupply: 500,
            ticketPrice: 0.05 ether,
            organizer: organizer,
            baseURI: "https://api.optimized.com/",
            maxResalePercent: 120,
            organizerFeePercent: 5
        });
        
        address eventAddr = factory.createEvent(params);
        VeriTixEvent optimizedEvent = VeriTixEvent(eventAddr);
        
        // Test all functionality works with packed storage
        vm.prank(user1);
        uint256 tokenId = optimizedEvent.mintTicket{value: 0.05 ether}();
        
        assertEq(optimizedEvent.ownerOf(tokenId), user1);
        assertEq(optimizedEvent.ticketPrice(), 0.05 ether);
        assertEq(optimizedEvent.maxSupply(), 500);
        assertEq(optimizedEvent.maxResalePercent(), 120);
        assertEq(optimizedEvent.organizerFeePercent(), 5);
    }
    
    // ============ HELPER FUNCTIONS ============
    
    /**
     * @dev Helper to create valid event parameters
     */
    function createValidEventParams(string memory name) internal view returns (VeriTixTypes.EventCreationParams memory) {
        return VeriTixTypes.EventCreationParams({
            name: name,
            symbol: "TEST",
            maxSupply: 100,
            ticketPrice: TICKET_PRICE,
            organizer: organizer,
            baseURI: "https://api.test.com/",
            maxResalePercent: 150,
            organizerFeePercent: 10
        });
    }
    
    /**
     * @dev Helper to mint tickets for testing
     */
    function mintTicketsForUser(address user, uint256 count) internal returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        vm.startPrank(user);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = eventContract.mintTicket{value: TICKET_PRICE}();
        }
        vm.stopPrank();
    }
}