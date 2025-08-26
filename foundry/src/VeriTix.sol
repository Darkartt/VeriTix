// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VeriTix
 * @dev A decentralized event ticketing system where each ticket is an ERC721 NFT
 */
contract VeriTix is ERC721, ERC721Enumerable, Ownable {
    // Struct to represent an event
    struct Event {
        string name;
        string description;
        string venue;
        uint256 date;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 maxTicketsPerBuyer;
        uint256 ticketsSold;
        address organizer;
        bool isActive;
        uint256 totalCollected;
        bool transfersAllowed;
        uint256 transferFeePercent;
    }

    // Mapping from event ID to Event
    mapping(uint256 => Event) public events;

    // Event ID counter
    uint256 private _nextEventId = 1;

    // Events
    event EventCreated(uint256 indexed eventId, string name, uint256 ticketPrice, uint256 maxTickets, address organizer);
    event TicketMinted(uint256 indexed eventId, uint256 indexed tokenId, address indexed buyer);
    event EventCancelled(uint256 indexed eventId, string reason);
    event RefundProcessed(uint256 indexed eventId, uint256 indexed tokenId, address indexed buyer, uint256 amount);

    constructor(address initialOwner)
        ERC721("VeriTix", "VTIX")
        Ownable(initialOwner)
    {}

    /**
     * @dev Create a new event (only owner can call)
     * @param name The name of the event
     * @param ticketPrice The price of each ticket in wei
     * @param maxTickets The maximum number of tickets available
     */
    function createEvent(
        string memory name,
        uint256 ticketPrice,
        uint256 maxTickets
    ) external onlyOwner {
        require(bytes(name).length > 0, "Event name cannot be empty");
        require(ticketPrice > 0, "Ticket price must be greater than 0");
        require(maxTickets > 0, "Max tickets must be greater than 0");

        uint256 eventId = _nextEventId++;

        Event storage newEvent = events[eventId];
        newEvent.name = name;
        newEvent.description = "";
        newEvent.venue = "";
        newEvent.date = 0;
        newEvent.ticketPrice = ticketPrice;
        newEvent.maxTickets = maxTickets;
        newEvent.maxTicketsPerBuyer = maxTickets; // Default: no limit per buyer
        newEvent.ticketsSold = 0;
        newEvent.organizer = msg.sender;
        newEvent.isActive = true;
        newEvent.totalCollected = 0;
        newEvent.transfersAllowed = true; // Default: transfers allowed
        newEvent.transferFeePercent = 0; // Default: no transfer fee

        emit EventCreated(eventId, name, ticketPrice, maxTickets, msg.sender);
    }

    /**
     * @dev Create an enhanced event with full metadata and restrictions
     * @param name The name of the event
     * @param description The event description
     * @param venue The venue location
     * @param date The event date (timestamp)
     * @param ticketPrice The price of each ticket in wei
     * @param maxTickets The maximum number of tickets available
     * @param maxTicketsPerBuyer Maximum tickets one buyer can purchase
     * @param transfersAllowed Whether ticket transfers are allowed
     * @param transferFeePercent Fee percentage for transfers (0-100)
     */
    function createEnhancedEvent(
        string memory name,
        string memory description,
        string memory venue,
        uint256 date,
        uint256 ticketPrice,
        uint256 maxTickets,
        uint256 maxTicketsPerBuyer,
        bool transfersAllowed,
        uint256 transferFeePercent
    ) external onlyOwner {
        require(bytes(name).length > 0, "Event name cannot be empty");
        require(ticketPrice > 0, "Ticket price must be greater than 0");
        require(maxTickets > 0, "Max tickets must be greater than 0");
        require(maxTicketsPerBuyer > 0, "Max tickets per buyer must be greater than 0");
        require(transferFeePercent <= 100, "Transfer fee cannot exceed 100%");
        require(date > block.timestamp, "Event date must be in the future");

        uint256 eventId = _nextEventId++;

        events[eventId] = Event({
            name: name,
            description: description,
            venue: venue,
            date: date,
            ticketPrice: ticketPrice,
            maxTickets: maxTickets,
            maxTicketsPerBuyer: maxTicketsPerBuyer,
            ticketsSold: 0,
            organizer: msg.sender,
            isActive: true,
            totalCollected: 0,
            transfersAllowed: transfersAllowed,
            transferFeePercent: transferFeePercent
        });

        emit EventCreated(eventId, name, ticketPrice, maxTickets, msg.sender);
    }

    /**
     * @dev Buy a ticket for a specific event
     * @param eventId The ID of the event to buy a ticket for
     */
    function buyTicket(uint256 eventId) external payable {
        Event storage eventInfo = events[eventId];
        require(bytes(eventInfo.name).length > 0, "Event does not exist");
        require(msg.value == eventInfo.ticketPrice, "Incorrect ticket price sent");
        require(eventInfo.ticketsSold < eventInfo.maxTickets, "Event is sold out");

        // Use Checks-Effects-Interactions pattern to prevent reentrancy
        uint256 ticketPrice = eventInfo.ticketPrice;
        address organizer = eventInfo.organizer;

        // Effects: Update state before external interactions
        eventInfo.ticketsSold++;
        uint256 tokenId = totalSupply() + 1;

        // Mint the NFT ticket to the buyer
        _mint(msg.sender, tokenId);

        // Interactions: External calls after state updates
        // Use call instead of transfer for better gas control and reentrancy protection
        (bool success, ) = payable(organizer).call{value: ticketPrice}("");
        require(success, "Payment transfer failed");

        emit TicketMinted(eventId, tokenId, msg.sender);
    }

    /**
     * @dev Get event details
     * @param eventId The ID of the event to query
     * @return name The event name
     * @return ticketPrice The ticket price
     * @return maxTickets Maximum number of tickets
     * @return ticketsSold Number of tickets sold
     * @return organizer The event organizer address
     */
    function getEventDetails(uint256 eventId) external view returns (
        string memory name,
        uint256 ticketPrice,
        uint256 maxTickets,
        uint256 ticketsSold,
        address organizer
    ) {
        Event storage eventInfo = events[eventId];
        require(bytes(eventInfo.name).length > 0, "Event does not exist");

        return (
            eventInfo.name,
            eventInfo.ticketPrice,
            eventInfo.maxTickets,
            eventInfo.ticketsSold,
            eventInfo.organizer
        );
    }

    /**
     * @dev Check if an event exists
     * @param eventId The ID of the event to check
     * @return bool True if the event exists
     */
    function eventExists(uint256 eventId) external view returns (bool) {
        return bytes(events[eventId].name).length > 0;
    }

    /**
     * @dev Get the total number of events created
     * @return uint256 The total number of events
     */
    function getTotalEvents() external view returns (uint256) {
        return _nextEventId - 1;
    }

    /**
     * @dev Get tickets available for an event
     * @param eventId The ID of the event
     * @return uint256 Number of tickets still available
     */
    function getTicketsAvailable(uint256 eventId) external view returns (uint256) {
        Event storage eventInfo = events[eventId];
        require(bytes(eventInfo.name).length > 0, "Event does not exist");

        return eventInfo.maxTickets - eventInfo.ticketsSold;
    }

    /**
     * @dev Verify ticket ownership and validity
     * @param tokenId The ticket token ID
     * @param owner The expected owner address
     * @return bool True if the ticket is valid and owned by the specified address
     */
    function verifyTicketOwnership(uint256 tokenId, address owner) external view returns (bool) {
        return ownerOf(tokenId) == owner && tokenId > 0;
    }

    /**
     * @dev Get event ID for a specific ticket
     * @param tokenId The ticket token ID
     * @return uint256 The event ID associated with the ticket
     * @notice This is a simplified version - in production, you'd store eventId per token
     */
    function getTicketEventId(uint256 tokenId) public pure returns (uint256) {
        // For now, return tokenId as eventId (simplified mapping)
        // In production, you'd have a mapping(uint256 => uint256) tokenToEventId
        return tokenId;
    }

    /**
     * @dev Get ticket details including event information
     * @param tokenId The ticket token ID
     * @return eventId The event ID
     * @return eventName The event name
     * @return ticketPrice The ticket price paid
     * @return owner The current ticket owner
     */
    function getTicketDetails(uint256 tokenId) external view returns (
        uint256 eventId,
        string memory eventName,
        uint256 ticketPrice,
        address owner
    ) {
        require(tokenId > 0, "Invalid token ID");

        // Check if token exists by trying to get owner
        address ticketOwner;
        try this.ownerOf(tokenId) returns (address _owner) {
            ticketOwner = _owner;
        } catch {
            revert("Token does not exist");
        }

        uint256 eventIdForToken = getTicketEventId(tokenId);

        if (bytes(events[eventIdForToken].name).length > 0) {
            Event storage eventInfo = events[eventIdForToken];
            return (eventIdForToken, eventInfo.name, eventInfo.ticketPrice, ticketOwner);
        }

        // Fallback for tickets without associated event (shouldn't happen in normal flow)
        return (eventIdForToken, "Unknown Event", 0, ticketOwner);
    }

    /**
     * @dev Check if a ticket is valid for entry (owned by caller and event exists)
     * @param tokenId The ticket token ID
     * @return bool True if ticket is valid for entry
     */
    function isValidForEntry(uint256 tokenId) external view returns (bool) {
        if (tokenId == 0) {
            return false;
        }

        // Check if token exists by trying to get owner
        address ticketOwner;
        try this.ownerOf(tokenId) returns (address _owner) {
            ticketOwner = _owner;
        } catch {
            return false;
        }

        uint256 eventId = getTicketEventId(tokenId);

        return ticketOwner == msg.sender && bytes(events[eventId].name).length > 0;
    }

    /**
     * @dev Cancel an event and enable refunds (only event organizer can call)
     * @param eventId The ID of the event to cancel
     * @param reason The reason for cancellation
     */
    function cancelEvent(uint256 eventId, string memory reason) external {
        Event storage eventInfo = events[eventId];
        require(bytes(eventInfo.name).length > 0, "Event does not exist");
        require(eventInfo.organizer == msg.sender, "Only event organizer can cancel");

        // Mark event as cancelled by clearing the name (soft delete)
        eventInfo.name = "";

        emit EventCancelled(eventId, reason);
    }

    /**
     * @dev Request refund for a ticket after event cancellation
     * @param tokenId The ticket token ID to refund
     * @notice Ticket must be burned after successful refund
     */
    function refundTicket(uint256 tokenId) external {
        require(tokenId > 0, "Invalid token ID");

        // Check if token exists and is owned by caller
        address ticketOwner = ownerOf(tokenId);
        require(ticketOwner == msg.sender, "Not ticket owner");

        uint256 eventId = getTicketEventId(tokenId);
        Event storage eventInfo = events[eventId];

        // Check if event was cancelled (name cleared)
        require(bytes(eventInfo.name).length == 0, "Event not cancelled");

        uint256 refundAmount = eventInfo.ticketPrice;

        // Burn the ticket NFT
        _burn(tokenId);

        // Process refund - ensure contract has enough balance
        require(address(this).balance >= refundAmount, "Insufficient contract balance");

        // Send refund using call pattern for better reliability
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Refund transfer failed");

        emit RefundProcessed(eventId, tokenId, msg.sender, refundAmount);
    }

    /**
     * @dev Check if an event is cancelled
     * @param eventId The ID of the event to check
     * @return bool True if the event is cancelled
     */
    function isEventCancelled(uint256 eventId) external view returns (bool) {
        return bytes(events[eventId].name).length == 0 && eventId > 0 && eventId < _nextEventId;
    }

    /**
     * @dev Get refund amount for a ticket
     * @param tokenId The ticket token ID
     * @return uint256 The refund amount in wei
     */
    function getRefundAmount(uint256 tokenId) external view returns (uint256) {
        require(tokenId > 0, "Invalid token ID");

        // Check if token exists
        try this.ownerOf(tokenId) returns (address) {
            // Token exists, continue
        } catch {
            return 0; // Return 0 if token doesn't exist
        }

        uint256 eventId = getTicketEventId(tokenId);
        Event storage eventInfo = events[eventId];

        // Only return refund amount if event is cancelled
        if (bytes(eventInfo.name).length == 0) {
            return eventInfo.ticketPrice;
        }

        return 0;
    }

    /**
     * @dev Batch create multiple events
     * @param names Array of event names
     * @param ticketPrices Array of ticket prices
     * @param maxTicketsArray Array of maximum tickets for each event
     */
    function batchCreateEvents(
        string[] memory names,
        uint256[] memory ticketPrices,
        uint256[] memory maxTicketsArray
    ) external onlyOwner {
        require(names.length == ticketPrices.length, "Mismatched array lengths");
        require(names.length == maxTicketsArray.length, "Mismatched array lengths");
        require(names.length > 0, "Cannot create zero events");
        require(names.length <= 50, "Cannot create more than 50 events at once");

        for (uint256 i = 0; i < names.length; i++) {
            require(bytes(names[i]).length > 0, "Event name cannot be empty");
            require(ticketPrices[i] > 0, "Ticket price must be greater than 0");
            require(maxTicketsArray[i] > 0, "Max tickets must be greater than 0");

            uint256 eventId = _nextEventId++;

            events[eventId] = Event({
                name: names[i],
                description: "",
                venue: "",
                date: 0,
                ticketPrice: ticketPrices[i],
                maxTickets: maxTicketsArray[i],
                maxTicketsPerBuyer: maxTicketsArray[i], // Default: no limit per buyer
                ticketsSold: 0,
                organizer: msg.sender,
                isActive: true,
                totalCollected: 0,
                transfersAllowed: true, // Default: transfers allowed
                transferFeePercent: 0 // Default: no transfer fee
            });

            emit EventCreated(eventId, names[i], ticketPrices[i], maxTicketsArray[i], msg.sender);
        }
    }

    /**
     * @dev Batch buy tickets for multiple events
     * @param eventIds Array of event IDs to buy tickets for
     * @param quantities Array of quantities for each event
     */
    function batchBuyTickets(
        uint256[] memory eventIds,
        uint256[] memory quantities
    ) external payable {
        require(eventIds.length == quantities.length, "Mismatched array lengths");
        require(eventIds.length > 0, "Cannot buy zero tickets");
        require(eventIds.length <= 20, "Cannot buy from more than 20 events at once");

        uint256 totalCost = 0;
        uint256[] memory tokenIds = new uint256[](eventIds.length);

        // Calculate total cost and validate purchases
        for (uint256 i = 0; i < eventIds.length; i++) {
            uint256 eventId = eventIds[i];
            uint256 quantity = quantities[i];

            require(quantity > 0, "Quantity must be greater than 0");
            require(quantity <= 10, "Cannot buy more than 10 tickets per event");

            Event storage eventInfo = events[eventId];
            require(bytes(eventInfo.name).length > 0, "Event does not exist");
            require(eventInfo.ticketsSold + quantity <= eventInfo.maxTickets, "Not enough tickets available");

            totalCost += eventInfo.ticketPrice * quantity;
        }

        require(msg.value >= totalCost, "Insufficient payment for all tickets");

        // Process purchases
        for (uint256 i = 0; i < eventIds.length; i++) {
            uint256 eventId = eventIds[i];
            uint256 quantity = quantities[i];
            Event storage eventInfo = events[eventId];

            // Mint tickets for this event
            for (uint256 j = 0; j < quantity; j++) {
                eventInfo.ticketsSold++;
                uint256 tokenId = totalSupply() + 1;
                _mint(msg.sender, tokenId);
                emit TicketMinted(eventId, tokenId, msg.sender);
            }
        }

        // Refund excess payment
        if (msg.value > totalCost) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - totalCost}("");
            require(refundSuccess, "Excess payment refund failed");
        }
    }

    /**
     * @dev Get comprehensive event information
     * @param eventId The ID of the event to query
     * @return name Event name
     * @return description Event description
     * @return venue Event venue
     * @return date Event date
     * @return ticketPrice Ticket price
     * @return maxTickets Maximum tickets
     * @return maxTicketsPerBuyer Max tickets per buyer
     * @return ticketsSold Number of tickets sold
     * @return organizer Event organizer
     * @return isActive Whether event is active
     * @return transfersAllowed Whether transfers are allowed
     * @return transferFeePercent Transfer fee percentage
     */
    function getFullEventDetails(uint256 eventId) external view returns (
        string memory name,
        string memory description,
        string memory venue,
        uint256 date,
        uint256 ticketPrice,
        uint256 maxTickets,
        uint256 maxTicketsPerBuyer,
        uint256 ticketsSold,
        address organizer,
        bool isActive,
        bool transfersAllowed,
        uint256 transferFeePercent
    ) {
        Event storage eventInfo = events[eventId];
        require(bytes(eventInfo.name).length > 0, "Event does not exist");

        return (
            eventInfo.name,
            eventInfo.description,
            eventInfo.venue,
            eventInfo.date,
            eventInfo.ticketPrice,
            eventInfo.maxTickets,
            eventInfo.maxTicketsPerBuyer,
            eventInfo.ticketsSold,
            eventInfo.organizer,
            eventInfo.isActive,
            eventInfo.transfersAllowed,
            eventInfo.transferFeePercent
        );
    }

    /**
     * @dev Update event settings (only organizer can call)
     * @param eventId The event ID to update
     * @param transfersAllowed Whether transfers are allowed
     * @param transferFeePercent Transfer fee percentage (0-100)
     */
    function updateEventSettings(
        uint256 eventId,
        bool transfersAllowed,
        uint256 transferFeePercent
    ) external {
        Event storage eventInfo = events[eventId];
        require(bytes(eventInfo.name).length > 0, "Event does not exist");
        require(eventInfo.organizer == msg.sender, "Only event organizer can update");
        require(transferFeePercent <= 100, "Transfer fee cannot exceed 100%");

        eventInfo.transfersAllowed = transfersAllowed;
        eventInfo.transferFeePercent = transferFeePercent;
    }

    // Required overrides for ERC721 and ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        address from = _ownerOf(tokenId);

        // Check transfer restrictions only for actual transfers (not minting or burning)
        if (from != address(0) && to != address(0)) {
            uint256 eventId = getTicketEventId(tokenId);
            Event storage eventInfo = events[eventId];

            // Check if transfers are allowed for this event
            require(eventInfo.transfersAllowed, "Ticket transfers not allowed for this event");

            // If there's a transfer fee, collect it
            if (eventInfo.transferFeePercent > 0) {
                uint256 transferFee = (eventInfo.ticketPrice * eventInfo.transferFeePercent) / 100;
                require(msg.value >= transferFee, "Insufficient transfer fee");

                // Transfer fee to organizer
                (bool success, ) = payable(eventInfo.organizer).call{value: transferFee}("");
                require(success, "Transfer fee payment failed");

                // Refund excess payment
                if (msg.value > transferFee) {
                    (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - transferFee}("");
                    require(refundSuccess, "Excess payment refund failed");
                }
            }
        }

        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
