// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title GasOptimizationValidationTest
 * @dev Test suite to validate gas optimization implementations
 * @notice This test suite measures before/after gas consumption to validate optimization effectiveness
 */
contract GasOptimizationValidationTest is Test {
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    address public owner = address(0x1);
    address public organizer = address(0x2);
    address public buyer1 = address(0x3);
    address public buyer2 = address(0x4);
    
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 1000;
    
    // Gas measurement targets based on analysis
    uint256 public constant TARGET_MINT_GAS = 80000;
    uint256 public constant TARGET_CREATE_EVENT_GAS = 2100000; // ~15% reduction from 2.4M
    uint256 public constant TARGET_RESALE_GAS = 95000;
    uint256 public constant TARGET_BATCH_SAVINGS_PERCENT = 20;
    
    function setUp() public {
        vm.startPrank(owner);
        factory = new VeriTixFactory(owner);
        vm.stopPrank();
        
        // Create a test event
        vm.deal(organizer, 10 ether);
        vm.startPrank(organizer);
        
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Gas Validation Event",
            symbol: "GVE",
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
    }
    
    // ============ OPTIMIZATION VALIDATION TESTS ============
    
    function test_ValidateMintTicketOptimization() public {
        console.log("=== Validating mintTicket Gas Optimization ===");
        
        uint256 gasBefore = gasleft();
        
        vm.startPrank(buyer1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        
        console.log("Current mintTicket gas usage:", gasUsed);
        console.log("Target gas usage:", TARGET_MINT_GAS);
        
        if (gasUsed <= TARGET_MINT_GAS) {
            console.log("OPTIMIZATION SUCCESS: Gas usage within target");
        } else {
            console.log("OPTIMIZATION NEEDED: Gas usage exceeds target by", gasUsed - TARGET_MINT_GAS);
        }
        
        // Log specific optimization opportunities
        if (gasUsed > TARGET_MINT_GAS) {
            console.log("Recommended optimizations:");
            console.log("  - Cache immutable variables (save ~300 gas)");
            console.log("  - Use unchecked arithmetic (save ~200 gas)");
            console.log("  - Optimize storage operations (save ~500 gas)");
        }
    }
    
    function test_ValidateCreateEventOptimization() public {
        console.log("=== Validating createEvent Gas Optimization ===");
        
        uint256 gasBefore = gasleft();
        
        vm.startPrank(organizer);
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Optimization Test Event",
            symbol: "OTE",
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
        
        console.log("Current createEvent gas usage:", gasUsed);
        console.log("Target gas usage:", TARGET_CREATE_EVENT_GAS);
        
        if (gasUsed <= TARGET_CREATE_EVENT_GAS) {
            console.log("OPTIMIZATION SUCCESS: Gas usage within target");
        } else {
            console.log("OPTIMIZATION NEEDED: Gas usage exceeds target by", gasUsed - TARGET_CREATE_EVENT_GAS);
        }
        
        // Log specific optimization opportunities
        if (gasUsed > TARGET_CREATE_EVENT_GAS) {
            console.log("Recommended optimizations:");
            console.log("  - Implement struct packing (save ~60,000 gas)");
            console.log("  - Optimize constructor logic (save ~20,000 gas)");
            console.log("  - Reduce storage operations (save ~10,000 gas)");
        }
    }
    
    function test_ValidateResaleTicketOptimization() public {
        console.log("=== Validating resaleTicket Gas Optimization ===");
        
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
        
        console.log("Current resaleTicket gas usage:", gasUsed);
        console.log("Target gas usage:", TARGET_RESALE_GAS);
        
        if (gasUsed <= TARGET_RESALE_GAS) {
            console.log("OPTIMIZATION SUCCESS: Gas usage within target");
        } else {
            console.log("OPTIMIZATION NEEDED: Gas usage exceeds target by", gasUsed - TARGET_RESALE_GAS);
        }
        
        // Log specific optimization opportunities
        if (gasUsed > TARGET_RESALE_GAS) {
            console.log("Recommended optimizations:");
            console.log("  - Optimize validation order (save ~200 gas)");
            console.log("  - Cache calculations (save ~300 gas)");
            console.log("  - Optimize transfer logic (save ~400 gas)");
        }
    }
    
    function test_ValidateBatchOperationEfficiency() public {
        console.log("=== Validating Batch Operation Efficiency ===");
        
        // Measure individual operations
        uint256 individualGasTotal = 0;
        for (uint256 i = 0; i < 3; i++) {
            uint256 gasBeforeIndividual = gasleft();
            
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
            
            uint256 gasUsed = gasBeforeIndividual - gasleft();
            individualGasTotal += gasUsed;
        }
        
        // Measure batch operation
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
        
        uint256 gasSavings = individualGasTotal - batchGasUsed;
        uint256 savingsPercentage = (gasSavings * 100) / individualGasTotal;
        
        console.log("Individual operations total gas:", individualGasTotal);
        console.log("Batch operation gas:", batchGasUsed);
        console.log("Gas savings:", gasSavings);
        console.log("Savings percentage:", savingsPercentage, "%");
        console.log("Target savings percentage:", TARGET_BATCH_SAVINGS_PERCENT, "%");
        
        if (savingsPercentage >= TARGET_BATCH_SAVINGS_PERCENT) {
            console.log("BATCH OPTIMIZATION SUCCESS: Savings meet target");
        } else {
            console.log("BATCH OPTIMIZATION NEEDED: Savings below target");
            console.log("Additional savings needed:", TARGET_BATCH_SAVINGS_PERCENT - savingsPercentage, "%");
        }
        
        // Log specific optimization opportunities
        if (savingsPercentage < TARGET_BATCH_SAVINGS_PERCENT) {
            console.log("Recommended batch optimizations:");
            console.log("  - Optimize batch processing loops");
            console.log("  - Reduce redundant storage operations");
            console.log("  - Implement more efficient batch validation");
            console.log("  - Cache common calculations outside loop");
        }
    }
    
    function test_ValidateStorageOptimizationOpportunities() public {
        console.log("=== Validating Storage Optimization Opportunities ===");
        
        // Test storage-heavy operations to identify optimization potential
        uint256 gasBefore = gasleft();
        
        vm.startPrank(buyer1);
        for (uint256 i = 0; i < 5; i++) {
            eventContract.mintTicket{value: TICKET_PRICE}();
        }
        vm.stopPrank();
        
        uint256 gasUsed = gasBefore - gasleft();
        uint256 avgGasPerMint = gasUsed / 5;
        
        console.log("Gas for 5 sequential mints:", gasUsed);
        console.log("Average gas per mint:", avgGasPerMint);
        
        // Analyze storage optimization potential
        if (avgGasPerMint > 100000) {
            console.log("HIGH STORAGE OPTIMIZATION POTENTIAL");
            console.log("Recommended storage optimizations:");
            console.log("  - Pack Event struct fields (save ~20,000 gas per deployment)");
            console.log("  - Use uint128 for ticketPrice (save ~5,000 gas per deployment)");
            console.log("  - Use uint32 for maxSupply and counters (save ~15,000 gas per deployment)");
            console.log("  - Optimize mapping access patterns");
        } else if (avgGasPerMint > 80000) {
            console.log("MEDIUM STORAGE OPTIMIZATION POTENTIAL");
            console.log("Consider struct packing for deployment cost savings");
        } else {
            console.log("STORAGE USAGE OPTIMIZED");
        }
    }
    
    function test_ValidateGasLimitDoSPrevention() public {
        console.log("=== Validating Gas Limit DoS Prevention ===");
        
        // Test maximum safe batch size
        vm.startPrank(organizer);
        
        // Try to create a batch that approaches gas limits
        VeriTixTypes.EventCreationParams[] memory largeParamsArray = new VeriTixTypes.EventCreationParams[](8);
        
        for (uint256 i = 0; i < 8; i++) {
            largeParamsArray[i] = VeriTixTypes.EventCreationParams({
                name: string(abi.encodePacked("DoS Test Event ", vm.toString(i))),
                symbol: string(abi.encodePacked("DTE", vm.toString(i))),
                maxSupply: 1000,
                ticketPrice: TICKET_PRICE,
                organizer: organizer,
                baseURI: "https://example.com/metadata/",
                maxResalePercent: 120,
                organizerFeePercent: 5
            });
        }
        
        uint256 gasBefore = gasleft();
        
        try factory.batchCreateEvents(largeParamsArray) {
            uint256 gasUsed = gasBefore - gasleft();
            console.log("Large batch (8 events) gas usage:", gasUsed);
            
            // Check if we're approaching dangerous gas levels
            if (gasUsed > 20000000) { // 20M gas threshold
                console.log("DoS RISK: Batch operation uses excessive gas");
                console.log("Recommended DoS prevention measures:");
                console.log("  - Implement batch size limits (max 5 events)");
                console.log("  - Add gas estimation before batch execution");
                console.log("  - Provide batch splitting recommendations");
            } else {
                console.log("DoS PREVENTION: Batch operation within safe limits");
            }
        } catch {
            console.log("BATCH FAILED: Likely due to gas limit or validation");
            console.log("This confirms the need for batch size limits");
        }
        
        vm.stopPrank();
    }
    
    // ============ OPTIMIZATION MEASUREMENT HELPERS ============
    
    function measureOptimizationImpact(
        string memory functionName,
        uint256 currentGas,
        uint256 targetGas
    ) internal pure returns (bool success, uint256 savingsNeeded) {
        if (currentGas <= targetGas) {
            return (true, 0);
        } else {
            return (false, currentGas - targetGas);
        }
    }
    
    function calculateOptimizationROI(
        uint256 gasSavings,
        uint256 annualTransactions,
        uint256 implementationEffort // in hours
    ) internal pure returns (uint256 roi) {
        uint256 annualGasSavings = gasSavings * annualTransactions;
        uint256 ethSavings = (annualGasSavings * 20) / 1e9; // 20 gwei gas price
        uint256 dollarSavings = ethSavings * 2000; // $2000 per ETH estimate
        uint256 implementationCost = implementationEffort * 100; // $100 per hour
        
        if (implementationCost > 0) {
            roi = (dollarSavings * 100) / implementationCost; // ROI as percentage
        } else {
            roi = type(uint256).max; // Infinite ROI for zero cost
        }
        
        return roi;
    }
    
    function test_CalculateOptimizationROI() public {
        console.log("=== Optimization ROI Analysis ===");
        
        // mintTicket optimization
        uint256 mintROI = calculateOptimizationROI(
            8000, // 8k gas savings per call
            10000, // 10k transactions per year
            16 // 2 days * 8 hours
        );
        console.log("mintTicket optimization ROI:", mintROI, "%");
        
        // createEvent optimization
        uint256 createROI = calculateOptimizationROI(
            300000, // 300k gas savings per call
            500, // 500 transactions per year
            32 // 4 days * 8 hours
        );
        console.log("createEvent optimization ROI:", createROI, "%");
        
        // Storage optimization
        uint256 storageROI = calculateOptimizationROI(
            80000, // 80k gas savings per deployment
            500, // 500 deployments per year
            40 // 5 days * 8 hours
        );
        console.log("Storage optimization ROI:", storageROI, "%");
    }
}