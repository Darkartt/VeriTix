// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title GasOptimizationTest
 * @dev Comprehensive gas profiling and optimization measurement suite
 * @notice This test suite profiles gas consumption for all major contract functions
 * and identifies optimization opportunities through detailed benchmarking
 */
contract GasOptimizationTest is Test {
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    address public owner = address(0x1);
    address public organizer = address(0x2);
    address public buyer1 = address(0x3);
    address public buyer2 = address(0x4);
    address public buyer3 = address(0x5);
    
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 1000;
    
    // Gas measurement storage
    struct GasMeasurement {
        uint256 gasUsed;
        uint256 timestamp;
        string functionName;
        string scenario;
    }
    
    mapping(string => GasMeasurement) public gasMeasurements;
    string[] public measurementKeys;
    
    function setUp() public {
        vm.startPrank(owner);
        factory = new VeriTixFactory(owner);
        vm.stopPrank();
        
        // Create a test event
        vm.deal(organizer, 10 ether);
        vm.startPrank(organizer);
        
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Gas Test Event",
            symbol: "GTE",
            maxSupply: MAX_SUPPLY,
            ticketPrice: TICKET_PRICE,
            organizer: organizer,
            baseURI: "https://example.com/metadata/",
            maxResalePercent: 120,
            organizerFeePercent: 5
        });
        
        address eventAddress = factory.createEvent(params);
        eventContract = VeriTixEvent(eventAddress);
        vm.stopPrank();
        
        // Fund test accounts
        vm.deal(buyer1, 10 ether);
        vm.deal(buyer2, 10 ether);
        vm.deal(buyer3, 10 ether);
    }
    
    // ============ FACTORY GAS BENCHMARKS ============
    
    function test_GasBenchmark_CreateEvent_Single() public {
        uint256 gasBefore = gasleft();
        
        vm.startPrank(organizer);
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Single Event Test",
            symbol: "SET",
            maxSupply: 500,
            ticketPrice: TICKET_PRICE,
            organizer: organizer,
            baseURI: "https://example.com/metadata/",
            maxResalePercent: 110,
            organizerFeePercent: 3
        });
        
        factory.createEvent(params);
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("CreateEvent_Single", "single_event_creation", gasUsed);
        
        console.log("Gas used for single event creation:", gasUsed);
    }
    
    function test_GasBenchmark_CreateEvent_Batch() public {
        uint256 gasBefore = gasleft();
        
        vm.startPrank(organizer);
        VeriTixTypes.EventCreationParams[] memory paramsArray = new VeriTixTypes.EventCreationParams[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            paramsArray[i] = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("Batch Event ", vm.toString(i))),
                symbol: string(abi.encodePacked("BE", vm.toString(i))),
                maxSupply: 300,
                ticketPrice: TICKET_PRICE,
                organizer: organizer,
                baseURI: "https://example.com/metadata/",
                maxResalePercent: 115,
                organizerFeePercent: 4
            });
        }
        
        factory.batchCreateEvents(paramsArray);
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("CreateEvent_Batch", "batch_event_creation_3_events", gasUsed);
        
        console.log("Gas used for batch event creation (3 events):", gasUsed);
        console.log("Average gas per event in batch:", gasUsed / 3);
    }
    
    function test_GasBenchmark_GetEventsPaginated() public {
        // Create multiple events first
        vm.startPrank(organizer);
        for (uint256 i = 0; i < 5; i++) {
            VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("Pagination Test ", vm.toString(i))),
                symbol: string(abi.encodePacked("PT", vm.toString(i))),
                maxSupply: 100,
                ticketPrice: TICKET_PRICE,
                organizer: organizer,
                baseURI: "https://example.com/metadata/",
                maxResalePercent: 110,
                organizerFeePercent: 2
            });
            factory.createEvent(params);
        }
        vm.stopPrank();
        
        uint256 gasBefore = gasleft();
        factory.getEventsPaginated(0, 5);
        uint256 gasUsed = gasBefore - gasleft();
        
        _recordGasMeasurement("GetEventsPaginated", "pagination_5_events", gasUsed);
        console.log("Gas used for paginated event retrieval (5 events):", gasUsed);
    }
    
    // ============ EVENT CONTRACT GAS BENCHMARKS ============
    
    function test_GasBenchmark_MintTicket_Single() public {
        uint256 gasBefore = gasleft();
        
        vm.startPrank(buyer1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("MintTicket_Single", "single_ticket_mint", gasUsed);
        
        console.log("Gas used for single ticket mint:", gasUsed);
    }
    
    function test_GasBenchmark_MintTicket_Sequential() public {
        uint256 totalGas = 0;
        
        // Mint 5 tickets sequentially to measure gas progression
        for (uint256 i = 0; i < 5; i++) {
            uint256 gasBefore = gasleft();
            
            vm.startPrank(buyer1);
            eventContract.mintTicket{value: TICKET_PRICE}();
            vm.stopPrank();
            
            uint256 gasUsed = gasBefore - gasleft();
            totalGas += gasUsed;
            
            console.log("Gas used for ticket", i + 1, ":", gasUsed);
        }
        
        _recordGasMeasurement("MintTicket_Sequential", "sequential_5_tickets", totalGas);
        console.log("Total gas for 5 sequential mints:", totalGas);
        console.log("Average gas per mint:", totalGas / 5);
    }
    
    function test_GasBenchmark_ResaleTicket() public {
        // First mint a ticket
        vm.startPrank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        vm.stopPrank();
        
        uint256 resalePrice = TICKET_PRICE * 115 / 100; // 115% of face value
        
        uint256 gasBefore = gasleft();
        
        vm.startPrank(buyer2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("ResaleTicket", "single_ticket_resale", gasUsed);
        
        console.log("Gas used for ticket resale:", gasUsed);
    }
    
    function test_GasBenchmark_RefundTicket() public {
        // First mint a ticket
        vm.startPrank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        vm.stopPrank();
        
        uint256 gasBefore = gasleft();
        
        vm.startPrank(buyer1);
        eventContract.refund(tokenId);
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("RefundTicket", "single_ticket_refund", gasUsed);
        
        console.log("Gas used for ticket refund:", gasUsed);
    }
    
    function test_GasBenchmark_CheckIn() public {
        // First mint a ticket
        vm.startPrank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        vm.stopPrank();
        
        uint256 gasBefore = gasleft();
        
        vm.startPrank(organizer);
        eventContract.checkIn(tokenId);
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("CheckIn", "single_ticket_checkin", gasUsed);
        
        console.log("Gas used for ticket check-in:", gasUsed);
    }
    
    function test_GasBenchmark_CancelEvent() public {
        uint256 gasBefore = gasleft();
        
        vm.startPrank(organizer);
        eventContract.cancelEvent("Gas benchmark test cancellation");
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("CancelEvent", "event_cancellation", gasUsed);
        
        console.log("Gas used for event cancellation:", gasUsed);
    }
    
    // ============ VIEW FUNCTION GAS BENCHMARKS ============
    
    function test_GasBenchmark_ViewFunctions() public {
        // Mint some tickets first
        vm.startPrank(buyer1);
        uint256 tokenId1 = eventContract.mintTicket{value: TICKET_PRICE}();
        uint256 tokenId2 = eventContract.mintTicket{value: TICKET_PRICE}();
        vm.stopPrank();
        
        // Test getEventInfo
        uint256 gasBefore = gasleft();
        eventContract.getEventInfo();
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("GetEventInfo", "view_event_info", gasUsed);
        console.log("Gas used for getEventInfo:", gasUsed);
        
        // Test getTicketMetadata
        gasBefore = gasleft();
        eventContract.getTicketMetadata(tokenId1);
        gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("GetTicketMetadata", "view_ticket_metadata", gasUsed);
        console.log("Gas used for getTicketMetadata:", gasUsed);
        
        // Test getCollectionMetadata
        gasBefore = gasleft();
        eventContract.getCollectionMetadata();
        gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("GetCollectionMetadata", "view_collection_metadata", gasUsed);
        console.log("Gas used for getCollectionMetadata:", gasUsed);
        
        // Test tokenURI
        gasBefore = gasleft();
        eventContract.tokenURI(tokenId1);
        gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("TokenURI", "view_token_uri", gasUsed);
        console.log("Gas used for tokenURI:", gasUsed);
    }
    
    // ============ STORAGE OPTIMIZATION ANALYSIS ============
    
    function test_GasBenchmark_StorageOperations() public {
        // Test storage-heavy operations to identify optimization opportunities
        
        // Multiple mints to analyze storage slot usage
        uint256 gasBefore = gasleft();
        
        vm.startPrank(buyer1);
        for (uint256 i = 0; i < 10; i++) {
            eventContract.mintTicket{value: TICKET_PRICE}();
        }
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("StorageOperations", "multiple_mints_10_tickets", gasUsed);
        
        console.log("Gas used for 10 sequential mints:", gasUsed);
        console.log("Average gas per mint in sequence:", gasUsed / 10);
        
        // Test mapping access patterns
        gasBefore = gasleft();
        for (uint256 i = 1; i <= 10; i++) {
            eventContract.getLastPricePaid(i);
        }
        gasUsed = gasBefore - gasleft();
        _recordGasMeasurement("MappingAccess", "sequential_mapping_reads_10", gasUsed);
        console.log("Gas used for 10 mapping reads:", gasUsed);
    }
    
    // ============ BATCH OPERATION ANALYSIS ============
    
    function test_GasBenchmark_BatchOperationEfficiency() public {
        // Compare efficiency of batch vs individual operations
        
        // Individual operations baseline
        uint256 individualGasTotal = 0;
        for (uint256 i = 0; i < 3; i++) {
            uint256 gasBefore = gasleft();
            
            vm.startPrank(organizer);
            VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("Individual ", vm.toString(i))),
                symbol: string(abi.encodePacked("IND", vm.toString(i))),
                maxSupply: 100,
                ticketPrice: TICKET_PRICE,
                organizer: organizer,
                baseURI: "https://example.com/metadata/",
                maxResalePercent: 110,
                organizerFeePercent: 2
            });
            factory.createEvent(params);
            vm.stopPrank();
            
            uint256 gasUsed = gasBefore - gasleft();
            individualGasTotal += gasUsed;
        }
        
        _recordGasMeasurement("BatchEfficiency", "individual_operations_3", individualGasTotal);
        
        // Batch operation
        uint256 gasBefore = gasleft();
        
        vm.startPrank(organizer);
        VeriTixTypes.EventCreationParams[] memory paramsArray = new VeriTixTypes.EventCreationParams[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            paramsArray[i] = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("Batch Efficiency ", vm.toString(i))),
                symbol: string(abi.encodePacked("BEF", vm.toString(i))),
                maxSupply: 100,
                ticketPrice: TICKET_PRICE,
                organizer: organizer,
                baseURI: "https://example.com/metadata/",
                maxResalePercent: 110,
                organizerFeePercent: 2
            });
        }
        
        factory.batchCreateEvents(paramsArray);
        vm.stopPrank();
        
        uint256 batchGasUsed = gasBefore - gasleft();
        _recordGasMeasurement("BatchEfficiency", "batch_operation_3", batchGasUsed);
        
        uint256 gasSavings = individualGasTotal - batchGasUsed;
        uint256 savingsPercentage = (gasSavings * 100) / individualGasTotal;
        
        console.log("Individual operations total gas:", individualGasTotal);
        console.log("Batch operation gas:", batchGasUsed);
        console.log("Gas savings:", gasSavings);
        console.log("Savings percentage:", savingsPercentage, "%");
        
        _recordGasMeasurement("BatchEfficiency", "gas_savings_absolute", gasSavings);
        _recordGasMeasurement("BatchEfficiency", "gas_savings_percentage", savingsPercentage);
    }
    
    // ============ GAS LIMIT ANALYSIS ============
    
    function test_GasBenchmark_GasLimitAnalysis() public {
        // Test operations approaching gas limits to identify DoS risks
        
        // Large batch creation test
        vm.startPrank(organizer);
        VeriTixTypes.EventCreationParams[] memory largeParamsArray = new VeriTixTypes.EventCreationParams[](10);
        
        for (uint256 i = 0; i < 10; i++) {
            largeParamsArray[i] = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("Large Batch Event ", vm.toString(i))),
                symbol: string(abi.encodePacked("LBE", vm.toString(i))),
                maxSupply: 1000,
                ticketPrice: TICKET_PRICE,
                organizer: organizer,
                baseURI: "https://example.com/metadata/",
                maxResalePercent: 120,
                organizerFeePercent: 5
            });
        }
        
        uint256 gasBefore = gasleft();
        factory.batchCreateEvents(largeParamsArray);
        uint256 gasUsed = gasBefore - gasleft();
        vm.stopPrank();
        
        _recordGasMeasurement("GasLimitAnalysis", "large_batch_10_events", gasUsed);
        console.log("Gas used for large batch (10 events):", gasUsed);
        
        // Calculate gas per event in large batch
        uint256 gasPerEvent = gasUsed / 10;
        console.log("Gas per event in large batch:", gasPerEvent);
        
        // Estimate maximum batch size for block gas limit (30M gas)
        uint256 maxBatchSize = 25000000 / gasPerEvent; // Leave 5M gas buffer
        console.log("Estimated max batch size for block limit:", maxBatchSize);
        
        _recordGasMeasurement("GasLimitAnalysis", "estimated_max_batch_size", maxBatchSize);
    }
    
    // ============ OPTIMIZATION OPPORTUNITY IDENTIFICATION ============
    
    function test_IdentifyOptimizationOpportunities() public {
        console.log("\n=== GAS OPTIMIZATION OPPORTUNITIES ===");
        
        // Analyze all recorded measurements
        for (uint256 i = 0; i < measurementKeys.length; i++) {
            string memory key = measurementKeys[i];
            GasMeasurement memory measurement = gasMeasurements[key];
            
            if (measurement.gasUsed > 200000) {
                console.log("HIGH GAS FUNCTION:", measurement.functionName);
                console.log("  Gas Used:", measurement.gasUsed);
                console.log("  Scenario:", measurement.scenario);
                console.log("  Optimization Priority: HIGH");
            } else if (measurement.gasUsed > 100000) {
                console.log("MEDIUM GAS FUNCTION:", measurement.functionName);
                console.log("  Gas Used:", measurement.gasUsed);
                console.log("  Scenario:", measurement.scenario);
                console.log("  Optimization Priority: MEDIUM");
            }
        }
        
        // Specific optimization recommendations
        console.log("\n=== SPECIFIC OPTIMIZATION RECOMMENDATIONS ===");
        
        // Check batch efficiency
        uint256 individualGas = gasMeasurements["BatchEfficiency_individual_operations_3"].gasUsed;
        uint256 batchGas = gasMeasurements["BatchEfficiency_batch_operation_3"].gasUsed;
        
        if (individualGas > 0 && batchGas > 0) {
            uint256 savingsPercentage = ((individualGas - batchGas) * 100) / individualGas;
            if (savingsPercentage < 20) {
                console.log("BATCH OPTIMIZATION NEEDED:");
                console.log("  Current batch savings:", savingsPercentage, "%");
                console.log("  Target batch savings: >20%");
                console.log("  Recommendation: Optimize batch processing loops");
            }
        }
        
        // Check storage optimization opportunities
        uint256 mintGas = gasMeasurements["MintTicket_Single_single_ticket_mint"].gasUsed;
        if (mintGas > 80000) {
            console.log("STORAGE OPTIMIZATION NEEDED:");
            console.log("  Single mint gas:", mintGas);
            console.log("  Target mint gas: <80000");
            console.log("  Recommendation: Optimize struct packing and storage operations");
        }
    }
    
    // ============ HELPER FUNCTIONS ============
    
    function _recordGasMeasurement(
        string memory functionName,
        string memory scenario,
        uint256 gasUsed
    ) internal {
        string memory key = string(abi.encodePacked(functionName, "_", scenario));
        
        gasMeasurements[key] = GasMeasurement({
            gasUsed: gasUsed,
            timestamp: block.timestamp,
            functionName: functionName,
            scenario: scenario
        });
        
        measurementKeys.push(key);
    }
    
    function getGasMeasurement(string memory key) external view returns (GasMeasurement memory) {
        return gasMeasurements[key];
    }
    
    function getAllMeasurementKeys() external view returns (string[] memory) {
        return measurementKeys;
    }
    
    function getTotalMeasurements() external view returns (uint256) {
        return measurementKeys.length;
    }
}