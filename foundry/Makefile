# VeriTix Factory Deployment Makefile
# This makefile provides convenient commands for deploying and managing VeriTix contracts

# ============ CONFIGURATION ============

# Default network (can be overridden)
NETWORK ?= local
RPC_URL ?= http://localhost:8545
PRIVATE_KEY ?= 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Contract addresses (set after deployment)
FACTORY_ADDRESS ?=
EVENT_ADDRESS ?=

# Verification settings
ETHERSCAN_API_KEY ?=
VERIFY ?= false

# ============ HELP ============

.PHONY: help
help: ## Show this help message
	@echo "VeriTix Factory Deployment Commands"
	@echo "=================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Environment Variables:"
	@echo "  NETWORK          - Target network (local, sepolia, mainnet, polygon, etc.)"
	@echo "  RPC_URL          - RPC endpoint URL"
	@echo "  PRIVATE_KEY      - Deployer private key"
	@echo "  FACTORY_ADDRESS  - Deployed factory address (for post-deployment commands)"
	@echo "  ETHERSCAN_API_KEY - API key for contract verification"
	@echo ""
	@echo "Examples:"
	@echo "  make deploy NETWORK=sepolia"
	@echo "  make verify FACTORY_ADDRESS=0x123... NETWORK=sepolia"
	@echo "  make create-event FACTORY_ADDRESS=0x123... NETWORK=mainnet"

# ============ INSTALLATION ============

.PHONY: install
install: ## Install dependencies
	@echo "Installing Foundry dependencies..."
	forge install
	@echo "Dependencies installed successfully"

.PHONY: build
build: ## Build contracts
	@echo "Building contracts..."
	forge build
	@echo "Build completed"

.PHONY: test
test: ## Run tests
	@echo "Running tests..."
	forge test -vvv
	@echo "Tests completed"

.PHONY: test-gas
test-gas: ## Run tests with gas reporting
	@echo "Running tests with gas reporting..."
	forge test --gas-report
	@echo "Gas report completed"

# ============ LOCAL DEVELOPMENT ============

.PHONY: anvil
anvil: ## Start local Anvil node
	@echo "Starting Anvil local node..."
	anvil --host 0.0.0.0 --port 8545

.PHONY: deploy-local
deploy-local: ## Deploy to local Anvil network
	@echo "Deploying to local network..."
	forge script script/Deploy.s.sol \
		--rpc-url http://localhost:8545 \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--broadcast \
		-vvvv
	@echo "Local deployment completed"

.PHONY: deploy-factory-local
deploy-factory-local: ## Deploy only factory to local network
	@echo "Deploying factory to local network..."
	forge script script/DeployFactory.s.sol \
		--rpc-url http://localhost:8545 \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--broadcast \
		-vvvv
	@echo "Factory deployment completed"

# ============ TESTNET DEPLOYMENT ============

.PHONY: deploy-sepolia
deploy-sepolia: ## Deploy to Sepolia testnet
	@echo "Deploying to Sepolia testnet..."
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "Error: PRIVATE_KEY not set"; exit 1; fi
	forge script script/Deploy.s.sol \
		--rpc-url https://sepolia.infura.io/v3/$(INFURA_API_KEY) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvv
	@echo "Sepolia deployment completed"

.PHONY: deploy-mumbai
deploy-mumbai: ## Deploy to Mumbai testnet
	@echo "Deploying to Mumbai testnet..."
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "Error: PRIVATE_KEY not set"; exit 1; fi
	forge script script/Deploy.s.sol \
		--rpc-url https://polygon-mumbai.infura.io/v3/$(INFURA_API_KEY) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--etherscan-api-key $(POLYGONSCAN_API_KEY) \
		-vvv
	@echo "Mumbai deployment completed"

# ============ MAINNET DEPLOYMENT ============

.PHONY: deploy-mainnet
deploy-mainnet: ## Deploy to Ethereum mainnet (use with caution)
	@echo "⚠️  WARNING: Deploying to Ethereum mainnet!"
	@echo "This will cost real ETH. Are you sure? (Press Ctrl+C to cancel)"
	@read -p "Type 'YES' to continue: " confirm && [ "$$confirm" = "YES" ]
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "Error: PRIVATE_KEY not set"; exit 1; fi
	forge script script/Deploy.s.sol \
		--rpc-url https://mainnet.infura.io/v3/$(INFURA_API_KEY) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--slow \
		-vv
	@echo "Mainnet deployment completed"

.PHONY: deploy-polygon
deploy-polygon: ## Deploy to Polygon mainnet
	@echo "⚠️  WARNING: Deploying to Polygon mainnet!"
	@echo "This will cost real MATIC. Are you sure? (Press Ctrl+C to cancel)"
	@read -p "Type 'YES' to continue: " confirm && [ "$$confirm" = "YES" ]
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "Error: PRIVATE_KEY not set"; exit 1; fi
	forge script script/Deploy.s.sol \
		--rpc-url https://polygon-mainnet.infura.io/v3/$(INFURA_API_KEY) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--etherscan-api-key $(POLYGONSCAN_API_KEY) \
		-vv
	@echo "Polygon deployment completed"

# ============ GENERIC DEPLOYMENT ============

.PHONY: deploy
deploy: ## Deploy to specified network
	@echo "Deploying to $(NETWORK)..."
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "Error: PRIVATE_KEY not set"; exit 1; fi
	@if [ -z "$(RPC_URL)" ]; then echo "Error: RPC_URL not set"; exit 1; fi
	forge script script/Deploy.s.sol \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		$(if $(filter true,$(VERIFY)),--verify --etherscan-api-key $(ETHERSCAN_API_KEY),) \
		-vvv
	@echo "Deployment to $(NETWORK) completed"

# ============ VERIFICATION ============

.PHONY: verify
verify: ## Verify deployed contracts
	@echo "Verifying deployment..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	forge script script/VerifyDeployment.s.sol \
		--rpc-url $(RPC_URL) \
		--sig "run(address)" $(FACTORY_ADDRESS) \
		-vvv
	@echo "Verification completed"

.PHONY: quick-verify
quick-verify: ## Quick verification check
	@echo "Running quick verification..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	forge script script/VerifyDeployment.s.sol \
		--rpc-url $(RPC_URL) \
		--sig "quickVerify(address)" $(FACTORY_ADDRESS)
	@echo "Quick verification completed"

.PHONY: verify-etherscan
verify-etherscan: ## Verify contracts on Etherscan
	@echo "Verifying contracts on Etherscan..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then echo "Error: ETHERSCAN_API_KEY not set"; exit 1; fi
	forge verify-contract $(FACTORY_ADDRESS) \
		src/VeriTixFactory.sol:VeriTixFactory \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--rpc-url $(RPC_URL)
	@echo "Etherscan verification completed"

# ============ MIGRATION ============

.PHONY: init-migration
init-migration: ## Initialize migration from old contract
	@echo "Initializing migration..."
	@if [ -z "$(OLD_CONTRACT)" ]; then echo "Error: OLD_CONTRACT not set"; exit 1; fi
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	forge script script/MigrationUtils.s.sol \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--sig "initializeMigration(address,address)" $(OLD_CONTRACT) $(FACTORY_ADDRESS) \
		--broadcast
	@echo "Migration initialized"

.PHONY: analyze-migration
analyze-migration: ## Analyze old contract for migration
	@echo "Analyzing migration requirements..."
	forge script script/MigrationUtils.s.sol \
		--rpc-url $(RPC_URL) \
		--sig "analyzeMigration()"
	@echo "Migration analysis completed"

.PHONY: execute-migration
execute-migration: ## Execute migration
	@echo "Executing migration..."
	forge script script/MigrationUtils.s.sol \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--sig "executeMigration()" \
		--broadcast
	@echo "Migration executed"

.PHONY: verify-migration
verify-migration: ## Verify migration results
	@echo "Verifying migration..."
	forge script script/MigrationUtils.s.sol \
		--rpc-url $(RPC_URL) \
		--sig "verifyMigration()"
	@echo "Migration verification completed"

# ============ FACTORY MANAGEMENT ============

.PHONY: factory-status
factory-status: ## Check factory status
	@echo "Checking factory status..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	@echo "Factory Address: $(FACTORY_ADDRESS)"
	@echo "Owner: $$(cast call $(FACTORY_ADDRESS) 'owner()' --rpc-url $(RPC_URL))"
	@echo "Total Events: $$(cast call $(FACTORY_ADDRESS) 'getTotalEvents()' --rpc-url $(RPC_URL))"
	@echo "Factory Paused: $$(cast call $(FACTORY_ADDRESS) 'factoryPaused()' --rpc-url $(RPC_URL))"
	@echo "Global Max Resale %: $$(cast call $(FACTORY_ADDRESS) 'globalMaxResalePercent()' --rpc-url $(RPC_URL))"

.PHONY: pause-factory
pause-factory: ## Pause factory operations
	@echo "Pausing factory..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	cast send $(FACTORY_ADDRESS) "setPaused(bool)" true \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "Factory paused"

.PHONY: unpause-factory
unpause-factory: ## Unpause factory operations
	@echo "Unpausing factory..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	cast send $(FACTORY_ADDRESS) "setPaused(bool)" false \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "Factory unpaused"

.PHONY: set-resale-percent
set-resale-percent: ## Set global max resale percentage (PERCENT=120)
	@echo "Setting global max resale percentage to $(PERCENT)%..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	@if [ -z "$(PERCENT)" ]; then echo "Error: PERCENT not set"; exit 1; fi
	cast send $(FACTORY_ADDRESS) "setGlobalMaxResalePercent(uint256)" $(PERCENT) \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "Global max resale percentage set to $(PERCENT)%"

.PHONY: set-organizer-fee
set-organizer-fee: ## Set default organizer fee (FEE=5)
	@echo "Setting default organizer fee to $(FEE)%..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	@if [ -z "$(FEE)" ]; then echo "Error: FEE not set"; exit 1; fi
	cast send $(FACTORY_ADDRESS) "setDefaultOrganizerFee(uint256)" $(FEE) \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "Default organizer fee set to $(FEE)%"

# ============ EVENT MANAGEMENT ============

.PHONY: create-event
create-event: ## Create a test event (requires NAME, SYMBOL, SUPPLY, PRICE)
	@echo "Creating event..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	@if [ -z "$(NAME)" ]; then echo "Error: NAME not set"; exit 1; fi
	@if [ -z "$(SYMBOL)" ]; then echo "Error: SYMBOL not set"; exit 1; fi
	@if [ -z "$(SUPPLY)" ]; then echo "Error: SUPPLY not set"; exit 1; fi
	@if [ -z "$(PRICE)" ]; then echo "Error: PRICE not set"; exit 1; fi
	cast send $(FACTORY_ADDRESS) \
		"createEvent((string,string,uint256,uint256,address,string,uint256,uint256))" \
		"($(NAME),$(SYMBOL),$(SUPPLY),$(PRICE),$$(cast wallet address --private-key $(PRIVATE_KEY)),https://api.veritix.com/$(SYMBOL)/,110,5)" \
		--value $$(cast call $(FACTORY_ADDRESS) 'eventCreationFee()' --rpc-url $(RPC_URL)) \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "Event created successfully"

.PHONY: list-events
list-events: ## List all events in factory
	@echo "Listing all events..."
	@if [ -z "$(FACTORY_ADDRESS)" ]; then echo "Error: FACTORY_ADDRESS not set"; exit 1; fi
	cast call $(FACTORY_ADDRESS) "getDeployedEvents()" --rpc-url $(RPC_URL)

.PHONY: event-info
event-info: ## Get event information (requires EVENT_ADDRESS)
	@echo "Getting event information..."
	@if [ -z "$(EVENT_ADDRESS)" ]; then echo "Error: EVENT_ADDRESS not set"; exit 1; fi
	@echo "Event Address: $(EVENT_ADDRESS)"
	cast call $(EVENT_ADDRESS) "getEventInfo()" --rpc-url $(RPC_URL)

# ============ TICKET OPERATIONS ============

.PHONY: mint-ticket
mint-ticket: ## Mint a ticket (requires EVENT_ADDRESS)
	@echo "Minting ticket..."
	@if [ -z "$(EVENT_ADDRESS)" ]; then echo "Error: EVENT_ADDRESS not set"; exit 1; fi
	@TICKET_PRICE=$$(cast call $(EVENT_ADDRESS) 'ticketPrice()' --rpc-url $(RPC_URL)); \
	cast send $(EVENT_ADDRESS) "mintTicket()" \
		--value $$TICKET_PRICE \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY)
	@echo "Ticket minted successfully"

.PHONY: check-balance
check-balance: ## Check ticket balance for address (requires ADDRESS)
	@echo "Checking ticket balance..."
	@if [ -z "$(EVENT_ADDRESS)" ]; then echo "Error: EVENT_ADDRESS not set"; exit 1; fi
	@if [ -z "$(ADDRESS)" ]; then echo "Error: ADDRESS not set"; exit 1; fi
	cast call $(EVENT_ADDRESS) "balanceOf(address)" $(ADDRESS) --rpc-url $(RPC_URL)

# ============ UTILITIES ============

.PHONY: clean
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	forge clean
	@echo "Clean completed"

.PHONY: update
update: ## Update dependencies
	@echo "Updating dependencies..."
	forge update
	@echo "Update completed"

.PHONY: gas-snapshot
gas-snapshot: ## Create gas usage snapshot
	@echo "Creating gas snapshot..."
	forge snapshot
	@echo "Gas snapshot created"

.PHONY: coverage
coverage: ## Generate test coverage report
	@echo "Generating coverage report..."
	forge coverage
	@echo "Coverage report generated"

# ============ ENVIRONMENT SETUP ============

.PHONY: setup-env
setup-env: ## Setup environment file template
	@echo "Creating .env template..."
	@cat > .env.template << 'EOF'
# VeriTix Deployment Environment Variables

# Network Configuration
NETWORK=sepolia
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=your_private_key_here

# API Keys
ETHERSCAN_API_KEY=your_etherscan_api_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
INFURA_API_KEY=your_infura_api_key

# Contract Addresses (set after deployment)
FACTORY_ADDRESS=
OLD_CONTRACT=

# Deployment Settings
VERIFY=true
FACTORY_OWNER=
EOF
	@echo ".env template created. Copy to .env and fill in your values."
	@echo "⚠️  Never commit .env files with real private keys!"

# Default target
.DEFAULT_GOAL := help

# ============ SECURITY AUDIT TARGETS ============

# Run comprehensive security analysis
.PHONY: security-audit
security-audit: ## Run comprehensive security analysis
	@echo "Running comprehensive security analysis..."
	./audit/scripts/run-security-analysis.sh

# Run only Slither analysis
.PHONY: slither
slither: ## Run Slither static analysis
	@echo "Running Slither static analysis..."
	./audit/scripts/run-security-analysis.sh slither

# Run only Mythril analysis  
.PHONY: mythril
mythril: ## Run Mythril symbolic execution
	@echo "Running Mythril symbolic execution..."
	./audit/scripts/run-security-analysis.sh mythril

# Run gas profiling and optimization analysis
.PHONY: gas-profile
gas-profile: ## Run gas profiling analysis
	@echo "Running gas profiling analysis..."
	./audit/scripts/run-security-analysis.sh gas

# Run security foundation tests
.PHONY: security-test
security-test: ## Run security foundation tests
	@echo "Running security foundation tests..."
	forge test --match-contract SecurityFoundationTest -vv

# Run gas benchmarks
.PHONY: gas-benchmark
gas-benchmark: ## Run gas benchmarks
	@echo "Running gas benchmarks..."
	forge test --match-test "test_GasBenchmark" --gas-report

# Generate security reports
.PHONY: security-report
security-report: ## Generate security reports
	@echo "Generating security reports..."
	./audit/scripts/run-security-analysis.sh report

# Setup audit environment
.PHONY: audit-setup
audit-setup: ## Setup audit environment
	@echo "Setting up audit environment..."
	mkdir -p audit/reports/slither audit/reports/mythril audit/reports/forge audit/baselines
	chmod +x audit/scripts/*.sh
	@echo "Installing security tools..."
	pip install slither-analyzer mythril || echo "Please install security tools manually"

# Clean audit reports
.PHONY: audit-clean
audit-clean: ## Clean audit reports
	@echo "Cleaning audit reports..."
	rm -rf audit/reports/*
	rm -rf audit/baselines/*

# Run vulnerability classification
.PHONY: classify-vulnerabilities
classify-vulnerabilities: ## Run vulnerability classification
	@echo "Running vulnerability classification..."
	node audit/scripts/vulnerability-classifier.js

# Run custom security analyzers
.PHONY: custom-analyzers
custom-analyzers: ## Run custom security analyzers
	@echo "Running custom security analyzers..."
	./audit/scripts/run-security-analysis.sh custom

# ============ ADDITIONAL TESTING TARGETS ============

# Run all tests with coverage
.PHONY: test-coverage
test-coverage: ## Run tests with coverage
	forge coverage

# Run integration tests
.PHONY: test-integration
test-integration: ## Run integration tests
	forge test --match-contract IntegrationTest -vv

# Run reentrancy tests
.PHONY: test-reentrancy
test-reentrancy: ## Run reentrancy tests
	forge test --match-contract ReentrancyTest -vv

# Run access control tests
.PHONY: test-access-control
test-access-control: ## Run access control tests
	forge test --match-contract AccessControlTest -vv

# Run all security-focused tests
.PHONY: test-security-all
test-security-all: ## Run all security-focused tests
	forge test --match-test "test_Security" -vv

# Run performance tests
.PHONY: test-performance
test-performance: ## Run performance tests
	forge test --match-test "test_Performance" -vv

# ============ OPTIMIZATION TARGETS ============

# Profile gas usage for optimization
.PHONY: optimize-gas
optimize-gas: ## Profile gas usage for optimization
	@echo "Profiling gas usage for optimization..."
	forge test --gas-report > audit/reports/gas-usage.txt
	node audit/scripts/gas-profiler.js

# Validate optimizations
.PHONY: validate-optimizations
validate-optimizations: ## Validate gas optimizations
	@echo "Validating gas optimizations..."
	forge test --match-test "test_GasBenchmark" --gas-report
	node audit/scripts/gas-profiler.js