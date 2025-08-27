// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/VeriTixFactory.sol";
import "../../src/VeriTixEvent.sol";
import "../../src/libraries/VeriTixTypes.sol";

/**
 * @title SimpleDeployment
 * @dev Simple deployment script for quick testing and development
 * @notice This script provides a minimal deployment for development purposes
 */
contract SimpleDeployment is Script {
    
    function run() external {
        console.log("=== Simple VeriTix Deployment ===");
        console.log("Deployer:", msg.sender);
        
        vm.startBroadcast();
        
        // Deploy factory
        VeriTixFactory factory = new VeriTixFactory(msg.sender);
        console.log("Factory deployed at:", address(factory));
        
        // Create a simple test event
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Test Concert",
            symbol: "CONCERT",
            maxSupply: 100,
            ticketPrice: 0.1 ether,
            organizer: msg.sender,
            baseURI: "https://api.veritix.com/test/",
            maxResalePercent: 110,
            organizerFeePercent: 5
        });
        
        address eventContract = factory.createEvent(params);
        console.log("Test event created at:", eventContract);
        
        vm.stopBroadcast();
        
        console.log("Simple deployment completed!");
    }
}