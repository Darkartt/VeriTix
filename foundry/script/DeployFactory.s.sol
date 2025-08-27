// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title DeployFactory
 * @dev Deployment script for the VeriTix Factory architecture
 * @notice This script deploys the VeriTixFactory contract and optionally creates test events
 */
contract DeployFactory is Script {
    
    // ============ DEPLOYMENT CONFIGURATION ============
    
    /// @dev Default factory owner (can be overridden via environment variable)
    address public constant DEFAULT_FACTORY_OWNER = 0x1234567890123456789012345678901234567890;
    
    /// @dev Whether to create test events after factory deployment
    bool public constant CREATE_TEST_EVENTS = true;
    
    /// @dev Number of test events to create
    uint256 public constant TEST_EVENTS_COUNT = 2;
    
    // ============ DEPLOYMENT STATE ============
    
    VeriTixFactory public factory;
    address[] public testEvents;
    
    // ============ MAIN DEPLOYMENT FUNCTION ============
    
    /**
     * @dev Main deployment function
     * @notice Deploys VeriTixFactory and optionally creates test events
     */
    function run() external {
        // Get deployment configuration
        address factoryOwner = getFactoryOwner();
        
        console.log("=== VeriTix Factory Deployment ===");
        console.log("Deployer:", msg.sender);
        console.log("Factory Owner:", factoryOwner);
        console.log("Chain ID:", block.chainid);
        
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Deploy the factory
        deployFactory(factoryOwner);
        
        // Create test events if enabled
        if (CREATE_TEST_EVENTS) {
            createTestEvents();
        }
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        // Log deployment summary
        logDeploymentSummary();
        
        // Verify deployments
        verifyDeployments();
    }
    
    // ============ DEPLOYMENT FUNCTIONS ============
    
    /**
     * @dev Deploy the VeriTixFactory contract
     * @param owner Address that will own the factory
     */
    function deployFactory(address owner) internal {
        console.log("\n--- Deploying VeriTixFactory ---");
        
        // Deploy factory with specified owner
        factory = new VeriTixFactory(owner);
        
        console.log("VeriTixFactory deployed at:", address(factory));
        console.log("Factory owner set to:", factory.owner());
        
        // Verify factory configuration
        require(factory.owner() == owner, "Factory owner not set correctly");
        require(factory.globalMaxResalePercent() == 120, "Default resale percent incorrect");
        require(factory.defaultOrganizerFee() == 5, "Default organizer fee incorrect");
        require(!factory.factoryPaused(), "Factory should not be paused initially");
        
        console.log("Factory configuration verified");
    }
    
    /**
     * @dev Create test events for demonstration and testing
     */
    function createTestEvents() internal {
        console.log("\n--- Creating Test Events ---");
        
        for (uint256 i = 0; i < TEST_EVENTS_COUNT; i++) {
            address eventContract = createTestEvent(i + 1);
            testEvents.push(eventContract);
        }
        
        console.log("Created", TEST_EVENTS_COUNT, "test events");
    }
    
    /**
     * @dev Create a single test event
     * @param eventNumber The event number for naming
     * @return eventContract Address of the created event contract
     */
    function createTestEvent(uint256 eventNumber) internal returns (address eventContract) {
        // Create event parameters
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: string(abi.encodePacked("Test Event ", vm.toString(eventNumber))),
            symbol: string(abi.encodePacked("TEST", vm.toString(eventNumber))),
            maxSupply: 100 + (eventNumber * 50), // Varying supply
            ticketPrice: 0.1 ether + (eventNumber * 0.05 ether), // Varying price
            organizer: msg.sender, // Deployer as organizer
            baseURI: string(abi.encodePacked("https://api.veritix.com/events/test", vm.toString(eventNumber), "/")),
            maxResalePercent: 110 + (eventNumber * 5), // Varying resale caps
            organizerFeePercent: 5 // Standard 5% fee
        });
        
        // Create the event
        eventContract = factory.createEvent(params);
        
        console.log("Test Event", eventNumber, "created at:", eventContract);
        console.log("  Name:", params.name);
        console.log("  Max Supply:", params.maxSupply);
        console.log("  Ticket Price:", params.ticketPrice);
        console.log("  Max Resale %:", params.maxResalePercent);
        
        return eventContract;
    }
    
    // ============ CONFIGURATION HELPERS ============
    
    /**
     * @dev Get factory owner from environment or use default
     * @return owner Address to set as factory owner
     */
    function getFactoryOwner() internal view returns (address owner) {
        // Try to get from environment variable
        try vm.envAddress("FACTORY_OWNER") returns (address envOwner) {
            if (envOwner != address(0)) {
                return envOwner;
            }
        } catch {
            // Environment variable not set or invalid
        }
        
        // Use deployer if no environment variable
        if (msg.sender != address(0)) {
            return msg.sender;
        }
        
        // Fallback to default
        return DEFAULT_FACTORY_OWNER;
    }
    
    // ============ LOGGING AND VERIFICATION ============
    
    /**
     * @dev Log comprehensive deployment summary
     */
    function logDeploymentSummary() internal view {
        console.log("\n=== Deployment Summary ===");
        console.log("VeriTixFactory:", address(factory));
        console.log("Factory Owner:", factory.owner());
        console.log("Global Max Resale %:", factory.globalMaxResalePercent());
        console.log("Default Organizer Fee %:", factory.defaultOrganizerFee());
        console.log("Event Creation Fee:", factory.eventCreationFee());
        console.log("Factory Paused:", factory.factoryPaused());
        
        if (testEvents.length > 0) {
            console.log("\nTest Events Created:");
            for (uint256 i = 0; i < testEvents.length; i++) {
                console.log("  Event", i + 1, ":", testEvents[i]);
            }
        }
        
        console.log("\nTotal Events in Factory:", factory.getTotalEvents());
        console.log("Deployment completed successfully!");
    }
    
    /**
     * @dev Verify all deployments are working correctly
     */
    function verifyDeployments() internal view {
        console.log("\n--- Verifying Deployments ---");
        
        // Verify factory
        require(address(factory) != address(0), "Factory not deployed");
        require(factory.owner() != address(0), "Factory owner not set");
        
        // Verify factory registry
        address[] memory deployedEvents = factory.getDeployedEvents();
        require(deployedEvents.length == testEvents.length, "Event count mismatch");
        
        // Verify each test event
        for (uint256 i = 0; i < testEvents.length; i++) {
            address eventAddr = testEvents[i];
            require(eventAddr != address(0), "Test event not deployed");
            require(factory.isValidEventContract(eventAddr), "Event not registered in factory");
            
            // Verify event contract
            VeriTixEvent eventContract = VeriTixEvent(eventAddr);
            require(eventContract.organizer() == msg.sender, "Event organizer incorrect");
            require(eventContract.maxSupply() > 0, "Event max supply not set");
            require(eventContract.ticketPrice() > 0, "Event ticket price not set");
        }
        
        console.log("All deployments verified successfully");
    }
}