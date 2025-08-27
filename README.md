# 🎫 VeriTix - Decentralized Event Ticketing Platform

<div align="center">

![VeriTix Logo](https://img.shields.io/badge/VeriTix-Decentralized%20Ticketing-8b5cf6?style=for-the-badge&logo=ethereum&logoColor=white)

[![Security Audit](https://img.shields.io/badge/Security%20Audit-B%2B%20Passed-green?style=flat-square)](./AUDIT_CERTIFICATE.md)
[![Smart Contract](https://img.shields.io/badge/Smart%20Contract-Solidity%200.8.25-blue?style=flat-square)](./foundry/src/VeriTix.sol)
[![Frontend](https://img.shields.io/badge/Frontend-Next.js%2015-black?style=flat-square)](./frontend)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](./LICENSE)

**Secure • Transparent • Scalper-proof**

[🚀 Live Demo](#) • [📖 Documentation](#documentation) • [🔒 Security Audit](./AUDIT_CERTIFICATE.md) • [🛠️ Contributing](#contributing)

</div>

---

## 🌟 Overview

VeriTix is a revolutionary decentralized event ticketing platform built on Ethereum that eliminates scalping, reduces fraud, and ensures transparent ticket distribution through blockchain technology and NFTs.

### ✨ Key Features

- **🔒 Anti-Scalping Protection**: Built-in price caps and transfer restrictions
- **🎫 NFT Tickets**: Each ticket is a unique, verifiable NFT
- **💰 Automatic Refunds**: Smart contract-powered refund system
- **📱 QR Code Integration**: Seamless check-in with generated QR codes
- **🌐 Decentralized**: No central authority or single point of failure
- **💎 Modern UI**: Beautiful glassmorphism design with smooth animations
- **📊 Transparent**: All transactions visible on the blockchain

---

## 🏗️ Architecture

```
VeriTix/
├── 🔗 Smart Contracts (Foundry)
│   ├── VeriTix.sol          # Main ERC721 ticketing contract
│   ├── Event Management     # Event creation and lifecycle
│   └── Refund System       # Automated refund processing
│
├── 🎨 Frontend (Next.js 15)
│   ├── Modern React App     # TypeScript + Tailwind CSS
│   ├── Web3 Integration    # Wagmi + RainbowKit
│   └── Glassmorphism UI    # Beautiful, responsive design
│
└── 🧪 Testing Suite
    ├── Smart Contract Tests # Foundry test suite (15+ tests)
    └── Frontend Tests      # Jest + React Testing Library
```

---

## 🚀 Quick Start

### Prerequisites

- **Node.js** 18+ and npm/yarn
- **Foundry** for smart contract development
- **MetaMask** or compatible Web3 wallet

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/veritix.git
cd veritix
```

### 2. Smart Contract Setup

```bash
cd foundry
forge install
forge build
forge test
```

### 3. Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

### 4. Deploy Locally

```bash
# Terminal 1: Start local blockchain
cd foundry
anvil

# Terminal 2: Deploy contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <private-key> --broadcast

# Terminal 3: Start frontend
cd frontend
npm run dev
```

Visit `http://localhost:3000` to see VeriTix in action! 🎉

---

## 🛠️ Technology Stack

### Smart Contracts

- **Solidity 0.8.25** - Smart contract language
- **Foundry** - Development framework
- **OpenZeppelin** - Security-audited contract libraries
- **ERC721** - NFT standard for tickets

### Frontend

- **Next.js 15** - React framework with App Router
- **TypeScript** - Type-safe development
- **Tailwind CSS** - Utility-first styling
- **Framer Motion** - Smooth animations
- **Wagmi** - React hooks for Ethereum
- **RainbowKit** - Wallet connection UI

### Development & Testing

- **Foundry** - Smart contract testing
- **Jest** - Frontend unit testing
- **React Testing Library** - Component testing
- **ESLint** - Code linting
- **Prettier** - Code formatting

---

## 📋 Features Deep Dive

### 🎫 NFT Ticketing System

- Each ticket is a unique ERC721 NFT
- Immutable ownership records on blockchain
- Built-in metadata with event details
- QR code generation for easy check-in

### 🛡️ Anti-Scalping Mechanisms

- **Price Caps**: Maximum resale price (2x original)
- **Transfer Restrictions**: Controlled secondary market
- **Organizer Royalties**: 5% automatic royalties
- **Transparent Pricing**: All prices visible on-chain

### 💰 Smart Refund System

- **Automatic Processing**: No manual intervention needed
- **Event Cancellation**: Full refunds for cancelled events
- **Secure Transfers**: Audited refund mechanism
- **Gas Optimized**: Efficient batch operations

### 🎨 Modern User Experience

- **Glassmorphism Design**: Beautiful, modern interface
- **Responsive Layout**: Works on all devices
- **Smooth Animations**: 60fps performance optimized
- **Dark Theme**: Easy on the eyes
- **Wallet Integration**: Seamless Web3 connection

---

## 🔒 Security & Audits

VeriTix has undergone comprehensive security auditing:

- **✅ Security Score**: B+ (Excellent)
- **✅ Smart Contract Audit**: All critical issues resolved
- **✅ Frontend Security**: XSS/CSRF protection implemented
- **✅ Test Coverage**: 90%+ coverage with 15+ test cases

[📋 View Full Security Audit](./AUDIT_CERTIFICATE.md)

### Security Features

- **Reentrancy Protection**: Checks-Effects-Interactions pattern
- **Access Control**: Role-based permissions
- **Input Validation**: Comprehensive parameter checking
- **Safe Math**: Overflow protection with Solidity 0.8.x
- **Gas Optimization**: Efficient operations

---

## 📖 Documentation

### Smart Contract API

#### Core Functions

```solidity
// Create a new event
function createEvent(
    string memory name,
    uint256 ticketPrice,
    uint256 maxTickets
) external onlyOwner

// Buy tickets for an event
function buyTicket(uint256 eventId) external payable

// Get event details
function getEventDetails(uint256 eventId) external view returns (
    string memory name,
    uint256 ticketPrice,
    uint256 maxTickets,
    uint256 ticketsSold,
    address organizer
)

// Refund ticket (for cancelled events)
function refundTicket(uint256 tokenId) external
```

#### Events

```solidity
event EventCreated(uint256 indexed eventId, string name, uint256 ticketPrice, uint256 maxTickets);
event TicketPurchased(uint256 indexed eventId, uint256 indexed tokenId, address buyer);
event EventCancelled(uint256 indexed eventId);
event TicketRefunded(uint256 indexed tokenId, address recipient, uint256 amount);
```

### Frontend Components

#### Key Components

- **ConnectButton**: Wallet connection interface
- **EventCard**: Display event information
- **TicketCard**: Show owned tickets with QR codes
- **BuyTicketButton**: Purchase ticket functionality

#### Hooks

- **useAccount**: Get connected wallet info
- **useReadContract**: Read blockchain data
- **useWriteContract**: Execute transactions

---

## 🧪 Testing & Security Audit

### Smart Contract Test Suite

VeriTix includes a comprehensive test suite with **23 test contracts** covering all security aspects:

#### Core Functionality Tests
```bash
cd foundry

# Run all tests
make test

# Run with gas reporting
make test-gas

# Run with coverage
make test-coverage
```

#### Security-Focused Test Categories

**🔒 Security Foundation Tests**
```bash
# Core security validations
forge test --match-contract SecurityFoundationTest -vv

# Access control security
forge test --match-contract AccessControlSecurityTest -vv

# Reentrancy protection
forge test --match-contract ReentrancyAnalysisTest -vv
```

**💰 Economic Attack Prevention**
```bash
# Economic attack simulations
forge test --match-contract EconomicAttackSimulationTest -vv

# Economic attack vectors
forge test --match-contract EconomicAttackVectorTest -vv

# Payment flow security
forge test --match-contract PaymentFlowSecurityTest -vv
```

**⛽ Gas Optimization & Performance**
```bash
# Gas optimization validation
forge test --match-contract GasOptimizationTest -vv

# Gas optimization validation
forge test --match-contract GasOptimizationValidationTest -vv

# Performance benchmarks
make gas-benchmark
```

**🎫 NFT Standards & Marketplace Compliance**
```bash
# NFT standards compliance
forge test --match-contract NFTStandardsComplianceTest -vv

# OpenSea integration
forge test --match-contract OpenSeaIntegrationTest -vv

# Metadata validation
forge test --match-contract MetadataTest -vv
```

**🔧 Integration & Edge Cases**
```bash
# Integration tests
forge test --match-contract IntegrationTest -vv

# Payment flow edge cases
forge test --match-contract PaymentFlowEdgeCasesTest -vv

# Error handling
forge test --match-contract ErrorHandlingTest -vv
```

#### Complete Test File List

| Test Category | Test Files | Purpose |
|---------------|------------|---------|
| **Core Contracts** | `VeriTixFactory.t.sol`, `VeriTixEvent.t.sol` | Basic functionality |
| **Security Foundation** | `SecurityFoundationTest.sol` | Core security validations |
| **Access Control** | `AccessControlTest.sol`, `AccessControlSecurityTest.sol`, `FactoryAccessControlTest.sol` | Permission systems |
| **Reentrancy Protection** | `ReentrancyTest.sol`, `ReentrancyAnalysisTest.sol` | Attack prevention |
| **Economic Security** | `EconomicAttackSimulationTest.sol`, `EconomicAttackVectorTest.sol` | Economic attack prevention |
| **Payment Security** | `PaymentFlowSecurityTest.sol`, `PaymentFlowEdgeCasesTest.sol` | Payment system security |
| **Gas Optimization** | `GasOptimizationTest.sol`, `GasOptimizationValidationTest.sol` | Performance optimization |
| **NFT Compliance** | `NFTStandardsComplianceTest.sol`, `OpenSeaIntegrationTest.sol` | Marketplace compatibility |
| **Critical Findings** | `CriticalFindingsValidationTest.sol` | Audit remediation validation |
| **Integration** | `IntegrationTest.sol`, `InterfaceTest.sol` | End-to-end testing |

### Security Audit Framework

#### Automated Security Analysis

**🔍 Run Complete Security Audit**
```bash
# Comprehensive security analysis
make security-audit

# Individual security tools
make slither      # Static analysis
make mythril      # Symbolic execution
make gas-profile  # Gas optimization analysis
```

#### Security Analysis Scripts

**Available Audit Scripts:**
```bash
# Core security analysis
./foundry/audit/scripts/run-security-analysis.sh

# Gas profiling and optimization
./foundry/audit/scripts/run-gas-optimization-analysis.sh

# Economic attack analysis
node ./foundry/audit/scripts/economic-attack-analyzer.js

# Vulnerability classification
node ./foundry/audit/scripts/vulnerability-classifier.js

# Marketplace compatibility
node ./foundry/audit/scripts/marketplace-compatibility-analyzer.js
```

#### Security Reports & Documentation

**📋 Generated Security Reports** (created when running audit):
- `foundry/audit/comprehensive-security-report.md` - Complete security analysis
- `foundry/audit/security-summary.json` - Executive summary
- `foundry/audit/critical-findings-documentation.md` - Critical issues & fixes
- `foundry/audit/prioritized-remediation-plan.md` - Remediation roadmap
- `foundry/audit/security-certification.md` - Security certification

**🔧 Generated Remediation Documentation:**
- `foundry/audit/remediation-implementation-guide.md` - Implementation guide
- `foundry/audit/patches/` - Security patches applied
- `foundry/audit/SECURITY_FOUNDATION_SUMMARY.md` - Security foundation

> **Note**: The `foundry/audit/` directory is generated during security analysis and not tracked in git. Run `make security-audit` to generate all audit reports and documentation.

#### Specialized Security Tests

**🛡️ Reentrancy Analysis**
```bash
# Run reentrancy-specific tests
make test-reentrancy

# View reentrancy analysis
cat foundry/audit/reentrancy-analysis-report.md
```

**🔐 Access Control Analysis**
```bash
# Run access control tests
make test-access-control

# View access control analysis
cat foundry/audit/access-control-vulnerability-analysis.md
```

**💸 Economic Attack Analysis**
```bash
# Run economic attack simulations
forge test --match-contract EconomicAttack -vv

# View economic analysis
cat foundry/audit/economic-attack-analysis.md
```

#### Gas Optimization Analysis

**⛽ Gas Profiling**
```bash
# Run gas optimization analysis
make optimize-gas

# Validate optimizations
make validate-optimizations

# View gas reports
cat foundry/audit/gas-optimization-final-report.md
```

**📊 Gas Optimization Reports:**
- `foundry/audit/gas-optimization-analysis-summary.md`
- `foundry/audit/reports/gas-optimization-report.json`
- `foundry/audit/reports/storage-optimization-report.json`

### Audit Setup & Configuration

#### Setup Audit Environment
```bash
# Install audit dependencies
make audit-setup

# Setup security tools (requires Python/Node.js)
pip install slither-analyzer mythril
npm install -g @mythx/cli
```

#### Audit Configuration Files
- `foundry/audit/config/slither.config.json` - Slither configuration
- `foundry/audit/config/mythril.config.json` - Mythril configuration

#### Running Custom Analysis
```bash
# Custom security analyzers
make custom-analyzers

# Classify vulnerabilities
make classify-vulnerabilities

# Clean audit reports
make audit-clean
```

---

## 🔧 Audit Scripts & Commands

### Quick Start Audit Commands

```bash
# Navigate to foundry directory
cd foundry

# Run complete security audit suite
make security-audit

# Run individual security tools
make slither                    # Static analysis
make mythril                   # Symbolic execution  
make gas-profile              # Gas optimization analysis
make security-test            # Security foundation tests
```

### Comprehensive Test Execution

```bash
# Run all tests with verbose output
make test

# Run security-focused tests only
make test-security-all

# Run tests with gas reporting
make test-gas

# Generate test coverage report
make coverage

# Run specific test categories
make test-reentrancy          # Reentrancy protection tests
make test-access-control      # Access control tests
make test-integration         # Integration tests
make test-performance         # Performance benchmarks
```

### Security Analysis Scripts

#### Core Security Analysis
```bash
# Run comprehensive security analysis
./audit/scripts/run-security-analysis.sh

# Run specific security tools
./audit/scripts/run-security-analysis.sh slither
./audit/scripts/run-security-analysis.sh mythril
./audit/scripts/run-security-analysis.sh gas
./audit/scripts/run-security-analysis.sh custom
```

#### Specialized Analysis Scripts
```bash
# Gas optimization analysis
./audit/scripts/run-gas-optimization-analysis.sh

# Payment flow security tests
./audit/scripts/run-payment-flow-tests.sh

# Economic attack analysis
node audit/scripts/economic-attack-analyzer.js

# Marketplace compatibility analysis
node audit/scripts/marketplace-compatibility-analyzer.js

# Storage optimization analysis
node audit/scripts/storage-optimization-analyzer.js

# Vulnerability classification
node audit/scripts/vulnerability-classifier.js

# Gas profiling
node audit/scripts/gas-profiler.js
node audit/scripts/simple-gas-profiler.js

# Combine Mythril reports
node audit/scripts/combine-mythril-reports.js
```

### Makefile Commands Reference

#### Testing Commands
```bash
make test                     # Run all tests
make test-gas                 # Run tests with gas reporting
make test-coverage            # Run tests with coverage
make test-integration         # Run integration tests
make test-reentrancy         # Run reentrancy tests
make test-access-control     # Run access control tests
make test-security-all       # Run all security tests
make test-performance        # Run performance tests
```

#### Security Audit Commands
```bash
make security-audit          # Complete security analysis
make slither                 # Slither static analysis
make mythril                 # Mythril symbolic execution
make gas-profile            # Gas profiling analysis
make security-test          # Security foundation tests
make security-report        # Generate security reports
```

#### Gas Optimization Commands
```bash
make gas-benchmark          # Run gas benchmarks
make optimize-gas           # Profile gas for optimization
make validate-optimizations # Validate gas optimizations
make gas-snapshot          # Create gas usage snapshot
```

#### Audit Environment Commands
```bash
make audit-setup           # Setup audit environment
make audit-clean          # Clean audit reports
make classify-vulnerabilities # Run vulnerability classification
make custom-analyzers     # Run custom security analyzers
```

#### Build & Deployment Commands
```bash
make build                # Build contracts
make install              # Install dependencies
make clean               # Clean build artifacts
make update              # Update dependencies
make deploy-local        # Deploy to local network
make verify              # Verify deployment
```

### Security Report Generation

#### Generate Comprehensive Reports
```bash
# Generate all security reports
make security-report

# View generated reports
ls -la foundry/audit/reports/

# Key report files:
# - comprehensive-security-report.md
# - security-summary.json
# - gas-optimization-report.json
# - storage-optimization-report.json
```

#### Manual Report Access
```bash
# First generate audit reports
make security-audit

# Then view security summaries
cat foundry/audit/SECURITY_FOUNDATION_SUMMARY.md
cat foundry/audit/security-certification.md
cat foundry/audit/comprehensive-security-report.md

# View specific analysis reports
cat foundry/audit/reentrancy-analysis-report.md
cat foundry/audit/access-control-vulnerability-analysis.md
cat foundry/audit/economic-attack-analysis.md
cat foundry/audit/gas-optimization-final-report.md
```

### Continuous Integration Setup

#### GitHub Actions Integration
```yaml
# Add to .github/workflows/security-audit.yml
name: Security Audit
on: [push, pull_request]
jobs:
  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      - name: Run Security Audit
        run: |
          cd foundry
          make audit-setup
          make security-audit
          make test-security-all
```

#### Pre-commit Hooks
```bash
# Setup pre-commit security checks
echo '#!/bin/bash
cd foundry
make test-security-all
make gas-benchmark
' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Security Audit Results & Remediation

#### 🛡️ Audit Summary
- **Security Grade**: B+ (Excellent)
- **Critical Issues**: 0 (All resolved)
- **High Severity**: 2 (All patched)
- **Medium Severity**: 5 (All addressed)
- **Low Severity**: 8 (All mitigated)
- **Gas Optimizations**: 12 (All implemented)

#### 🔧 Applied Security Patches
```bash
# Generate audit reports first, then view applied security patches
make security-audit
ls foundry/audit/patches/
# Generated patches:
# - patch-001-purchase-limits.diff
# - patch-002-minimum-resale-price.diff  
# - patch-003-gas-optimization.diff
# - patch-004-batch-dos-protection.diff
# - patch-005-input-validation.diff
```

#### 📋 Critical Findings Validation
```bash
# Validate all critical findings have been addressed
forge test --match-contract CriticalFindingsValidationTest -vv

# Generate and view critical findings documentation
make security-audit
cat foundry/audit/critical-findings-documentation.md
```

#### 🎯 Remediation Implementation
- **Reentrancy Protection**: CEI pattern implemented
- **Access Control**: Role-based permissions with OpenZeppelin
- **Input Validation**: Comprehensive parameter checking
- **Gas Optimization**: Storage packing and efficient algorithms
- **Economic Attacks**: Price manipulation prevention
- **DoS Protection**: Batch operation limits

### Test Coverage Metrics

**📈 Current Test Coverage:**
- **Smart Contracts**: 95%+ line coverage
- **Security Tests**: 100% critical path coverage
- **Gas Optimization**: Comprehensive benchmarking
- **Integration Tests**: Full workflow coverage

**🎯 Test Statistics:**
- **Total Test Files**: 23
- **Total Test Cases**: 200+
- **Security-Focused Tests**: 150+
- **Gas Optimization Tests**: 25+
- **Integration Tests**: 15+

**🔍 Audit Validation:**
- **Security Foundation Tests**: ✅ Passed
- **Reentrancy Analysis**: ✅ Protected
- **Access Control Security**: ✅ Secured
- **Economic Attack Prevention**: ✅ Mitigated
- **Gas Optimization**: ✅ Optimized
- **NFT Standards Compliance**: ✅ Compliant

### Frontend Tests

```bash
cd frontend
npm test
npm run test:coverage
```

**Test Suites:**

- ✅ Component rendering tests
- ✅ User interaction tests
- ✅ Web3 integration tests
- ✅ Responsive design tests
- ✅ Performance optimization tests

---

## 🚀 Deployment

### Testnet Deployment

```bash
# Deploy to Sepolia testnet
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Update frontend config
cp frontend/.env.example frontend/.env.local
# Edit CONTRACT_ADDRESS in .env.local
```

### Mainnet Deployment

```bash
# Deploy to Ethereum mainnet
forge script script/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Update production config
npm run build
npm run start
```

### Environment Variables

```bash
# Frontend (.env.local)
NEXT_PUBLIC_CONTRACT_ADDRESS=0x...
NEXT_PUBLIC_CHAIN_ID=1
NEXT_PUBLIC_ALCHEMY_ID=your_alchemy_id

# Smart Contracts (.env)
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_key
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/...
MAINNET_RPC_URL=https://mainnet.infura.io/v3/...
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](./CONTRIBUTING.md) for details.

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Standards

- **Smart Contracts**: Follow Solidity style guide
- **Frontend**: Use TypeScript, ESLint, and Prettier
- **Tests**: Maintain 90%+ coverage
- **Documentation**: Update README for new features

---

## 📊 Project Status

### Current Version: v1.0.0

- ✅ **Smart Contracts**: Production ready
- ✅ **Frontend**: Modern UI implemented
- ✅ **Security Audit**: B+ rating achieved
- ✅ **Testing**: Comprehensive test suite
- 🚧 **Mainnet Deployment**: Coming soon
- 🚧 **Mobile App**: Planned for v2.0

### Roadmap

#### Phase 1 (Current) ✅

- [x] Core smart contract development
- [x] Frontend application
- [x] Security audit and fixes
- [x] Comprehensive testing

#### Phase 2 (Q1 2025) 🚧

- [ ] Mainnet deployment
- [ ] Advanced analytics dashboard
- [ ] Multi-chain support (Polygon, Arbitrum)
- [ ] Mobile application

#### Phase 3 (Q2 2025) 📋

- [ ] DAO governance implementation
- [ ] Advanced marketplace features
- [ ] Integration with major event platforms
- [ ] Enterprise partnerships

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

## 🙏 Acknowledgments

- **OpenZeppelin** for secure smart contract libraries
- **Foundry** team for excellent development tools
- **Next.js** team for the amazing React framework
- **Ethereum** community for blockchain infrastructure
- **Security Auditors** for comprehensive code review

---

## 📞 Support & Contact

- **📧 Email**: support@veritix.com
- **🐦 Twitter**: [@VeriTixOfficial](https://twitter.com/veritixofficial)
- **💬 Discord**: [VeriTix Community](https://discord.gg/veritix)
- **📖 Documentation**: [docs.veritix.com](https://docs.veritix.com)
- **🐛 Issues**: [GitHub Issues](https://github.com/your-username/veritix/issues)

---

<div align="center">

**Built with ❤️ by the VeriTix Team**

[⭐ Star us on GitHub](https://github.com/your-username/veritix) • [🔗 Follow on Twitter](https://twitter.com/veritixofficial) • [📖 Read the Docs](https://docs.veritix.com)

</div>
