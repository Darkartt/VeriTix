#!/bin/bash

# VeriTix Payment Flow Security Test Runner
# Executes comprehensive payment flow security tests and generates reports

set -e

echo "🔒 VeriTix Payment Flow Security Analysis"
echo "========================================"
echo ""

# Change to foundry directory
cd "$(dirname "$0")/../.."

# Ensure we have forge available
if ! command -v forge &> /dev/null; then
    echo "❌ Forge not found. Please install Foundry first."
    exit 1
fi

echo "📋 Running Payment Flow Security Tests..."
echo ""

# Run core payment flow security tests
echo "🧪 Executing PaymentFlowSecurityTest..."
forge test --match-contract PaymentFlowSecurityTest -vv

echo ""
echo "🧪 Executing PaymentFlowEdgeCasesTest..."
forge test --match-contract PaymentFlowEdgeCasesTest -vv

echo ""
echo "📊 Generating Gas Report for Payment Functions..."
forge test --match-contract PaymentFlowSecurityTest --gas-report

echo ""
echo "🔍 Running Specific Payment Vulnerability Tests..."

# Test exact payment validation
echo "  → Testing exact payment validation..."
forge test --match-test "test_MintTicket_ExactPaymentRequired|test_MintTicket_RejectsOverpayment|test_MintTicket_RejectsUnderpayment" -v

# Test refund calculation accuracy
echo "  → Testing refund calculation accuracy..."
forge test --match-test "test_Refund_AlwaysFaceValue|test_Refund_InsufficientContractBalance" -v

# Test double-spending prevention
echo "  → Testing double-spending prevention..."
forge test --match-test "test_Refund_PreventsDoubleSpending|test_Refund_PreventsAfterCheckIn" -v

# Test balance management
echo "  → Testing contract balance management..."
forge test --match-test "test_ContractBalance_AccurateTracking|test_ContractBalance_ResaleManagement" -v

# Test fund drainage protection
echo "  → Testing fund drainage protection..."
forge test --match-test "test_FundDrainage_UnauthorizedWithdrawal|test_FundDrainage_ReentrancyProtection" -v

echo ""
echo "✅ Payment Flow Security Analysis Complete"
echo ""
echo "📄 Analysis report available at: audit/payment-flow-security-analysis.md"
echo "🧪 Test files: test/PaymentFlowSecurityTest.sol, test/PaymentFlowEdgeCasesTest.sol"
echo ""
echo "🎯 Key Security Validations:"
echo "   ✓ Exact payment validation (no overpay/underpay acceptance)"
echo "   ✓ Refund calculation accuracy (always face value)"
echo "   ✓ Double-spending prevention (ticket burning + state checks)"
echo "   ✓ Contract balance management (proper fund tracking)"
echo "   ✓ Fund drainage protection (reentrancy guards + balance checks)"
echo "   ✓ Batch operation consistency (sequential operation validation)"
echo ""