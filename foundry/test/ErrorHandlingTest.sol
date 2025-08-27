// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/interfaces/IVeriTixFactory.sol";
import "../src/interfaces/IVeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title ErrorHandlingTest
 * @dev Comprehensive tests for error conditions and edge cases in VeriTix contracts
 */
contract ErrorHandlingTest is Test {
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    address public owner;
    address public organizer;
    address public user1;
    address public user2;
    
    VeriTixTypes.EventCreationParams public validParams;
    
    function setUp() public {
        owner = address(this);
        organizer = makeAddr("organizer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        factory = new VeriTixFactory(owner);
        
        validParams = VeriTixTypes.EventCreationParams({
            name: "Test Concert",
            symbol: "TC",
            maxSupply: 100,
            ticketPrice: 0.1 ether,
            baseURI: "https://api.example.com/",
            maxResalePercent: 110,
            organizerFeePercent: 5,
            organizer: organizer
        });
        
        eventContract = new VeriTixEvent(
            validParams.name,
            validParams.symbol,
            validParams.maxSupply,
            validParams.ticketPrice,
            validParams.organizer,
            validParams.baseURI,
            validParams.maxResalePercent,
            validParams.organizerFeePercent
        );
    }
    
    // ============ FACTORY ERROR TESTS ============
    
    function test_Factory_InvalidEventName_Empty() public {
        VeriTixTypes.EventCreationParams memory params = validParams;
        params.name = "";
        
        vm.expectRevert(abi.encodeWithSelector(IVeriTixFactory.InvalidEventName.selector));
        factory.createEvent(params);
    }
    
    function test_Factory_InvalidMaxSupply_Zero() public {
        VeriTixTypes.EventCreationParams memory params = validParams;
        params.maxSupply = 0;
        
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixFactory.InvalidMaxSupply.selector, 
            0, 
            VeriTixTypes.MAX_TICKETS_PER_EVENT
        ));
        factory.createEvent(params);
    }
    
    function test_Factory_TicketPriceTooLow() public {
        VeriTixTypes.EventCreationParams memory params = validParams;
        params.ticketPrice = VeriTixTypes.MIN_TICKET_PRICE - 1;
        
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixFactory.TicketPriceTooLow.selector, 
            VeriTixTypes.MIN_TICKET_PRICE - 1, 
            VeriTixTypes.MIN_TICKET_PRICE
        ));
        factory.createEvent(params);
    }
    
    function test_Factory_InvalidOrganizerAddress() public {
        VeriTixTypes.EventCreationParams memory params = validParams;
        params.organizer = address(0);
        
        vm.expectRevert(abi.encodeWithSelector(IVeriTixFactory.InvalidOrganizerAddress.selector));
        factory.createEvent(params);
    }
    
    function test_Factory_ResalePercentTooLow() public {
        VeriTixTypes.EventCreationParams memory params = validParams;
        params.maxResalePercent = 99;
        
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixFactory.ResalePercentTooLow.selector, 
            99
        ));
        factory.createEvent(params);
    }
    
    function test_Factory_FactoryPaused() public {
        factory.setPaused(true);
        
        vm.expectRevert(abi.encodeWithSelector(IVeriTixFactory.FactoryPaused.selector));
        factory.createEvent(validParams);
    }
    
    function test_Factory_EmptyBatchArray() public {
        VeriTixTypes.EventCreationParams[] memory emptyArray = new VeriTixTypes.EventCreationParams[](0);
        
        vm.expectRevert(abi.encodeWithSelector(IVeriTixFactory.EmptyBatchArray.selector));
        factory.batchCreateEvents(emptyArray);
    }
    
    function test_Factory_GlobalResalePercentTooLow() public {
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixFactory.GlobalResalePercentTooLow.selector, 
            99
        ));
        factory.setGlobalMaxResalePercent(99);
    }
    
    function test_Factory_InvalidNewOwner() public {
        vm.expectRevert(abi.encodeWithSelector(IVeriTixFactory.InvalidNewOwner.selector));
        factory.transferOwnership(address(0));
    }
    
    function test_Factory_NoFeesToWithdraw() public {
        vm.expectRevert(abi.encodeWithSelector(IVeriTixFactory.NoFeesToWithdraw.selector));
        factory.withdrawFees(payable(owner));
    }
    
    // ============ EVENT CONTRACT ERROR TESTS ============
    
    function test_Event_Constructor_EmptyEventName() public {
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.EmptyEventName.selector));
        new VeriTixEvent(
            "",
            validParams.symbol,
            validParams.maxSupply,
            validParams.ticketPrice,
            validParams.organizer,
            validParams.baseURI,
            validParams.maxResalePercent,
            validParams.organizerFeePercent
        );
    }
    
    function test_Event_Constructor_InvalidMaxSupply_Zero() public {
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.InvalidMaxSupply.selector));
        new VeriTixEvent(
            validParams.name,
            validParams.symbol,
            0,
            validParams.ticketPrice,
            validParams.organizer,
            validParams.baseURI,
            validParams.maxResalePercent,
            validParams.organizerFeePercent
        );
    }
    
    function test_Event_Constructor_InvalidTicketPrice_Zero() public {
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.InvalidTicketPrice.selector));
        new VeriTixEvent(
            validParams.name,
            validParams.symbol,
            validParams.maxSupply,
            0,
            validParams.organizer,
            validParams.baseURI,
            validParams.maxResalePercent,
            validParams.organizerFeePercent
        );
    }
    
    function test_Event_MintTicket_ZeroPayment() public {
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.ZeroPayment.selector));
        eventContract.mintTicket();
    }
    
    function test_Event_MintTicket_IncorrectPayment() public {
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.IncorrectPayment.selector, 
            0.05 ether, 
            validParams.ticketPrice
        ));
        eventContract.mintTicket{value: 0.05 ether}();
    }
    
    function test_Event_MintTicket_EventCancelled() public {
        vm.prank(organizer);
        eventContract.cancelEvent("Test cancellation");
        
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.EventIsCancelled.selector));
        eventContract.mintTicket{value: validParams.ticketPrice}();
    }
    
    function test_Event_ResaleTicket_InvalidResalePrice() public {
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.InvalidResalePrice.selector));
        eventContract.resaleTicket(1, 0);
    }
    
    function test_Event_ResaleTicket_TicketNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.TicketNotFound.selector));
        eventContract.resaleTicket{value: 0.1 ether}(999, 0.1 ether);
    }
    
    function test_Event_CheckIn_InvalidTokenId() public {
        vm.prank(organizer);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.InvalidTokenId.selector, 0));
        eventContract.checkIn(0);
    }
    
    function test_Event_CancelEvent_EmptyReason() public {
        vm.prank(organizer);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.EmptyCancellationReason.selector));
        eventContract.cancelEvent("");
    }
    
    function test_Event_SetBaseURI_EmptyURI() public {
        vm.prank(organizer);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.EmptyBaseURI.selector));
        eventContract.setBaseURI("");
    }
    
    function test_Event_TransfersDisabled() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: validParams.ticketPrice}();
        
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.TransfersDisabled.selector));
        eventContract.transferFrom(user1, user2, tokenId);
    }
    
    // ============ BOUNDARY CONDITION TESTS ============
    
    function test_Event_SoldOut() public {
        VeriTixEvent smallEvent = new VeriTixEvent(
            "Small Event",
            "SMALL",
            1,
            0.1 ether,
            organizer,
            "https://api.example.com/",
            110,
            5
        );
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        smallEvent.mintTicket{value: 0.1 ether}();
        
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(IVeriTixEvent.EventSoldOut.selector));
        smallEvent.mintTicket{value: 0.1 ether}();
    }
    
    function test_Event_ResaleExceedsMaximumPrice() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: validParams.ticketPrice}();
        
        uint256 maxPrice = VeriTixTypes.calculateMaxResalePrice(
            validParams.ticketPrice, 
            validParams.maxResalePercent
        );
        uint256 excessivePrice = maxPrice + 1;
        
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.ExceedsResaleCap.selector,
            excessivePrice,
            maxPrice
        ));
        eventContract.resaleTicket{value: excessivePrice}(tokenId, excessivePrice);
    }
    
    // ============ ACCESS CONTROL TESTS ============
    
    function test_Event_OnlyOrganizerCanCheckIn() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: validParams.ticketPrice}();
        
        vm.prank(user1);
        vm.expectRevert();
        eventContract.checkIn(tokenId);
        
        vm.prank(organizer);
        eventContract.checkIn(tokenId);
    }
    
    function test_Event_OnlyOrganizerCanCancel() public {
        vm.prank(user1);
        vm.expectRevert();
        eventContract.cancelEvent("Unauthorized cancellation");
        
        vm.prank(organizer);
        eventContract.cancelEvent("Authorized cancellation");
    }
    
    function test_Factory_OnlyOwnerCanSetGlobalSettings() public {
        vm.prank(user1);
        vm.expectRevert();
        factory.setGlobalMaxResalePercent(150);
        
        factory.setGlobalMaxResalePercent(150);
    }
}