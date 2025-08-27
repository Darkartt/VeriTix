// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./DeployFactory.s.sol";
import "./VerifyDeployment.s.sol";
import "../src/VeriTixFactory.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title Deploy
 * @dev Main deployment script with environment-specific configurations
 * @notice This script handles deployment across different networks with appropriate settings
 */
contract Deploy is Script {
    
    // ============ NETWORK CONFIGURATIONS ============
    
    struct NetworkConfig {
        string name;
        uint256 chainId;
        uint256 globalMaxResalePercent;
        uint256 defaultOrganizerFee;
        uint256 eventCreationFee;
        bool createTestEvents;
        uint256 testEventsCount;
        bool verifyContracts;
    }
    
    mapping(uint256 => NetworkConfig) public networkConfigs;
    
    // ============ DEPLOYMENT STATE ============
    
    NetworkConfig public currentConfig;
    DeployFactory public deployFactory;
    VerifyDeployment public verifyDeployment;
    
    address public deployedFactory;
    address[] public deployedEvents;
    
    // ============ CONSTRUCTOR ============
    
    constructor() {
        setupNetworkConfigs();
    }
    
    // ============ MAIN DEPLOYMENT FUNCTION ============
    
    /**
     * @dev Main deployment function that handles all networks
     */
    function run() external {
        // Get current network configuration
        currentConfig = getNetworkConfig();
        
        console.log("=== VeriTix Deployment ===");
        console.log("Network:", currentConfig.name);
        console.log("Chain ID:", currentConfig.chainId);
        console.log("Deployer:", msg.sender);
        
        // Deploy contracts
        deployContracts();
        
        // Configure factory if needed
        configureFactory();
        
        // Verify deployment if enabled
        if (currentConfig.verifyContracts) {
            verifyDeployment = new VerifyDeployment();
            verifyDeployment.run(deployedFactory);
        }
        
        // Generate deployment report
        generateDeploymentReport();
    }
    
    // ============ DEPLOYMENT FUNCTIONS ============
    
    /**
     * @dev Deploy all contracts
     */
    function deployContracts() internal {
        console.log("\n--- Deploying Contracts ---");
        
        // Deploy factory
        deployFactory = new DeployFactory();
        deployFactory.run();
        
        // Get deployed factory address
        deployedFactory = address(deployFactory.factory());
        
        // Get deployed test events from factory
        address[] memory factoryEvents = deployFactory.factory().getDeployedEvents();
        for (uint256 i = 0; i < factoryEvents.length; i++) {
            deployedEvents.push(factoryEvents[i]);
        }
        
        console.log("Factory deployed at:", deployedFactory);
        console.log("Test events created:", deployedEvents.length);
    }
    
    /**
     * @dev Configure factory with network-specific settings
     */
    function configureFactory() internal {
        if (deployedFactory == address(0)) {
            console.log("No factory to configure");
            return;
        }
        
        console.log("\n--- Configuring Factory ---");
        
        VeriTixFactory factory = VeriTixFactory(deployedFactory);
        
        vm.startBroadcast();
        
        // Set global max resale percent if different from default
        if (currentConfig.globalMaxResalePercent != 120) {
            factory.setGlobalMaxResalePercent(currentConfig.globalMaxResalePercent);
            console.log("Global max resale percent set to:", currentConfig.globalMaxResalePercent);
        }
        
        // Set default organizer fee if different from default
        if (currentConfig.defaultOrganizerFee != 5) {
            factory.setDefaultOrganizerFee(currentConfig.defaultOrganizerFee);
            console.log("Default organizer fee set to:", currentConfig.defaultOrganizerFee);
        }
        
        // Set event creation fee if specified
        if (currentConfig.eventCreationFee > 0) {
            factory.setEventCreationFee(currentConfig.eventCreationFee);
            console.log("Event creation fee set to:", currentConfig.eventCreationFee);
        }
        
        vm.stopBroadcast();
        
        console.log("Factory configuration completed");
    }
    
    // ============ NETWORK CONFIGURATION ============
    
    /**
     * @dev Setup network-specific configurations
     */
    function setupNetworkConfigs() internal {
        // Mainnet configuration
        networkConfigs[1] = NetworkConfig({
            name: "Ethereum Mainnet",
            chainId: 1,
            globalMaxResalePercent: 120,
            defaultOrganizerFee: 5,
            eventCreationFee: 0.01 ether, // Small fee to prevent spam
            createTestEvents: false, // No test events on mainnet
            testEventsCount: 0,
            verifyContracts: true
        });
        
        // Sepolia testnet configuration
        networkConfigs[11155111] = NetworkConfig({
            name: "Sepolia Testnet",
            chainId: 11155111,
            globalMaxResalePercent: 120,
            defaultOrganizerFee: 5,
            eventCreationFee: 0, // Free on testnet
            createTestEvents: true,
            testEventsCount: 3,
            verifyContracts: true
        });
        
        // Polygon mainnet configuration
        networkConfigs[137] = NetworkConfig({
            name: "Polygon Mainnet",
            chainId: 137,
            globalMaxResalePercent: 115, // Slightly lower for Polygon
            defaultOrganizerFee: 3, // Lower fee for Polygon
            eventCreationFee: 1 ether, // 1 MATIC
            createTestEvents: false,
            testEventsCount: 0,
            verifyContracts: true
        });
        
        // Mumbai testnet configuration
        networkConfigs[80001] = NetworkConfig({
            name: "Mumbai Testnet",
            chainId: 80001,
            globalMaxResalePercent: 115,
            defaultOrganizerFee: 3,
            eventCreationFee: 0, // Free on testnet
            createTestEvents: true,
            testEventsCount: 2,
            verifyContracts: true
        });
        
        // Local/Anvil configuration
        networkConfigs[31337] = NetworkConfig({
            name: "Local Network",
            chainId: 31337,
            globalMaxResalePercent: 120,
            defaultOrganizerFee: 5,
            eventCreationFee: 0, // Free for local testing
            createTestEvents: true,
            testEventsCount: 5,
            verifyContracts: false // No verification on local
        });
        
        // Base mainnet configuration
        networkConfigs[8453] = NetworkConfig({
            name: "Base Mainnet",
            chainId: 8453,
            globalMaxResalePercent: 120,
            defaultOrganizerFee: 4,
            eventCreationFee: 0.001 ether,
            createTestEvents: false,
            testEventsCount: 0,
            verifyContracts: true
        });
        
        // Arbitrum One configuration
        networkConfigs[42161] = NetworkConfig({
            name: "Arbitrum One",
            chainId: 42161,
            globalMaxResalePercent: 120,
            defaultOrganizerFee: 4,
            eventCreationFee: 0.001 ether,
            createTestEvents: false,
            testEventsCount: 0,
            verifyContracts: true
        });
    }
    
    /**
     * @dev Get configuration for current network
     * @return config Network configuration
     */
    function getNetworkConfig() internal view returns (NetworkConfig memory config) {
        uint256 chainId = block.chainid;
        
        // Check if we have a specific configuration for this chain
        if (networkConfigs[chainId].chainId != 0) {
            return networkConfigs[chainId];
        }
        
        // Default configuration for unknown networks
        console.log("Warning: Unknown network, using default configuration");
        return NetworkConfig({
            name: string(abi.encodePacked("Unknown Network (", vm.toString(chainId), ")")),
            chainId: chainId,
            globalMaxResalePercent: 120,
            defaultOrganizerFee: 5,
            eventCreationFee: 0,
            createTestEvents: true,
            testEventsCount: 2,
            verifyContracts: false
        });
    }
    
    // ============ REPORTING ============
    
    /**
     * @dev Generate comprehensive deployment report
     */
    function generateDeploymentReport() internal view {
        console.log("\n=== Deployment Report ===");
        
        console.log("Network Information:");
        console.log("  Name:", currentConfig.name);
        console.log("  Chain ID:", currentConfig.chainId);
        console.log("  Block Number:", block.number);
        console.log("  Timestamp:", block.timestamp);
        
        console.log("\nDeployed Contracts:");
        console.log("  VeriTixFactory:", deployedFactory);
        
        if (deployedEvents.length > 0) {
            console.log("  Test Events:");
            for (uint256 i = 0; i < deployedEvents.length; i++) {
                console.log("    Event", i + 1, ":", deployedEvents[i]);
            }
        }
        
        console.log("\nFactory Configuration:");
        if (deployedFactory != address(0)) {
            VeriTixFactory factory = VeriTixFactory(deployedFactory);
            console.log("  Owner:", factory.owner());
            console.log("  Global Max Resale %:", factory.globalMaxResalePercent());
            console.log("  Default Organizer Fee %:", factory.defaultOrganizerFee());
            console.log("  Event Creation Fee:", factory.eventCreationFee());
            console.log("  Factory Paused:", factory.factoryPaused());
            console.log("  Total Events:", factory.getTotalEvents());
        }
        
        console.log("\nDeployment Summary:");
        console.log("  Deployer:", msg.sender);
        console.log("  Gas Used: [Check transaction receipts]");
        console.log("  Verification:", currentConfig.verifyContracts ? "Enabled" : "Disabled");
        
        console.log("\nNext Steps:");
        if (currentConfig.verifyContracts) {
            console.log("  1. Verify contracts on block explorer");
        }
        console.log("  2. Update frontend configuration with new addresses");
        console.log("  3. Test event creation and ticket operations");
        console.log("  4. Set up monitoring and alerts");
        
        console.log("\n[SUCCESS] Deployment completed successfully!");
    }
    
    // ============ UTILITY FUNCTIONS ============
    
    /**
     * @dev Deploy to specific network with custom configuration
     * @param chainId Target chain ID
     * @param customConfig Custom configuration to use
     */
    function deployToNetwork(uint256 chainId, NetworkConfig memory customConfig) external {
        require(block.chainid == chainId, "Chain ID mismatch");
        
        currentConfig = customConfig;
        
        console.log("=== Custom Network Deployment ===");
        console.log("Target Chain ID:", chainId);
        console.log("Custom Configuration Applied");
        
        deployContracts();
        configureFactory();
        
        if (currentConfig.verifyContracts) {
            verifyDeployment = new VerifyDeployment();
            verifyDeployment.run(deployedFactory);
        }
        
        generateDeploymentReport();
    }
    
    /**
     * @dev Get deployment addresses for external use
     * @return factory Address of deployed factory
     * @return events Array of deployed event addresses
     */
    function getDeploymentAddresses() external view returns (address factory, address[] memory events) {
        return (deployedFactory, deployedEvents);
    }
    
    /**
     * @dev Check if network is supported
     * @param chainId Chain ID to check
     * @return supported Whether the network has a configuration
     */
    function isNetworkSupported(uint256 chainId) external view returns (bool supported) {
        return networkConfigs[chainId].chainId != 0;
    }
    
    /**
     * @dev Get network configuration for a specific chain
     * @param chainId Chain ID to get configuration for
     * @return config Network configuration
     */
    function getNetworkConfigForChain(uint256 chainId) external view returns (NetworkConfig memory config) {
        return networkConfigs[chainId];
    }
}