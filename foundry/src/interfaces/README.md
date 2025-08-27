# VeriTix Factory Architecture - Interfaces and Data Structures

This directory contains the core interfaces and data structures for the VeriTix factory-based ticketing system. The architecture transforms VeriTix from a monolithic contract to a factory pattern where each event gets its own dedicated ERC721 contract.

## Architecture Overview

```
VeriTixFactory (deploys) → VeriTixEvent (individual event contracts)
                        → VeriTixEvent
                        → VeriTixEvent
                        → ...
```

## Core Components

### 1. IVeriTixEvent Interface

**File**: `IVeriTixEvent.sol`

The standard interface that all individual event contracts must implement. Each event is a separate ERC721 contract with built-in anti-scalping mechanisms.

#### Key Features:
- **Primary Sales**: `mintTicket()` for face-value ticket purchases
- **Controlled Resale**: `resaleTicket()` with price caps and organizer fees
- **Refund System**: `refund()` and `cancelRefund()` always at face value
- **Venue Check-in**: `checkIn()` to mark tickets as used
- **Event Management**: `cancelEvent()` for organizer-initiated cancellations
- **Transfer Restrictions**: Blocks direct transfers, forces use of resale mechanism

#### Anti-Scalping Mechanisms:
1. **Price Caps**: Resale prices cannot exceed configured percentage of face value
2. **Organizer Fees**: Organizers receive percentage of resale transactions
3. **Transfer Blocking**: Direct transfers via `transferFrom` are disabled
4. **Face Value Refunds**: Refunds always at original price, regardless of resale markup
5. **Usage Tracking**: Checked-in tickets cannot be resold or refunded

### 2. IVeriTixFactory Interface

**File**: `IVeriTixFactory.sol`

The factory contract interface for deploying and managing individual event contracts.

#### Key Features:
- **Event Deployment**: `createEvent()` and `batchCreateEvents()`
- **Event Discovery**: `getDeployedEvents()`, `getEventsByOrganizer()`
- **Global Policies**: Platform-wide resale limits and fee structures
- **Registry Management**: Complete tracking of all deployed events
- **Analytics**: Aggregated statistics across all events

#### Global Governance:
- Maximum resale percentage limits across all events
- Default organizer fee structures
- Event creation fees and limits
- Emergency pause functionality

### 3. VeriTixTypes Library

**File**: `VeriTixTypes.sol`

Shared data structures, enums, and utility functions used across all contracts.

#### Core Data Structures:

##### EventCreationParams
Parameters required to deploy a new event contract:
```solidity
struct EventCreationParams {
    string name;                    // Event name
    string symbol;                  // Event symbol/ticker
    uint256 maxSupply;             // Maximum tickets
    uint256 ticketPrice;           // Face value price
    string baseURI;                // Metadata base URI
    uint256 maxResalePercent;      // Resale price cap
    uint256 organizerFeePercent;   // Organizer fee on resales
    address organizer;             // Event organizer address
}
```

##### EventRegistry
Factory registry entry for tracking deployed events:
```solidity
struct EventRegistry {
    address eventContract;         // Deployed contract address
    address organizer;            // Event organizer
    uint256 createdAt;           // Creation timestamp
    string eventName;            // Event name
    EventStatus status;          // Current status
    uint256 ticketPrice;        // Face value price
    uint256 maxSupply;          // Maximum tickets
}
```

##### TicketInfo
Comprehensive ticket information:
```solidity
struct TicketInfo {
    uint256 tokenId;             // NFT token ID
    address currentOwner;        // Current owner
    uint256 originalPrice;       // Original face value
    uint256 lastPricePaid;      // Most recent price paid
    TicketState state;          // Current state
    bool isCheckedIn;           // Venue usage status
    uint256 mintedAt;           // Mint timestamp
}
```

#### Enums:

##### TicketState
```solidity
enum TicketState {
    Available,    // Can be purchased
    Sold,         // Owned, can be resold/refunded
    CheckedIn,    // Used at venue, locked
    Refunded      // Burned and refunded
}
```

##### EventStatus
```solidity
enum EventStatus {
    Active,       // Tickets can be sold
    SoldOut,      // All tickets sold
    Cancelled,    // Cancelled by organizer
    Completed     // Event has occurred
}
```

#### Utility Functions:
- `calculateMaxResalePrice()`: Compute maximum allowed resale price
- `calculateOrganizerFee()`: Compute organizer fee for resales
- `validateEventParams()`: Validate event creation parameters
- `canResaleTicket()`: Check if ticket state allows resale
- `canRefundTicket()`: Check if ticket state allows refund

## Security Considerations

### Access Control
- **Factory Owner**: Can update global policies, pause operations
- **Event Organizers**: Can check in tickets, cancel events, update metadata
- **Ticket Holders**: Can resell (with restrictions) and refund tickets

### Anti-Scalping Measures
1. **On-chain Price Caps**: Maximum resale percentage enforced by smart contract
2. **Transfer Restrictions**: Direct transfers blocked, must use controlled resale
3. **Organizer Incentives**: Organizers receive fees from resales
4. **Face Value Refunds**: Removes profit motive from speculative buying

### Economic Security
- **Refund Protection**: Always at face value, prevents manipulation
- **Fee Collection**: Automated organizer fee distribution
- **Supply Limits**: Maximum tickets per event to prevent gas issues
- **Price Minimums**: Prevent spam with minimum ticket prices

## Integration Guidelines

### For Event Organizers
1. Call `factory.createEvent()` with event parameters
2. Receive dedicated event contract address
3. Use event contract for check-ins and management
4. Receive automatic fee distribution from resales

### For Ticket Buyers
1. Call `eventContract.mintTicket()` for primary purchases
2. Use `eventContract.resaleTicket()` for resales (not direct transfers)
3. Call `eventContract.refund()` if unable to attend
4. Present ticket at venue for check-in

### For Marketplaces
1. Each event appears as separate ERC721 collection
2. Must respect transfer restrictions (use resale mechanism)
3. Can display standard NFT metadata
4. Should show anti-scalping features prominently

## Constants and Limits

```solidity
uint256 public constant MAX_RESALE_PERCENTAGE = 300;      // 300% max resale
uint256 public constant MAX_ORGANIZER_FEE_PERCENT = 50;   // 50% max organizer fee
uint256 public constant MIN_TICKET_PRICE = 0.001 ether;   // Minimum ticket price
uint256 public constant MAX_TICKETS_PER_EVENT = 100000;   // Maximum event size
uint256 public constant MAX_EVENTS_PER_ORGANIZER = 1000;  // Organizer limit
```

## Error Handling

All interfaces define comprehensive custom errors for better debugging and user experience:

- `EventSoldOut()`: No more tickets available
- `IncorrectPayment()`: Wrong ETH amount sent
- `NotTicketOwner()`: Caller doesn't own the ticket
- `TicketAlreadyUsed()`: Ticket has been checked in
- `ExceedsResaleCap()`: Resale price too high
- `TransfersDisabled()`: Direct transfer attempted
- `EventCancelled()`: Event has been cancelled
- `UnauthorizedAccess()`: Insufficient permissions

## Future Extensions

The interface design allows for future enhancements:
- Dynamic pricing mechanisms
- Loyalty programs and discounts
- Multi-tier ticket types
- Integration with external identity systems
- Advanced analytics and reporting
- Cross-event functionality