// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixEvent.sol";
import "../src/VeriTixFactory.sol";
import "../src/libraries/VeriTixTypes.sol";
import "../src/interfaces/IVeriTixEvent.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title NFTStandardsComplianceTest
 * @dev Comprehensive test suite for ERC721 compliance and marketplace compatibility
 * @notice Tests all aspects of NFT standards compliance including OpenSea integration
 */
contract NFTStandardsComplianceTest is Test {
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    address public owner = address(0x1);
    address public organizer = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public marketplace = address(0x5);
    
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 1000;
    string public constant EVENT_NAME = "Test Concert 2024";
    string public constant EVENT_SYMBOL = "TC24";
    string public constant BASE_URI = "https://api.veritix.com/metadata/";
    
    // ERC721 Interface IDs
    bytes4 private constant INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
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
        vm.deal(marketplace, 10 ether);
    }
    
    // ============ ERC165 INTERFACE SUPPORT TESTS ============
    
    function test_ERC165_SupportsInterface() public {
        // Test ERC165 support
        assertTrue(eventContract.supportsInterface(INTERFACE_ID_ERC165));
        
        // Test ERC721 support
        assertTrue(eventContract.supportsInterface(INTERFACE_ID_ERC721));
        
        // Test ERC721Metadata support
        assertTrue(eventContract.supportsInterface(INTERFACE_ID_ERC721_METADATA));
        
        // Test custom interface support
        assertTrue(eventContract.supportsInterface(type(IVeriTixEvent).interfaceId));
        
        // Test unsupported interface
        assertFalse(eventContract.supportsInterface(0x12345678));
    }
    
    function test_ERC165_InterfaceDetection() public {
        // Verify interface detection works correctly
        IERC165 erc165 = IERC165(address(eventContract));
        assertTrue(erc165.supportsInterface(type(IERC165).interfaceId));
        assertTrue(erc165.supportsInterface(type(IERC721).interfaceId));
        assertTrue(erc165.supportsInterface(type(IERC721Metadata).interfaceId));
    }
    
    // ============ ERC721 CORE FUNCTIONALITY TESTS ============
    
    function test_ERC721_BasicFunctionality() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test balanceOf
        assertEq(eventContract.balanceOf(user1), 1);
        assertEq(eventContract.balanceOf(user2), 0);
        
        // Test ownerOf
        assertEq(eventContract.ownerOf(tokenId), user1);
        
        // Test totalSupply (if implemented)
        assertEq(eventContract.totalSupply(), 1);
    }
    
    function test_ERC721_TransferRestrictions() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test that direct transfers are blocked
        vm.prank(user1);
        vm.expectRevert(IVeriTixEvent.TransfersDisabled.selector);
        eventContract.transferFrom(user1, user2, tokenId);
        
        // Test that safeTransferFrom is also blocked
        vm.prank(user1);
        vm.expectRevert(IVeriTixEvent.TransfersDisabled.selector);
        eventContract.safeTransferFrom(user1, user2, tokenId);
    }
    
    function test_ERC721_ApprovalMechanism() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test approve function
        vm.prank(user1);
        eventContract.approve(user2, tokenId);
        assertEq(eventContract.getApproved(tokenId), user2);
        
        // Test that approved user still can't transfer due to restrictions
        vm.prank(user2);
        vm.expectRevert(IVeriTixEvent.TransfersDisabled.selector);
        eventContract.transferFrom(user1, user2, tokenId);
    }
    
    function test_ERC721_ApprovalForAll() public {
        // Test setApprovalForAll
        vm.prank(user1);
        eventContract.setApprovalForAll(marketplace, true);
        assertTrue(eventContract.isApprovedForAll(user1, marketplace));
        
        // Test revoking approval
        vm.prank(user1);
        eventContract.setApprovalForAll(marketplace, false);
        assertFalse(eventContract.isApprovedForAll(user1, marketplace));
    }
    
    // ============ ERC721 METADATA TESTS ============
    
    function test_ERC721Metadata_BasicInfo() public {
        // Test name and symbol
        assertEq(eventContract.name(), EVENT_NAME);
        assertEq(eventContract.symbol(), EVENT_SYMBOL);
    }
    
    function test_ERC721Metadata_TokenURI() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test tokenURI
        string memory expectedURI = string(abi.encodePacked(BASE_URI, "1"));
        assertEq(eventContract.tokenURI(tokenId), expectedURI);
    }
    
    function test_ERC721Metadata_TokenURIForNonexistentToken() public {
        // Test tokenURI for non-existent token
        vm.expectRevert();
        eventContract.tokenURI(999);
    }
    
    function test_ERC721Metadata_BaseURIFunctionality() public {
        // Test baseURI function
        assertEq(eventContract.baseURI(), BASE_URI);
        
        // Test updating base URI (organizer only)
        string memory newBaseURI = "https://new-api.veritix.com/metadata/";
        vm.prank(organizer);
        eventContract.setBaseURI(newBaseURI);
        assertEq(eventContract.baseURI(), newBaseURI);
        
        // Verify tokenURI updates with new base URI
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        string memory expectedURI = string(abi.encodePacked(newBaseURI, "1"));
        assertEq(eventContract.tokenURI(tokenId), expectedURI);
    }
    
    // ============ MARKETPLACE COMPATIBILITY TESTS ============
    
    function test_MarketplaceCompatibility_OpenSeaStandards() public {
        // Mint a ticket for testing
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test that contract implements required interfaces for OpenSea
        assertTrue(eventContract.supportsInterface(type(IERC721).interfaceId));
        assertTrue(eventContract.supportsInterface(type(IERC721Metadata).interfaceId));
        
        // Test metadata structure compatibility
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify metadata contains required fields for marketplaces
        assertEq(metadata.tokenId, tokenId);
        assertEq(metadata.eventName, EVENT_NAME);
        assertEq(metadata.eventSymbol, EVENT_SYMBOL);
        assertEq(metadata.organizer, organizer);
        assertEq(metadata.owner, user1);
        assertFalse(metadata.checkedIn);
        assertFalse(metadata.cancelled);
        assertTrue(bytes(metadata.tokenURI).length > 0);
    }
    
    function test_MarketplaceCompatibility_CollectionMetadata() public {
        // Test collection-level metadata for marketplace integration
        VeriTixTypes.CollectionMetadata memory collection = eventContract.getCollectionMetadata();
        
        // Verify collection metadata structure
        assertEq(collection.name, EVENT_NAME);
        assertEq(collection.symbol, EVENT_SYMBOL);
        assertEq(collection.organizer, organizer);
        assertEq(collection.maxSupply, MAX_SUPPLY);
        assertEq(collection.ticketPrice, TICKET_PRICE);
        assertEq(collection.contractAddress, address(eventContract));
        assertTrue(bytes(collection.description).length > 0);
        assertTrue(bytes(collection.baseURI).length > 0);
    }
    
    function test_MarketplaceCompatibility_ApprovalWorkflow() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test marketplace approval workflow
        vm.prank(user1);
        eventContract.setApprovalForAll(marketplace, true);
        
        // Verify marketplace can query approval status
        assertTrue(eventContract.isApprovedForAll(user1, marketplace));
        
        // Test individual token approval
        vm.prank(user1);
        eventContract.approve(marketplace, tokenId);
        assertEq(eventContract.getApproved(tokenId), marketplace);
    }
    
    // ============ CONTROLLED RESALE COMPATIBILITY TESTS ============
    
    function test_ControlledResale_MarketplaceIntegration() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test that resale mechanism works with marketplace approval
        vm.prank(user1);
        eventContract.setApprovalForAll(marketplace, true);
        
        // Calculate resale price within limits
        uint256 maxResalePrice = eventContract.getMaxResalePrice(tokenId);
        uint256 resalePrice = TICKET_PRICE + (TICKET_PRICE / 10); // 110% of face value
        
        // Verify resale price is within limits
        assertLe(resalePrice, maxResalePrice);
        
        // Test controlled resale mechanism
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        // Verify ownership transfer
        assertEq(eventContract.ownerOf(tokenId), user2);
        assertEq(eventContract.balanceOf(user1), 0);
        assertEq(eventContract.balanceOf(user2), 1);
    }
    
    function test_ControlledResale_PricingCompliance() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test maximum resale price calculation
        uint256 maxResalePrice = eventContract.getMaxResalePrice(tokenId);
        uint256 expectedMaxPrice = (TICKET_PRICE * 110) / 100; // 110% configured in setUp
        assertEq(maxResalePrice, expectedMaxPrice);
        
        // Test that excessive pricing is rejected
        uint256 excessivePrice = maxResalePrice + 1 wei;
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.ExceedsResaleCap.selector, excessivePrice, maxResalePrice));
        eventContract.resaleTicket{value: excessivePrice}(tokenId, excessivePrice);
    }
    
    // ============ TRANSFER AND APPROVAL EDGE CASES ============
    
    function test_TransferRestrictions_EdgeCases() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test transfer to zero address is blocked (OpenZeppelin may have its own check)
        vm.prank(user1);
        vm.expectRevert(); // Generic revert since OpenZeppelin might check zero address first
        eventContract.transferFrom(user1, address(0), tokenId);
        
        // Test self-transfer is blocked
        vm.prank(user1);
        vm.expectRevert(IVeriTixEvent.TransfersDisabled.selector);
        eventContract.transferFrom(user1, user1, tokenId);
    }
    
    function test_ApprovalEdgeCases() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test approving zero address
        vm.prank(user1);
        eventContract.approve(address(0), tokenId);
        assertEq(eventContract.getApproved(tokenId), address(0));
        
        // Test approving self
        vm.prank(user1);
        eventContract.approve(user1, tokenId);
        assertEq(eventContract.getApproved(tokenId), user1);
    }
    
    // ============ BURN FUNCTIONALITY TESTS ============
    
    function test_BurnFunctionality_RefundScenario() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Verify initial state
        assertEq(eventContract.ownerOf(tokenId), user1);
        assertEq(eventContract.totalSupply(), 1);
        
        // Process refund (which burns the token)
        vm.prank(user1);
        eventContract.refund(tokenId);
        
        // Verify token is burned
        vm.expectRevert();
        eventContract.ownerOf(tokenId);
        
        // Verify supply is decremented
        assertEq(eventContract.totalSupply(), 0);
        
        // Verify balance is updated
        assertEq(eventContract.balanceOf(user1), 0);
    }
    
    // ============ MARKETPLACE METADATA STANDARDS ============
    
    function test_MetadataStandards_JSONStructure() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Get comprehensive metadata
        VeriTixTypes.TicketMetadata memory metadata = eventContract.getTicketMetadata(tokenId);
        
        // Verify all required fields are present and valid
        assertTrue(metadata.tokenId > 0);
        assertTrue(bytes(metadata.eventName).length > 0);
        assertTrue(bytes(metadata.eventSymbol).length > 0);
        assertTrue(metadata.organizer != address(0));
        assertTrue(metadata.ticketPrice > 0);
        assertTrue(metadata.maxResalePrice >= metadata.ticketPrice);
        assertTrue(metadata.owner != address(0));
        assertTrue(bytes(metadata.tokenURI).length > 0);
        
        // Verify pricing relationships
        assertEq(metadata.ticketPrice, TICKET_PRICE);
        assertEq(metadata.lastPricePaid, TICKET_PRICE);
        assertGe(metadata.maxResalePrice, metadata.ticketPrice);
    }
    
    function test_MetadataStandards_CollectionInfo() public {
        // Get collection metadata
        VeriTixTypes.CollectionMetadata memory collection = eventContract.getCollectionMetadata();
        
        // Verify collection-level information for marketplace display
        assertTrue(bytes(collection.name).length > 0);
        assertTrue(bytes(collection.symbol).length > 0);
        assertTrue(bytes(collection.description).length > 0);
        assertTrue(collection.organizer != address(0));
        assertTrue(collection.maxSupply > 0);
        assertTrue(collection.ticketPrice > 0);
        assertTrue(collection.contractAddress != address(0));
        assertTrue(bytes(collection.baseURI).length > 0);
        
        // Verify anti-scalping information is exposed
        assertGe(collection.maxResalePercent, 100);
        assertLe(collection.organizerFeePercent, 50);
    }
    
    // ============ INTEGRATION WITH EXTERNAL CONTRACTS ============
    
    function test_ExternalContractIntegration_ERC721Receiver() public {
        // Deploy a mock ERC721 receiver contract
        MockERC721Receiver receiver = new MockERC721Receiver();
        
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test that safeTransferFrom would work with proper receiver (if transfers were enabled)
        // Note: This tests the interface compatibility, actual transfer will fail due to restrictions
        vm.prank(user1);
        vm.expectRevert(IVeriTixEvent.TransfersDisabled.selector);
        eventContract.safeTransferFrom(user1, address(receiver), tokenId);
    }
    
    // ============ GAS OPTIMIZATION VERIFICATION ============
    
    function test_GasOptimization_BatchOperations() public {
        // Test gas efficiency of multiple mints
        uint256 gasStart = gasleft();
        
        vm.startPrank(user1);
        for (uint256 i = 0; i < 5; i++) {
            eventContract.mintTicket{value: TICKET_PRICE}();
        }
        vm.stopPrank();
        
        uint256 gasUsed = gasStart - gasleft();
        
        // Verify reasonable gas usage (this is a baseline test)
        // In practice, you'd compare against benchmarks
        assertTrue(gasUsed > 0);
        console.log("Gas used for 5 mints:", gasUsed);
    }
    
    // ============ ERROR HANDLING TESTS ============
    
    function test_ErrorHandling_InvalidTokenOperations() public {
        // Test operations on non-existent tokens
        vm.expectRevert();
        eventContract.ownerOf(999);
        
        vm.expectRevert();
        eventContract.getApproved(999);
        
        vm.expectRevert();
        eventContract.tokenURI(999);
        
        vm.expectRevert();
        eventContract.getTicketMetadata(999);
    }
    
    function test_ErrorHandling_UnauthorizedOperations() public {
        // Mint a ticket
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test unauthorized approval
        vm.prank(user2);
        vm.expectRevert();
        eventContract.approve(user2, tokenId);
        
        // Test unauthorized transfer attempt
        vm.prank(user2);
        vm.expectRevert();
        eventContract.transferFrom(user1, user2, tokenId);
    }
}

/**
 * @dev Mock ERC721 receiver for testing safe transfer compatibility
 */
contract MockERC721Receiver is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}