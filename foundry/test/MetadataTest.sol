// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixEvent.sol";
import "../src/VeriTixFactory.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title MetadataTest
 * @dev Comprehensive tests for metadata and marketplace integration features
 * @notice Tests tokenURI functionality, metadata structures, and marketplace compatibility
 */
contract MetadataTest is Test {
    // ============ TEST CONTRACTS ============

    VeriTixFactory public factory;
    VeriTixEvent public eventContract;

    // ============ TEST CONSTANTS ============

    string constant EVENT_NAME = "VeriTix Concert 2024";
    string constant EVENT_SYMBOL = "VCON24";
    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant TICKET_PRICE = 0.1 ether;
    address constant ORGANIZER = address(0x1234);
    string constant BASE_URI = "https://api.veritix.com/metadata/";
    uint256 constant MAX_RESALE_PERCENT = 110; // 110%
    uint256 constant ORGANIZER_FEE_PERCENT = 5; // 5%

    // ============ TEST ADDRESSES ============

    address buyer1 = address(0x1111);
    address buyer2 = address(0x2222);

    // ============ SETUP ============

    function setUp() public {
        // Deploy factory
        factory = new VeriTixFactory(address(this));
        
        // Deploy event contract
        eventContract = new VeriTixEvent(
            EVENT_NAME,
            EVENT_SYMBOL,
            MAX_SUPPLY,
            TICKET_PRICE,
            ORGANIZER,
            BASE_URI,
            MAX_RESALE_PERCENT,
            ORGANIZER_FEE_PERCENT
        );
        
        // Fund test addresses
        vm.deal(buyer1, 10 ether);
        vm.deal(buyer2, 10 ether);
    }

    // ============ TOKEN URI TESTS ============

    function test_TokenURI_ValidToken() public {
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Check tokenURI
        string memory expectedURI = string(abi.encodePacked(BASE_URI, "1"));
        assertEq(eventContract.tokenURI(tokenId), expectedURI);
    }   
 function test_TokenURI_MultipleTokens() public {
        // Mint multiple tickets
        vm.prank(buyer1);
        uint256 tokenId1 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(buyer2);
        uint256 tokenId2 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Check tokenURIs
        assertEq(eventContract.tokenURI(tokenId1), string(abi.encodePacked(BASE_URI, "1")));
        assertEq(eventContract.tokenURI(tokenId2), string(abi.encodePacked(BASE_URI, "2")));
    }
    
    function test_TokenURI_NonExistentToken() public {
        // Try to get URI for non-existent token
        vm.expectRevert();
        eventContract.tokenURI(999);
    }
    
    function test_TokenURI_EmptyBaseURI() public {
        // Deploy contract with valid base URI, then set it to empty (which should fail)
        vm.prank(ORGANIZER);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.EmptyBaseURI.selector));
        eventContract.setBaseURI("");
    }
    
    function test_BaseURI_Update() public {
        string memory newBaseURI = "https://new.veritix.com/metadata/";
        
        // Update base URI as organizer
        vm.prank(ORGANIZER);
        eventContract.setBaseURI(newBaseURI);
        
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Check updated tokenURI
        string memory expectedURI = string(abi.encodePacked(newBaseURI, "1"));
        assertEq(eventContract.tokenURI(tokenId), expectedURI);
    }

    // ============ TICKET METADATA TESTS ============

    function test_GetTicketMetadata_BasicInfo() public {
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Get metadata
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify basic information
        assertEq(metadata.tokenId, tokenId);
        assertEq(metadata.eventName, EVENT_NAME);
        assertEq(metadata.eventSymbol, EVENT_SYMBOL);
        assertEq(metadata.organizer, ORGANIZER);
        assertEq(metadata.ticketPrice, TICKET_PRICE);
        assertEq(metadata.lastPricePaid, TICKET_PRICE);
        assertEq(metadata.owner, buyer1);
        assertFalse(metadata.checkedIn);
        assertFalse(metadata.cancelled);
    } 
   function test_GetTicketMetadata_MaxResalePrice() public {
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Get metadata
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify max resale price calculation
        uint256 expectedMaxPrice = (TICKET_PRICE * MAX_RESALE_PERCENT) / 100;
        assertEq(metadata.maxResalePrice, expectedMaxPrice);
    }
    
    function test_GetTicketMetadata_AfterResale() public {
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Resale the ticket
        uint256 resalePrice = 0.105 ether; // 5% markup
        vm.prank(buyer2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        // Get metadata after resale
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify updated information
        assertEq(metadata.owner, buyer2);
        assertEq(metadata.lastPricePaid, resalePrice);
        assertEq(metadata.ticketPrice, TICKET_PRICE); // Original price unchanged
    }
    
    function test_GetTicketMetadata_AfterCheckIn() public {
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Check in the ticket
        vm.prank(ORGANIZER);
        eventContract.checkIn(tokenId);
        
        // Get metadata after check-in
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify check-in status
        assertTrue(metadata.checkedIn);
    }
    
    function test_GetTicketMetadata_CancelledEvent() public {
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Cancel the event
        vm.prank(ORGANIZER);
        eventContract.cancelEvent("Venue unavailable");
        
        // Get metadata after cancellation
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify cancellation status
        assertTrue(metadata.cancelled);
    }

    // ============ COLLECTION METADATA TESTS ============

    function test_GetCollectionMetadata_BasicInfo() public {
        // Get collection metadata
        VeriTixTypes.CollectionMetadata memory collection = eventContract.getCollectionMetadata();
        
        // Verify basic information
        assertEq(collection.name, EVENT_NAME);
        assertEq(collection.symbol, EVENT_SYMBOL);
        assertEq(collection.organizer, ORGANIZER);
        assertEq(collection.maxSupply, MAX_SUPPLY);
        assertEq(collection.ticketPrice, TICKET_PRICE);
        assertEq(collection.maxResalePercent, MAX_RESALE_PERCENT);
        assertEq(collection.organizerFeePercent, ORGANIZER_FEE_PERCENT);
        assertEq(collection.baseURI, BASE_URI);
        assertEq(collection.contractAddress, address(eventContract));
        assertFalse(collection.cancelled);
    }
    
    function test_GetCollectionMetadata_Description() public {
        // Get collection metadata
        VeriTixTypes.CollectionMetadata memory collection = eventContract.getCollectionMetadata();
        
        // Verify description format
        string memory expectedDescription = string(abi.encodePacked(
            "VeriTix Event: ", EVENT_NAME, " - Anti-scalping NFT tickets with controlled resale"
        ));
        assertEq(collection.description, expectedDescription);
    }
    
    function test_GetCollectionMetadata_SupplyTracking() public {
        // Initial state - no tickets minted
        VeriTixTypes.CollectionMetadata memory collection = eventContract.getCollectionMetadata();
        assertEq(collection.totalSupply, 0);
        
        // Mint some tickets
        vm.prank(buyer1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(buyer2);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Check updated supply
        collection = eventContract.getCollectionMetadata();
        assertEq(collection.totalSupply, 2);
    }
    
    function test_GetCollectionMetadata_AfterCancellation() public {
        // Cancel the event
        vm.prank(ORGANIZER);
        eventContract.cancelEvent("Force majeure");
        
        // Get collection metadata
        VeriTixTypes.CollectionMetadata memory collection = eventContract.getCollectionMetadata();
        
        // Verify cancellation status
        assertTrue(collection.cancelled);
    }

    // ============ MARKETPLACE INTEGRATION TESTS ============

    function test_SupportsInterface_ERC721() public {
        // Test ERC721 interface support
        assertTrue(eventContract.supportsInterface(type(IERC721).interfaceId));
    }
    
    function test_SupportsInterface_VeriTixEvent() public {
        // Test IVeriTixEvent interface support
        assertTrue(eventContract.supportsInterface(type(IVeriTixEvent).interfaceId));
    }
    
    function test_SupportsInterface_ERC165() public {
        // Test ERC165 interface support
        assertTrue(eventContract.supportsInterface(type(IERC165).interfaceId));
    }
    
    function test_MarketplaceCompatibility_TokenExists() public {
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test standard ERC721 functions used by marketplaces
        assertEq(eventContract.ownerOf(tokenId), buyer1);
        assertEq(eventContract.balanceOf(buyer1), 1);
        assertTrue(bytes(eventContract.tokenURI(tokenId)).length > 0);
        assertEq(eventContract.name(), EVENT_NAME);
        assertEq(eventContract.symbol(), EVENT_SYMBOL);
    }    
function test_MarketplaceCompatibility_TransferRestrictions() public {
        // Mint a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Approve buyer2 for transfer
        vm.prank(buyer1);
        eventContract.approve(buyer2, tokenId);
        
        // Try direct transfer (should fail)
        vm.prank(buyer2);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.TransfersDisabled.selector));
        eventContract.transferFrom(buyer1, buyer2, tokenId);
        
        // Verify approval still works (for marketplace compatibility)
        assertEq(eventContract.getApproved(tokenId), buyer2);
    }

    // ============ ERROR HANDLING TESTS ============

    function test_GetTicketMetadata_NonExistentToken() public {
        // Try to get metadata for non-existent token
        vm.expectRevert();
        eventContract.getTicketMetadata(999);
    }
    
    function test_TokenURI_BurnedToken() public {
        // Mint and then refund (burn) a ticket
        vm.prank(buyer1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(buyer1);
        eventContract.refund(tokenId);
        
        // Try to get URI for burned token
        vm.expectRevert();
        eventContract.tokenURI(tokenId);
    }

    // ============ BASE URI MANAGEMENT TESTS ============

    function test_SetBaseURI_Success() public {
        string memory newBaseURI = "https://updated.veritix.com/metadata/";
        
        vm.prank(ORGANIZER);
        eventContract.setBaseURI(newBaseURI);
        
        assertEq(eventContract.baseURI(), newBaseURI);
    }
    
    function test_SetBaseURI_UnauthorizedAccess() public {
        string memory newBaseURI = "https://malicious.com/metadata/";
        
        vm.prank(buyer1);
        vm.expectRevert();
        eventContract.setBaseURI(newBaseURI);
    }
    
    function test_SetBaseURI_EmptyURI() public {
        vm.prank(ORGANIZER);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.EmptyBaseURI.selector));
        eventContract.setBaseURI("");
    }
    
    function test_SetBaseURI_SameURI() public {
        vm.prank(ORGANIZER);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.BaseURIUnchanged.selector));
        eventContract.setBaseURI(BASE_URI);
    }

    // ============ INTEGRATION WITH FACTORY TESTS ============

    function test_FactoryDeployedEvent_MetadataConsistency() public {
        // Create event through factory
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Factory Event",
            symbol: "FACT",
            maxSupply: 500,
            ticketPrice: 0.05 ether,
            baseURI: "https://factory.veritix.com/metadata/",
            maxResalePercent: 115,
            organizerFeePercent: 3,
            organizer: ORGANIZER
        });
        
        vm.prank(ORGANIZER);
        address eventAddress = factory.createEvent(params);
        VeriTixEvent factoryEvent = VeriTixEvent(eventAddress);
        
        // Test metadata consistency
        VeriTixTypes.CollectionMetadata memory collection = factoryEvent.getCollectionMetadata();
        assertEq(collection.name, "Factory Event");
        assertEq(collection.symbol, "FACT");
        assertEq(collection.maxSupply, 500);
        assertEq(collection.ticketPrice, 0.05 ether);
        assertEq(collection.baseURI, "https://factory.veritix.com/metadata/");
    }
}