// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/interfaces/IVeriTixEvent.sol";
import "../src/interfaces/IVeriTixFactory.sol";
import "../src/libraries/VeriTixTypes.sol";

/**
 * @title InterfaceTest
 * @dev Test contract to verify interface compilation and data structure functionality
 */
contract InterfaceTest is Test {
    using VeriTixTypes for *;

    function testEventCreationParamsValidation() public {
        // Test valid parameters
        VeriTixTypes.EventCreationParams memory validParams = VeriTixTypes.EventCreationParams({
            name: "Test Event",
            symbol: "TEST",
            maxSupply: 1000,
            ticketPrice: 0.1 ether,
            baseURI: "https://api.example.com/metadata/",
            maxResalePercent: 110,
            organizerFeePercent: 5,
            organizer: address(0x123)
        });

        assertTrue(VeriTixTypes.validateEventParams(validParams));

        // Test invalid parameters - empty name
        VeriTixTypes.EventCreationParams memory invalidParams = validParams;
        invalidParams.name = "";
        assertFalse(VeriTixTypes.validateEventParams(invalidParams));

        // Test invalid parameters - zero organizer
        invalidParams = validParams;
        invalidParams.organizer = address(0);
        assertFalse(VeriTixTypes.validateEventParams(invalidParams));

        // Test invalid parameters - price too low
        invalidParams = validParams;
        invalidParams.ticketPrice = 0.0001 ether; // Below MIN_TICKET_PRICE
        assertFalse(VeriTixTypes.validateEventParams(invalidParams));
    }

    function testMaxResalePriceCalculation() public {
        uint256 originalPrice = 1 ether;
        uint256 maxResalePercent = 110; // 110%

        uint256 maxPrice = VeriTixTypes.calculateMaxResalePrice(originalPrice, maxResalePercent);
        assertEq(maxPrice, 1.1 ether);

        // Test with different values
        originalPrice = 0.5 ether;
        maxResalePercent = 150; // 150%
        maxPrice = VeriTixTypes.calculateMaxResalePrice(originalPrice, maxResalePercent);
        assertEq(maxPrice, 0.75 ether);
    }

    function testOrganizerFeeCalculation() public {
        uint256 resalePrice = 1 ether;
        uint256 organizerFeePercent = 5; // 5%

        uint256 fee = VeriTixTypes.calculateOrganizerFee(resalePrice, organizerFeePercent);
        assertEq(fee, 0.05 ether);

        // Test with different values
        resalePrice = 2 ether;
        organizerFeePercent = 10; // 10%
        fee = VeriTixTypes.calculateOrganizerFee(resalePrice, organizerFeePercent);
        assertEq(fee, 0.2 ether);
    }

    function testTicketStateValidation() public {
        // Test resale permissions
        assertTrue(VeriTixTypes.canResaleTicket(VeriTixTypes.TicketState.Sold));
        assertFalse(VeriTixTypes.canResaleTicket(VeriTixTypes.TicketState.Available));
        assertFalse(VeriTixTypes.canResaleTicket(VeriTixTypes.TicketState.CheckedIn));
        assertFalse(VeriTixTypes.canResaleTicket(VeriTixTypes.TicketState.Refunded));

        // Test refund permissions
        assertTrue(VeriTixTypes.canRefundTicket(VeriTixTypes.TicketState.Sold));
        assertFalse(VeriTixTypes.canRefundTicket(VeriTixTypes.TicketState.Available));
        assertFalse(VeriTixTypes.canRefundTicket(VeriTixTypes.TicketState.CheckedIn));
        assertFalse(VeriTixTypes.canRefundTicket(VeriTixTypes.TicketState.Refunded));
    }

    function testConstants() public {
        // Verify constants are set to expected values
        assertEq(VeriTixTypes.MAX_RESALE_PERCENTAGE, 300);
        assertEq(VeriTixTypes.MAX_ORGANIZER_FEE_PERCENT, 50);
        assertEq(VeriTixTypes.MIN_TICKET_PRICE, 0.001 ether);
        assertEq(VeriTixTypes.MAX_TICKETS_PER_EVENT, 100000);
        assertEq(VeriTixTypes.MAX_EVENTS_PER_ORGANIZER, 1000);
    }

    function testEventRegistryStructure() public {
        // Test that we can create and manipulate EventRegistry structs
        VeriTixTypes.EventRegistry memory registry = VeriTixTypes.EventRegistry({
            eventContract: address(0x456),
            organizer: address(0x123),
            createdAt: block.timestamp,
            eventName: "Test Event",
            status: VeriTixTypes.EventStatus.Active,
            ticketPrice: 1 ether,
            maxSupply: 1000
        });

        assertEq(registry.eventContract, address(0x456));
        assertEq(registry.organizer, address(0x123));
        assertEq(registry.eventName, "Test Event");
        assertTrue(registry.status == VeriTixTypes.EventStatus.Active);
    }

    function testTicketInfoStructure() public {
        // Test that we can create and manipulate TicketInfo structs
        VeriTixTypes.TicketInfo memory ticketInfo = VeriTixTypes.TicketInfo({
            tokenId: 1,
            currentOwner: address(0x789),
            originalPrice: 1 ether,
            lastPricePaid: 1.1 ether,
            state: VeriTixTypes.TicketState.Sold,
            isCheckedIn: false,
            mintedAt: block.timestamp
        });

        assertEq(ticketInfo.tokenId, 1);
        assertEq(ticketInfo.currentOwner, address(0x789));
        assertEq(ticketInfo.originalPrice, 1 ether);
        assertEq(ticketInfo.lastPricePaid, 1.1 ether);
        assertTrue(ticketInfo.state == VeriTixTypes.TicketState.Sold);
        assertFalse(ticketInfo.isCheckedIn);
    }
}