// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./VeriTixEvent.sol";
import "./interfaces/IVeriTixFactory.sol";
import "./libraries/VeriTixTypes.sol";

/**
 * @title VeriTixFactory
 * @dev Factory contract that deploys and manages individual VeriTixEvent contracts
 * @notice This factory creates isolated event contracts with global policy enforcement
 */
contract VeriTixFactory is IVeriTixFactory, Ownable, ReentrancyGuard {
    
    // ============ STATE VARIABLES ============
    
    /// @dev Array of all deployed event contract addresses
    address[] public deployedEvents;
    
    /// @dev Mapping from organizer address to their event contracts
    mapping(address => address[]) public organizerEvents;
    
    /// @dev Mapping from event contract address to registry information
    mapping(address => VeriTixTypes.EventRegistry) public eventRegistry;
    
    /// @dev Global maximum resale percentage enforced across all events
    uint256 public globalMaxResalePercent = 120; // 120% by default
    
    /// @dev Default organizer fee percentage for new events
    uint256 public defaultOrganizerFee = 5; // 5% by default
    
    /// @dev Fee required to create new events (in wei)
    uint256 public eventCreationFee = 0;
    
    /// @dev Whether factory operations are paused
    bool public factoryPaused = false;
    
    /// @dev Maximum number of events per organizer
    uint256 public maxEventsPerOrganizer = VeriTixTypes.MAX_EVENTS_PER_ORGANIZER;
    
    // ============ CONSTRUCTOR ============
    
    /**
     * @dev Initialize the factory with default settings
     * @param initialOwner Address that will own the factory contract
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        // Factory is ready to deploy events
    }
    
    // ============ MODIFIERS ============
    
    /**
     * @dev Ensures factory is not paused
     */
    modifier whenNotPaused() {
        if (factoryPaused) revert FactoryPaused();
        _;
    }
    
    /**
     * @dev Validates event creation parameters with comprehensive checks
     */
    modifier validEventParams(VeriTixTypes.EventCreationParams calldata params) {
        // Check event name
        if (bytes(params.name).length == 0) {
            revert InvalidEventName();
        }
        if (bytes(params.name).length > 100) { // Reasonable limit
            revert InvalidEventName();
        }
        
        // Check event symbol
        if (bytes(params.symbol).length == 0) {
            revert InvalidEventSymbol();
        }
        if (bytes(params.symbol).length > 20) { // Reasonable limit
            revert InvalidEventSymbol();
        }
        
        // Check max supply
        if (params.maxSupply == 0) {
            revert InvalidMaxSupply(params.maxSupply, VeriTixTypes.MAX_TICKETS_PER_EVENT);
        }
        if (params.maxSupply > VeriTixTypes.MAX_TICKETS_PER_EVENT) {
            revert InvalidMaxSupply(params.maxSupply, VeriTixTypes.MAX_TICKETS_PER_EVENT);
        }
        
        // Check ticket price
        if (params.ticketPrice < VeriTixTypes.MIN_TICKET_PRICE) {
            revert TicketPriceTooLow(params.ticketPrice, VeriTixTypes.MIN_TICKET_PRICE);
        }
        
        // Check organizer address
        if (params.organizer == address(0)) {
            revert InvalidOrganizerAddress();
        }
        
        // Check base URI
        if (bytes(params.baseURI).length == 0) {
            revert InvalidBaseURI();
        }
        
        // Check resale percentage
        if (params.maxResalePercent < 100) {
            revert ResalePercentTooLow(params.maxResalePercent);
        }
        if (params.maxResalePercent > globalMaxResalePercent) {
            revert ExceedsGlobalResaleLimit(params.maxResalePercent, globalMaxResalePercent);
        }
        
        // Check organizer fee
        if (params.organizerFeePercent > VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT) {
            revert OrganizerFeeTooHigh(params.organizerFeePercent, VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT);
        }
        
        _;
    }
    
    /**
     * @dev Ensures organizer hasn't exceeded event limit
     */
    modifier withinOrganizerLimit(address organizer) {
        if (organizerEvents[organizer].length >= maxEventsPerOrganizer) {
            revert OrganizerEventLimitReached();
        }
        _;
    }
    
    /**
     * @dev Validates event creation fee payment
     */
    modifier validCreationFee() {
        if (msg.value < eventCreationFee) {
            revert InsufficientCreationFee(msg.value, eventCreationFee);
        }
        _;
    }
    
    // ============ EVENT CREATION ============
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function createEvent(VeriTixTypes.EventCreationParams calldata params) 
        external 
        payable 
        whenNotPaused
        validEventParams(params)
        withinOrganizerLimit(params.organizer)
        validCreationFee
        nonReentrant
        returns (address eventContract) 
    {
        // Gas optimization: Deploy new VeriTixEvent contract with minimal stack usage
        eventContract = address(new VeriTixEvent(
            params.name,
            params.symbol,
            params.maxSupply,
            params.ticketPrice,
            params.organizer,
            params.baseURI,
            params.maxResalePercent,
            params.organizerFeePercent
        ));
        
        // Register the event (optimized internal function)
        _registerEvent(eventContract, params);
        
        // Emit event creation
        emit EventCreated(
            eventContract,
            params.organizer,
            params.name,
            params.ticketPrice,
            params.maxSupply
        );
        
        return eventContract;
    }    

    /**
     * @inheritdoc IVeriTixFactory
     */
    function batchCreateEvents(VeriTixTypes.EventCreationParams[] calldata paramsArray)
        external
        payable
        whenNotPaused
        validCreationFee
        nonReentrant
        returns (address[] memory eventContracts)
    {
        uint256 length = paramsArray.length;
        
        // Validate batch parameters
        if (length == 0) {
            revert EmptyBatchArray();
        }
        if (length > 10) { // Limit batch size to prevent gas issues
            revert BatchSizeTooLarge(length, 10);
        }
        
        eventContracts = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            // Validate each event's parameters using the same comprehensive checks
            VeriTixTypes.EventCreationParams calldata params = paramsArray[i];
            
            // Check event name
            if (bytes(params.name).length == 0 || bytes(params.name).length > 100) {
                revert InvalidEventName();
            }
            
            // Check event symbol
            if (bytes(params.symbol).length == 0 || bytes(params.symbol).length > 20) {
                revert InvalidEventSymbol();
            }
            
            // Check max supply
            if (params.maxSupply == 0 || params.maxSupply > VeriTixTypes.MAX_TICKETS_PER_EVENT) {
                revert InvalidMaxSupply(params.maxSupply, VeriTixTypes.MAX_TICKETS_PER_EVENT);
            }
            
            // Check ticket price
            if (params.ticketPrice < VeriTixTypes.MIN_TICKET_PRICE) {
                revert TicketPriceTooLow(params.ticketPrice, VeriTixTypes.MIN_TICKET_PRICE);
            }
            
            // Check organizer address
            if (params.organizer == address(0)) {
                revert InvalidOrganizerAddress();
            }
            
            // Check base URI
            if (bytes(params.baseURI).length == 0) {
                revert InvalidBaseURI();
            }
            
            // Check resale percentage
            if (params.maxResalePercent < 100) {
                revert ResalePercentTooLow(params.maxResalePercent);
            }
            if (params.maxResalePercent > globalMaxResalePercent) {
                revert ExceedsGlobalResaleLimit(params.maxResalePercent, globalMaxResalePercent);
            }
            
            // Check organizer fee
            if (params.organizerFeePercent > VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT) {
                revert OrganizerFeeTooHigh(params.organizerFeePercent, VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT);
            }
            
            // Check organizer event limit
            if (organizerEvents[params.organizer].length >= maxEventsPerOrganizer) {
                revert OrganizerEventLimitReached();
            }
            
            // Deploy event contract
            address eventContract = address(new VeriTixEvent(
                paramsArray[i].name,
                paramsArray[i].symbol,
                paramsArray[i].maxSupply,
                paramsArray[i].ticketPrice,
                paramsArray[i].organizer,
                paramsArray[i].baseURI,
                paramsArray[i].maxResalePercent,
                paramsArray[i].organizerFeePercent
            ));
            
            eventContracts[i] = eventContract;
            
            // Register the event
            _registerEvent(eventContract, paramsArray[i]);
            
            // Emit event creation
            emit EventCreated(
                eventContract,
                paramsArray[i].organizer,
                paramsArray[i].name,
                paramsArray[i].ticketPrice,
                paramsArray[i].maxSupply
            );
        }
        
        return eventContracts;
    }
    
    // ============ EVENT DISCOVERY ============
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getDeployedEvents() external view returns (address[] memory events) {
        return deployedEvents;
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getEventsByOrganizer(address organizer) 
        external 
        view 
        returns (address[] memory events) 
    {
        return organizerEvents[organizer];
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getEventRegistry(address eventContract) 
        external 
        view 
        returns (VeriTixTypes.EventRegistry memory registry) 
    {
        return eventRegistry[eventContract];
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getEventsPaginated(uint256 offset, uint256 limit)
        external
        view
        returns (VeriTixTypes.EventRegistry[] memory events, uint256 totalCount)
    {
        totalCount = deployedEvents.length;
        
        // Validate pagination parameters
        if (limit == 0 || limit > 100) { // Reasonable limit to prevent gas issues
            revert InvalidPaginationLimit(limit, 100);
        }
        
        if (offset > totalCount) { // Allow offset == totalCount for empty result
            revert InvalidPaginationOffset(offset, totalCount);
        }
        
        if (offset >= totalCount) {
            return (new VeriTixTypes.EventRegistry[](0), totalCount);
        }
        
        uint256 end = offset + limit;
        if (end > totalCount) {
            end = totalCount;
        }
        
        uint256 resultLength = end - offset;
        events = new VeriTixTypes.EventRegistry[](resultLength);
        
        for (uint256 i = 0; i < resultLength; i++) {
            events[i] = eventRegistry[deployedEvents[offset + i]];
        }
        
        return (events, totalCount);
    }
    
    // ============ FACTORY MANAGEMENT ============
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function setGlobalMaxResalePercent(uint256 newMaxPercent) external onlyOwner {
        if (newMaxPercent < 100) {
            revert GlobalResalePercentTooLow(newMaxPercent);
        }
        if (newMaxPercent > VeriTixTypes.MAX_RESALE_PERCENTAGE) {
            revert GlobalResalePercentTooHigh(newMaxPercent, VeriTixTypes.MAX_RESALE_PERCENTAGE);
        }
        
        uint256 oldValue = globalMaxResalePercent;
        globalMaxResalePercent = newMaxPercent;
        
        emit FactorySettingUpdated("globalMaxResalePercent", oldValue, newMaxPercent);
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function setDefaultOrganizerFee(uint256 newFeePercent) external onlyOwner {
        if (newFeePercent > VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT) {
            revert OrganizerFeeTooHigh(newFeePercent, VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT);
        }
        
        uint256 oldValue = defaultOrganizerFee;
        defaultOrganizerFee = newFeePercent;
        
        emit FactorySettingUpdated("defaultOrganizerFee", oldValue, newFeePercent);
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function setEventCreationFee(uint256 newFee) external onlyOwner {
        uint256 oldValue = eventCreationFee;
        eventCreationFee = newFee;
        
        emit FactorySettingUpdated("eventCreationFee", oldValue, newFee);
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function setPaused(bool paused) external onlyOwner {
        factoryPaused = paused;
        emit FactoryPauseToggled(paused);
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function transferOwnership(address newOwner) public override(IVeriTixFactory, Ownable) onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidNewOwner();
        }
        super.transferOwnership(newOwner);
    }    

    // ============ FACTORY INFORMATION ============
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getFactoryConfig() external view returns (VeriTixTypes.FactoryConfig memory config) {
        return VeriTixTypes.FactoryConfig({
            platformOwner: owner(),
            globalMaxResalePercent: globalMaxResalePercent,
            defaultOrganizerFee: defaultOrganizerFee,
            factoryPaused: factoryPaused,
            eventCreationFee: eventCreationFee
        });
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getTotalEvents() external view returns (uint256 count) {
        return deployedEvents.length;
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getOrganizerEventCount(address organizer) external view returns (uint256 count) {
        return organizerEvents[organizer].length;
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function isValidEventContract(address eventContract) external view returns (bool isValid) {
        return eventRegistry[eventContract].eventContract != address(0);
    }
    
    // ============ ANALYTICS ============
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getGlobalStats() external view returns (
        uint256 totalTicketsSold,
        uint256 totalRevenue,
        uint256 totalEvents,
        uint256 activeEvents
    ) {
        totalEvents = deployedEvents.length;
        
        for (uint256 i = 0; i < deployedEvents.length; i++) {
            VeriTixTypes.EventRegistry memory registry = eventRegistry[deployedEvents[i]];
            
            if (registry.status == VeriTixTypes.EventStatus.Active || 
                registry.status == VeriTixTypes.EventStatus.SoldOut) {
                activeEvents++;
            }
            
            // Note: For full implementation, we would need to call the event contracts
            // to get actual sales data. This is a simplified version.
            // In practice, you might want to track this data in the factory or use events
        }
        
        return (totalTicketsSold, totalRevenue, totalEvents, activeEvents);
    }
    
    /**
     * @inheritdoc IVeriTixFactory
     */
    function getEventsByStatus(VeriTixTypes.EventStatus status) 
        external 
        view 
        returns (address[] memory events) 
    {
        // First pass: count matching events
        uint256 count = 0;
        for (uint256 i = 0; i < deployedEvents.length; i++) {
            if (eventRegistry[deployedEvents[i]].status == status) {
                count++;
            }
        }
        
        // Second pass: populate result array
        events = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < deployedEvents.length; i++) {
            if (eventRegistry[deployedEvents[i]].status == status) {
                events[index] = deployedEvents[i];
                index++;
            }
        }
        
        return events;
    }
    
    // ============ INTERNAL FUNCTIONS ============
    
    /**
     * @dev Register a newly deployed event in the factory registry
     * @param eventContract Address of the deployed event contract
     * @param params Event creation parameters used for deployment
     */
    function _registerEvent(
        address eventContract, 
        VeriTixTypes.EventCreationParams calldata params
    ) internal {
        // Gas optimization: Cache organizer address to avoid multiple calldata reads
        address organizer_ = params.organizer;
        
        // Add to global registry
        deployedEvents.push(eventContract);
        
        // Add to organizer's events
        organizerEvents[organizer_].push(eventContract);
        
        // Create registry entry (single SSTORE operation)
        eventRegistry[eventContract] = VeriTixTypes.EventRegistry({
            eventContract: eventContract,
            organizer: organizer_,
            createdAt: block.timestamp,
            eventName: params.name,
            status: VeriTixTypes.EventStatus.Active,
            ticketPrice: params.ticketPrice,
            maxSupply: params.maxSupply
        });
    }
    
    /**
     * @dev Withdraw accumulated creation fees (owner only)
     * @param to Address to send the fees to
     */
    function withdrawFees(address payable to) external onlyOwner {
        if (to == address(0)) {
            revert InvalidFeeRecipient();
        }
        
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoFeesToWithdraw();
        }
        
        (bool success, ) = to.call{value: balance}("");
        if (!success) {
            revert FeeWithdrawalFailed();
        }
    }
    
    /**
     * @dev Emergency function to update event status (owner only)
     * @param eventContract Address of the event contract
     * @param newStatus New status to set
     */
    function updateEventStatus(address eventContract, VeriTixTypes.EventStatus newStatus) 
        external 
        onlyOwner 
    {
        if (eventRegistry[eventContract].eventContract == address(0)) {
            revert EventNotFound(eventContract);
        }
        eventRegistry[eventContract].status = newStatus;
    }
}