// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IVeriTixEvent.sol";
import "./libraries/VeriTixTypes.sol";

/**
 * @title VeriTixEvent
 * @dev Individual event contract for VeriTix NFT tickets with anti-scalping mechanisms
 * @notice This contract represents a single event with its own ERC721 NFT collection
 * Each ticket is an NFT with controlled transfer and resale mechanisms
 */
contract VeriTixEvent is ERC721, Ownable, ReentrancyGuard, IVeriTixEvent {
    // ============ STATE VARIABLES ============

    /// @dev Maximum number of tickets that can be minted for this event
    uint256 public immutable maxSupply;

    /// @dev Face value price per ticket in wei
    uint256 public immutable ticketPrice;

    /// @dev Address of the event organizer (also the contract owner)
    address public immutable organizer;

    /// @dev Maximum resale percentage (e.g., 110 = 110% of face value)
    uint256 public immutable maxResalePercent;

    /// @dev Organizer fee percentage on resales (e.g., 5 = 5%)
    uint256 public immutable organizerFeePercent;

    /// @dev Base URI for token metadata
    string private _baseTokenURI;

    /// @dev Current number of tickets minted
    uint256 private _currentTokenId;

    /// @dev Current number of tickets in circulation (minted - burned)
    uint256 private _totalSupply;

    /// @dev Whether the event has been cancelled
    bool public cancelled;

    /// @dev Mapping from token ID to the last price paid for that ticket
    mapping(uint256 => uint256) public lastPricePaid;

    /// @dev Mapping from token ID to check-in status
    mapping(uint256 => bool) public checkedIn;

    // ============ CONSTRUCTOR ============

    /**
     * @dev Initialize a new VeriTix event contract
     * @param name_ The name of the event (e.g., "Concert 2024")
     * @param symbol_ The symbol/ticker for the event (e.g., "CONC24")
     * @param maxSupply_ Maximum number of tickets available
     * @param ticketPrice_ Face value price per ticket in wei
     * @param organizer_ Address of the event organizer
     * @param baseURI_ Base URI for token metadata
     * @param maxResalePercent_ Maximum resale percentage (e.g., 110 = 110%)
     * @param organizerFeePercent_ Organizer fee on resales (e.g., 5 = 5%)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 ticketPrice_,
        address organizer_,
        string memory baseURI_,
        uint256 maxResalePercent_,
        uint256 organizerFeePercent_
    ) ERC721(name_, symbol_) Ownable(organizer_) {
        // Validate event name
        if (bytes(name_).length == 0) {
            revert EmptyEventName();
        }

        // Validate event symbol
        if (bytes(symbol_).length == 0) {
            revert EmptyEventSymbol();
        }

        // Validate max supply
        if (maxSupply_ == 0) {
            revert InvalidMaxSupply();
        }
        if (maxSupply_ > VeriTixTypes.MAX_TICKETS_PER_EVENT) {
            revert InvalidMaxSupply();
        }

        // Validate ticket price
        if (ticketPrice_ == 0) {
            revert InvalidTicketPrice();
        }
        if (ticketPrice_ < VeriTixTypes.MIN_TICKET_PRICE) {
            revert InvalidTicketPrice();
        }

        // Validate organizer address
        if (organizer_ == address(0)) {
            revert InvalidOrganizerAddress();
        }

        // Validate base URI
        if (bytes(baseURI_).length == 0) {
            revert EmptyBaseURI();
        }

        // Validate max resale percentage
        if (maxResalePercent_ < 100) {
            revert InvalidMaxResalePercent(maxResalePercent_);
        }
        if (maxResalePercent_ > VeriTixTypes.MAX_RESALE_PERCENTAGE) {
            revert InvalidMaxResalePercent(maxResalePercent_);
        }

        // Validate organizer fee percentage
        if (organizerFeePercent_ > VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT) {
            revert InvalidOrganizerFeePercent(
                organizerFeePercent_,
                VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT
            );
        }

        maxSupply = maxSupply_;
        ticketPrice = ticketPrice_;
        organizer = organizer_;
        maxResalePercent = maxResalePercent_;
        organizerFeePercent = organizerFeePercent_;
        _baseTokenURI = baseURI_;
        _currentTokenId = 0;
        _totalSupply = 0;
        cancelled = false;
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @dev Get basic event information
     * @return name The event name
     * @return symbol The event symbol (ticker)
     * @return organizer_ The event organizer address
     * @return ticketPrice_ The face value ticket price
     * @return maxSupply_ The maximum number of tickets
     * @return totalSupply_ The current number of tickets minted
     */
    function getEventInfo()
        external
        view
        override
        returns (
            string memory name,
            string memory symbol,
            address organizer_,
            uint256 ticketPrice_,
            uint256 maxSupply_,
            uint256 totalSupply_
        )
    {
        return (
            super.name(),
            super.symbol(),
            organizer,
            ticketPrice,
            maxSupply,
            _totalSupply
        );
    }

    /**
     * @dev Get anti-scalping configuration
     * @return maxResalePercent_ The maximum resale percentage
     * @return organizerFeePercent_ The organizer fee percentage on resales
     */
    function getAntiScalpingConfig()
        external
        view
        override
        returns (uint256 maxResalePercent_, uint256 organizerFeePercent_)
    {
        return (maxResalePercent, organizerFeePercent);
    }

    /**
     * @dev Get the original purchase price for a ticket (always face value)
     * @param tokenId The ID of the ticket
     * @return originalPrice The original face value price paid
     */
    function getOriginalPrice(
        uint256 tokenId
    ) external view override returns (uint256 originalPrice) {
        _requireOwned(tokenId);
        return ticketPrice;
    }

    /**
     * @dev Get the last price paid for a ticket (including resales)
     * @param tokenId The ID of the ticket
     * @return lastPrice The most recent price paid for the ticket
     */
    function getLastPricePaid(
        uint256 tokenId
    ) external view override returns (uint256 lastPrice) {
        _requireOwned(tokenId);
        return lastPricePaid[tokenId];
    }

    /**
     * @dev Check if a ticket has been checked in
     * @param tokenId The ID of the ticket to check
     * @return isCheckedIn_ True if the ticket has been checked in
     */
    function isCheckedIn(
        uint256 tokenId
    ) external view override returns (bool isCheckedIn_) {
        _requireOwned(tokenId);
        return checkedIn[tokenId];
    }

    /**
     * @dev Check if the event has been cancelled
     * @return isCancelled_ True if the event has been cancelled
     */
    function isCancelled() external view override returns (bool isCancelled_) {
        return cancelled;
    }

    /**
     * @dev Get the base URI for token metadata
     * @return baseURI_ The base URI string
     */
    function baseURI() external view override returns (string memory baseURI_) {
        return _baseURI();
    }

    /**
     * @dev Get the maximum allowed resale price for a ticket
     * @param tokenId The ID of the ticket
     * @return maxPrice The maximum allowed resale price
     */
    function getMaxResalePrice(
        uint256 tokenId
    ) external view override returns (uint256 maxPrice) {
        _requireOwned(tokenId);
        return
            VeriTixTypes.calculateMaxResalePrice(ticketPrice, maxResalePercent);
    }

    /**
     * @dev Returns the total number of tokens in circulation
     * @return The current token supply (minted - burned)
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token
     * @param tokenId The token ID to get the URI for
     * @return The complete URI for the token metadata
     * @notice Returns marketplace-friendly metadata URI combining base URI with token ID
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI_ = _baseURI();
        return
            bytes(baseURI_).length > 0
                ? string(abi.encodePacked(baseURI_, _toString(tokenId)))
                : "";
    }

    /**
     * @dev Get comprehensive metadata for marketplace integration
     * @param tokenId The token ID to get metadata for
     * @return metadata Structured metadata for the ticket
     */
    function getTicketMetadata(
        uint256 tokenId
    )
        external
        view
        override
        returns (VeriTixTypes.TicketMetadata memory metadata)
    {
        _requireOwned(tokenId);

        address ticketOwner = _ownerOf(tokenId);

        return
            VeriTixTypes.TicketMetadata({
                tokenId: tokenId,
                eventName: name(),
                eventSymbol: symbol(),
                organizer: organizer,
                ticketPrice: ticketPrice,
                lastPricePaid: lastPricePaid[tokenId],
                maxResalePrice: VeriTixTypes.calculateMaxResalePrice(
                    ticketPrice,
                    maxResalePercent
                ),
                owner: ticketOwner,
                checkedIn: checkedIn[tokenId],
                cancelled: cancelled,
                tokenURI: tokenURI(tokenId)
            });
    }

    /**
     * @dev Get collection-level metadata for marketplace integration
     * @return collection Structured collection metadata
     */
    function getCollectionMetadata()
        external
        view
        override
        returns (VeriTixTypes.CollectionMetadata memory collection)
    {
        return
            VeriTixTypes.CollectionMetadata({
                name: name(),
                symbol: symbol(),
                description: string(
                    abi.encodePacked(
                        "VeriTix Event: ",
                        name(),
                        " - Anti-scalping NFT tickets with controlled resale"
                    )
                ),
                organizer: organizer,
                totalSupply: _totalSupply,
                maxSupply: maxSupply,
                ticketPrice: ticketPrice,
                maxResalePercent: maxResalePercent,
                organizerFeePercent: organizerFeePercent,
                cancelled: cancelled,
                baseURI: _baseTokenURI,
                contractAddress: address(this)
            });
    }

    /**
     * @dev Check if this contract supports the given interface
     * @param interfaceId The interface identifier to check
     * @return True if the interface is supported
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IVeriTixEvent).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ============ INTERNAL FUNCTIONS ============

    /**
     * @dev Override _baseURI to return the stored base URI
     * @return The base URI for token metadata
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation
     * @param value The number to convert
     * @return The string representation of the number
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /// @dev Flag to allow internal transfers during resale
    bool private _allowTransfer;

    /**
     * @dev Override _update to implement transfer restrictions
     * @notice Blocks direct transfers, only allows minting and burning
     * All resales must go through the resaleTicket function
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // Allow minting (from == address(0)) and burning (to == address(0))
        if (from != address(0) && to != address(0)) {
            // Allow transfer only if it's initiated by the resale mechanism
            if (!_allowTransfer) {
                revert TransfersDisabled();
            }
        }

        return super._update(to, tokenId, auth);
    }

    // ============ PLACEHOLDER FUNCTIONS ============
    // These functions are defined in the interface but will be implemented in later tasks

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
    function mintTicket()
        external
        payable
        override
        nonReentrant
        returns (uint256 tokenId)
    {
        // Gas optimization: Cache immutable values to avoid multiple SLOAD operations
        uint256 _ticketPrice = ticketPrice;
        uint256 _maxSupply = maxSupply;

        // Check for zero payment (gas optimized: single comparison)
        if (msg.value != _ticketPrice) {
            revert IncorrectPayment(msg.value, _ticketPrice);
        }

        // Check if event is cancelled (single SLOAD)
        if (cancelled) {
            revert EventIsCancelled();
        }

        // Gas optimization: Use unchecked increment for token ID
        uint256 currentId = _currentTokenId;
        if (currentId >= _maxSupply) {
            revert EventSoldOut();
        }

        unchecked {
            tokenId = ++currentId;
            _currentTokenId = currentId;
            _totalSupply++;
        }

        // Mint the NFT to the buyer
        _safeMint(msg.sender, tokenId);

        // Record the original purchase price (always face value for primary sales)
        lastPricePaid[tokenId] = _ticketPrice;

        // Emit event for primary sale
        emit TicketMinted(tokenId, msg.sender, _ticketPrice);

        return tokenId;
    }

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
    function resaleTicket(
        uint256 tokenId,
        uint256 price
    ) external payable override nonReentrant {
        // Gas optimization: Early validation with single comparison
        if (msg.value != price || price == 0) {
            revert IncorrectPayment(msg.value, price);
        }

        // Check if event is cancelled (single SLOAD)
        if (cancelled) {
            revert EventIsCancelled();
        }

        // Verify ticket exists and get current owner
        address currentOwner = _ownerOf(tokenId);
        if (currentOwner == address(0)) {
            revert TicketNotFound();
        }

        // Verify caller is not the current owner (they are the buyer)
        if (msg.sender == currentOwner) {
            revert CannotBuyOwnTicket();
        }

        // Verify ticket hasn't been checked in (single SLOAD)
        if (checkedIn[tokenId]) {
            revert TicketAlreadyUsed();
        }

        // Gas optimization: Cache immutable values
        uint256 _ticketPrice = ticketPrice;
        uint256 _maxResalePercent = maxResalePercent;
        uint256 _organizerFeePercent = organizerFeePercent;
        address _organizer = organizer;

        // Calculate maximum allowed resale price
        uint256 maxPrice = VeriTixTypes.calculateMaxResalePrice(
            _ticketPrice,
            _maxResalePercent
        );

        // Verify price doesn't exceed cap
        if (price > maxPrice) {
            revert ExceedsResaleCap(price, maxPrice);
        }

        // Calculate organizer fee
        uint256 organizerFee = VeriTixTypes.calculateOrganizerFee(
            price,
            _organizerFeePercent
        );

        // Gas optimization: Calculate seller proceeds once
        uint256 sellerProceeds;
        unchecked {
            sellerProceeds = price - organizerFee;
        }

        // Temporarily allow transfer for resale mechanism
        _allowTransfer = true;

        // Transfer the NFT from seller to buyer
        _transfer(currentOwner, msg.sender, tokenId);

        // Disable transfers again
        _allowTransfer = false;

        // Update the last price paid for this ticket
        lastPricePaid[tokenId] = price;

        // Transfer funds to seller (CEI pattern - effects before interactions)
        if (sellerProceeds > 0) {
            (bool sellerSuccess, ) = payable(currentOwner).call{
                value: sellerProceeds
            }("");
            if (!sellerSuccess) {
                revert RefundFailed();
            }
        }

        // Transfer organizer fee (if any)
        if (organizerFee > 0) {
            (bool organizerSuccess, ) = payable(_organizer).call{
                value: organizerFee
            }("");
            if (!organizerSuccess) {
                revert RefundFailed();
            }
        }

        // Emit resale event
        emit TicketResold(
            tokenId,
            currentOwner,
            msg.sender,
            price,
            organizerFee
        );
    }

    /**
     * @dev Request a refund for a ticket (always at face value)
     * @param tokenId The ID of the ticket to refund
     *
     * Requirements:
     * - Caller must own the ticket
     * - Ticket must not be checked in
     * - Event must not be cancelled (use cancelRefund for cancelled events)
     */
    function refund(uint256 tokenId) external override nonReentrant {
        // Verify ticket exists and get owner
        address ticketOwner = _ownerOf(tokenId);
        if (ticketOwner != msg.sender) {
            revert NotTicketOwner();
        }

        // Verify ticket hasn't been checked in (single SLOAD)
        if (checkedIn[tokenId]) {
            revert TicketAlreadyUsed();
        }

        // Verify event hasn't been cancelled (single SLOAD)
        if (cancelled) {
            revert EventIsCancelled();
        }

        // Gas optimization: Cache immutable value
        uint256 refundAmount = ticketPrice;

        // Check contract has sufficient balance for refund
        if (address(this).balance < refundAmount) {
            revert InsufficientContractBalance(
                refundAmount,
                address(this).balance
            );
        }

        // Burn the ticket (CEI pattern - effects before interactions)
        _burn(tokenId);

        // Gas optimization: Use unchecked decrement
        unchecked {
            _totalSupply--;
        }

        // Clear the price tracking for this token (gas optimization: single SSTORE to zero)
        delete lastPricePaid[tokenId];
        delete checkedIn[tokenId];

        // Transfer refund to ticket holder (interactions last)
        (bool success, ) = payable(ticketOwner).call{value: refundAmount}("");
        if (!success) {
            revert RefundFailed();
        }

        // Emit refund event
        emit TicketRefunded(tokenId, ticketOwner, refundAmount);
    }

    /**
     * @dev Request a refund after event cancellation
     * @param tokenId The ID of the ticket to refund
     *
     * Requirements:
     * - Event must be cancelled
     * - Caller must own the ticket
     */
    function cancelRefund(uint256 tokenId) external override nonReentrant {
        // Verify event has been cancelled (single SLOAD)
        if (!cancelled) {
            revert EventNotCancelled();
        }

        // Verify ticket exists and get owner
        address ticketOwner = _ownerOf(tokenId);
        if (ticketOwner != msg.sender) {
            revert NotTicketOwner();
        }

        // Gas optimization: Cache immutable value
        uint256 refundAmount = ticketPrice;

        // Check contract has sufficient balance for refund
        if (address(this).balance < refundAmount) {
            revert InsufficientContractBalance(
                refundAmount,
                address(this).balance
            );
        }

        // Burn the ticket (CEI pattern - effects before interactions)
        _burn(tokenId);

        // Gas optimization: Use unchecked decrement
        unchecked {
            _totalSupply--;
        }

        // Clear the price tracking for this token (gas optimization: single SSTORE to zero)
        delete lastPricePaid[tokenId];
        delete checkedIn[tokenId];

        // Transfer refund to ticket holder (interactions last)
        (bool success, ) = payable(ticketOwner).call{value: refundAmount}("");
        if (!success) {
            revert RefundFailed();
        }

        // Emit refund event
        emit TicketRefunded(tokenId, ticketOwner, refundAmount);
    }

    /**
     * @dev Check in a ticket at the venue (organizer only)
     * @param tokenId The ID of the ticket to check in
     *
     * Requirements:
     * - Caller must be the event organizer
     * - Ticket must exist and not be already checked in
     */
    function checkIn(uint256 tokenId) external override onlyOwner {
        // Validate token ID range
        if (tokenId == 0 || tokenId > _currentTokenId) {
            revert InvalidTokenId(tokenId);
        }

        // Verify ticket exists and get owner
        address ticketOwner = _ownerOf(tokenId);
        if (ticketOwner == address(0)) {
            revert TicketNotFound();
        }

        // Verify ticket hasn't been checked in already
        if (checkedIn[tokenId]) {
            revert TicketAlreadyUsed();
        }

        // Mark ticket as checked in
        checkedIn[tokenId] = true;

        // Emit check-in event
        emit TicketCheckedIn(tokenId, ticketOwner);
    }

    /**
     * @dev Cancel the event (organizer only, irreversible)
     * @param reason The reason for cancellation
     *
     * Requirements:
     * - Caller must be the event organizer
     * - Event must not already be cancelled
     */
    function cancelEvent(string calldata reason) external override onlyOwner {
        // Validate cancellation reason
        if (bytes(reason).length == 0) {
            revert EmptyCancellationReason();
        }

        // Verify event hasn't already been cancelled
        if (cancelled) {
            revert EventAlreadyCancelled();
        }

        // Set cancelled state (irreversible)
        cancelled = true;

        // Emit cancellation event
        emit EventCancelled(reason);
    }

    function setBaseURI(
        string calldata newBaseURI
    ) external override onlyOwner {
        // Validate new base URI
        if (bytes(newBaseURI).length == 0) {
            revert EmptyBaseURI();
        }

        // Check if URI is actually changing
        if (keccak256(bytes(newBaseURI)) == keccak256(bytes(_baseTokenURI))) {
            revert BaseURIUnchanged();
        }

        // Update base URI
        _baseTokenURI = newBaseURI;
    }
}
