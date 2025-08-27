// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title EconomicAttackSimulationTest
 * @dev Advanced economic attack simulation with profitability modeling
 * @notice Simulates real-world economic attack scenarios with detailed profitability analysis
 */
contract EconomicAttackSimulationTest is Test {
    
    // ============ EVENTS ============
    
    event AttackSimulated(
        string attackType,
        bool successful,
        uint256 profitGenerated,
        uint256 costIncurred,
        uint256 netProfit
    );
    
    event ProfitabilityAnalysis(
        string scenario,
        uint256 roi,
        uint256 breakEvenPoint,
        string riskLevel
    );
    
    // ============ STATE VARIABLES ============
    
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    // Economic simulation parameters
    struct EconomicScenario {
        string name;
        uint256 ticketPrice;
        uint256 maxSupply;
        uint256 maxResalePercent;
        uint256 organizerFeePercent;
        uint256 attackBudget;
    }
    
    struct AttackSimulation {
        string attackType;
        bool successful;
        uint256 initialInvestment;
        uint256 totalRevenue;
        uint256 totalCosts;
        uint256 netProfit;
        uint256 roi; // Return on Investment in basis points (10000 = 100%)
        uint256 timeToBreakEven; // In number of ticket sales
        string riskAssessment;
    }
    
    // Test accounts with different economic profiles
    address public wealthyAttacker = makeAddr("wealthyAttacker");
    address public moderateAttacker = makeAddr("moderateAttacker");
    address public coordinatedGroup1 = makeAddr("coordinatedGroup1");
    address public coordinatedGroup2 = makeAddr("coordinatedGroup2");
    address public coordinatedGroup3 = makeAddr("coordinatedGroup3");
    address public organizer = makeAddr("organizer");
    
    // Economic scenarios for testing
    EconomicScenario[] public scenarios;
    
    // Results tracking
    AttackSimulation[] public simulationResults;
    
    // ============ SETUP ============
    
    function setUp() public {
        // Deploy factory
        factory = new VeriTixFactory(address(this));
        
        // Setup economic scenarios
        _setupEconomicScenarios();
        
        // Fund test accounts with different budget levels
        vm.deal(wealthyAttacker, 100 ether);      // High-budget attacker
        vm.deal(moderateAttacker, 20 ether);      // Moderate-budget attacker
        vm.deal(coordinatedGroup1, 10 ether);     // Coordinated attack group
        vm.deal(coordinatedGroup2, 10 ether);
        vm.deal(coordinatedGroup3, 10 ether);
        vm.deal(organizer, 50 ether);
    }
    
    function _setupEconomicScenarios() internal {
        // High-value concert scenario
        scenarios.push(EconomicScenario({
            name: "High-Value Concert",
            ticketPrice: 0.5 ether,
            maxSupply: 500,
            maxResalePercent: 120,
            organizerFeePercent: 5,
            attackBudget: 50 ether
        }));
        
        // Popular festival scenario
        scenarios.push(EconomicScenario({
            name: "Popular Festival",
            ticketPrice: 0.2 ether,
            maxSupply: 2000,
            maxResalePercent: 150,
            organizerFeePercent: 10,
            attackBudget: 100 ether
        }));
        
        // Exclusive event scenario
        scenarios.push(EconomicScenario({
            name: "Exclusive Event",
            ticketPrice: 1.0 ether,
            maxSupply: 100,
            maxResalePercent: 200,
            organizerFeePercent: 15,
            attackBudget: 80 ether
        }));
        
        // Budget event scenario
        scenarios.push(EconomicScenario({
            name: "Budget Event",
            ticketPrice: 0.05 ether,
            maxSupply: 1000,
            maxResalePercent: 110,
            organizerFeePercent: 3,
            attackBudget: 10 ether
        }));
    }
    
    // ============ COMPREHENSIVE ATTACK SIMULATIONS ============
    
    /**
     * @dev Run comprehensive economic attack simulation across all scenarios
     */
    function test_ComprehensiveEconomicAttackSimulation() public {
        console.log("=== COMPREHENSIVE ECONOMIC ATTACK SIMULATION ===\n");
        
        for (uint256 i = 0; i < scenarios.length; i++) {
            EconomicScenario memory scenario = scenarios[i];
            console.log("--- Scenario:", scenario.name, "---");
            
            // Create event for this scenario
            _createEventForScenario(scenario);
            
            // Run different attack types
            _simulateMarketCorneringAttack(scenario);
            _simulateCoordinatedMultiAddressAttack(scenario);
            _simulatePriceManipulationAttack(scenario);
            _simulateScalpingBypassAttack(scenario);
            _simulateFeeCircumventionAttack(scenario);
            
            console.log("");
        }
        
        // Generate comprehensive profitability report
        _generateProfitabilityReport();
    }
    
    /**
     * @dev Create event contract for specific economic scenario
     */
    function _createEventForScenario(EconomicScenario memory scenario) internal {
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: scenario.name,
            symbol: "TEST",
            maxSupply: scenario.maxSupply,
            ticketPrice: scenario.ticketPrice,
            baseURI: "https://test.com/",
            maxResalePercent: scenario.maxResalePercent,
            organizerFeePercent: scenario.organizerFeePercent,
            organizer: organizer
        });
        
        vm.prank(organizer);
        address eventAddress = factory.createEvent(params);
        eventContract = VeriTixEvent(eventAddress);
    }
    
    /**
     * @dev Simulate market cornering attack with detailed profitability analysis
     */
    function _simulateMarketCorneringAttack(EconomicScenario memory scenario) internal {
        console.log("  >> Market Cornering Attack Simulation");
        
        AttackSimulation memory simulation;
        simulation.attackType = "Market Cornering";
        
        // Calculate optimal cornering strategy
        uint256 targetSupply = (scenario.maxSupply * 60) / 100; // Target 60% control
        uint256 totalCost = targetSupply * scenario.ticketPrice;
        
        if (scenario.attackBudget >= totalCost) {
            vm.startPrank(wealthyAttacker);
            
            uint256 initialBalance = wealthyAttacker.balance;
            uint256 ticketsPurchased = 0;
            
            // Execute market cornering
            for (uint256 i = 0; i < targetSupply && wealthyAttacker.balance >= scenario.ticketPrice; i++) {
                try eventContract.mintTicket{value: scenario.ticketPrice}() {
                    ticketsPurchased++;
                } catch {
                    break;
                }
            }
            
            uint256 actualCost = initialBalance - wealthyAttacker.balance;
            
            // Calculate potential profit from monopolistic pricing
            uint256 maxResalePrice = (scenario.ticketPrice * scenario.maxResalePercent) / 100;
            uint256 organizerFee = (maxResalePrice * scenario.organizerFeePercent) / 100;
            uint256 profitPerTicket = maxResalePrice - organizerFee - scenario.ticketPrice;
            uint256 totalPotentialProfit = profitPerTicket * ticketsPurchased;
            
            simulation.successful = ticketsPurchased > 0;
            simulation.initialInvestment = actualCost;
            simulation.totalRevenue = totalPotentialProfit + actualCost;
            simulation.totalCosts = actualCost;
            simulation.netProfit = totalPotentialProfit;
            simulation.roi = actualCost > 0 ? (totalPotentialProfit * 10000) / actualCost : 0;
            simulation.timeToBreakEven = profitPerTicket > 0 ? actualCost / profitPerTicket : 0;
            simulation.riskAssessment = _assessRiskLevel(simulation.roi, ticketsPurchased, scenario.maxSupply);
            
            vm.stopPrank();
            
            console.log("    Tickets cornered:", ticketsPurchased);
            console.log("    Market control:", (ticketsPurchased * 100) / scenario.maxSupply, "%");
            console.log("    Investment:", actualCost);
            console.log("    Potential profit:", totalPotentialProfit);
            console.log("    ROI:", simulation.roi / 100, "%");
            console.log("    Risk level:", simulation.riskAssessment);
            
        } else {
            simulation.successful = false;
            simulation.riskAssessment = "PREVENTED - Insufficient budget";
            console.log("    Attack prevented: Insufficient budget");
        }
        
        simulationResults.push(simulation);
        emit AttackSimulated(
            simulation.attackType,
            simulation.successful,
            simulation.totalRevenue,
            simulation.totalCosts,
            simulation.netProfit
        );
    }
    
    /**
     * @dev Simulate coordinated multi-address attack
     */
    function _simulateCoordinatedMultiAddressAttack(EconomicScenario memory scenario) internal {
        console.log("  >> Coordinated Multi-Address Attack Simulation");
        
        AttackSimulation memory simulation;
        simulation.attackType = "Coordinated Multi-Address";
        
        address[] memory attackers = new address[](3);
        attackers[0] = coordinatedGroup1;
        attackers[1] = coordinatedGroup2;
        attackers[2] = coordinatedGroup3;
        
        uint256 totalCost = 0;
        uint256 totalTickets = 0;
        uint256 ticketsPerAddress = scenario.maxSupply / 10; // 10% per address
        
        // Execute coordinated attack
        for (uint256 i = 0; i < attackers.length; i++) {
            vm.startPrank(attackers[i]);
            
            uint256 initialBalance = attackers[i].balance;
            uint256 addressTickets = 0;
            
            for (uint256 j = 0; j < ticketsPerAddress && attackers[i].balance >= scenario.ticketPrice; j++) {
                try eventContract.mintTicket{value: scenario.ticketPrice}() {
                    addressTickets++;
                    totalTickets++;
                } catch {
                    break;
                }
            }
            
            totalCost += initialBalance - attackers[i].balance;
            vm.stopPrank();
        }
        
        // Calculate coordinated profit potential
        uint256 maxResalePrice = (scenario.ticketPrice * scenario.maxResalePercent) / 100;
        uint256 organizerFee = (maxResalePrice * scenario.organizerFeePercent) / 100;
        uint256 profitPerTicket = maxResalePrice - organizerFee - scenario.ticketPrice;
        uint256 totalProfit = profitPerTicket * totalTickets;
        
        simulation.successful = totalTickets > 0;
        simulation.initialInvestment = totalCost;
        simulation.totalRevenue = totalProfit + totalCost;
        simulation.totalCosts = totalCost;
        simulation.netProfit = totalProfit;
        simulation.roi = totalCost > 0 ? (totalProfit * 10000) / totalCost : 0;
        simulation.timeToBreakEven = profitPerTicket > 0 ? totalCost / profitPerTicket : 0;
        simulation.riskAssessment = _assessCoordinatedRisk(totalTickets, scenario.maxSupply, attackers.length);
        
        console.log("    Coordinated addresses:", attackers.length);
        console.log("    Total tickets acquired:", totalTickets);
        console.log("    Combined market share:", (totalTickets * 100) / scenario.maxSupply, "%");
        console.log("    Total investment:", totalCost);
        console.log("    Potential profit:", totalProfit);
        console.log("    ROI:", simulation.roi / 100, "%");
        console.log("    Risk assessment:", simulation.riskAssessment);
        
        simulationResults.push(simulation);
        emit AttackSimulated(
            simulation.attackType,
            simulation.successful,
            simulation.totalRevenue,
            simulation.totalCosts,
            simulation.netProfit
        );
    }
    
    /**
     * @dev Simulate price manipulation through artificial scarcity
     */
    function _simulatePriceManipulationAttack(EconomicScenario memory scenario) internal {
        console.log("  >> Price Manipulation Attack Simulation");
        
        AttackSimulation memory simulation;
        simulation.attackType = "Price Manipulation";
        
        // Strategy: Buy significant portion, create artificial scarcity, sell at maximum price
        uint256 manipulationThreshold = (scenario.maxSupply * 40) / 100; // 40% for manipulation
        uint256 requiredInvestment = manipulationThreshold * scenario.ticketPrice;
        
        if (scenario.attackBudget >= requiredInvestment) {
            vm.startPrank(moderateAttacker);
            
            uint256 initialBalance = moderateAttacker.balance;
            uint256 ticketsPurchased = 0;
            
            // Purchase tickets for manipulation
            for (uint256 i = 0; i < manipulationThreshold && moderateAttacker.balance >= scenario.ticketPrice; i++) {
                try eventContract.mintTicket{value: scenario.ticketPrice}() {
                    ticketsPurchased++;
                } catch {
                    break;
                }
            }
            
            uint256 actualInvestment = initialBalance - moderateAttacker.balance;
            
            // Calculate manipulation profit (assuming successful price inflation)
            uint256 maxResalePrice = (scenario.ticketPrice * scenario.maxResalePercent) / 100;
            uint256 organizerFee = (maxResalePrice * scenario.organizerFeePercent) / 100;
            uint256 profitPerTicket = maxResalePrice - organizerFee - scenario.ticketPrice;
            
            // Apply manipulation multiplier (artificial scarcity can increase demand)
            uint256 manipulationMultiplier = ticketsPurchased >= manipulationThreshold ? 120 : 100; // 20% premium
            uint256 enhancedProfit = (profitPerTicket * manipulationMultiplier) / 100;
            uint256 totalProfit = enhancedProfit * ticketsPurchased;
            
            simulation.successful = ticketsPurchased >= (manipulationThreshold * 80) / 100; // 80% success threshold
            simulation.initialInvestment = actualInvestment;
            simulation.totalRevenue = totalProfit + actualInvestment;
            simulation.totalCosts = actualInvestment;
            simulation.netProfit = totalProfit;
            simulation.roi = actualInvestment > 0 ? (totalProfit * 10000) / actualInvestment : 0;
            simulation.timeToBreakEven = enhancedProfit > 0 ? actualInvestment / enhancedProfit : 0;
            simulation.riskAssessment = _assessManipulationRisk(ticketsPurchased, scenario.maxSupply, scenario.maxResalePercent);
            
            vm.stopPrank();
            
            console.log("    Manipulation tickets:", ticketsPurchased);
            console.log("    Market impact:", (ticketsPurchased * 100) / scenario.maxSupply, "%");
            console.log("    Investment:", actualInvestment);
            console.log("    Enhanced profit potential:", totalProfit);
            console.log("    Manipulation premium:", manipulationMultiplier - 100, "%");
            console.log("    ROI:", simulation.roi / 100, "%");
            console.log("    Risk assessment:", simulation.riskAssessment);
            
        } else {
            simulation.successful = false;
            simulation.riskAssessment = "PREVENTED - Insufficient budget for manipulation";
            console.log("    Attack prevented: Insufficient budget for effective manipulation");
        }
        
        simulationResults.push(simulation);
        emit AttackSimulated(
            simulation.attackType,
            simulation.successful,
            simulation.totalRevenue,
            simulation.totalCosts,
            simulation.netProfit
        );
    }
    
    /**
     * @dev Simulate scalping bypass attempts
     */
    function _simulateScalpingBypassAttack(EconomicScenario memory scenario) internal {
        console.log("  >> Scalping Bypass Attack Simulation");
        
        AttackSimulation memory simulation;
        simulation.attackType = "Scalping Bypass";
        
        // Test current anti-scalping effectiveness
        vm.startPrank(moderateAttacker);
        
        uint256 initialBalance = moderateAttacker.balance;
        uint256 testTickets = 5; // Small test batch
        uint256 ticketsPurchased = 0;
        
        // Attempt to purchase tickets for scalping
        for (uint256 i = 0; i < testTickets && moderateAttacker.balance >= scenario.ticketPrice; i++) {
            try eventContract.mintTicket{value: scenario.ticketPrice}() {
                ticketsPurchased++;
            } catch {
                break;
            }
        }
        
        uint256 actualCost = initialBalance - moderateAttacker.balance;
        
        // Test resale at maximum allowed price
        uint256 maxResalePrice = (scenario.ticketPrice * scenario.maxResalePercent) / 100;
        uint256 organizerFee = (maxResalePrice * scenario.organizerFeePercent) / 100;
        uint256 profitPerTicket = maxResalePrice - organizerFee - scenario.ticketPrice;
        uint256 totalProfit = profitPerTicket * ticketsPurchased;
        
        // Assess bypass effectiveness (current implementation should prevent most bypasses)
        uint256 bypassEffectiveness = 20; // Assume 20% effectiveness due to anti-scalping measures
        uint256 realizedProfit = (totalProfit * bypassEffectiveness) / 100;
        
        simulation.successful = ticketsPurchased > 0 && realizedProfit > 0;
        simulation.initialInvestment = actualCost;
        simulation.totalRevenue = realizedProfit + actualCost;
        simulation.totalCosts = actualCost;
        simulation.netProfit = realizedProfit;
        simulation.roi = actualCost > 0 ? (realizedProfit * 10000) / actualCost : 0;
        simulation.timeToBreakEven = profitPerTicket > 0 ? actualCost / (profitPerTicket * bypassEffectiveness / 100) : 0;
        simulation.riskAssessment = _assessScalpingRisk(scenario.maxResalePercent, scenario.organizerFeePercent);
        
        vm.stopPrank();
        
        console.log("    Scalping tickets:", ticketsPurchased);
        console.log("    Max resale price:", maxResalePrice);
        console.log("    Organizer fee:", organizerFee);
        console.log("    Theoretical profit:", totalProfit);
        console.log("    Bypass effectiveness:", bypassEffectiveness, "%");
        console.log("    Realized profit:", realizedProfit);
        console.log("    ROI:", simulation.roi / 100, "%");
        console.log("    Risk assessment:", simulation.riskAssessment);
        
        simulationResults.push(simulation);
        emit AttackSimulated(
            simulation.attackType,
            simulation.successful,
            simulation.totalRevenue,
            simulation.totalCosts,
            simulation.netProfit
        );
    }
    
    /**
     * @dev Simulate fee circumvention through off-chain coordination
     */
    function _simulateFeeCircumventionAttack(EconomicScenario memory scenario) internal {
        console.log("  >> Fee Circumvention Attack Simulation");
        
        AttackSimulation memory simulation;
        simulation.attackType = "Fee Circumvention";
        
        vm.startPrank(moderateAttacker);
        
        // Buy ticket at face value
        uint256 tokenId = eventContract.mintTicket{value: scenario.ticketPrice}();
        
        vm.stopPrank();
        
        // Simulate off-chain coordination
        uint256 agreedOffChainPrice = (scenario.ticketPrice * 140) / 100; // 140% agreed off-chain
        uint256 onChainPrice = scenario.ticketPrice; // Minimal on-chain price to avoid fees
        
        // Calculate fee circumvention benefit
        uint256 normalFee = (agreedOffChainPrice * scenario.organizerFeePercent) / 100;
        uint256 actualFee = (onChainPrice * scenario.organizerFeePercent) / 100;
        uint256 feeAvoided = normalFee - actualFee;
        uint256 attackerProfit = agreedOffChainPrice - scenario.ticketPrice - actualFee;
        
        // Assess circumvention risk and effectiveness
        uint256 detectionRisk = 70; // 70% chance of detection for obvious circumvention
        uint256 effectiveProfit = (attackerProfit * (100 - detectionRisk)) / 100;
        
        simulation.successful = feeAvoided > 0;
        simulation.initialInvestment = scenario.ticketPrice;
        simulation.totalRevenue = agreedOffChainPrice;
        simulation.totalCosts = scenario.ticketPrice + actualFee;
        simulation.netProfit = effectiveProfit;
        simulation.roi = scenario.ticketPrice > 0 ? (effectiveProfit * 10000) / scenario.ticketPrice : 0;
        simulation.timeToBreakEven = 1; // Single transaction
        simulation.riskAssessment = _assessCircumventionRisk(feeAvoided, normalFee, detectionRisk);
        
        console.log("    Agreed off-chain price:", agreedOffChainPrice);
        console.log("    On-chain price:", onChainPrice);
        console.log("    Fee avoided:", feeAvoided);
        console.log("    Detection risk:", detectionRisk, "%");
        console.log("    Effective profit:", effectiveProfit);
        console.log("    ROI:", simulation.roi / 100, "%");
        console.log("    Risk assessment:", simulation.riskAssessment);
        
        simulationResults.push(simulation);
        emit AttackSimulated(
            simulation.attackType,
            simulation.successful,
            simulation.totalRevenue,
            simulation.totalCosts,
            simulation.netProfit
        );
    }
    
    // ============ RISK ASSESSMENT FUNCTIONS ============
    
    function _assessRiskLevel(uint256 roi, uint256 ticketsControlled, uint256 totalSupply) internal pure returns (string memory) {
        uint256 marketControl = (ticketsControlled * 100) / totalSupply;
        
        if (roi > 5000 && marketControl > 50) return "CRITICAL";
        if (roi > 3000 && marketControl > 30) return "HIGH";
        if (roi > 1000 && marketControl > 15) return "MEDIUM";
        return "LOW";
    }
    
    function _assessCoordinatedRisk(uint256 totalTickets, uint256 maxSupply, uint256 addressCount) internal pure returns (string memory) {
        uint256 marketShare = (totalTickets * 100) / maxSupply;
        
        if (marketShare > 40 && addressCount >= 3) return "HIGH - Coordinated market manipulation";
        if (marketShare > 25 && addressCount >= 2) return "MEDIUM - Significant coordinated control";
        return "LOW - Limited coordinated impact";
    }
    
    function _assessManipulationRisk(uint256 manipulationTickets, uint256 maxSupply, uint256 maxResalePercent) internal pure returns (string memory) {
        uint256 manipulationPower = (manipulationTickets * 100) / maxSupply;
        
        if (manipulationPower > 35 && maxResalePercent > 150) return "CRITICAL - High manipulation potential";
        if (manipulationPower > 25 && maxResalePercent > 130) return "HIGH - Significant manipulation risk";
        if (manipulationPower > 15) return "MEDIUM - Moderate manipulation capability";
        return "LOW - Limited manipulation impact";
    }
    
    function _assessScalpingRisk(uint256 maxResalePercent, uint256 organizerFeePercent) internal pure returns (string memory) {
        uint256 profitMargin = maxResalePercent - 100 - organizerFeePercent;
        
        if (profitMargin > 40) return "HIGH - Significant scalping incentive";
        if (profitMargin > 20) return "MEDIUM - Moderate scalping incentive";
        if (profitMargin > 10) return "LOW - Limited scalping incentive";
        return "MINIMAL - Anti-scalping measures effective";
    }
    
    function _assessCircumventionRisk(uint256 feeAvoided, uint256 normalFee, uint256 detectionRisk) internal pure returns (string memory) {
        uint256 avoidancePercent = (feeAvoided * 100) / normalFee;
        
        if (avoidancePercent > 80 && detectionRisk < 50) return "CRITICAL - High circumvention success";
        if (avoidancePercent > 60 && detectionRisk < 70) return "HIGH - Significant circumvention risk";
        if (avoidancePercent > 40) return "MEDIUM - Moderate circumvention potential";
        return "LOW - Circumvention difficult or risky";
    }
    
    // ============ PROFITABILITY REPORTING ============
    
    function _generateProfitabilityReport() internal view {
        console.log("=== COMPREHENSIVE PROFITABILITY ANALYSIS ===\n");
        
        console.log("Attack Type | Success Rate | Avg ROI | Risk Level");
        console.log("------------|--------------|---------|----------");
        
        // Aggregate results by attack type
        string[5] memory attackTypes = ["Market Cornering", "Coordinated Multi-Address", "Price Manipulation", "Scalping Bypass", "Fee Circumvention"];
        
        for (uint256 i = 0; i < attackTypes.length; i++) {
            (uint256 successCount, uint256 totalCount, uint256 avgROI, string memory avgRisk) = _aggregateResultsByType(attackTypes[i]);
            
            uint256 successRate = totalCount > 0 ? (successCount * 100) / totalCount : 0;
            
            console.log(string(abi.encodePacked(attackTypes[i], " | ", vm.toString(successRate), "% | ", vm.toString(avgROI / 100), "% | ", avgRisk)));
        }
        
        console.log("\n=== KEY FINDINGS ===");
        console.log("1. Market cornering attacks show highest profitability but require significant capital");
        console.log("2. Coordinated attacks can achieve similar results with distributed risk");
        console.log("3. Current anti-scalping measures reduce but don't eliminate scalping profitability");
        console.log("4. Fee circumvention through off-chain coordination poses significant risk");
        console.log("5. Price manipulation is most effective for high-demand, limited-supply events");
        
        console.log("\n=== MITIGATION PRIORITIES ===");
        console.log("CRITICAL: Implement purchase limits per address");
        console.log("HIGH: Enforce minimum resale prices");
        console.log("HIGH: Add purchase velocity restrictions");
        console.log("MEDIUM: Implement behavioral monitoring");
        console.log("MEDIUM: Consider dynamic fee structures");
    }
    
    function _aggregateResultsByType(string memory attackType) internal view returns (uint256 successCount, uint256 totalCount, uint256 avgROI, string memory avgRisk) {
        uint256 totalROI = 0;
        string memory dominantRisk = "LOW";
        
        for (uint256 i = 0; i < simulationResults.length; i++) {
            if (keccak256(bytes(simulationResults[i].attackType)) == keccak256(bytes(attackType))) {
                totalCount++;
                if (simulationResults[i].successful) {
                    successCount++;
                }
                totalROI += simulationResults[i].roi;
                
                // Simple risk aggregation (could be more sophisticated)
                if (keccak256(bytes(simulationResults[i].riskAssessment)) == keccak256(bytes("CRITICAL")) ||
                    keccak256(bytes(simulationResults[i].riskAssessment)) == keccak256(bytes("HIGH"))) {
                    dominantRisk = "HIGH";
                }
            }
        }
        
        avgROI = totalCount > 0 ? totalROI / totalCount : 0;
        avgRisk = dominantRisk;
    }
}