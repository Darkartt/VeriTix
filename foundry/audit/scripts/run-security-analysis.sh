#!/bin/bash

# VeriTix Security Analysis Automation Script
# This script runs comprehensive security analysis using multiple tools

set -e  # Exit on any error

# Configuration
FOUNDRY_DIR="$(pwd)"
AUDIT_DIR="$FOUNDRY_DIR/audit"
REPORTS_DIR="$AUDIT_DIR/reports"
CONFIG_DIR="$AUDIT_DIR/config"
SCRIPTS_DIR="$AUDIT_DIR/scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create necessary directories
setup_directories() {
    log "Setting up audit directories..."
    
    mkdir -p "$REPORTS_DIR/slither"
    mkdir -p "$REPORTS_DIR/mythril"
    mkdir -p "$REPORTS_DIR/forge"
    mkdir -p "$AUDIT_DIR/baselines"
    
    success "Audit directories created"
}

# Check if required tools are installed
check_dependencies() {
    log "Checking security analysis dependencies..."
    
    # Check Foundry
    if ! command -v forge &> /dev/null; then
        error "Foundry (forge) is not installed. Please install from https://getfoundry.sh/"
        exit 1
    fi
    
    # Check Slither
    if ! command -v slither &> /dev/null; then
        warning "Slither is not installed. Installing via pip..."
        pip install slither-analyzer || {
            error "Failed to install Slither. Please install manually: pip install slither-analyzer"
            exit 1
        }
    fi
    
    # Check Mythril
    if ! command -v myth &> /dev/null; then
        warning "Mythril is not installed. Installing via pip..."
        pip install mythril || {
            error "Failed to install Mythril. Please install manually: pip install mythril"
            exit 1
        }
    fi
    
    # Check Node.js for custom analyzers
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed. Required for custom analyzers."
        exit 1
    fi
    
    success "All dependencies are available"
}

# Build contracts
build_contracts() {
    log "Building contracts with Foundry..."
    
    forge clean
    forge build --force || {
        error "Contract compilation failed"
        exit 1
    }
    
    success "Contracts built successfully"
}

# Run Foundry tests with gas reporting
run_foundry_tests() {
    log "Running Foundry tests with gas reporting..."
    
    # Run tests with gas reporting
    forge test --gas-report > "$REPORTS_DIR/forge/test-results.txt" 2>&1 || {
        warning "Some tests failed, but continuing with analysis"
    }
    
    # Run tests with JSON output for processing
    forge test --json > "$REPORTS_DIR/forge/test-results.json" 2>&1 || {
        warning "JSON test output failed, but continuing"
    }
    
    success "Foundry tests completed"
}

# Run Slither analysis
run_slither_analysis() {
    log "Running Slither static analysis..."
    
    local slither_config="$CONFIG_DIR/slither.config.json"
    local output_dir="$REPORTS_DIR/slither"
    
    # Run Slither with configuration
    slither . \
        --config-file "$slither_config" \
        --json "$output_dir/slither-report.json" \
        --sarif "$output_dir/slither-report.sarif" \
        --checklist \
        --markdown "$output_dir/slither-report.md" \
        > "$output_dir/slither-output.txt" 2>&1 || {
        warning "Slither analysis completed with findings"
    }
    
    success "Slither analysis completed"
}

# Run Mythril analysis
run_mythril_analysis() {
    log "Running Mythril symbolic execution analysis..."
    
    local output_dir="$REPORTS_DIR/mythril"
    
    # Analyze main contracts
    local contracts=("VeriTix" "VeriTixFactory" "VeriTixEvent")
    
    for contract in "${contracts[@]}"; do
        log "Analyzing $contract with Mythril..."
        
        # Find the contract file
        local contract_file=$(find src -name "*.sol" -exec grep -l "contract $contract" {} \;)
        
        if [ -n "$contract_file" ]; then
            myth analyze "$contract_file" \
                --solv 0.8.19 \
                --execution-timeout 1800 \
                --create-timeout 120 \
                --max-depth 50 \
                --output json \
                > "$output_dir/${contract}-mythril-report.json" 2>&1 || {
                warning "Mythril analysis for $contract completed with findings"
            }
        else
            warning "Contract file for $contract not found"
        fi
    done
    
    # Combine all Mythril reports
    node "$SCRIPTS_DIR/combine-mythril-reports.js" "$output_dir" > "$output_dir/mythril-report.json"
    
    success "Mythril analysis completed"
}

# Run custom security analyzers
run_custom_analyzers() {
    log "Running custom security analyzers..."
    
    # Run vulnerability classifier
    cd "$FOUNDRY_DIR"
    node "$SCRIPTS_DIR/vulnerability-classifier.js" || {
        warning "Vulnerability classification completed with warnings"
    }
    
    success "Custom analyzers completed"
}

# Run gas profiling
run_gas_profiling() {
    log "Running gas profiling and optimization analysis..."
    
    cd "$FOUNDRY_DIR"
    node "$SCRIPTS_DIR/gas-profiler.js" || {
        warning "Gas profiling completed with warnings"
    }
    
    success "Gas profiling completed"
}

# Generate comprehensive security report
generate_security_report() {
    log "Generating comprehensive security report..."
    
    local report_file="$REPORTS_DIR/comprehensive-security-report.json"
    
    # Combine all analysis results
    node -e "
    const fs = require('fs');
    const path = require('path');
    
    const reportsDir = '$REPORTS_DIR';
    const report = {
        metadata: {
            generated_at: new Date().toISOString(),
            version: '1.0.0',
            analysis_tools: ['slither', 'mythril', 'foundry', 'custom']
        },
        security_assessment: {},
        gas_optimization: {},
        test_results: {},
        recommendations: []
    };
    
    // Load security assessment if available
    try {
        const securityFile = path.join(reportsDir, 'security-assessment.json');
        if (fs.existsSync(securityFile)) {
            report.security_assessment = JSON.parse(fs.readFileSync(securityFile, 'utf8'));
        }
    } catch (e) { console.warn('Security assessment not available'); }
    
    // Load gas optimization report if available
    try {
        const gasFile = path.join(reportsDir, 'gas-optimization-report.json');
        if (fs.existsSync(gasFile)) {
            report.gas_optimization = JSON.parse(fs.readFileSync(gasFile, 'utf8'));
        }
    } catch (e) { console.warn('Gas optimization report not available'); }
    
    // Load test results if available
    try {
        const testFile = path.join(reportsDir, 'forge/test-results.json');
        if (fs.existsSync(testFile)) {
            report.test_results = JSON.parse(fs.readFileSync(testFile, 'utf8'));
        }
    } catch (e) { console.warn('Test results not available'); }
    
    // Generate overall recommendations
    report.recommendations = [
        {
            priority: 'HIGH',
            category: 'SECURITY',
            title: 'Address Critical Security Findings',
            description: 'Review and remediate all critical and high-severity security findings before mainnet deployment'
        },
        {
            priority: 'MEDIUM', 
            category: 'GAS_OPTIMIZATION',
            title: 'Implement Gas Optimizations',
            description: 'Apply identified gas optimizations to reduce transaction costs for users'
        },
        {
            priority: 'LOW',
            category: 'TESTING',
            title: 'Enhance Test Coverage',
            description: 'Increase test coverage for edge cases and security scenarios'
        }
    ];
    
    fs.writeFileSync('$report_file', JSON.stringify(report, null, 2));
    console.log('Comprehensive security report generated');
    "
    
    success "Comprehensive security report generated at $report_file"
}

# Display analysis summary
display_summary() {
    log "Security Analysis Summary"
    echo "=========================="
    
    # Security Assessment Summary
    if [ -f "$REPORTS_DIR/security-assessment.json" ]; then
        echo "Security Assessment:"
        node -e "
        const report = JSON.parse(require('fs').readFileSync('$REPORTS_DIR/security-assessment.json', 'utf8'));
        console.log('  Overall Score: ' + report.security_assessment.overall_score + '/100');
        console.log('  Mainnet Ready: ' + (report.security_assessment.mainnet_ready ? 'YES' : 'NO'));
        console.log('  Total Findings: ' + report.security_assessment.total_findings);
        "
    fi
    
    # Gas Optimization Summary
    if [ -f "$REPORTS_DIR/gas-optimization-report.json" ]; then
        echo "Gas Optimization:"
        node -e "
        const report = JSON.parse(require('fs').readFileSync('$REPORTS_DIR/gas-optimization-report.json', 'utf8'));
        console.log('  Optimization Opportunities: ' + report.summary.total_optimization_opportunities);
        console.log('  Potential Savings: ' + report.summary.potential_total_savings + ' gas');
        console.log('  High Priority: ' + report.summary.high_priority_optimizations);
        "
    fi
    
    echo ""
    echo "Reports generated in: $REPORTS_DIR"
    echo "=========================="
}

# Main execution function
main() {
    log "Starting VeriTix Security Analysis"
    
    # Setup
    setup_directories
    check_dependencies
    
    # Build and test
    build_contracts
    run_foundry_tests
    
    # Security analysis
    run_slither_analysis
    run_mythril_analysis
    run_custom_analyzers
    
    # Gas analysis
    run_gas_profiling
    
    # Generate reports
    generate_security_report
    
    # Display summary
    display_summary
    
    success "Security analysis completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "slither")
        setup_directories
        check_dependencies
        build_contracts
        run_slither_analysis
        ;;
    "mythril")
        setup_directories
        check_dependencies
        build_contracts
        run_mythril_analysis
        ;;
    "gas")
        setup_directories
        check_dependencies
        build_contracts
        run_foundry_tests
        run_gas_profiling
        ;;
    "test")
        setup_directories
        check_dependencies
        build_contracts
        run_foundry_tests
        ;;
    "custom")
        setup_directories
        check_dependencies
        run_custom_analyzers
        ;;
    "report")
        generate_security_report
        display_summary
        ;;
    *)
        main
        ;;
esac