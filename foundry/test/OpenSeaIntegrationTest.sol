// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixEvent.sol";
import "../src/VeriTixFactory.sol";
import "../src/libraries/VeriTixTypes.sol";
import "../src/interfaces/IVeriTixEvent.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title OpenSeaIntegrationTest
 * @dev Comprehensive test suite for OpenSea marketplace integration
 * @notice Tests all OpenSea-specific requirements and compatibility features
 */
contract OpenSeaIntegrationTest is Test {
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    address public owner = address(0x1);
    address public organizer = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public openSeaProxy = address(0x5);
    
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 1000;
    string public constant EVENT_NAME = "VeriTix Concert 2024";
    string public constant EVENT_SYMBOL = "VTIX24";
    string public constant BASE_URI = "https://api.veritix.com/metadata/";
    
    // OpenSea specific constants
    address public constant OPENSEA_CONDUIT = 0x1E0049783F008A0085193E00003D00cd54003c71;
    bytes32 public constant OPENSEA_DOMAIN_SEPARATOR = keccak256("OpenSea");
    
    function setUp() public {
        vm.startPrank(owner);
        factory = new VeriTixFactory(owner);
        vm.stopPrank();
        
        // Create test event
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: EVENT_NAME,
            symbol: EVENT_SYMBOL,
            maxSupply: MAX_SUPPLY,
            ticketPrice: TICKET_PRICE,
            baseURI: BASE_URI,
            maxResalePercent: 110,
            organizerFeePercent: 5,
            organizer: organizer
        });
        
        vm.prank(organizer);
        address eventAddress = factory.createEvent(params);
        eventContract = VeriTixEvent(eventAddress);
        
        // Fund test accounts
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(openSeaProxy, 10 ether);
    }
    
    // ============ OPENSEA INTERFACE REQUIREMENTS ============
    
    function test_OpenSea_RequiredInterfaces() public {
        // Test ERC165 support (required by OpenSea)
        assertTrue(eventContract.supportsInterface(type(IERC165).interfaceId));
        
        // Test ERC721 support (required by OpenSea)
        assertTrue(eventContract.supportsInterface(type(IERC721).interfaceId));
        
        // Test ERC721Metadata support (required by OpenSea)
        assertTrue(eventContract.supportsInterface(type(IERC721Metadata).interfaceId));
        
        // Verify interface detection works correctly
        IERC165 erc165Contract = IERC165(address(eventContract));
        assertTrue(erc165Contract.supportsInterface(type(IERC721).interfaceId));
    }
    
    function test_OpenSea_MetadataRequirements() public {
        // Mint a ticket for testing
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test name() function (required by OpenSea)
        string memory name = eventContract.name();
        assertEq(name, EVENT_NAME);
        assertTrue(bytes(name).length > 0);
        
        // Test symbol() function (required by OpenSea)
        string memory symbol = eventContract.symbol();
        assertEq(symbol, EVENT_SYMBOL);
        assertTrue(bytes(symbol).length > 0);
        
        // Test tokenURI() function (required by OpenSea)
        string memory tokenURI = eventContract.tokenURI(tokenId);
        assertTrue(bytes(tokenURI).length > 0);
        
        // Verify tokenURI format matches OpenSea expectations
        string memory expectedURI = string(abi.encodePacked(BASE_URI, "1"));
        assertEq(tokenURI, expectedURI);
    }
    
    // ============ OPENSEA APPROVAL MECHANISMS ============
    
    function test_OpenSea_ApprovalWorkflow() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test individual token approval (OpenSea standard workflow)
        vm.prank(user1);
        eventContract.approve(openSeaProxy, tokenId);
        
        // Verify approval was set
        assertEq(eventContract.getApproved(tokenId), openSeaProxy);
        
        // Test approval for all (OpenSea batch operations)
        vm.prank(user1);
        eventContract.setApprovalForAll(openSeaProxy, true);
        
        // Verify approval for all was set
        assertTrue(eventContract.isApprovedForAll(user1, openSeaProxy));
        
        // Test revoking approval for all
        vm.prank(user1);
        eventContract.setApprovalForAll(openSeaProxy, false);
        
        // Verify approval was revoked
        assertFalse(eventContract.isApprovedForAll(user1, openSeaProxy));
    }
    
    function test_OpenSea_ApprovalEvents() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test that Approval event is emitted (required by OpenSea)
        vm.expectEmit(true, true, true, false);
        emit Approval(user1, openSeaProxy, tokenId);
        
        vm.prank(user1);
        eventContract.approve(openSeaProxy, tokenId);
        
        // Test that ApprovalForAll event is emitted
        vm.expectEmit(true, true, false, false);
        emit ApprovalForAll(user1, openSeaProxy, true);
        
        vm.prank(user1);
        eventContract.setApprovalForAll(openSeaProxy, true);
    }
    
    // ============ OPENSEA TRANSFER COMPATIBILITY ============
    
    function test_OpenSea_TransferRestrictions() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Approve OpenSea proxy
        vm.prank(user1);
        eventContract.setApprovalForAll(openSeaProxy, true);
        
        // Test that OpenSea proxy cannot directly transfer due to VeriTix restrictions
        vm.prank(openSeaProxy);
        vm.expectRevert(IVeriTixEvent.TransfersDisabled.selector);
        eventContract.transferFrom(user1, user2, tokenId);
        
        // Test that safeTransferFrom is also blocked
        vm.prank(openSeaProxy);
        vm.expectRevert(IVeriTixEvent.TransfersDisabled.selector);
        eventContract.safeTransferFrom(user1, user2, tokenId);
    }
    
    function test_OpenSea_ControlledResaleIntegration() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test that controlled resale mechanism works for OpenSea integration
        uint256 resalePrice = TICKET_PRICE + (TICKET_PRICE / 10); // 110% of face value
        
        // Simulate OpenSea facilitating the resale through VeriTix mechanism
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        // Verify ownership transfer occurred
        assertEq(eventContract.ownerOf(tokenId), user2);
        
        // Verify Transfer event was emitted (required by OpenSea)
        // Note: This would be tested with vm.expectEmit in practice
    }
    
    // ============ OPENSEA METADATA STANDARDS ============
    
    function test_OpenSea_MetadataStructure() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Get VeriTix metadata structure
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify metadata contains fields expected by OpenSea
        assertTrue(metadata.tokenId > 0);
        assertTrue(bytes(metadata.eventName).length > 0);
        assertTrue(bytes(metadata.eventSymbol).length > 0);
        assertTrue(metadata.owner != address(0));
        assertTrue(bytes(metadata.tokenURI).length > 0);
        
        // Verify pricing information for OpenSea display
        assertEq(metadata.ticketPrice, TICKET_PRICE);
        assertEq(metadata.lastPricePaid, TICKET_PRICE);
        assertGe(metadata.maxResalePrice, metadata.ticketPrice);
    }
    
    function test_OpenSea_CollectionMetadata() public {
        // Get collection metadata for OpenSea collection page
        VeriTixTypes.CollectionMetadata memory collection = eventContract.getCollectionMetadata();
        
        // Verify collection information for OpenSea
        assertEq(collection.name, EVENT_NAME);
        assertEq(collection.symbol, EVENT_SYMBOL);
        assertTrue(bytes(collection.description).length > 0);
        assertEq(collection.organizer, organizer);
        assertEq(collection.maxSupply, MAX_SUPPLY);
        assertEq(collection.contractAddress, address(eventContract));
        
        // Verify anti-scalping information is available
        assertGe(collection.maxResalePercent, 100);
        assertLe(collection.organizerFeePercent, 50);
    }
    
    // ============ OPENSEA BATCH OPERATIONS ============
    
    function test_OpenSea_BatchApprovals() public {
        // Mint multiple tickets
        vm.startPrank(user1);
        uint256 tokenId1 = eventContract.mintTicket{value: TICKET_PRICE}();
        uint256 tokenId2 = eventContract.mintTicket{value: TICKET_PRICE}();
        uint256 tokenId3 = eventContract.mintTicket{value: TICKET_PRICE}();
        vm.stopPrank();
        
        // Test batch approval using setApprovalForAll (OpenSea standard)
        vm.prank(user1);
        eventContract.setApprovalForAll(openSeaProxy, true);
        
        // Verify all tokens are approved
        assertTrue(eventContract.isApprovedForAll(user1, openSeaProxy));
        
        // Test individual approvals still work
        vm.prank(user1);
        eventContract.approve(user2, tokenId1);
        assertEq(eventContract.getApproved(tokenId1), user2);
    }
    
    function test_OpenSea_BalanceQueries() public {
        // Test initial balance
        assertEq(eventContract.balanceOf(user1), 0);
        
        // Mint tickets and verify balance updates
        vm.startPrank(user1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        assertEq(eventContract.balanceOf(user1), 1);
        
        eventContract.mintTicket{value: TICKET_PRICE}();
        assertEq(eventContract.balanceOf(user1), 2);
        vm.stopPrank();
        
        // Test balance after transfer (through resale)
        uint256 resalePrice = TICKET_PRICE + (TICKET_PRICE / 10);
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(1, resalePrice);
        
        // Verify balances updated correctly
        assertEq(eventContract.balanceOf(user1), 1);
        assertEq(eventContract.balanceOf(user2), 1);
    }
    
    // ============ OPENSEA ERROR HANDLING ============
    
    function test_OpenSea_ErrorHandling() public {
        // Test queries for non-existent tokens (OpenSea compatibility)
        vm.expectRevert();
        eventContract.ownerOf(999);
        
        vm.expectRevert();
        eventContract.getApproved(999);
        
        vm.expectRevert();
        eventContract.tokenURI(999);
        
        // Test balance query for zero address
        vm.expectRevert();
        eventContract.balanceOf(address(0));
    }
    
    // ============ OPENSEA GAS OPTIMIZATION ============
    
    function test_OpenSea_GasEfficiency() public {
        // Test gas efficiency for OpenSea operations
        uint256 gasStart;
        uint256 gasUsed;
        
        // Test minting gas cost
        gasStart = gasleft();
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        gasUsed = gasStart - gasleft();
        
        console.log("Mint gas cost:", gasUsed);
        assertTrue(gasUsed < 200000); // Reasonable gas limit for minting
        
        // Test approval gas cost
        gasStart = gasleft();
        vm.prank(user1);
        eventContract.approve(openSeaProxy, tokenId);
        gasUsed = gasStart - gasleft();
        
        console.log("Approval gas cost:", gasUsed);
        assertTrue(gasUsed < 50000); // Reasonable gas limit for approval
        
        // Test setApprovalForAll gas cost
        gasStart = gasleft();
        vm.prank(user1);
        eventContract.setApprovalForAll(openSeaProxy, true);
        gasUsed = gasStart - gasleft();
        
        console.log("SetApprovalForAll gas cost:", gasUsed);
        assertTrue(gasUsed < 50000); // Reasonable gas limit for batch approval
    }
    
    // ============ OPENSEA INTEGRATION SCENARIOS ============
    
    function test_OpenSea_FullIntegrationScenario() public {
        // Scenario: User lists ticket on OpenSea, another user buys through VeriTix resale
        
        // Step 1: User mints ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Step 2: User approves OpenSea for listing
        vm.prank(user1);
        eventContract.setApprovalForAll(openSeaProxy, true);
        
        // Step 3: OpenSea displays ticket with metadata
        string memory tokenURI = eventContract.tokenURI(tokenId);
        assertTrue(bytes(tokenURI).length > 0);
        
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        assertEq(metadata.owner, user1);
        
        // Step 4: Buyer purchases through VeriTix resale mechanism
        uint256 resalePrice = TICKET_PRICE + (TICKET_PRICE / 10);
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        // Step 5: Verify ownership transfer and OpenSea compatibility
        assertEq(eventContract.ownerOf(tokenId), user2);
        assertEq(eventContract.balanceOf(user1), 0);
        assertEq(eventContract.balanceOf(user2), 1);
        
        // Step 6: Verify metadata updates for new owner
        VeriTixTypes.TicketMetadata memory updatedMetadata = eventContract.getTicketMetadata(tokenId);
        assertEq(updatedMetadata.owner, user2);
        assertEq(updatedMetadata.lastPricePaid, resalePrice);
    }
    
    function test_OpenSea_CollectionDiscovery() public {
        // Test collection-level information for OpenSea discovery
        
        // Mint some tickets to populate collection
        vm.startPrank(user1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        eventContract.mintTicket{value: TICKET_PRICE}();
        vm.stopPrank();
        
        // Get collection metadata
        VeriTixTypes.CollectionMetadata memory collection = eventContract.getCollectionMetadata();
        
        // Verify collection is discoverable with proper information
        assertTrue(bytes(collection.name).length > 0);
        assertTrue(bytes(collection.symbol).length > 0);
        assertTrue(bytes(collection.description).length > 0);
        assertEq(collection.totalSupply, 2);
        assertEq(collection.maxSupply, MAX_SUPPLY);
        
        // Verify contract address for OpenSea verification
        assertEq(collection.contractAddress, address(eventContract));
    }
    
    // ============ OPENSEA SPECIAL FEATURES ============
    
    function test_OpenSea_CustomMetadataFields() public {
        // Test that VeriTix-specific metadata is available for OpenSea display
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify anti-scalping information is available
        assertTrue(metadata.maxResalePrice > metadata.ticketPrice);
        assertEq(metadata.ticketPrice, TICKET_PRICE);
        
        // Verify event-specific information
        assertEq(metadata.eventName, EVENT_NAME);
        assertEq(metadata.organizer, organizer);
        assertFalse(metadata.checkedIn);
        assertFalse(metadata.cancelled);
    }
    
    // Events for testing
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}