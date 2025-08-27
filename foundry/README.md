# 🎫 VeriTix Smart Contracts

**Decentralized Event Ticketing Platform - Smart Contract Implementation**

This directory contains the complete smart contract implementation for VeriTix, built with Foundry for maximum security, efficiency, and auditability.

---

## 📋 Overview

VeriTix smart contracts provide a comprehensive decentralized ticketing solution with anti-scalping protection, automated refunds, and NFT-based ticket ownership.

### 🏗️ Architecture

```
foundry/
├── 📄 src/                     # Smart contract source code
│   ├── VeriTixFactory.sol      # Factory contract for creating events
│   ├── VeriTixEvent.sol        # Individual event contract (ERC721)
│   ├── interfaces/             # Contract interfaces
│   └── libraries/              # Shared libraries and types
├── 🧪 test/                    # Comprehensive test suite (23 test files)
├── 📜 script/                  # Deployment and utility scripts
├── 🔧 Makefile                 # Build and deployment automation
└── 📖 README.md               # This file
```

---

## 🚀 Quick Start

### Prerequisites

- **Foundry** installed ([Installation Guide](https://book.getfoundry.sh/getting-started/installation))
- **Git** for cloning dependencies
- **Node.js** (for audit scripts)

### Installation

```bash
# Install dependencies
make install

# Build contracts
make build

# Run tests
make test
```

---

## 🔗 Smart Contracts

### Core Contracts

#### VeriTixFactory.sol
**Factory contract for creating and managing events**

```solidity
// Create a new event
function createEvent(EventParams memory params) external payable returns (address)

// Get all deployed events
function getDeployedEvents() external view returns (address[] memory)

// Factory management functions
function setPaused(bool _paused) external onlyOwner
function setGlobalMaxResalePercent(uint256 _percent) external onlyOwner
```

**Key Features:**
- Event creation with customizable parameters
- Global anti-scalping settings
- Pausable functionality for emergency stops
- Event registry and management

#### VeriTixEvent.sol
**Individual event contract implementing ERC721**

```solidity
// Purchase tickets
function mintTicket() external payable

// Get event information
function getEventInfo() external view returns (EventInfo memory)

// Refund system (for cancelled events)
function refundTicket(uint256 tokenId) external

// Resale with price protection
function resaleTicket(uint256 tokenId, uint256 price) external
```

**Key Features:**
- ERC721 NFT tickets with metadata
- Anti-scalping price protection
- Automated refund system
- QR code generation for check-ins
- Marketplace compatibility (OpenSea)

### Interfaces & Libraries

#### IVeriTixFactory.sol & IVeriTixEvent.sol
- Clean interface definitions
- Event signatures and data structures
- Integration guidelines for frontends

#### VeriTixTypes.sol
- Shared data structures
- Event parameters and configurations
- Standardized types across contracts

---

## 🧪 Testing Suite

### Comprehensive Test Coverage (23 Test Files)

#### Core Functionality Tests
```bash
# Test factory and event contracts
forge test --match-contract VeriTixFactory -v
forge test --match-contract VeriTixEvent -v
```

#### Security-Focused Tests
```bash
# Security foundation tests
make security-test

# Reentrancy protection tests
make test-reentrancy

# Access control tests
make test-access-control

# Economic attack prevention
forge test --match-contract EconomicAttack -v
```

#### Gas Optimization Tests
```bash
# Gas benchmarking
make gas-benchmark

# Gas optimization validation
forge test --match-contract GasOptimization -v
```

#### Integration & Compliance Tests
```bash
# NFT standards compliance
forge test --match-contract NFTStandardsCompliance -v

# OpenSea integration
forge test --match-contract OpenSeaIntegration -v

# Full integration tests
make test-integration
```

### Test Categories

| Category | Files | Purpose |
|----------|-------|---------|
| **Core** | `VeriTixFactory.t.sol`, `VeriTixEvent.t.sol` | Basic functionality |
| **Security** | `SecurityFoundationTest.sol`, `AccessControlSecurityTest.sol` | Security validations |
| **Reentrancy** | `ReentrancyTest.sol`, `ReentrancyAnalysisTest.sol` | Attack prevention |
| **Economic** | `EconomicAttackSimulationTest.sol`, `PaymentFlowSecurityTest.sol` | Economic security |
| **Gas** | `GasOptimizationTest.sol`, `GasOptimizationValidationTest.sol` | Performance |
| **Compliance** | `NFTStandardsComplianceTest.sol`, `OpenSeaIntegrationTest.sol` | Standards |
| **Integration** | `IntegrationTest.sol`, `CriticalFindingsValidationTest.sol` | End-to-end |

---

## 🔧 Build & Development

### Basic Commands

```bash
# Build contracts
forge build

# Run all tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Generate coverage report
forge coverage

# Format code
forge fmt

# Create gas snapshot
forge snapshot
```

### Advanced Testing

```bash
# Verbose test output
forge test -vvv

# Test specific contract
forge test --match-contract SecurityFoundationTest

# Test specific function
forge test --match-test test_SecurityValidation

# Run tests with coverage
make test-coverage
```

---

## 🚀 Deployment

### Local Development

```bash
# Start local blockchain
make anvil

# Deploy to local network (in another terminal)
make deploy-local

# Verify deployment
make verify FACTORY_ADDRESS=<deployed_address>
```

### Testnet Deployment

```bash
# Deploy to Sepolia
make deploy-sepolia PRIVATE_KEY=<your_key>

# Deploy to Mumbai (Polygon testnet)
make deploy-mumbai PRIVATE_KEY=<your_key>
```

### Mainnet Deployment

```bash
# Deploy to Ethereum mainnet (use with caution!)
make deploy-mainnet PRIVATE_KEY=<your_key>

# Deploy to Polygon mainnet
make deploy-polygon PRIVATE_KEY=<your_key>
```

### Environment Configuration

Create `.env` file:
```bash
# Copy template
make setup-env

# Edit .env with your values
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
INFURA_API_KEY=your_infura_api_key
```

---

## 🔒 Security & Auditing

### Security Analysis

```bash
# Run comprehensive security audit
make security-audit

# Individual security tools
make slither          # Static analysis
make mythril          # Symbolic execution
make gas-profile      # Gas optimization analysis
```

### Security Features

- **✅ Reentrancy Protection**: CEI pattern implementation
- **✅ Access Control**: OpenZeppelin role-based permissions
- **✅ Input Validation**: Comprehensive parameter checking
- **✅ Integer Overflow**: Solidity 0.8.x built-in protection
- **✅ Economic Attacks**: Price manipulation prevention
- **✅ DoS Protection**: Gas limit considerations and batch limits

### Audit Reports

Security audit reports are generated during analysis:
```bash
# Generate audit reports
make security-audit

# View reports (after generation)
ls audit/reports/
cat audit/comprehensive-security-report.md
```

---

## 🎯 Contract Interactions

### Factory Contract Usage

```bash
# Check factory status
make factory-status FACTORY_ADDRESS=<address>

# Create an event
make create-event \
  FACTORY_ADDRESS=<address> \
  NAME="Concert 2024" \
  SYMBOL="CONCERT24" \
  SUPPLY=1000 \
  PRICE=100000000000000000  # 0.1 ETH in wei

# List all events
make list-events FACTORY_ADDRESS=<address>
```

### Event Contract Usage

```bash
# Get event information
make event-info EVENT_ADDRESS=<address>

# Mint a ticket
make mint-ticket EVENT_ADDRESS=<address>

# Check ticket balance
make check-balance EVENT_ADDRESS=<address> ADDRESS=<wallet>
```

### Using Cast for Direct Interactions

```bash
# Get factory owner
cast call <FACTORY_ADDRESS> "owner()" --rpc-url <RPC_URL>

# Get total events created
cast call <FACTORY_ADDRESS> "getTotalEvents()" --rpc-url <RPC_URL>

# Get event details
cast call <EVENT_ADDRESS> "getEventInfo()" --rpc-url <RPC_URL>

# Check ticket price
cast call <EVENT_ADDRESS> "ticketPrice()" --rpc-url <RPC_URL>
```

---

## 📊 Gas Optimization

### Gas Benchmarks

```bash
# Run gas benchmarks
make gas-benchmark

# Profile gas usage
make optimize-gas

# Validate optimizations
make validate-optimizations
```

### Optimization Features

- **Storage Packing**: Efficient struct layouts
- **Batch Operations**: Reduced transaction costs
- **Optimized Loops**: Gas-efficient iterations
- **Minimal External Calls**: Reduced gas overhead
- **Event Emission**: Efficient logging

---

## 🔧 Makefile Commands Reference

### Development Commands
```bash
make install              # Install dependencies
make build               # Build contracts
make test                # Run all tests
make clean               # Clean build artifacts
make update              # Update dependencies
```

### Testing Commands
```bash
make test-gas            # Tests with gas reporting
make test-coverage       # Tests with coverage
make test-security-all   # All security tests
make test-integration    # Integration tests
make gas-benchmark       # Gas benchmarking
```

### Deployment Commands
```bash
make deploy-local        # Deploy to local network
make deploy-sepolia      # Deploy to Sepolia testnet
make deploy-mainnet      # Deploy to mainnet
make verify              # Verify deployment
```

### Security Commands
```bash
make security-audit      # Complete security analysis
make slither            # Static analysis
make mythril            # Symbolic execution
make audit-setup        # Setup audit environment
```

---

## 📖 Documentation & Resources

### Smart Contract Documentation

- **Solidity Style Guide**: Follows official Solidity conventions
- **NatSpec Comments**: Comprehensive function documentation
- **OpenZeppelin**: Uses audited security libraries
- **ERC Standards**: ERC721 compliance for NFT tickets

### External Resources

- **Foundry Book**: [https://book.getfoundry.sh/](https://book.getfoundry.sh/)
- **OpenZeppelin Docs**: [https://docs.openzeppelin.com/](https://docs.openzeppelin.com/)
- **Solidity Docs**: [https://docs.soliditylang.org/](https://docs.soliditylang.org/)
- **ERC721 Standard**: [https://eips.ethereum.org/EIPS/eip-721](https://eips.ethereum.org/EIPS/eip-721)

---

## 🤝 Contributing

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch
3. **Write** comprehensive tests
4. **Run** security analysis
5. **Submit** pull request

### Code Standards

- **Solidity 0.8.25+**: Latest stable version
- **OpenZeppelin**: Use audited libraries
- **NatSpec**: Document all public functions
- **Test Coverage**: Maintain 95%+ coverage
- **Gas Optimization**: Efficient implementations

### Security Requirements

- **All tests must pass**: Including security tests
- **Gas benchmarks**: No significant regressions
- **Static analysis**: Clean Slither reports
- **Code review**: Peer review required

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

## 🙏 Acknowledgments

- **OpenZeppelin** for secure smart contract libraries
- **Foundry** team for excellent development tools
- **Ethereum** community for blockchain infrastructure
- **Security Auditors** for comprehensive code review

---

**Built with ❤️ by [Darkartt](https://github.com/Darkartt/)**

*Secure • Transparent • Scalper-proof*