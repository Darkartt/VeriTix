// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VeriTix.sol";

/**
 * @title DeployVeriTix
 * @dev Deployment script for the VeriTix contract
 */
contract DeployVeriTix is Script {
    function run() external {
        // Start broadcasting transactions (uses the private key from --private-key flag)
        vm.startBroadcast();

        // Deploy the VeriTix contract with the deployer as the initial owner
        VeriTix veriTix = new VeriTix(msg.sender);

        // Log the deployment
        console.log("VeriTix deployed at:", address(veriTix));
        console.log("Deployed by:", msg.sender);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
