// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/VeriTixTypes.sol";

/**
 * @title IVeriTixEvent
 * @dev Interface for individual VeriTix event contracts
 * @notice This interface defines the standard for event-specific NFT ticket contracts
 * deployed by the VeriTixFactory. Each event gets its own contract implementing this interface.
 */
interface IVeriTixEvent is IERC721 {
    
    // ============ EVENTS ============
    
    /**
     * @dev Emitted when a ticket is minted (primary sale)
     * @param tokenId The ID of the minted ticket
     * @param buyer The address that purchased the ticket
     * @param price The price paid for the ticket
     */
    event TicketMinted(uint256 indexed tokenId, address indexed buyer, uint256 price);
    
    /**
     * @dev Emitted when a ticket is resold through the controlled resale mechanism
     * @param tokenId The ID of the resold ticket
     * @param seller The address selling the ticket
     * @param buyer The address buying the ticket
     * @param price The resale price
     * @param organizerFee The fee collected by the organizer
     */
    event TicketResold(
        uint256 indexed tokenId, 
        address indexed seller, 
        address indexed buyer, 
        uint256 price, 
        uint256 organizerFee
    );
    
    /**
     * @dev Emitted when a ticket is refunded
     * @param tokenId The ID of the refunded ticket
     * @param holder The address that held the ticket
     * @param refundAmount The amount refunded (always face value)
     */
    event TicketRefunded(uint256 indexed tokenId, address indexed holder, uint256 refundAmount);
    
    /**
     * @dev Emitted when a ticket is checked in at the venue
     * @param tokenId The ID of the checked-in ticket
     * @param holder The address that held the ticket at check-in
     */
    event TicketCheckedIn(uint256 indexed tokenId, address indexed holder);
    
    /**
     * @dev Emitted when the event is cancelled by the organizer
     * @param reason The reason for cancellation
     */
    event EventCancelled(string reason);
    
    // ============ ERRORS ============
    
    /// @dev Thrown when the event has sold out
    error EventSoldOut();
    
    /// @dev Thrown when incorrect payment is sent
    error IncorrectPayment(uint256 sent, uint256 required);
    
    /// @dev Thrown when caller is not the ticket owner
    error NotTicketOwner();
    
    /// @dev Thrown when attempting to operate on a ticket that has been checked in
    error TicketAlreadyUsed();
    
    /// @dev Thrown when resale price exceeds the maximum allowed
    error ExceedsResaleCap(uint256 price, uint256 maximum);
    
    /// @dev Thrown when attempting direct transfers (bypassing resale mechanism)
    error TransfersDisabled();
    
    /// @dev Thrown when the event has been cancelled
    error EventIsCancelled();
    
    /// @dev Thrown when trying to cancel an already cancelled event
    error EventAlreadyCancelled();
    
    /// @dev Thrown when trying to use cancelRefund on a non-cancelled event
    error EventNotCancelled();
    
    /// @dev Thrown when a refund operation fails
    error RefundFailed();
    
    /// @dev Thrown when caller lacks required permissions
    error UnauthorizedAccess();
    
    /// @dev Thrown when a ticket does not exist
    error TicketNotFound();
    
    /// @dev Thrown when trying to buy your own ticket
    error CannotBuyOwnTicket();
    
    /// @dev Thrown when resale price is zero
    error InvalidResalePrice();
    
    /// @dev Thrown when trying to resale to zero address
    error InvalidBuyerAddress();
    
    /// @dev Thrown when trying to check in non-existent ticket
    error InvalidTokenId(uint256 tokenId);
    
    /// @dev Thrown when cancellation reason is empty
    error EmptyCancellationReason();
    
    /// @dev Thrown when trying to mint with zero payment
    error ZeroPayment();
    
    /// @dev Thrown when contract has insufficient balance for refund
    error InsufficientContractBalance(uint256 required, uint256 available);
    
    /// @dev Thrown when trying to operate on burned ticket
    error TicketBurned(uint256 tokenId);
    
    /// @dev Thrown when base URI is empty
    error EmptyBaseURI();
    
    /// @dev Thrown when trying to set base URI to same value
    error BaseURIUnchanged();
    
    /// @dev Thrown when max supply is zero
    error InvalidMaxSupply();
    
    /// @dev Thrown when ticket price is zero
    error InvalidTicketPrice();
    
    /// @dev Thrown when max resale percent is below 100%
    error InvalidMaxResalePercent(uint256 provided);
    
    /// @dev Thrown when organizer fee percent exceeds maximum
    error InvalidOrganizerFeePercent(uint256 provided, uint256 maximum);
    
    /// @dev Thrown when organizer address is zero
    error InvalidOrganizerAddress();
    
    /// @dev Thrown when event name is empty
    error EmptyEventName();
    
    /// @dev Thrown when event symbol is empty
    error EmptyEventSymbol();
    
    // ============ PRIMARY SALES ============
    
    /**
     * @dev Mint a new ticket (primary sale)
     * @notice Caller must send exact ticket price in ETH
     * @return tokenId The ID of the newly minted ticket
     * 
     * Requirements:
     * - Event must not be sold out
     * - Event must not be cancelled
     * - Caller must send exact ticket price
     */
    function mintTicket() external payable returns (uint256 tokenId);
    
    // ============ RESALE MECHANISM ============
    
    /**
     * @dev Resell a ticket through the controlled resale mechanism
     * @param tokenId The ID of the ticket to resell
     * @param price The resale price (must not exceed price cap)
     * @notice Buyer must send exact resale price in ETH
     * 
     * Requirements:
     * - Caller must own the ticket
     * - Ticket must not be checked in
     * - Price must not exceed maximum resale percentage
     * - Event must not be cancelled
     */
    function resaleTicket(uint256 tokenId, uint256 price) external payable;
    
    /**
     * @dev Get the maximum allowed resale price for a ticket
     * @param tokenId The ID of the ticket
     * @return maxPrice The maximum allowed resale price
     */
    function getMaxResalePrice(uint256 tokenId) external view returns (uint256 maxPrice);
    
    // ============ REFUND SYSTEM ============
    
    /**
     * @dev Request a refund for a ticket (always at face value)
     * @param tokenId The ID of the ticket to refund
     * 
     * Requirements:
     * - Caller must own the ticket
     * - Ticket must not be checked in
     * - Event must not be cancelled (use cancelRefund for cancelled events)
     */
    function refund(uint256 tokenId) external;
    
    /**
     * @dev Request a refund after event cancellation
     * @param tokenId The ID of the ticket to refund
     * 
     * Requirements:
     * - Event must be cancelled
     * - Caller must own the ticket
     */
    function cancelRefund(uint256 tokenId) external;
    
    // ============ VENUE CHECK-IN ============
    
    /**
     * @dev Check in a ticket at the venue (organizer only)
     * @param tokenId The ID of the ticket to check in
     * 
     * Requirements:
     * - Caller must be the event organizer
     * - Ticket must exist and not be already checked in
     */
    function checkIn(uint256 tokenId) external;
    
    /**
     * @dev Check if a ticket has been checked in
     * @param tokenId The ID of the ticket to check
     * @return isCheckedIn True if the ticket has been checked in
     */
    function isCheckedIn(uint256 tokenId) external view returns (bool isCheckedIn);
    
    // ============ EVENT MANAGEMENT ============
    
    /**
     * @dev Cancel the event (organizer only, irreversible)
     * @param reason The reason for cancellation
     * 
     * Requirements:
     * - Caller must be the event organizer
     * - Event must not already be cancelled
     */
    function cancelEvent(string calldata reason) external;
    
    /**
     * @dev Check if the event has been cancelled
     * @return isCancelled True if the event has been cancelled
     */
    function isCancelled() external view returns (bool isCancelled);
    
    // ============ EVENT INFORMATION ============
    
    /**
     * @dev Get basic event information
     * @return name The event name
     * @return symbol The event symbol (ticker)
     * @return organizer The event organizer address
     * @return ticketPrice The face value ticket price
     * @return maxSupply The maximum number of tickets
     * @return totalSupply The current number of tickets minted
     */
    function getEventInfo() external view returns (
        string memory name,
        string memory symbol,
        address organizer,
        uint256 ticketPrice,
        uint256 maxSupply,
        uint256 totalSupply
    );
    
    /**
     * @dev Get anti-scalping configuration
     * @return maxResalePercent The maximum resale percentage (e.g., 110 = 110% of face value)
     * @return organizerFeePercent The organizer fee percentage on resales
     */
    function getAntiScalpingConfig() external view returns (
        uint256 maxResalePercent,
        uint256 organizerFeePercent
    );
    
    /**
     * @dev Get the original purchase price for a ticket
     * @param tokenId The ID of the ticket
     * @return originalPrice The original face value price paid
     */
    function getOriginalPrice(uint256 tokenId) external view returns (uint256 originalPrice);
    
    /**
     * @dev Get the last price paid for a ticket (including resales)
     * @param tokenId The ID of the ticket
     * @return lastPrice The most recent price paid for the ticket
     */
    function getLastPricePaid(uint256 tokenId) external view returns (uint256 lastPrice);
    
    // ============ MARKETPLACE INTEGRATION ============
    
    /**
     * @dev Get the base URI for token metadata
     * @return baseURI The base URI string
     */
    function baseURI() external view returns (string memory baseURI);
    
    /**
     * @dev Update the base URI for token metadata (organizer only)
     * @param newBaseURI The new base URI
     */
    function setBaseURI(string calldata newBaseURI) external;
    
    /**
     * @dev Get comprehensive metadata for marketplace integration
     * @param tokenId The token ID to get metadata for
     * @return metadata Structured metadata for the ticket
     */
    function getTicketMetadata(uint256 tokenId) external view returns (VeriTixTypes.TicketMetadata memory metadata);
    
    /**
     * @dev Get collection-level metadata for marketplace integration
     * @return collection Structured collection metadata
     */
    function getCollectionMetadata() external view returns (VeriTixTypes.CollectionMetadata memory collection);
}