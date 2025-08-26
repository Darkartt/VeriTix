# 🤝 Contributing to VeriTix

Thank you for your interest in contributing to VeriTix! We welcome contributions from developers of all skill levels.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Security Considerations](#security-considerations)

## 📜 Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- **Be respectful** and inclusive to all contributors
- **Be constructive** in discussions and feedback
- **Focus on the code**, not the person
- **Help others learn** and grow in the community

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn
- Foundry for smart contract development
- Git for version control
- Basic knowledge of Solidity, TypeScript, and React

### Development Setup

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/veritix.git
   cd veritix
   ```

2. **Set up the development environment**
   ```bash
   # Install smart contract dependencies
   cd foundry
   forge install
   
   # Install frontend dependencies
   cd ../frontend
   npm install
   ```

3. **Run the development environment**
   ```bash
   # Terminal 1: Start local blockchain
   cd foundry
   anvil
   
   # Terminal 2: Deploy contracts locally
   forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <anvil-private-key> --broadcast
   
   # Terminal 3: Start frontend
   cd frontend
   npm run dev
   ```

## 🛠️ Contributing Guidelines

### Types of Contributions

We welcome the following types of contributions:

- **🐛 Bug fixes**: Fix issues in smart contracts or frontend
- **✨ New features**: Add new functionality
- **📚 Documentation**: Improve README, comments, or guides
- **🧪 Tests**: Add or improve test coverage
- **🎨 UI/UX**: Enhance user interface and experience
- **⚡ Performance**: Optimize gas usage or frontend performance
- **🔒 Security**: Identify and fix security vulnerabilities

### Before You Start

1. **Check existing issues** to see if your idea is already being worked on
2. **Create an issue** to discuss major changes before implementing
3. **Ask questions** in discussions if you're unsure about anything

## 🔄 Pull Request Process

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 2. Make Your Changes

- Follow our [coding standards](#coding-standards)
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass

### 3. Commit Your Changes

Use conventional commit messages:

```bash
git commit -m "feat: add event cancellation functionality"
git commit -m "fix: resolve refund transfer issue"
git commit -m "docs: update API documentation"
git commit -m "test: add unit tests for ticket purchasing"
```

**Commit Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `style`: Code style changes
- `perf`: Performance improvements
- `chore`: Maintenance tasks

### 4. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub with:
- **Clear title** describing the change
- **Detailed description** of what was changed and why
- **Screenshots** for UI changes
- **Testing instructions** for reviewers

## 📝 Coding Standards

### Smart Contracts (Solidity)

```solidity
// ✅ Good: Clear function names and documentation
/**
 * @notice Purchase a ticket for a specific event
 * @param eventId The ID of the event to purchase a ticket for
 * @dev Requires payment equal to ticket price
 */
function buyTicket(uint256 eventId) external payable {
    require(eventId < totalEvents, "Event does not exist");
    require(msg.value == events[eventId].ticketPrice, "Incorrect payment amount");
    // ... implementation
}

// ❌ Bad: Unclear naming and no documentation
function buy(uint256 id) external payable {
    require(id < total);
    // ... implementation
}
```

**Solidity Guidelines:**
- Use clear, descriptive function and variable names
- Add comprehensive NatSpec documentation
- Follow Checks-Effects-Interactions pattern
- Use OpenZeppelin libraries when possible
- Optimize for gas efficiency
- Include proper error messages

### Frontend (TypeScript/React)

```typescript
// ✅ Good: Typed components with clear props
interface EventCardProps {
  event: Event;
  onBuyTicket: (eventId: number) => void;
  isLoading?: boolean;
}

export const EventCard: React.FC<EventCardProps> = ({
  event,
  onBuyTicket,
  isLoading = false
}) => {
  return (
    <div className="glass-card-unified p-6">
      <h3 className="text-h3-unified">{event.name}</h3>
      {/* ... component implementation */}
    </div>
  );
};

// ❌ Bad: Untyped component with unclear props
export const EventCard = ({ event, onClick, loading }) => {
  return <div>{event.name}</div>;
};
```

**Frontend Guidelines:**
- Use TypeScript for all components
- Follow React best practices and hooks
- Use Tailwind CSS classes consistently
- Implement proper error handling
- Add loading states for async operations
- Ensure responsive design

### Code Formatting

We use automated formatting tools:

```bash
# Smart contracts
forge fmt

# Frontend
npm run lint
npm run format
```

## 🧪 Testing Requirements

### Smart Contract Tests

All smart contract changes must include tests:

```solidity
// Example test structure
contract VeriTixTest is Test {
    VeriTix public veriTix;
    
    function setUp() public {
        veriTix = new VeriTix(address(this));
    }
    
    function testBuyTicket() public {
        // Arrange
        veriTix.createEvent("Test Event", 1 ether, 100);
        
        // Act
        veriTix.buyTicket{value: 1 ether}(0);
        
        // Assert
        assertEq(veriTix.ownerOf(0), address(this));
    }
}
```

**Test Requirements:**
- Unit tests for all public functions
- Edge case testing
- Gas optimization tests
- Security vulnerability tests
- Integration tests for complex workflows

### Frontend Tests

```typescript
// Example component test
import { render, screen, fireEvent } from '@testing-library/react';
import { EventCard } from './EventCard';

describe('EventCard', () => {
  const mockEvent = {
    id: 1,
    name: 'Test Event',
    price: '0.1',
    maxTickets: 100,
    soldTickets: 50
  };

  it('should render event information correctly', () => {
    render(<EventCard event={mockEvent} onBuyTicket={jest.fn()} />);
    
    expect(screen.getByText('Test Event')).toBeInTheDocument();
    expect(screen.getByText('0.1 ETH')).toBeInTheDocument();
  });

  it('should call onBuyTicket when button is clicked', () => {
    const mockOnBuyTicket = jest.fn();
    render(<EventCard event={mockEvent} onBuyTicket={mockOnBuyTicket} />);
    
    fireEvent.click(screen.getByText('GET TICKET'));
    expect(mockOnBuyTicket).toHaveBeenCalledWith(1);
  });
});
```

**Frontend Test Requirements:**
- Component rendering tests
- User interaction tests
- Integration tests with Web3 hooks
- Responsive design tests
- Performance tests

### Running Tests

```bash
# Smart contract tests
cd foundry
forge test -vvv

# Frontend tests
cd frontend
npm test
npm run test:coverage

# All tests should pass before submitting PR
```

## 🔒 Security Considerations

### Smart Contract Security

- **Never introduce reentrancy vulnerabilities**
- **Always validate inputs** and check preconditions
- **Use SafeMath** or Solidity 0.8.x for overflow protection
- **Follow Checks-Effects-Interactions** pattern
- **Be cautious with external calls**
- **Test edge cases** thoroughly

### Frontend Security

- **Validate all user inputs** on both client and server
- **Sanitize data** before displaying
- **Use HTTPS** for all external requests
- **Never expose private keys** or sensitive data
- **Implement proper error handling**

### Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** create a public issue
2. **Email** security@veritix.com with details
3. **Wait** for our response before disclosure
4. **Follow** responsible disclosure practices

## 📋 Review Process

### What We Look For

- **Code Quality**: Clean, readable, well-documented code
- **Testing**: Comprehensive test coverage
- **Security**: No vulnerabilities introduced
- **Performance**: Gas-efficient smart contracts, fast frontend
- **Documentation**: Updated README and inline comments

### Review Timeline

- **Initial Review**: Within 2-3 business days
- **Follow-up**: Within 1 business day for requested changes
- **Merge**: After approval from 2+ maintainers

## 🎯 Good First Issues

Looking for a place to start? Check out issues labeled:

- `good first issue`: Perfect for newcomers
- `help wanted`: We need community help
- `documentation`: Improve our docs
- `testing`: Add more test coverage

## 💬 Getting Help

- **GitHub Discussions**: Ask questions and share ideas
- **Discord**: Join our community chat
- **Email**: Contact maintainers directly
- **Documentation**: Check our comprehensive docs

## 🙏 Recognition

Contributors will be:

- **Listed** in our README contributors section
- **Mentioned** in release notes for significant contributions
- **Invited** to join our contributor Discord channel
- **Eligible** for future bounties and rewards

---

Thank you for contributing to VeriTix! Together, we're building the future of decentralized event ticketing. 🎫✨