// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title VeriTixTypes
 * @dev Shared data structures and enums for the VeriTix factory architecture
 * @notice This library contains all common types used across VeriTix contracts
 */
library VeriTixTypes {
    
    // ============ ENUMS ============
    
    /**
     * @dev Represents the current state of a ticket in its lifecycle
     */
    enum TicketState {
        Available,    // Ticket can be purchased (not yet minted)
        Sold,         // Ticket is owned by someone, can be resold/refunded
        CheckedIn,    // Ticket has been used at venue, cannot be resold/refunded
        Refunded      // Ticket has been refunded and burned
    }
    
    /**
     * @dev Represents the current status of an event
     */
    enum EventStatus {
        Active,       // Event is active, tickets can be sold
        SoldOut,      // All tickets have been sold
        Cancelled,    // Event has been cancelled by organizer
        Completed     // Event has taken place (optional status for future use)
    }
    
    // ============ STRUCTS ============
    
    /**
     * @dev Parameters required to create a new event
     * @notice Used by the factory when deploying new event contracts
     */
    struct EventCreationParams {
        string name;                    // Event name (e.g., "Concert 2024")
        string symbol;                  // Event symbol/ticker (e.g., "CONC24")
        uint256 maxSupply;             // Maximum number of tickets available
        uint256 ticketPrice;           // Face value price per ticket in wei
        string baseURI;                // Base URI for token metadata
        uint256 maxResalePercent;      // Maximum resale percentage (e.g., 110 = 110%)
        uint256 organizerFeePercent;   // Organizer fee on resales (e.g., 5 = 5%)
        address organizer;             // Address of the event organizer
    }
    
    /**
     * @dev Registry entry for tracking deployed events in the factory
     */
    struct EventRegistry {
        address eventContract;         // Address of the deployed event contract
        address organizer;            // Address of the event organizer
        uint256 createdAt;           // Timestamp when event was created
        string eventName;            // Name of the event for easy lookup
        EventStatus status;          // Current status of the event
        uint256 ticketPrice;        // Face value ticket price
        uint256 maxSupply;          // Maximum number of tickets
    }
    
    /**
     * @dev Comprehensive ticket information
     * @notice Contains all relevant data about a specific ticket
     */
    struct TicketInfo {
        uint256 tokenId;             // The NFT token ID
        address currentOwner;        // Current owner of the ticket
        uint256 originalPrice;       // Original face value price paid
        uint256 lastPricePaid;      // Most recent price paid (including resales)
        TicketState state;          // Current state of the ticket
        bool isCheckedIn;           // Whether ticket has been used at venue
        uint256 mintedAt;           // Timestamp when ticket was minted
    }
    
    /**
     * @dev Anti-scalping configuration for an event
     */
    struct AntiScalpingConfig {
        uint256 maxResalePercent;      // Maximum resale percentage of face value
        uint256 organizerFeePercent;   // Percentage fee organizer gets on resales
        bool transfersDisabled;        // Whether direct transfers are blocked
        uint256 globalMaxResalePercent; // Platform-wide maximum resale limit
    }
    
    /**
     * @dev Factory configuration and global settings
     */
    struct FactoryConfig {
        address platformOwner;         // Owner of the factory contract
        uint256 globalMaxResalePercent; // Platform-wide maximum resale percentage
        uint256 defaultOrganizerFee;   // Default organizer fee for new events
        bool factoryPaused;           // Emergency pause for factory operations
        uint256 eventCreationFee;    // Fee required to create new events
    }
    
    /**
     * @dev Event statistics for analytics and reporting
     */
    struct EventStats {
        uint256 totalTicketsSold;     // Number of tickets sold
        uint256 totalRevenue;         // Total revenue generated (primary + resale fees)
        uint256 totalResales;         // Number of resale transactions
        uint256 totalRefunds;         // Number of refunds processed
        uint256 totalCheckedIn;       // Number of tickets checked in at venue
        uint256 averageResalePrice;   // Average resale price
    }
    
    /**
     * @dev Resale transaction details
     */
    struct ResaleTransaction {
        uint256 tokenId;              // The ticket being resold
        address seller;               // Address selling the ticket
        address buyer;                // Address buying the ticket
        uint256 price;                // Resale price
        uint256 organizerFee;         // Fee paid to organizer
        uint256 timestamp;            // When the resale occurred
    }
    
    /**
     * @dev Comprehensive metadata for individual tickets (marketplace integration)
     */
    struct TicketMetadata {
        uint256 tokenId;              // The NFT token ID
        string eventName;             // Name of the event
        string eventSymbol;           // Symbol/ticker of the event
        address organizer;            // Event organizer address
        uint256 ticketPrice;          // Original face value price
        uint256 lastPricePaid;        // Most recent price paid
        uint256 maxResalePrice;       // Maximum allowed resale price
        address owner;                // Current owner of the ticket
        bool checkedIn;               // Whether ticket has been used
        bool cancelled;               // Whether event is cancelled
        string tokenURI;              // Complete metadata URI
    }
    
    /**
     * @dev Collection-level metadata for marketplace integration
     */
    struct CollectionMetadata {
        string name;                  // Collection name (event name)
        string symbol;                // Collection symbol
        string description;           // Collection description
        address organizer;            // Event organizer
        uint256 totalSupply;          // Current number of minted tickets
        uint256 maxSupply;            // Maximum tickets available
        uint256 ticketPrice;          // Face value ticket price
        uint256 maxResalePercent;     // Maximum resale percentage
        uint256 organizerFeePercent;  // Organizer fee on resales
        bool cancelled;               // Whether event is cancelled
        string baseURI;               // Base URI for metadata
        address contractAddress;      // Address of the event contract
    }
    
    // ============ CONSTANTS ============
    
    /// @dev Maximum allowed resale percentage (300% = 3x face value)
    uint256 public constant MAX_RESALE_PERCENTAGE = 300;
    
    /// @dev Maximum organizer fee percentage (50% of resale transaction)
    uint256 public constant MAX_ORGANIZER_FEE_PERCENT = 50;
    
    /// @dev Minimum ticket price (0.001 ETH to prevent spam)
    uint256 public constant MIN_TICKET_PRICE = 0.001 ether;
    
    /// @dev Maximum tickets per event (to prevent gas issues)
    uint256 public constant MAX_TICKETS_PER_EVENT = 100000;
    
    /// @dev Maximum events per organizer (to prevent spam)
    uint256 public constant MAX_EVENTS_PER_ORGANIZER = 1000;
    
    // ============ HELPER FUNCTIONS ============
    
    /**
     * @dev Calculate the maximum allowed resale price for a ticket
     * @param originalPrice The original face value price
     * @param maxResalePercent The maximum resale percentage (e.g., 110 = 110%)
     * @return maxPrice The maximum allowed resale price
     */
    function calculateMaxResalePrice(
        uint256 originalPrice, 
        uint256 maxResalePercent
    ) internal pure returns (uint256 maxPrice) {
        return (originalPrice * maxResalePercent) / 100;
    }
    
    /**
     * @dev Calculate organizer fee for a resale transaction
     * @param resalePrice The price of the resale
     * @param organizerFeePercent The organizer fee percentage
     * @return fee The fee amount to be paid to the organizer
     */
    function calculateOrganizerFee(
        uint256 resalePrice, 
        uint256 organizerFeePercent
    ) internal pure returns (uint256 fee) {
        return (resalePrice * organizerFeePercent) / 100;
    }
    
    /**
     * @dev Validate event creation parameters
     * @param params The event creation parameters to validate
     * @return isValid True if all parameters are valid
     */
    function validateEventParams(EventCreationParams memory params) 
        internal 
        pure 
        returns (bool isValid) 
    {
        return (
            bytes(params.name).length > 0 &&
            bytes(params.symbol).length > 0 &&
            params.maxSupply > 0 &&
            params.maxSupply <= MAX_TICKETS_PER_EVENT &&
            params.ticketPrice >= MIN_TICKET_PRICE &&
            params.maxResalePercent >= 100 && // Must be at least 100% (face value)
            params.maxResalePercent <= MAX_RESALE_PERCENTAGE &&
            params.organizerFeePercent <= MAX_ORGANIZER_FEE_PERCENT &&
            params.organizer != address(0)
        );
    }
    
    /**
     * @dev Check if a ticket state allows resale
     * @param state The current ticket state
     * @return canResale True if the ticket can be resold
     */
    function canResaleTicket(TicketState state) internal pure returns (bool canResale) {
        return state == TicketState.Sold;
    }
    
    /**
     * @dev Check if a ticket state allows refund
     * @param state The current ticket state
     * @return canRefund True if the ticket can be refunded
     */
    function canRefundTicket(TicketState state) internal pure returns (bool canRefund) {
        return state == TicketState.Sold;
    }
}