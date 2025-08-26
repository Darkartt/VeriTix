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
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 ticketsSold;
        address organizer;
    }

    // Mapping from event ID to Event
    mapping(uint256 => Event) public events;

    // Event ID counter
    uint256 private _nextEventId = 1;

    // Events
    event EventCreated(uint256 indexed eventId, string name, uint256 ticketPrice, uint256 maxTickets, address organizer);
    event TicketMinted(uint256 indexed eventId, uint256 indexed tokenId, address indexed buyer);

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

        events[eventId] = Event({
            name: name,
            ticketPrice: ticketPrice,
            maxTickets: maxTickets,
            ticketsSold: 0,
            organizer: msg.sender
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

        // Increment tickets sold
        eventInfo.ticketsSold++;

        // Mint the NFT ticket to the buyer
        uint256 tokenId = totalSupply() + 1;
        _mint(msg.sender, tokenId);

        // Transfer funds to the event organizer
        payable(eventInfo.organizer).transfer(msg.value);

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

    // Required overrides for ERC721 and ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
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
