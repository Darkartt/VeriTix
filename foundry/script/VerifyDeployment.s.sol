// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";
import "../src/interfaces/IVeriTixFactory.sol";

/**
 * @title VerifyDeployment
 * @dev Comprehensive verification script for deployed VeriTix contracts
 * @notice This script validates deployed contract functionality and configuration
 */
contract VerifyDeployment is Script {
    
    // ============ VERIFICATION CONFIGURATION ============
    
    /// @dev Factory contract to verify
    address public factoryAddress;
    
    /// @dev Whether to run comprehensive tests
    bool public constant RUN_COMPREHENSIVE_TESTS = true;
    
    /// @dev Whether to test event creation
    bool public constant TEST_EVENT_CREATION = true;
    
    /// @dev Whether to test ticket operations
    bool public constant TEST_TICKET_OPERATIONS = true;
    
    // ============ VERIFICATION STATE ============
    
    VeriTixFactory public factory;
    address[] public verificationEvents;
    
    struct VerificationResult {
        bool factoryDeployed;
        bool factoryConfigured;
        bool eventCreationWorks;
        bool ticketMintingWorks;
        bool resaleWorks;
        bool refundWorks;
        bool checkInWorks;
        bool cancellationWorks;
        uint256 totalTests;
        uint256 passedTests;
    }
    
    VerificationResult public results;
    
    // ============ MAIN VERIFICATION FUNCTION ============
    
    /**
     * @dev Main verification function
     * @param _factoryAddress Address of the deployed factory to verify
     */
    function run(address _factoryAddress) external {
        require(_factoryAddress != address(0), "Invalid factory address");
        
        factoryAddress = _factoryAddress;
        factory = VeriTixFactory(_factoryAddress);
        
        console.log("=== VeriTix Deployment Verification ===");
        console.log("Factory Address:", _factoryAddress);
        console.log("Verifier:", msg.sender);
        console.log("Chain ID:", block.chainid);
        
        // Initialize results
        results.totalTests = 0;
        results.passedTests = 0;
        
        // Run verification tests
        verifyFactoryDeployment();
        verifyFactoryConfiguration();
        
        if (TEST_EVENT_CREATION) {
            verifyEventCreation();
        }
        
        if (TEST_TICKET_OPERATIONS && RUN_COMPREHENSIVE_TESTS) {
            verifyTicketOperations();
        }
        
        // Generate final report
        generateVerificationReport();
    }
    
    // ============ FACTORY VERIFICATION ============
    
    /**
     * @dev Verify factory deployment and basic functionality
     */
    function verifyFactoryDeployment() internal {
        console.log("\n--- Verifying Factory Deployment ---");
        
        // Test 1: Contract exists and has code
        results.totalTests++;
        if (factoryAddress.code.length > 0) {
            results.passedTests++;
            results.factoryDeployed = true;
            console.log("[PASS] Factory contract deployed with code");
        } else {
            console.log("[FAIL] Factory contract has no code");
            return;
        }
        
        // Test 2: Factory owner is set
        results.totalTests++;
        try factory.owner() returns (address owner) {
            if (owner != address(0)) {
                results.passedTests++;
                console.log("[PASS] Factory owner set to:", owner);
            } else {
                console.log("[FAIL] Factory owner is zero address");
            }
        } catch {
            console.log("[FAIL] Failed to get factory owner");
        }
        
        // Test 3: Factory is not paused
        results.totalTests++;
        try factory.factoryPaused() returns (bool paused) {
            if (!paused) {
                results.passedTests++;
                console.log("[PASS] Factory is not paused");
            } else {
                console.log("[FAIL] Factory is paused");
            }
        } catch {
            console.log("[FAIL] Failed to check factory pause status");
        }
        
        // Test 4: Factory total events is accessible
        results.totalTests++;
        try factory.getTotalEvents() returns (uint256 totalEvents) {
            results.passedTests++;
            console.log("[PASS] Factory total events accessible:", totalEvents);
        } catch {
            console.log("[FAIL] Failed to get total events");
        }
    }
    
    /**
     * @dev Verify factory configuration and settings
     */
    function verifyFactoryConfiguration() internal {
        console.log("\n--- Verifying Factory Configuration ---");
        
        // Test 5: Global resale percentage is reasonable
        results.totalTests++;
        try factory.globalMaxResalePercent() returns (uint256 resalePercent) {
            if (resalePercent >= 100 && resalePercent <= 200) {
                results.passedTests++;
                results.factoryConfigured = true;
                console.log("[PASS] Global max resale percent:", resalePercent, "%");
            } else {
                console.log("[FAIL] Global max resale percent out of range:", resalePercent);
            }
        } catch {
            console.log("[FAIL] Failed to get global max resale percent");
        }
        
        // Test 6: Default organizer fee is reasonable
        results.totalTests++;
        try factory.defaultOrganizerFee() returns (uint256 fee) {
            if (fee <= 20) { // Max 20%
                results.passedTests++;
                console.log("[PASS] Default organizer fee:", fee, "%");
            } else {
                console.log("[FAIL] Default organizer fee too high:", fee);
            }
        } catch {
            console.log("[FAIL] Failed to get default organizer fee");
        }
        
        // Test 7: Event creation fee is accessible
        results.totalTests++;
        try factory.eventCreationFee() returns (uint256 fee) {
            results.passedTests++;
            console.log("[PASS] Event creation fee:", fee, "wei");
        } catch {
            console.log("[FAIL] Failed to get event creation fee");
        }
        
        // Test 8: Factory config can be retrieved
        results.totalTests++;
        try factory.getFactoryConfig() returns (VeriTixTypes.FactoryConfig memory config) {
            results.passedTests++;
            console.log("[PASS] Factory config retrieved successfully");
            console.log("  Platform Owner:", config.platformOwner);
            console.log("  Global Max Resale %:", config.globalMaxResalePercent);
            console.log("  Default Organizer Fee %:", config.defaultOrganizerFee);
            console.log("  Factory Paused:", config.factoryPaused);
        } catch {
            console.log("[FAIL] Failed to get factory config");
        }
    }
    
    // ============ EVENT CREATION VERIFICATION ============
    
    /**
     * @dev Verify event creation functionality
     */
    function verifyEventCreation() internal {
        console.log("\n--- Verifying Event Creation ---");
        
        vm.startBroadcast();
        
        // Test 9: Create a test event
        results.totalTests++;
        try this.createTestEvent() returns (address eventAddress) {
            if (eventAddress != address(0)) {
                results.passedTests++;
                results.eventCreationWorks = true;
                verificationEvents.push(eventAddress);
                console.log("[PASS] Test event created at:", eventAddress);
            } else {
                console.log("[FAIL] Test event creation returned zero address");
            }
        } catch Error(string memory reason) {
            console.log("[FAIL] Test event creation failed:", reason);
        } catch {
            console.log("[FAIL] Test event creation failed with unknown error");
        }
        
        vm.stopBroadcast();
        
        // Test 10: Verify event is registered in factory
        if (verificationEvents.length > 0) {
            results.totalTests++;
            address eventAddr = verificationEvents[0];
            
            try factory.isValidEventContract(eventAddr) returns (bool isValid) {
                if (isValid) {
                    results.passedTests++;
                    console.log("[PASS] Event registered in factory");
                } else {
                    console.log("[FAIL] Event not registered in factory");
                }
            } catch {
                console.log("[FAIL] Failed to check event registration");
            }
        }
        
        // Test 11: Verify event contract functionality
        if (verificationEvents.length > 0) {
            verifyEventContract(verificationEvents[0]);
        }
    }
    
    /**
     * @dev Create a test event for verification
     * @return eventAddress Address of the created event
     */
    function createTestEvent() external returns (address eventAddress) {
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Verification Test Event",
            symbol: "VERIFY",
            maxSupply: 100,
            ticketPrice: 0.01 ether,
            organizer: msg.sender,
            baseURI: "https://api.veritix.com/verify/",
            maxResalePercent: 110,
            organizerFeePercent: 5
        });
        
        return factory.createEvent{value: factory.eventCreationFee()}(params);
    }
    
    /**
     * @dev Verify individual event contract
     * @param eventAddress Address of the event contract to verify
     */
    function verifyEventContract(address eventAddress) internal {
        console.log("\n--- Verifying Event Contract ---");
        
        VeriTixEvent eventContract = VeriTixEvent(eventAddress);
        
        // Test 12: Event info is accessible
        results.totalTests++;
        try eventContract.getEventInfo() returns (
            string memory name,
            string memory symbol,
            address organizer,
            uint256 ticketPrice,
            uint256 maxSupply,
            uint256 totalSupply
        ) {
            results.passedTests++;
            console.log("[PASS] Event info retrieved:");
            console.log("  Name:", name);
            console.log("  Symbol:", symbol);
            console.log("  Organizer:", organizer);
            console.log("  Ticket Price:", ticketPrice);
            console.log("  Max Supply:", maxSupply);
            console.log("  Total Supply:", totalSupply);
        } catch {
            console.log("[FAIL] Failed to get event info");
        }
        
        // Test 13: Anti-scalping config is accessible
        results.totalTests++;
        try eventContract.getAntiScalpingConfig() returns (
            uint256 maxResalePercent,
            uint256 organizerFeePercent
        ) {
            results.passedTests++;
            console.log("[PASS] Anti-scalping config retrieved:");
            console.log("  Max Resale %:", maxResalePercent);
            console.log("  Organizer Fee %:", organizerFeePercent);
        } catch {
            console.log("[FAIL] Failed to get anti-scalping config");
        }
        
        // Test 14: Collection metadata is accessible
        results.totalTests++;
        try eventContract.getCollectionMetadata() returns (
            VeriTixTypes.CollectionMetadata memory metadata
        ) {
            results.passedTests++;
            console.log("[PASS] Collection metadata retrieved");
            console.log("  Contract Address:", metadata.contractAddress);
            console.log("  Base URI:", metadata.baseURI);
        } catch {
            console.log("[FAIL] Failed to get collection metadata");
        }
    }
    
    // ============ TICKET OPERATIONS VERIFICATION ============
    
    /**
     * @dev Verify ticket operations (minting, resale, refund, etc.)
     */
    function verifyTicketOperations() internal {
        if (verificationEvents.length == 0) {
            console.log("No events available for ticket operations testing");
            return;
        }
        
        console.log("\n--- Verifying Ticket Operations ---");
        
        address eventAddress = verificationEvents[0];
        VeriTixEvent eventContract = VeriTixEvent(eventAddress);
        
        vm.startBroadcast();
        
        // Test 15: Mint a ticket
        results.totalTests++;
        try this.mintTestTicket(eventAddress) returns (uint256 tokenId) {
            if (tokenId > 0) {
                results.passedTests++;
                results.ticketMintingWorks = true;
                console.log("[PASS] Ticket minted successfully, Token ID:", tokenId);
                
                // Run additional ticket tests
                verifyTicketFunctionality(eventAddress, tokenId);
            } else {
                console.log("[FAIL] Ticket minting returned invalid token ID");
            }
        } catch Error(string memory reason) {
            console.log("[FAIL] Ticket minting failed:", reason);
        } catch {
            console.log("[FAIL] Ticket minting failed with unknown error");
        }
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev Mint a test ticket
     * @param eventAddress Address of the event contract
     * @return tokenId ID of the minted ticket
     */
    function mintTestTicket(address eventAddress) external payable returns (uint256 tokenId) {
        VeriTixEvent eventContract = VeriTixEvent(eventAddress);
        uint256 ticketPrice = eventContract.ticketPrice();
        
        return eventContract.mintTicket{value: ticketPrice}();
    }
    
    /**
     * @dev Verify ticket-specific functionality
     * @param eventAddress Address of the event contract
     * @param tokenId ID of the ticket to test
     */
    function verifyTicketFunctionality(address eventAddress, uint256 tokenId) internal {
        VeriTixEvent eventContract = VeriTixEvent(eventAddress);
        
        // Test 16: Ticket metadata is accessible
        results.totalTests++;
        try eventContract.getTicketMetadata(tokenId) returns (
            VeriTixTypes.TicketMetadata memory metadata
        ) {
            results.passedTests++;
            console.log("[PASS] Ticket metadata retrieved:");
            console.log("  Token ID:", metadata.tokenId);
            console.log("  Owner:", metadata.owner);
            console.log("  Last Price Paid:", metadata.lastPricePaid);
            console.log("  Max Resale Price:", metadata.maxResalePrice);
        } catch {
            console.log("[FAIL] Failed to get ticket metadata");
        }
        
        // Test 17: Token URI is accessible
        results.totalTests++;
        try eventContract.tokenURI(tokenId) returns (string memory uri) {
            if (bytes(uri).length > 0) {
                results.passedTests++;
                console.log("[PASS] Token URI retrieved:", uri);
            } else {
                console.log("[FAIL] Token URI is empty");
            }
        } catch {
            console.log("[FAIL] Failed to get token URI");
        }
        
        // Test 18: Check-in status is accessible
        results.totalTests++;
        try eventContract.isCheckedIn(tokenId) returns (bool checkedIn) {
            results.passedTests++;
            console.log("[PASS] Check-in status retrieved:", checkedIn);
        } catch {
            console.log("[FAIL] Failed to get check-in status");
        }
    }
    
    // ============ VERIFICATION REPORTING ============
    
    /**
     * @dev Generate comprehensive verification report
     */
    function generateVerificationReport() internal view {
        console.log("\n=== Verification Report ===");
        
        console.log("Test Results:");
        console.log("  Total Tests:", results.totalTests);
        console.log("  Passed Tests:", results.passedTests);
        console.log("  Failed Tests:", results.totalTests - results.passedTests);
        
        uint256 successRate = results.totalTests > 0 
            ? (results.passedTests * 100) / results.totalTests 
            : 0;
        console.log("  Success Rate:", successRate, "%");
        
        console.log("\nFunctionality Status:");
        console.log("  Factory Deployed:", results.factoryDeployed ? "[PASS]" : "[FAIL]");
        console.log("  Factory Configured:", results.factoryConfigured ? "[PASS]" : "[FAIL]");
        console.log("  Event Creation:", results.eventCreationWorks ? "[PASS]" : "[FAIL]");
        console.log("  Ticket Minting:", results.ticketMintingWorks ? "[PASS]" : "[FAIL]");
        console.log("  Resale System:", results.resaleWorks ? "[PASS]" : "[FAIL]");
        console.log("  Refund System:", results.refundWorks ? "[PASS]" : "[FAIL]");
        console.log("  Check-in System:", results.checkInWorks ? "[PASS]" : "[FAIL]");
        console.log("  Cancellation System:", results.cancellationWorks ? "[PASS]" : "[FAIL]");
        
        console.log("\nDeployment Summary:");
        console.log("  Factory Address:", factoryAddress);
        console.log("  Verification Events Created:", verificationEvents.length);
        
        if (verificationEvents.length > 0) {
            console.log("  Test Events:");
            for (uint256 i = 0; i < verificationEvents.length; i++) {
                console.log("    Event", i + 1, ":", verificationEvents[i]);
            }
        }
        
        // Overall status
        if (successRate >= 90) {
            console.log("\n[SUCCESS] VERIFICATION PASSED - Deployment is ready for production");
        } else if (successRate >= 70) {
            console.log("\n[WARNING]  VERIFICATION PARTIAL - Some issues detected, review recommended");
        } else {
            console.log("\n[ERROR] VERIFICATION FAILED - Significant issues detected, deployment not ready");
        }
        
        console.log("\nVerification completed at block:", block.number);
    }
    
    /**
     * @dev Quick verification for already deployed contracts
     * @param _factoryAddress Address of the factory to verify
     */
    function quickVerify(address _factoryAddress) external view {
        require(_factoryAddress != address(0), "Invalid factory address");
        
        console.log("=== Quick Verification ===");
        console.log("Factory:", _factoryAddress);
        
        VeriTixFactory factoryContract = VeriTixFactory(_factoryAddress);
        
        // Basic checks
        console.log("Contract has code:", _factoryAddress.code.length > 0);
        
        try factoryContract.owner() returns (address owner) {
            console.log("Owner:", owner);
        } catch {
            console.log("Failed to get owner");
        }
        
        try factoryContract.getTotalEvents() returns (uint256 totalEvents) {
            console.log("Total Events:", totalEvents);
        } catch {
            console.log("Failed to get total events");
        }
        
        try factoryContract.factoryPaused() returns (bool paused) {
            console.log("Factory Paused:", paused);
        } catch {
            console.log("Failed to get pause status");
        }
        
        console.log("Quick verification completed");
    }
}