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

## 🧪 Testing

### Smart Contract Tests

```bash
cd foundry
forge test -vvv
```

**Test Coverage:**
- ✅ Event creation and management
- ✅ Ticket purchasing and validation
- ✅ Refund system functionality
- ✅ Access control and permissions
- ✅ Edge cases and error handling
- ✅ Gas optimization tests

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