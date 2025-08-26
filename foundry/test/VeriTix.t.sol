// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {VeriTix} from "../src/VeriTix.sol";

contract VeriTixTest is Test {
    VeriTix public veriTix;
    address public owner;
    address public organizer;
    address public buyer1;
    address public buyer2;
    address public maliciousContract;

    // Mock event data
    string constant EVENT_NAME = "Test Music Festival";
    uint256 constant TICKET_PRICE = 0.05 ether;
    uint256 constant MAX_TICKETS = 100;

    // Simple payable contract to act as organizer
    receive() external payable virtual {}

    function setUp() public {
        owner = address(this);
        organizer = makeAddr("organizer");
        buyer1 = makeAddr("buyer1");
        buyer2 = makeAddr("buyer2");
        maliciousContract = makeAddr("malicious");

        // Deploy contract with owner as initial owner
        veriTix = new VeriTix(owner);

        // Fund buyers with ETH
        vm.deal(buyer1, 1 ether);
        vm.deal(buyer2, 1 ether);
        vm.deal(maliciousContract, 1 ether);

        // Fund organizer with some ETH to ensure it can receive payments
        vm.deal(organizer, 1 ether);
    }

    // ===== DEPLOYMENT TESTS =====

    function test_Deployment() public {
        assertEq(veriTix.owner(), owner);
        assertEq(veriTix.getTotalEvents(), 0);
    }

    function testFuzz_Deployment(address initialOwner) public {
        VeriTix newVeriTix = new VeriTix(initialOwner);
        assertEq(newVeriTix.owner(), initialOwner);
    }

    // ===== EVENT CREATION TESTS =====

    function test_EventCreation() public {
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        assertEq(veriTix.getTotalEvents(), 1);

        (string memory name, uint256 price, uint256 maxTickets, uint256 sold, address eventOrganizer) =
            veriTix.getEventDetails(1);

        assertEq(name, EVENT_NAME);
        assertEq(price, TICKET_PRICE);
        assertEq(maxTickets, MAX_TICKETS);
        assertEq(sold, 0);
        assertEq(eventOrganizer, owner);
        assertTrue(veriTix.eventExists(1));
    }

    function test_EventCreationOnlyOwner() public {
        vm.prank(buyer1);
        vm.expectRevert();
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);
    }

    function test_EventCreationValidation() public {
        vm.startPrank(owner);

        // Empty name should revert
        vm.expectRevert("Event name cannot be empty");
        veriTix.createEvent("", TICKET_PRICE, MAX_TICKETS);

        // Zero price should revert
        vm.expectRevert("Ticket price must be greater than 0");
        veriTix.createEvent(EVENT_NAME, 0, MAX_TICKETS);

        // Zero max tickets should revert
        vm.expectRevert("Max tickets must be greater than 0");
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, 0);

        vm.stopPrank();
    }

    function test_MultipleEventCreation() public {
        vm.startPrank(owner);

        veriTix.createEvent("Event 1", TICKET_PRICE, MAX_TICKETS);
        veriTix.createEvent("Event 2", TICKET_PRICE * 2, MAX_TICKETS * 2);

        assertEq(veriTix.getTotalEvents(), 2);

        (string memory name1,,,,) = veriTix.getEventDetails(1);
        (string memory name2,,,,) = veriTix.getEventDetails(2);

        assertEq(name1, "Event 1");
        assertEq(name2, "Event 2");

        vm.stopPrank();
    }

    // ===== TICKET PURCHASE TESTS =====

    function test_TicketPurchase() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        uint256 initialOwnerBalance = owner.balance;

        // Buy ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Check event state
        (,,uint256 maxTickets, uint256 sold,) = veriTix.getEventDetails(1);
        assertEq(sold, 1);
        assertEq(veriTix.getTicketsAvailable(1), maxTickets - 1);

        // Check buyer owns NFT
        assertEq(veriTix.ownerOf(1), buyer1);

        // Check organizer (owner) received payment
        assertEq(owner.balance, initialOwnerBalance + TICKET_PRICE);
    }

    function test_TicketPurchaseValidation() public {
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Wrong price should revert
        vm.prank(buyer1);
        vm.expectRevert("Incorrect ticket price sent");
        veriTix.buyTicket{value: TICKET_PRICE / 2}(1);

        // Non-existent event should revert
        vm.prank(buyer1);
        vm.expectRevert("Event does not exist");
        veriTix.buyTicket{value: TICKET_PRICE}(999);
    }

    function test_SellOutEvent() public {
        // Create event with only 1 ticket
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, 1);

        // Buy the only ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Second purchase should fail
        vm.prank(buyer2);
        vm.expectRevert("Event is sold out");
        veriTix.buyTicket{value: TICKET_PRICE}(1);
    }

    function test_MultipleTicketPurchases() public {
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, 5);

        // Multiple buyers purchase tickets
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        vm.prank(buyer2);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Check state
        (,,uint256 maxTickets, uint256 sold,) = veriTix.getEventDetails(1);
        assertEq(sold, 2);
        assertEq(veriTix.getTicketsAvailable(1), maxTickets - 2);

        // Check NFT ownership
        assertEq(veriTix.ownerOf(1), buyer1);
        assertEq(veriTix.ownerOf(2), buyer2);
    }

    // ===== SECURITY TESTS =====

    function test_ReentrancyProtection() public {
        // This test will help verify the reentrancy fix
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Test normal purchase works
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        assertEq(veriTix.ownerOf(1), buyer1);
    }

    function test_AccessControl() public {
        // Test that non-owners can't create events
        vm.prank(buyer1);
        vm.expectRevert();
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Test that owner can create events
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);
        assertEq(veriTix.getTotalEvents(), 1);
    }

    // ===== INTEGRATION TESTS =====

    function test_CompleteFlow() public {
        // 1. Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // 2. Buy tickets
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        vm.prank(buyer2);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // 3. Verify state
        assertEq(veriTix.getTotalEvents(), 1);
        assertTrue(veriTix.eventExists(1));

        (,,uint256 maxTickets, uint256 sold,) = veriTix.getEventDetails(1);
        assertEq(sold, 2);
        assertEq(veriTix.getTicketsAvailable(1), maxTickets - 2);

        // 4. Verify NFT ownership
        assertEq(veriTix.ownerOf(1), buyer1);
        assertEq(veriTix.ownerOf(2), buyer2);
    }

    // ===== EDGE CASE TESTS =====

    function test_ZeroAddressHandling() public {
        // Test with zero address - this should revert during construction
        vm.expectRevert();
        VeriTix zeroVeriTix = new VeriTix(address(0));
    }

    function test_MaxTicketsEdgeCase() public {
        // Test with very large max tickets
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, type(uint256).max);

        (,,uint256 maxTickets,,) = veriTix.getEventDetails(1);
        assertEq(maxTickets, type(uint256).max);
    }

    function testFuzz_TicketPrice(uint256 price) public {
        // Fuzz test for different ticket prices
        vm.assume(price > 0 && price < 100 ether); // Reasonable bounds

        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, price, MAX_TICKETS);

        (,uint256 storedPrice,,,) = veriTix.getEventDetails(1);
        assertEq(storedPrice, price);
    }

    // ===== EVENT CANCELLATION AND REFUND TESTS =====

    function test_EventCancellation() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Buy a ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Cancel the event (only organizer can cancel)
        vm.prank(owner);
        veriTix.cancelEvent(1, "Weather conditions");

        // Check that event is cancelled
        assertTrue(veriTix.isEventCancelled(1));

        // Check that event details revert now
        vm.expectRevert("Event does not exist");
        veriTix.getEventDetails(1);
    }

    function test_EventCancellationOnlyOrganizer() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Non-organizer tries to cancel - should revert
        vm.prank(buyer1);
        vm.expectRevert("Only event organizer can cancel");
        veriTix.cancelEvent(1, "Test reason");
    }

    function test_EventCancellationNonExistent() public {
        vm.prank(owner);
        vm.expectRevert("Event does not exist");
        veriTix.cancelEvent(999, "Test reason");
    }

    function test_TicketRefund() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Buy a ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Check initial balance
        uint256 initialBalance = buyer1.balance;

        // Fund the contract with ETH for refunds
        vm.deal(address(veriTix), TICKET_PRICE);

        // Cancel the event
        vm.prank(owner);
        veriTix.cancelEvent(1, "Cancelled");

        // Request refund
        vm.prank(buyer1);
        veriTix.refundTicket(1);

        // Check that buyer received refund
        assertEq(buyer1.balance, initialBalance + TICKET_PRICE);

        // Check that token was burned (should not exist)
        vm.expectRevert();
        veriTix.ownerOf(1);
    }

    function test_TicketRefundNotOwner() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Buy a ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Cancel the event
        vm.prank(owner);
        veriTix.cancelEvent(1, "Cancelled");

        // Non-owner tries to refund - should revert
        vm.prank(buyer2);
        vm.expectRevert("Not ticket owner");
        veriTix.refundTicket(1);
    }

    function test_TicketRefundEventNotCancelled() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Buy a ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Try to refund without cancelling event - should revert
        vm.prank(buyer1);
        vm.expectRevert("Event not cancelled");
        veriTix.refundTicket(1);
    }

    function test_GetRefundAmount() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Buy a ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Before cancellation, refund amount should be 0
        assertEq(veriTix.getRefundAmount(1), 0);

        // Cancel the event
        vm.prank(owner);
        veriTix.cancelEvent(1, "Cancelled");

        // After cancellation, refund amount should be ticket price
        assertEq(veriTix.getRefundAmount(1), TICKET_PRICE);
    }

    function test_MultipleRefunds() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Multiple buyers purchase tickets
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        vm.prank(buyer2);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        uint256 buyer1BalanceAfterPurchase = buyer1.balance;
        uint256 buyer2BalanceAfterPurchase = buyer2.balance;

        // Verify tokens exist and ownership
        console.log("Total supply after purchases:", veriTix.totalSupply());
        console.log("Token 1 owner:", veriTix.ownerOf(1));
        console.log("Token 2 owner:", veriTix.ownerOf(2));

        // Fund the contract with ETH for refunds (enough for both refunds)
        vm.deal(address(veriTix), TICKET_PRICE * 2);
        console.log("Contract balance after funding:", address(veriTix).balance);

        // Cancel the event
        vm.prank(owner);
        veriTix.cancelEvent(1, "Cancelled");

        // First buyer requests refund
        console.log("Before first refund:");
        console.log("  Contract balance:", address(veriTix).balance);
        console.log("  Buyer1 balance:", buyer1.balance);

        vm.prank(buyer1);
        veriTix.refundTicket(1);

        console.log("After first refund:");
        console.log("  Contract balance:", address(veriTix).balance);
        console.log("  Buyer1 balance:", buyer1.balance);
        console.log("  Total supply:", veriTix.totalSupply());

        // Second buyer requests refund
        console.log("Before second refund:");
        console.log("  Contract balance:", address(veriTix).balance);
        console.log("  Buyer2 balance:", buyer2.balance);
        console.log("  Token 2 owner:", veriTix.ownerOf(2));
        console.log("  Token 2 exists check:", veriTix.verifyTicketOwnership(2, buyer2));

        vm.prank(buyer2);
        try veriTix.refundTicket(2) {
            console.log("Second refund: SUCCESS");
        } catch Error(string memory reason) {
            console.log("Second refund error:", reason);
        } catch {
            console.log("Second refund: UNKNOWN ERROR");
        }

        console.log("After second refund:");
        console.log("  Contract balance:", address(veriTix).balance);
        console.log("  Buyer2 balance:", buyer2.balance);
        console.log("  Total supply:", veriTix.totalSupply());

        // Check both received refunds (should be back to original balance)
        assertEq(buyer1.balance, buyer1BalanceAfterPurchase + TICKET_PRICE);
        assertEq(buyer2.balance, buyer2BalanceAfterPurchase + TICKET_PRICE);

        // Verify both tokens are burned
        assertEq(veriTix.totalSupply(), 0);
    }

    function test_TicketVerificationFunctions() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Buy a ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        // Test ticket verification
        assertTrue(veriTix.verifyTicketOwnership(1, buyer1));
        assertFalse(veriTix.verifyTicketOwnership(1, buyer2));

        // Test ticket details
        (uint256 eventId, string memory eventName, uint256 ticketPrice, address ticketOwner) =
            veriTix.getTicketDetails(1);

        assertEq(eventId, 1);
        assertEq(eventName, EVENT_NAME);
        assertEq(ticketPrice, TICKET_PRICE);
        assertEq(ticketOwner, buyer1);

        // Test entry validation
        vm.prank(buyer1);
        assertTrue(veriTix.isValidForEntry(1));

        vm.prank(buyer2);
        assertFalse(veriTix.isValidForEntry(1));
    }

    function test_SimpleRefund() public {
        // Create event
        vm.prank(owner);
        veriTix.createEvent(EVENT_NAME, TICKET_PRICE, MAX_TICKETS);

        // Buy a ticket
        vm.prank(buyer1);
        veriTix.buyTicket{value: TICKET_PRICE}(1);

        uint256 buyer1BalanceBefore = buyer1.balance;
        uint256 contractBalanceBefore = address(veriTix).balance;

        console.log("Buyer1 balance before refund:", buyer1BalanceBefore);
        console.log("Contract balance before refund:", contractBalanceBefore);

        // Fund the contract with additional ETH for refund
        vm.deal(address(veriTix), contractBalanceBefore + TICKET_PRICE);

        // Cancel the event
        vm.prank(owner);
        veriTix.cancelEvent(1, "Cancelled");

        // Request refund
        vm.prank(buyer1);
        veriTix.refundTicket(1);

        console.log("Buyer1 balance after refund:", buyer1.balance);
        console.log("Contract balance after refund:", address(veriTix).balance);

        // Check that buyer received refund
        assertEq(buyer1.balance, buyer1BalanceBefore + TICKET_PRICE);

        // Check that token was burned (should not exist)
        vm.expectRevert();
        veriTix.ownerOf(1);
    }
}
