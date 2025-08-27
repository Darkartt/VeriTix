// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VeriTix.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title MigrationUtils
 * @dev Utilities for migrating from monolithic VeriTix to factory architecture
 * @notice This script provides tools to transition existing events to the new system
 */
contract MigrationUtils is Script {
    
    // ============ MIGRATION CONFIGURATION ============
    
    /// @dev Address of the old monolithic VeriTix contract
    address public oldVeriTixContract;
    
    /// @dev Address of the new VeriTixFactory contract
    address public newFactoryContract;
    
    /// @dev Maximum number of events to migrate in a single transaction
    uint256 public constant MAX_MIGRATION_BATCH = 10;
    
    // ============ MIGRATION STATE ============
    
    VeriTix public oldContract;
    VeriTixFactory public newFactory;
    
    struct MigrationEvent {
        string name;
        string symbol;
        uint256 maxSupply;
        uint256 ticketPrice;
        address organizer;
        string baseURI;
        uint256 maxResalePercent;
        uint256 organizerFeePercent;
        bool migrated;
    }
    
    mapping(uint256 => MigrationEvent) public migrationEvents;
    uint256 public totalMigrationEvents;
    
    // ============ MAIN MIGRATION FUNCTIONS ============
    
    /**
     * @dev Initialize migration with contract addresses
     * @param _oldContract Address of the old VeriTix contract
     * @param _newFactory Address of the new VeriTixFactory contract
     */
    function initializeMigration(address _oldContract, address _newFactory) external {
        require(_oldContract != address(0), "Invalid old contract address");
        require(_newFactory != address(0), "Invalid new factory address");
        
        oldVeriTixContract = _oldContract;
        newFactoryContract = _newFactory;
        
        oldContract = VeriTix(_oldContract);
        newFactory = VeriTixFactory(_newFactory);
        
        console.log("=== Migration Initialization ===");
        console.log("Old VeriTix Contract:", _oldContract);
        console.log("New Factory Contract:", _newFactory);
        console.log("Migration initialized successfully");
    }
    
    /**
     * @dev Analyze the old contract to prepare migration data
     * @notice This function scans the old contract and prepares migration parameters
     */
    function analyzeMigration() external view {
        require(oldVeriTixContract != address(0), "Migration not initialized");
        
        console.log("\n=== Migration Analysis ===");
        
        // Note: This is a simplified analysis since the old VeriTix contract
        // structure isn't fully defined. In a real migration, you would:
        // 1. Read event data from the old contract
        // 2. Extract organizer information
        // 3. Calculate ticket sales and pricing
        // 4. Prepare migration parameters
        
        console.log("Old contract analysis:");
        console.log("  Contract address:", oldVeriTixContract);
        console.log("  Contract code size:", oldVeriTixContract.code.length);
        
        // Check if old contract is still active
        try oldContract.owner() returns (address owner) {
            console.log("  Contract owner:", owner);
            console.log("  Contract appears to be active");
        } catch {
            console.log("  Contract may be inactive or incompatible");
        }
        
        console.log("\nMigration analysis completed");
        console.log("Manual review required for event-specific parameters");
    }
    
    /**
     * @dev Create migration events based on old contract data
     * @param eventParams Array of event parameters for migration
     */
    function prepareMigrationEvents(VeriTixTypes.EventCreationParams[] calldata eventParams) external {
        require(newFactoryContract != address(0), "Migration not initialized");
        require(eventParams.length > 0, "No events to migrate");
        require(eventParams.length <= MAX_MIGRATION_BATCH, "Too many events in batch");
        
        console.log("\n=== Preparing Migration Events ===");
        console.log("Events to migrate:", eventParams.length);
        
        for (uint256 i = 0; i < eventParams.length; i++) {
            VeriTixTypes.EventCreationParams memory params = eventParams[i];
            
            // Validate migration parameters
            require(bytes(params.name).length > 0, "Event name required");
            require(bytes(params.symbol).length > 0, "Event symbol required");
            require(params.maxSupply > 0, "Max supply must be positive");
            require(params.ticketPrice > 0, "Ticket price must be positive");
            require(params.organizer != address(0), "Organizer address required");
            
            // Store migration event data
            migrationEvents[totalMigrationEvents] = MigrationEvent({
                name: params.name,
                symbol: params.symbol,
                maxSupply: params.maxSupply,
                ticketPrice: params.ticketPrice,
                organizer: params.organizer,
                baseURI: params.baseURI,
                maxResalePercent: params.maxResalePercent,
                organizerFeePercent: params.organizerFeePercent,
                migrated: false
            });
            
            console.log("Prepared event", totalMigrationEvents, ":", params.name);
            totalMigrationEvents++;
        }
        
        console.log("Migration events prepared successfully");
    }
    
    /**
     * @dev Execute the migration by creating new event contracts
     * @notice This function creates new event contracts in the factory
     */
    function executeMigration() external {
        require(newFactoryContract != address(0), "Migration not initialized");
        require(totalMigrationEvents > 0, "No events prepared for migration");
        
        console.log("\n=== Executing Migration ===");
        
        vm.startBroadcast();
        
        uint256 successfulMigrations = 0;
        
        for (uint256 i = 0; i < totalMigrationEvents; i++) {
            MigrationEvent storage migEvent = migrationEvents[i];
            
            if (migEvent.migrated) {
                console.log("Event", i, "already migrated, skipping");
                continue;
            }
            
            try this.migrateEvent(i) {
                migEvent.migrated = true;
                successfulMigrations++;
                console.log("Successfully migrated event", i, ":", migEvent.name);
            } catch Error(string memory reason) {
                console.log("Failed to migrate event", i, ":", reason);
            } catch {
                console.log("Failed to migrate event", i, ": Unknown error");
            }
        }
        
        vm.stopBroadcast();
        
        console.log("\nMigration completed:");
        console.log("  Successful migrations:", successfulMigrations);
        console.log("  Failed migrations:", totalMigrationEvents - successfulMigrations);
    }
    
    /**
     * @dev Migrate a single event
     * @param eventIndex Index of the event to migrate
     */
    function migrateEvent(uint256 eventIndex) external {
        require(eventIndex < totalMigrationEvents, "Invalid event index");
        
        MigrationEvent memory migEvent = migrationEvents[eventIndex];
        require(!migEvent.migrated, "Event already migrated");
        
        // Create event parameters
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: migEvent.name,
            symbol: migEvent.symbol,
            maxSupply: migEvent.maxSupply,
            ticketPrice: migEvent.ticketPrice,
            organizer: migEvent.organizer,
            baseURI: migEvent.baseURI,
            maxResalePercent: migEvent.maxResalePercent,
            organizerFeePercent: migEvent.organizerFeePercent
        });
        
        // Create the event in the new factory
        address newEventContract = newFactory.createEvent(params);
        
        console.log("Migrated event to:", newEventContract);
    }
    
    // ============ MIGRATION VERIFICATION ============
    
    /**
     * @dev Verify migration results
     * @notice Checks that all events were migrated correctly
     */
    function verifyMigration() external view {
        require(newFactoryContract != address(0), "Migration not initialized");
        
        console.log("\n=== Migration Verification ===");
        
        uint256 migratedCount = 0;
        uint256 factoryEventCount = newFactory.getTotalEvents();
        
        for (uint256 i = 0; i < totalMigrationEvents; i++) {
            if (migrationEvents[i].migrated) {
                migratedCount++;
            }
        }
        
        console.log("Events prepared for migration:", totalMigrationEvents);
        console.log("Events successfully migrated:", migratedCount);
        console.log("Events in factory:", factoryEventCount);
        
        // Verify factory events
        address[] memory factoryEvents = newFactory.getDeployedEvents();
        console.log("Factory events:");
        for (uint256 i = 0; i < factoryEvents.length; i++) {
            console.log("  Event", i, ":", factoryEvents[i]);
            
            // Verify event contract
            VeriTixEvent eventContract = VeriTixEvent(factoryEvents[i]);
            (string memory name, , , , , ) = eventContract.getEventInfo();
            console.log("    Name:", name);
        }
        
        if (migratedCount == totalMigrationEvents) {
            console.log("Migration verification: SUCCESS");
        } else {
            console.log("Migration verification: INCOMPLETE");
        }
    }
    
    // ============ MIGRATION UTILITIES ============
    
    /**
     * @dev Generate migration report
     * @notice Creates a comprehensive report of the migration process
     */
    function generateMigrationReport() external view {
        console.log("\n=== Migration Report ===");
        console.log("Migration Configuration:");
        console.log("  Old Contract:", oldVeriTixContract);
        console.log("  New Factory:", newFactoryContract);
        console.log("  Total Events Prepared:", totalMigrationEvents);
        
        uint256 migratedCount = 0;
        console.log("\nEvent Migration Status:");
        
        for (uint256 i = 0; i < totalMigrationEvents; i++) {
            MigrationEvent memory migEvent = migrationEvents[i];
            string memory status = migEvent.migrated ? "MIGRATED" : "PENDING";
            
            console.log("  Event", i, ":", migEvent.name);
            console.log("    Status:", status);
            console.log("    Organizer:", migEvent.organizer);
            console.log("    Max Supply:", migEvent.maxSupply);
            console.log("    Ticket Price:", migEvent.ticketPrice);
            
            if (migEvent.migrated) {
                migratedCount++;
            }
        }
        
        console.log("\nMigration Summary:");
        console.log("  Migration Progress:", migratedCount, "/", totalMigrationEvents);
        
        if (migratedCount == totalMigrationEvents) {
            console.log("  Status: COMPLETE");
        } else if (migratedCount > 0) {
            console.log("  Status: IN PROGRESS");
        } else {
            console.log("  Status: NOT STARTED");
        }
    }
    
    /**
     * @dev Reset migration state (for testing)
     * @notice Clears all migration data - use with caution
     */
    function resetMigration() external {
        console.log("Resetting migration state...");
        
        for (uint256 i = 0; i < totalMigrationEvents; i++) {
            delete migrationEvents[i];
        }
        
        totalMigrationEvents = 0;
        oldVeriTixContract = address(0);
        newFactoryContract = address(0);
        
        console.log("Migration state reset");
    }
}