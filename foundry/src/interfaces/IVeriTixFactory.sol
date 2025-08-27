// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/VeriTixTypes.sol";

/**
 * @title IVeriTixFactory
 * @dev Interface for the VeriTix factory contract that deploys individual event contracts
 * @notice This factory creates and manages individual VeriTixEvent contracts, providing
 * centralized governance while maintaining event isolation
 */
interface IVeriTixFactory {
    
    // ============ EVENTS ============
    
    /**
     * @dev Emitted when a new event contract is deployed
     * @param eventContract Address of the newly deployed event contract
     * @param organizer Address of the event organizer
     * @param eventName Name of the event
     * @param ticketPrice Face value price of tickets
     * @param maxSupply Maximum number of tickets available
     */
    event EventCreated(
        address indexed eventContract,
        address indexed organizer,
        string eventName,
        uint256 ticketPrice,
        uint256 maxSupply
    );
    
    /**
     * @dev Emitted when global factory settings are updated
     * @param setting The setting that was changed
     * @param oldValue The previous value
     * @param newValue The new value
     */
    event FactorySettingUpdated(string setting, uint256 oldValue, uint256 newValue);
    
    /**
     * @dev Emitted when the factory is paused or unpaused
     * @param isPaused True if factory is now paused
     */
    event FactoryPauseToggled(bool isPaused);
    
    // ============ ERRORS ============
    
    /// @dev Thrown when event creation parameters are invalid
    error InvalidEventParameters();
    
    /// @dev Thrown when resale percentage exceeds global limits
    error ExceedsGlobalResaleLimit(uint256 requested, uint256 maximum);
    
    /// @dev Thrown when caller lacks required permissions
    error UnauthorizedAccess();
    
    /// @dev Thrown when event deployment fails
    error EventDeploymentFailed();
    
    /// @dev Thrown when factory operations are paused
    error FactoryPaused();
    
    /// @dev Thrown when organizer has reached maximum event limit
    error OrganizerEventLimitReached();
    
    /// @dev Thrown when insufficient fee is provided for event creation
    error InsufficientCreationFee(uint256 sent, uint256 required);
    
    /// @dev Thrown when event name is empty or too long
    error InvalidEventName();
    
    /// @dev Thrown when event symbol is empty or too long
    error InvalidEventSymbol();
    
    /// @dev Thrown when max supply is zero or exceeds limits
    error InvalidMaxSupply(uint256 provided, uint256 maximum);
    
    /// @dev Thrown when ticket price is below minimum
    error TicketPriceTooLow(uint256 provided, uint256 minimum);
    
    /// @dev Thrown when organizer address is zero
    error InvalidOrganizerAddress();
    
    /// @dev Thrown when base URI is empty
    error InvalidBaseURI();
    
    /// @dev Thrown when resale percentage is below 100%
    error ResalePercentTooLow(uint256 provided);
    
    /// @dev Thrown when organizer fee exceeds maximum
    error OrganizerFeeTooHigh(uint256 provided, uint256 maximum);
    
    /// @dev Thrown when trying to set global resale percent below 100%
    error GlobalResalePercentTooLow(uint256 provided);
    
    /// @dev Thrown when trying to set global resale percent above maximum
    error GlobalResalePercentTooHigh(uint256 provided, uint256 maximum);
    
    /// @dev Thrown when trying to transfer ownership to zero address
    error InvalidNewOwner();
    
    /// @dev Thrown when batch operation array is empty
    error EmptyBatchArray();
    
    /// @dev Thrown when batch operation exceeds maximum size
    error BatchSizeTooLarge(uint256 provided, uint256 maximum);
    
    /// @dev Thrown when pagination offset exceeds total count
    error InvalidPaginationOffset(uint256 offset, uint256 totalCount);
    
    /// @dev Thrown when pagination limit is zero or too large
    error InvalidPaginationLimit(uint256 limit, uint256 maximum);
    
    /// @dev Thrown when querying non-existent event
    error EventNotFound(address eventContract);
    
    /// @dev Thrown when fee withdrawal fails
    error FeeWithdrawalFailed();
    
    /// @dev Thrown when no fees available to withdraw
    error NoFeesToWithdraw();
    
    /// @dev Thrown when invalid recipient address for fee withdrawal
    error InvalidFeeRecipient();
    
    // ============ EVENT CREATION ============
    
    /**
     * @dev Create a new event contract
     * @param params Event creation parameters
     * @return eventContract Address of the newly deployed event contract
     * 
     * Requirements:
     * - Factory must not be paused
     * - Caller must pay event creation fee (if any)
     * - Parameters must be valid
     * - Organizer must not exceed event limit
     * - Resale percentage must not exceed global limit
     */
    function createEvent(VeriTixTypes.EventCreationParams calldata params) 
        external 
        payable 
        returns (address eventContract);
    
    /**
     * @dev Create multiple events in a single transaction
     * @param paramsArray Array of event creation parameters
     * @return eventContracts Array of newly deployed event contract addresses
     */
    function batchCreateEvents(VeriTixTypes.EventCreationParams[] calldata paramsArray)
        external
        payable
        returns (address[] memory eventContracts);
    
    // ============ EVENT DISCOVERY ============
    
    /**
     * @dev Get all deployed event contract addresses
     * @return events Array of all event contract addresses
     */
    function getDeployedEvents() external view returns (address[] memory events);
    
    /**
     * @dev Get events created by a specific organizer
     * @param organizer The organizer address to query
     * @return events Array of event contract addresses created by the organizer
     */
    function getEventsByOrganizer(address organizer) 
        external 
        view 
        returns (address[] memory events);
    
    /**
     * @dev Get detailed registry information for an event
     * @param eventContract Address of the event contract
     * @return registry Complete registry information for the event
     */
    function getEventRegistry(address eventContract) 
        external 
        view 
        returns (VeriTixTypes.EventRegistry memory registry);
    
    /**
     * @dev Get paginated list of events with details
     * @param offset Starting index for pagination
     * @param limit Maximum number of events to return
     * @return events Array of event registry entries
     * @return totalCount Total number of events in the factory
     */
    function getEventsPaginated(uint256 offset, uint256 limit)
        external
        view
        returns (VeriTixTypes.EventRegistry[] memory events, uint256 totalCount);
    
    // ============ FACTORY MANAGEMENT ============
    
    /**
     * @dev Update global maximum resale percentage (owner only)
     * @param newMaxPercent New maximum resale percentage
     * 
     * Requirements:
     * - Caller must be factory owner
     * - New percentage must be reasonable (>= 100%, <= MAX_RESALE_PERCENTAGE)
     */
    function setGlobalMaxResalePercent(uint256 newMaxPercent) external;
    
    /**
     * @dev Update default organizer fee percentage (owner only)
     * @param newFeePercent New default organizer fee percentage
     */
    function setDefaultOrganizerFee(uint256 newFeePercent) external;
    
    /**
     * @dev Update event creation fee (owner only)
     * @param newFee New fee required to create events
     */
    function setEventCreationFee(uint256 newFee) external;
    
    /**
     * @dev Pause or unpause factory operations (owner only)
     * @param paused True to pause, false to unpause
     */
    function setPaused(bool paused) external;
    
    /**
     * @dev Transfer factory ownership (owner only)
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external;
    
    // ============ FACTORY INFORMATION ============
    
    /**
     * @dev Get current factory configuration
     * @return config Complete factory configuration
     */
    function getFactoryConfig() external view returns (VeriTixTypes.FactoryConfig memory config);
    
    /**
     * @dev Get total number of events created
     * @return count Total event count
     */
    function getTotalEvents() external view returns (uint256 count);
    
    /**
     * @dev Get number of events created by a specific organizer
     * @param organizer The organizer address to query
     * @return count Number of events created by the organizer
     */
    function getOrganizerEventCount(address organizer) external view returns (uint256 count);
    
    /**
     * @dev Check if an address is a valid event contract deployed by this factory
     * @param eventContract Address to check
     * @return isValid True if the address is a valid event contract from this factory
     */
    function isValidEventContract(address eventContract) external view returns (bool isValid);
    
    // ============ ANALYTICS ============
    
    /**
     * @dev Get aggregated statistics across all events
     * @return totalTicketsSold Total tickets sold across all events
     * @return totalRevenue Total revenue generated across all events
     * @return totalEvents Total number of events created
     * @return activeEvents Number of currently active events
     */
    function getGlobalStats() external view returns (
        uint256 totalTicketsSold,
        uint256 totalRevenue,
        uint256 totalEvents,
        uint256 activeEvents
    );
    
    /**
     * @dev Get events filtered by status
     * @param status The event status to filter by
     * @return events Array of event addresses with the specified status
     */
    function getEventsByStatus(VeriTixTypes.EventStatus status) 
        external 
        view 
        returns (address[] memory events);
}