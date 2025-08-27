// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VeriTixFactory.sol";
import "../src/VeriTixEvent.sol";
import "../src/libraries/VeriTixTypes.sol";
import "../src/interfaces/IVeriTixEvent.sol";

/**
 * @title PaymentFlowEdgeCasesTest
 * @dev Advanced edge case testing for VeriTix payment flows
 * @notice Tests complex scenarios, gas limit attacks, and boundary conditions
 */
contract PaymentFlowEdgeCasesTest is Test {
    VeriTixFactory public factory;
    VeriTixEvent public eventContract;
    
    address public owner = makeAddr("owner");
    address public organizer = makeAddr("organizer");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public constant MAX_RESALE_PERCENT = 120; // 120%
    uint256 public constant ORGANIZER_FEE_PERCENT = 10; // 10%
    
    function setUp() public {
        vm.startPrank(owner);
        factory = new VeriTixFactory(owner);
        vm.stopPrank();
        
        VeriTixTypes.EventCreationParams memory params = VeriTixTypes.EventCreationParams({
            name: "Edge Case Event",
            symbol: "EDGE",
            maxSupply: MAX_SUPPLY,
            ticketPrice: TICKET_PRICE,
            baseURI: "https://edge.com/",
            maxResalePercent: MAX_RESALE_PERCENT,
            organizerFeePercent: ORGANIZER_FEE_PERCENT,
            organizer: organizer
        });
        
        vm.prank(organizer);
        address eventAddress = factory.createEvent(params);
        eventContract = VeriTixEvent(eventAddress);
        
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    // ============ PRECISION AND ROUNDING TESTS ============
    
    /**
     * @dev Test organizer fee calculation with rounding
     */
    function test_OrganizerFee_RoundingPrecision() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Test with price that causes rounding (within 120% cap)
        uint256 resalePrice = (TICKET_PRICE * 115) / 100; // 115% of face value
        uint256 expectedFee = (resalePrice * ORGANIZER_FEE_PERCENT) / 100; // 0.0123 ether
        
        uint256 organizerBalanceBefore = organizer.balance;
        uint256 sellerBalanceBefore = user1.balance;
        
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        // Verify precise fee calculation
        assertEq(organizer.balance - organizerBalanceBefore, expectedFee);
        assertEq(user1.balance - sellerBalanceBefore, resalePrice - expectedFee);
    }
    
    /**
     * @dev Test minimum possible resale price (1 wei above face value)
     */
    function test_MinimumResalePrice() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 minResalePrice = TICKET_PRICE + 1; // 1 wei above face value
        uint256 expectedFee = (minResalePrice * ORGANIZER_FEE_PERCENT) / 100;
        
        vm.prank(user2);
        eventContract.resaleTicket{value: minResalePrice}(tokenId, minResalePrice);
        
        assertEq(eventContract.ownerOf(tokenId), user2);
        assertEq(eventContract.getLastPricePaid(tokenId), minResalePrice);
    }
    
    /**
     * @dev Test maximum possible resale price
     */
    function test_MaximumResalePrice() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 maxResalePrice = (TICKET_PRICE * MAX_RESALE_PERCENT) / 100;
        uint256 expectedFee = (maxResalePrice * ORGANIZER_FEE_PERCENT) / 100;
        
        vm.prank(user2);
        eventContract.resaleTicket{value: maxResalePrice}(tokenId, maxResalePrice);
        
        assertEq(eventContract.ownerOf(tokenId), user2);
        assertEq(eventContract.getLastPricePaid(tokenId), maxResalePrice);
    }

    // ============ BATCH OPERATION TESTS ============
    
    /**
     * @dev Test rapid sequential minting for balance consistency
     */
    function test_RapidSequentialMinting() public {
        uint256 initialBalance = address(eventContract).balance;
        uint256 numTickets = 5;
        
        for (uint256 i = 0; i < numTickets; i++) {
            address buyer = makeAddr(string(abi.encodePacked("buyer", i)));
            vm.deal(buyer, 1 ether);
            vm.prank(buyer);
            eventContract.mintTicket{value: TICKET_PRICE}();
        }
        
        assertEq(address(eventContract).balance, initialBalance + (TICKET_PRICE * numTickets));
    }
    
    /**
     * @dev Test rapid sequential refunds for balance consistency
     */
    function test_RapidSequentialRefunds() public {
        uint256[] memory tokenIds = new uint256[](3);
        address[] memory buyers = new address[](3);
        
        // Mint tickets
        for (uint256 i = 0; i < 3; i++) {
            buyers[i] = makeAddr(string(abi.encodePacked("buyer", i)));
            vm.deal(buyers[i], 1 ether);
            vm.prank(buyers[i]);
            tokenIds[i] = eventContract.mintTicket{value: TICKET_PRICE}();
        }
        
        uint256 balanceAfterMinting = address(eventContract).balance;
        
        // Rapid refunds
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(buyers[i]);
            eventContract.refund(tokenIds[i]);
        }
        
        assertEq(address(eventContract).balance, balanceAfterMinting - (TICKET_PRICE * 3));
    }
    
    /**
     * @dev Test mixed operations (mint, resale, refund) for balance consistency
     */
    function test_MixedOperationsBalanceConsistency() public {
        // Initial state
        uint256 initialBalance = address(eventContract).balance;
        
        // Mint 2 tickets
        vm.prank(user1);
        uint256 tokenId1 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user2);
        uint256 tokenId2 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 balanceAfterMinting = address(eventContract).balance;
        assertEq(balanceAfterMinting, initialBalance + (TICKET_PRICE * 2));
        
        // Resale one ticket (within 120% cap)
        uint256 resalePrice = (TICKET_PRICE * 115) / 100; // 115% of face value
        address buyer3 = makeAddr("buyer3");
        vm.deal(buyer3, 1 ether);
        
        vm.prank(buyer3);
        eventContract.resaleTicket{value: resalePrice}(tokenId1, resalePrice);
        
        // Balance should remain same (funds distributed to seller/organizer)
        assertEq(address(eventContract).balance, balanceAfterMinting);
        
        // Refund the other ticket
        vm.prank(user2);
        eventContract.refund(tokenId2);
        
        // Balance should decrease by face value
        assertEq(address(eventContract).balance, balanceAfterMinting - TICKET_PRICE);
    }

    // ============ BOUNDARY CONDITION TESTS ============
    
    /**
     * @dev Test payment with exactly maximum uint256 value (should fail)
     */
    function test_MaxUint256Payment() public {
        vm.deal(user1, type(uint256).max);
        
        vm.prank(user1);
        vm.expectRevert(); // Should fail due to incorrect payment
        eventContract.mintTicket{value: type(uint256).max}();
    }
    
    /**
     * @dev Test resale at exactly the price cap boundary
     */
    function test_ResalePriceCapBoundary() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 maxPrice = (TICKET_PRICE * MAX_RESALE_PERCENT) / 100;
        
        // Should succeed at exactly the cap
        vm.prank(user2);
        eventContract.resaleTicket{value: maxPrice}(tokenId, maxPrice);
        
        assertEq(eventContract.ownerOf(tokenId), user2);
    }
    
    /**
     * @dev Test resale 1 wei above the price cap (should fail)
     */
    function test_ResalePriceCapExceeded() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 maxPrice = (TICKET_PRICE * MAX_RESALE_PERCENT) / 100;
        uint256 excessivePrice = maxPrice + 1;
        
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(
            IVeriTixEvent.ExceedsResaleCap.selector,
            excessivePrice,
            maxPrice
        ));
        eventContract.resaleTicket{value: excessivePrice}(tokenId, excessivePrice);
    }

    // ============ COMPLEX SCENARIO TESTS ============
    
    /**
     * @dev Test multiple resales of the same ticket
     */
    function test_MultipleResalesBalanceTracking() public {
        // Initial mint
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 contractBalanceAfterMint = address(eventContract).balance;
        
        // First resale
        uint256 resalePrice1 = TICKET_PRICE + 0.02 ether;
        address buyer2 = makeAddr("buyer2");
        vm.deal(buyer2, 1 ether);
        
        vm.prank(buyer2);
        eventContract.resaleTicket{value: resalePrice1}(tokenId, resalePrice1);
        
        // Contract balance should remain the same
        assertEq(address(eventContract).balance, contractBalanceAfterMint);
        
        // Second resale
        uint256 resalePrice2 = TICKET_PRICE + 0.01 ether;
        address buyer3 = makeAddr("buyer3");
        vm.deal(buyer3, 1 ether);
        
        vm.prank(buyer3);
        eventContract.resaleTicket{value: resalePrice2}(tokenId, resalePrice2);
        
        // Contract balance should still remain the same
        assertEq(address(eventContract).balance, contractBalanceAfterMint);
        
        // Final refund should still be at face value
        uint256 buyer3BalanceBefore = buyer3.balance;
        
        vm.prank(buyer3);
        eventContract.refund(tokenId);
        
        assertEq(buyer3.balance, buyer3BalanceBefore + TICKET_PRICE);
    }
    
    /**
     * @dev Test event cancellation with mixed ticket states
     */
    function test_EventCancellationMixedStates() public {
        // Mint tickets
        vm.prank(user1);
        uint256 tokenId1 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user2);
        uint256 tokenId2 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        // Check in one ticket
        vm.prank(organizer);
        eventContract.checkIn(tokenId1);
        
        // Cancel event
        vm.prank(organizer);
        eventContract.cancelEvent("Mixed state test");
        
        // Checked-in ticket can still get cancel refund
        vm.prank(user1);
        eventContract.cancelRefund(tokenId1);
        
        // Regular ticket can get cancel refund
        vm.prank(user2);
        eventContract.cancelRefund(tokenId2);
        
        // Contract should be drained
        assertEq(address(eventContract).balance, 0);
    }

    // ============ GAS OPTIMIZATION TESTS ============
    
    /**
     * @dev Test gas consumption for minting operations
     */
    function test_MintingGasConsumption() public {
        uint256 gasBefore = gasleft();
        
        vm.prank(user1);
        eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Gas usage should be reasonable (adjust threshold as needed)
        assertLt(gasUsed, 200000); // Should use less than 200k gas
    }
    
    /**
     * @dev Test gas consumption for resale operations
     */
    function test_ResaleGasConsumption() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 resalePrice = TICKET_PRICE + 0.01 ether;
        
        uint256 gasBefore = gasleft();
        
        vm.prank(user2);
        eventContract.resaleTicket{value: resalePrice}(tokenId, resalePrice);
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Resale should be gas-efficient
        assertLt(gasUsed, 300000); // Should use less than 300k gas
    }
    
    /**
     * @dev Test gas consumption for refund operations
     */
    function test_RefundGasConsumption() public {
        vm.prank(user1);
        uint256 tokenId = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 gasBefore = gasleft();
        
        vm.prank(user1);
        eventContract.refund(tokenId);
        
        uint256 gasUsed = gasBefore - gasleft();
        
        // Refund should be gas-efficient
        assertLt(gasUsed, 250000); // Should use less than 250k gas
    }

    // ============ FUND RECOVERY TESTS ============
    
    /**
     * @dev Test fund recovery after partial refunds
     */
    function test_FundRecoveryPartialRefunds() public {
        // Mint multiple tickets
        address[] memory buyers = new address[](5);
        uint256[] memory tokenIds = new uint256[](5);
        
        for (uint256 i = 0; i < 5; i++) {
            buyers[i] = makeAddr(string(abi.encodePacked("buyer", i)));
            vm.deal(buyers[i], 1 ether);
            vm.prank(buyers[i]);
            tokenIds[i] = eventContract.mintTicket{value: TICKET_PRICE}();
        }
        
        uint256 totalFunds = address(eventContract).balance;
        
        // Refund some tickets
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(buyers[i]);
            eventContract.refund(tokenIds[i]);
        }
        
        // Remaining funds should be accurate
        assertEq(address(eventContract).balance, totalFunds - (TICKET_PRICE * 3));
        
        // Remaining tickets should still be refundable
        vm.prank(buyers[3]);
        eventContract.refund(tokenIds[3]);
        
        vm.prank(buyers[4]);
        eventContract.refund(tokenIds[4]);
        
        assertEq(address(eventContract).balance, 0);
    }
    
    /**
     * @dev Test fund state after event cancellation
     */
    function test_FundStateAfterCancellation() public {
        // Mint tickets
        vm.prank(user1);
        uint256 tokenId1 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        vm.prank(user2);
        uint256 tokenId2 = eventContract.mintTicket{value: TICKET_PRICE}();
        
        uint256 totalFunds = address(eventContract).balance;
        
        // Cancel event
        vm.prank(organizer);
        eventContract.cancelEvent("Fund state test");
        
        // Funds should still be available for cancel refunds
        assertEq(address(eventContract).balance, totalFunds);
        
        // Process cancel refunds
        vm.prank(user1);
        eventContract.cancelRefund(tokenId1);
        
        assertEq(address(eventContract).balance, totalFunds - TICKET_PRICE);
        
        vm.prank(user2);
        eventContract.cancelRefund(tokenId2);
        
        assertEq(address(eventContract).balance, 0);
    }
}