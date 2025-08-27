# VeriTix Factory Deployment Checklist

This checklist ensures a complete and secure deployment of the VeriTix Factory architecture.

## Pre-Deployment Checklist

### 1. Environment Setup
- [ ] Foundry installed and updated (`foundryup`)
- [ ] Dependencies installed (`forge install`)
- [ ] Contracts compile successfully (`forge build`)
- [ ] All tests pass (`forge test`)
- [ ] Gas snapshots created (`forge snapshot`)

### 2. Security Review
- [ ] Code audit completed (for production)
- [ ] Security tests pass (`forge test --match-contract SecurityTest`)
- [ ] Access control tests pass (`forge test --match-contract AccessControlTest`)
- [ ] Reentrancy tests pass (`forge test --match-contract ReentrancyTest`)
- [ ] Integration tests pass (`forge test --match-contract IntegrationTest`)

### 3. Configuration Preparation
- [ ] Network configuration verified
- [ ] RPC endpoints tested and accessible
- [ ] Private keys secured (hardware wallet recommended for mainnet)
- [ ] Etherscan API keys configured
- [ ] Gas price strategy determined

### 4. Documentation Review
- [ ] Deployment documentation reviewed
- [ ] Contract interfaces documented
- [ ] Migration plan prepared (if applicable)
- [ ] Rollback plan prepared

## Deployment Process

### 1. Local Testing
- [ ] Deploy to local Anvil network
  ```bash
  make anvil  # In separate terminal
  make deploy-local
  ```
- [ ] Verify local deployment functionality
  ```bash
  make verify FACTORY_ADDRESS=<address> RPC_URL=http://localhost:8545
  ```
- [ ] Test event creation and ticket operations
- [ ] Verify gas usage is acceptable

### 2. Testnet Deployment
- [ ] Deploy to testnet (Sepolia recommended)
  ```bash
  make deploy-sepolia PRIVATE_KEY=$PRIVATE_KEY
  ```
- [ ] Verify contracts on block explorer
  ```bash
  make verify-etherscan FACTORY_ADDRESS=<address> ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY
  ```
- [ ] Run comprehensive verification
  ```bash
  make verify FACTORY_ADDRESS=<address> RPC_URL=$SEPOLIA_RPC_URL
  ```
- [ ] Test all functionality on testnet
- [ ] Performance testing completed
- [ ] Frontend integration tested

### 3. Mainnet Deployment (Production Only)
- [ ] Final security review completed
- [ ] Deployment parameters finalized
- [ ] Gas price optimized for deployment time
- [ ] Deploy to mainnet
  ```bash
  make deploy-mainnet PRIVATE_KEY=$PRIVATE_KEY
  ```
- [ ] Verify contracts immediately after deployment
- [ ] Run post-deployment verification
- [ ] Monitor for any issues in first 24 hours

## Post-Deployment Checklist

### 1. Contract Verification
- [ ] Factory contract verified on Etherscan/block explorer
- [ ] Test event contracts verified (if created)
- [ ] Contract source code matches deployed bytecode
- [ ] ABI and metadata uploaded correctly

### 2. Functional Verification
- [ ] Factory owner set correctly
- [ ] Factory configuration matches requirements
- [ ] Event creation works
- [ ] Ticket minting works
- [ ] Resale mechanism works
- [ ] Refund system works
- [ ] Check-in system works
- [ ] Event cancellation works

### 3. Security Verification
- [ ] Access controls working correctly
- [ ] Transfer restrictions enforced
- [ ] Price caps enforced
- [ ] Reentrancy protection active
- [ ] Emergency functions accessible to owner only

### 4. Integration Testing
- [ ] Frontend can interact with contracts
- [ ] Marketplace integration works (if applicable)
- [ ] Wallet integration works
- [ ] Event creation UI works
- [ ] Ticket purchasing UI works

### 5. Monitoring Setup
- [ ] Contract events monitoring configured
- [ ] Error alerting set up
- [ ] Gas usage monitoring active
- [ ] Transaction monitoring active
- [ ] Balance monitoring for critical addresses

## Configuration Checklist

### Factory Configuration
- [ ] Global max resale percentage: ____%
- [ ] Default organizer fee: ____%
- [ ] Event creation fee: ____ ETH/MATIC
- [ ] Factory owner: 0x____
- [ ] Factory not paused

### Network-Specific Settings
#### Mainnet
- [ ] Global max resale: 120%
- [ ] Default organizer fee: 5%
- [ ] Event creation fee: 0.01 ETH
- [ ] No test events created

#### Testnet
- [ ] Global max resale: 120%
- [ ] Default organizer fee: 5%
- [ ] Event creation fee: 0 ETH
- [ ] Test events created for testing

#### Polygon
- [ ] Global max resale: 115%
- [ ] Default organizer fee: 3%
- [ ] Event creation fee: 1 MATIC

## Migration Checklist (If Applicable)

### Pre-Migration
- [ ] Old contract analysis completed
- [ ] Migration parameters prepared
- [ ] Migration scripts tested on testnet
- [ ] Backup plan prepared

### Migration Execution
- [ ] Migration initialized
  ```bash
  make init-migration OLD_CONTRACT=<address> FACTORY_ADDRESS=<address>
  ```
- [ ] Migration analysis completed
  ```bash
  make analyze-migration
  ```
- [ ] Migration executed
  ```bash
  make execute-migration
  ```
- [ ] Migration verified
  ```bash
  make verify-migration
  ```

### Post-Migration
- [ ] All events migrated successfully
- [ ] Old contract deprecated/paused
- [ ] Users notified of migration
- [ ] Frontend updated to use new contracts

## Documentation Updates

### Technical Documentation
- [ ] Contract addresses documented
- [ ] ABI files updated
- [ ] Integration guide updated
- [ ] API documentation updated

### User Documentation
- [ ] User guide updated with new addresses
- [ ] FAQ updated with migration information
- [ ] Support documentation updated
- [ ] Troubleshooting guide updated

## Communication Checklist

### Internal Team
- [ ] Development team notified of deployment
- [ ] QA team has access to testnet deployment
- [ ] DevOps team has monitoring configured
- [ ] Support team briefed on changes

### External Communication
- [ ] Users notified of upcoming deployment (if applicable)
- [ ] Partners notified of new contract addresses
- [ ] Community updated via official channels
- [ ] Documentation published

## Emergency Procedures

### Rollback Plan
- [ ] Rollback criteria defined
- [ ] Rollback procedures documented
- [ ] Emergency contacts identified
- [ ] Communication plan for emergencies

### Emergency Functions
- [ ] Factory pause function tested
- [ ] Emergency withdrawal functions tested
- [ ] Owner transfer procedures documented
- [ ] Multi-sig procedures documented (if applicable)

## Final Sign-off

### Technical Review
- [ ] Lead Developer: _________________ Date: _______
- [ ] Security Auditor: ______________ Date: _______
- [ ] QA Lead: ______________________ Date: _______

### Business Review
- [ ] Product Manager: _______________ Date: _______
- [ ] Project Manager: ______________ Date: _______

### Deployment Authorization
- [ ] CTO/Technical Lead: ____________ Date: _______

## Deployment Record

### Deployment Information
- **Network**: _______________
- **Date**: _________________
- **Time**: _________________
- **Deployer Address**: 0x____________________
- **Factory Address**: 0x_____________________
- **Deployment Transaction**: 0x_______________
- **Block Number**: __________________________
- **Gas Used**: _____________________________
- **Gas Price**: ____________________________

### Verification Information
- **Etherscan Verification**: ________________
- **Functional Tests**: _____________________
- **Integration Tests**: ____________________
- **Security Verification**: _________________

### Notes
_Add any additional notes, issues encountered, or deviations from standard process:_

---

**Deployment Status**: [ ] Complete [ ] Incomplete [ ] Failed

**Next Steps**:
1. ________________________________
2. ________________________________
3. ________________________________

**Responsible Party**: _______________
**Follow-up Date**: _________________