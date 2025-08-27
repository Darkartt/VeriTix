# VeriTix Factory Deployment Guide

This guide provides comprehensive instructions for deploying and verifying the VeriTix Factory architecture.

## Overview

The VeriTix Factory architecture consists of:
- **VeriTixFactory**: Main factory contract that deploys individual event contracts
- **VeriTixEvent**: Individual event contracts (ERC721) with anti-scalping features
- **Supporting Libraries**: VeriTixTypes and interfaces

## Prerequisites

### Environment Setup

1. **Install Foundry**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Install Dependencies**
   ```bash
   cd foundry
   forge install
   ```

3. **Set Environment Variables**
   ```bash
   # Required for deployment
   export PRIVATE_KEY="your_private_key_here"
   export RPC_URL="your_rpc_url_here"
   
   # Optional configuration
   export FACTORY_OWNER="0x..." # Defaults to deployer address
   export ETHERSCAN_API_KEY="your_etherscan_api_key" # For verification
   ```

### Network Configuration

Supported networks:
- **Mainnet**: `--rpc-url $MAINNET_RPC_URL`
- **Sepolia**: `--rpc-url $SEPOLIA_RPC_URL`
- **Polygon**: `--rpc-url $POLYGON_RPC_URL`
- **Local**: `--rpc-url http://localhost:8545`

## Deployment Process

### 1. Deploy Factory Contract

#### Basic Deployment
```bash
# Deploy to local network (anvil)
forge script script/DeployFactory.s.sol --rpc-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast

# Deploy to testnet (Sepolia)
forge script script/DeployFactory.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Deploy to mainnet
forge script script/DeployFactory.s.sol --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --slow
```

#### Advanced Deployment with Custom Configuration
```bash
# Deploy with custom factory owner
FACTORY_OWNER=0x1234567890123456789012345678901234567890 \
forge script script/DeployFactory.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Deploy without test events
forge script script/DeployFactory.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast \
  --sig "run(bool)" false
```

### 2. Verify Deployment

#### Automatic Verification (during deployment)
```bash
# Verify on Etherscan during deployment
forge script script/DeployFactory.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

#### Manual Verification (after deployment)
```bash
# Verify factory contract
forge verify-contract <FACTORY_ADDRESS> src/VeriTixFactory.sol:VeriTixFactory --etherscan-api-key $ETHERSCAN_API_KEY --rpc-url $RPC_URL

# Verify event contract
forge verify-contract <EVENT_ADDRESS> src/VeriTixEvent.sol:VeriTixEvent --etherscan-api-key $ETHERSCAN_API_KEY --rpc-url $RPC_URL
```

#### Functional Verification
```bash
# Run comprehensive verification tests
forge script script/VerifyDeployment.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  --sig "run(address)" <FACTORY_ADDRESS>

# Quick verification check
forge script script/VerifyDeployment.s.sol --rpc-url $RPC_URL \
  --sig "quickVerify(address)" <FACTORY_ADDRESS>
```

## Migration from Monolithic Contract

### 1. Prepare Migration

```bash
# Initialize migration utilities
forge script script/MigrationUtils.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  --sig "initializeMigration(address,address)" <OLD_CONTRACT> <NEW_FACTORY>

# Analyze existing contract
forge script script/MigrationUtils.s.sol --rpc-url $RPC_URL \
  --sig "analyzeMigration()"
```

### 2. Execute Migration

```bash
# Prepare migration events (example)
forge script script/MigrationUtils.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  --sig "prepareMigrationEvents((string,string,uint256,uint256,address,string,uint256,uint256)[])" \
  '[("Event 1","EVT1",100,1000000000000000000,"0x...","https://api.veritix.com/1/",110,5)]'

# Execute migration
forge script script/MigrationUtils.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  --sig "executeMigration()"

# Verify migration results
forge script script/MigrationUtils.s.sol --rpc-url $RPC_URL \
  --sig "verifyMigration()"
```

## Post-Deployment Configuration

### 1. Factory Configuration

```bash
# Set global resale percentage (owner only)
cast send <FACTORY_ADDRESS> "setGlobalMaxResalePercent(uint256)" 120 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Set default organizer fee (owner only)
cast send <FACTORY_ADDRESS> "setDefaultOrganizerFee(uint256)" 5 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Set event creation fee (owner only)
cast send <FACTORY_ADDRESS> "setEventCreationFee(uint256)" 1000000000000000000 \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### 2. Create Events

```bash
# Create an event via cast
cast send <FACTORY_ADDRESS> "createEvent((string,string,uint256,uint256,address,string,uint256,uint256))" \
  '("My Event","MYEVT",1000,50000000000000000,"0x...","https://api.veritix.com/myevent/",110,5)' \
  --value 0 --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## Monitoring and Maintenance

### 1. Check Factory Status

```bash
# Get factory configuration
cast call <FACTORY_ADDRESS> "getFactoryConfig()" --rpc-url $RPC_URL

# Get total events
cast call <FACTORY_ADDRESS> "getTotalEvents()" --rpc-url $RPC_URL

# Check if factory is paused
cast call <FACTORY_ADDRESS> "factoryPaused()" --rpc-url $RPC_URL
```

### 2. Monitor Events

```bash
# Get all deployed events
cast call <FACTORY_ADDRESS> "getDeployedEvents()" --rpc-url $RPC_URL

# Get events by organizer
cast call <FACTORY_ADDRESS> "getEventsByOrganizer(address)" <ORGANIZER_ADDRESS> --rpc-url $RPC_URL

# Get event info
cast call <EVENT_ADDRESS> "getEventInfo()" --rpc-url $RPC_URL
```

### 3. Emergency Procedures

```bash
# Pause factory (owner only)
cast send <FACTORY_ADDRESS> "setPaused(bool)" true \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Cancel event (organizer only)
cast send <EVENT_ADDRESS> "cancelEvent(string)" "Emergency cancellation" \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## Testing

### 1. Local Testing

```bash
# Start local node
anvil

# Deploy to local network
forge script script/DeployFactory.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# Run tests
forge test -vvv
```

### 2. Integration Testing

```bash
# Run integration tests
forge test --match-contract IntegrationTest -vvv

# Run specific test
forge test --match-test testCompleteTicketLifecycle -vvv

# Run with gas reporting
forge test --gas-report
```

## Troubleshooting

### Common Issues

1. **Deployment Fails with "Insufficient Funds"**
   - Ensure deployer account has enough ETH for gas
   - Check gas price and limit settings

2. **Verification Fails**
   - Ensure contract is deployed and confirmed
   - Check Etherscan API key is valid
   - Wait for block confirmations before verifying

3. **Event Creation Fails**
   - Check factory is not paused
   - Verify event parameters are valid
   - Ensure sufficient payment for creation fee

4. **Migration Issues**
   - Verify old contract address is correct
   - Check migration parameters match old contract data
   - Ensure sufficient gas for batch operations

### Debug Commands

```bash
# Check contract bytecode
cast code <CONTRACT_ADDRESS> --rpc-url $RPC_URL

# Get transaction receipt
cast receipt <TX_HASH> --rpc-url $RPC_URL

# Simulate transaction
cast call <CONTRACT_ADDRESS> "functionName()" --rpc-url $RPC_URL

# Check balance
cast balance <ADDRESS> --rpc-url $RPC_URL
```

## Security Considerations

### 1. Private Key Management
- Never commit private keys to version control
- Use hardware wallets for mainnet deployments
- Consider multi-sig wallets for factory ownership

### 2. Contract Verification
- Always verify contracts on Etherscan
- Run comprehensive functional tests
- Audit contracts before mainnet deployment

### 3. Access Control
- Set appropriate factory owner
- Use multi-sig for critical operations
- Monitor factory settings changes

## Gas Optimization

### Deployment Costs (Estimated)
- **VeriTixFactory**: ~2,500,000 gas
- **VeriTixEvent**: ~2,000,000 gas per event
- **Event Creation**: ~2,100,000 gas per event

### Optimization Tips
- Deploy during low gas periods
- Use `--optimize` flag for production
- Consider CREATE2 for deterministic addresses

## Support

For deployment issues or questions:
1. Check the troubleshooting section above
2. Review contract documentation
3. Run verification scripts to identify issues
4. Check network status and gas prices

## Appendix

### A. Environment Variables Reference
```bash
# Required
PRIVATE_KEY=           # Deployer private key
RPC_URL=              # Network RPC URL

# Optional
FACTORY_OWNER=        # Custom factory owner (defaults to deployer)
ETHERSCAN_API_KEY=    # For contract verification
CREATE_TEST_EVENTS=   # Whether to create test events (true/false)
TEST_EVENTS_COUNT=    # Number of test events to create
```

### B. Contract Addresses Template
```
Network: [NETWORK_NAME]
Factory: [FACTORY_ADDRESS]
Owner: [OWNER_ADDRESS]
Deployed: [TIMESTAMP]
Block: [BLOCK_NUMBER]
Tx Hash: [DEPLOYMENT_TX_HASH]
```

### C. Verification Checklist
- [ ] Factory contract deployed successfully
- [ ] Factory owner set correctly
- [ ] Factory configuration is correct
- [ ] Event creation works
- [ ] Ticket minting works
- [ ] Resale mechanism works
- [ ] Refund system works
- [ ] Check-in system works
- [ ] Contracts verified on Etherscan
- [ ] Integration tests pass
- [ ] Security audit completed (for production)