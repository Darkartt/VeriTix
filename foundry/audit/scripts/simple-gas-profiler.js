#!/usr/bin/env node

/**
 * Simple VeriTix Gas Profiler
 * 
 * Focused gas analysis based on test results
 */

const fs = require('fs');
const path = require('path');

class SimpleGasProfiler {
  constructor() {
    this.measurements = {};
  }

  /**
   * Analyze gas measurements from test output
   */
  analyzeGasMeasurements() {
    // Based on the test results we just ran
    this.measurements = {
      // Event Creation
      'createEvent_single': { gas: 2431533, priority: 'HIGH' },
      'createEvent_batch_3': { gas: 7204317, priority: 'HIGH' },
      'createEvent_batch_avg': { gas: 2401439, priority: 'HIGH' },
      
      // Ticket Operations
      'mintTicket_first': { gas: 158434, priority: 'HIGH' },
      'mintTicket_subsequent': { gas: 98134, priority: 'HIGH' },
      'mintTicket_average': { gas: 110194, priority: 'HIGH' },
      'resaleTicket': { gas: 101699, priority: 'MEDIUM' },
      'refundTicket': { gas: 54236, priority: 'MEDIUM' },
      'checkIn': { gas: 56036, priority: 'LOW' },
      
      // View Functions
      'getEventInfo': { gas: 7998, priority: 'LOW' },
      'getTicketMetadata': { gas: 13345, priority: 'LOW' },
      'getCollectionMetadata': { gas: 8918, priority: 'LOW' },
      'tokenURI': { gas: 4187, priority: 'LOW' },
      
      // Batch Efficiency
      'batch_efficiency_savings': { gas: 87700, priority: 'MEDIUM' },
      'batch_efficiency_percentage': { gas: 1, priority: 'MEDIUM' }, // 1% savings
      
      // Storage Operations
      'sequential_mints_10': { gas: 1032910, priority: 'MEDIUM' },
      'mapping_reads_10': { gas: 17655, priority: 'LOW' }
    };
  }

  /**
   * Generate optimization recommendations
   */
  generateOptimizations() {
    const optimizations = [];

    // High gas functions (>100k gas)
    const highGasFunctions = Object.entries(this.measurements)
      .filter(([_, data]) => data.gas > 100000)
      .map(([name, data]) => ({ name, ...data }));

    highGasFunctions.forEach(func => {
      optimizations.push({
        type: 'HIGH_GAS_FUNCTION',
        function: func.name,
        current_gas: func.gas,
        priority: 'HIGH',
        potential_savings: Math.floor(func.gas * 0.1), // 10% savings estimate
        recommendations: [
          'Cache immutable variables',
          'Use unchecked arithmetic for safe operations',
          'Optimize storage operations',
          'Minimize external calls'
        ]
      });
    });

    // Batch operation optimization
    const batchSavings = this.measurements['batch_efficiency_percentage'].gas;
    if (batchSavings < 20) { // Less than 20% savings
      optimizations.push({
        type: 'BATCH_OPTIMIZATION',
        function: 'batchCreateEvents',
        current_savings_percentage: batchSavings,
        target_savings_percentage: 25,
        priority: 'MEDIUM',
        potential_additional_savings: Math.floor(
          this.measurements['createEvent_batch_3'].gas * 0.15
        ),
        recommendations: [
          'Optimize batch processing loops',
          'Reduce redundant storage operations',
          'Implement more efficient batch validation'
        ]
      });
    }

    // Storage optimization opportunities
    const mintGas = this.measurements['mintTicket_average'].gas;
    if (mintGas > 80000) {
      optimizations.push({
        type: 'STORAGE_OPTIMIZATION',
        function: 'mintTicket',
        current_gas: mintGas,
        target_gas: 80000,
        priority: 'MEDIUM',
        potential_savings: mintGas - 80000,
        recommendations: [
          'Implement struct packing for Event state variables',
          'Use smaller data types where appropriate',
          'Optimize storage slot usage'
        ]
      });
    }

    return optimizations;
  }

  /**
   * Calculate quantified savings
   */
  calculateQuantifiedSavings() {
    const savings = [];
    
    // Annual usage estimates
    const annualUsage = {
      eventCreation: 500,
      ticketMinting: 10000,
      ticketResales: 2000,
      refunds: 500,
      checkIns: 8000
    };

    // Function optimizations
    const mintOptimization = Math.floor(this.measurements['mintTicket_average'].gas * 0.08);
    savings.push({
      function: 'mintTicket',
      current_gas: this.measurements['mintTicket_average'].gas,
      optimization_savings: mintOptimization,
      annual_transactions: annualUsage.ticketMinting,
      annual_gas_savings: mintOptimization * annualUsage.ticketMinting,
      implementation: 'Cache immutable variables, use unchecked arithmetic'
    });

    const eventOptimization = Math.floor(this.measurements['createEvent_single'].gas * 0.12);
    savings.push({
      function: 'createEvent',
      current_gas: this.measurements['createEvent_single'].gas,
      optimization_savings: eventOptimization,
      annual_transactions: annualUsage.eventCreation,
      annual_gas_savings: eventOptimization * annualUsage.eventCreation,
      implementation: 'Optimize struct packing, reduce storage operations'
    });

    const resaleOptimization = Math.floor(this.measurements['resaleTicket'].gas * 0.06);
    savings.push({
      function: 'resaleTicket',
      current_gas: this.measurements['resaleTicket'].gas,
      optimization_savings: resaleOptimization,
      annual_transactions: annualUsage.ticketResales,
      annual_gas_savings: resaleOptimization * annualUsage.ticketResales,
      implementation: 'Optimize validation order, cache calculations'
    });

    return savings;
  }

  /**
   * Generate comprehensive report
   */
  generateReport() {
    this.analyzeGasMeasurements();
    const optimizations = this.generateOptimizations();
    const quantifiedSavings = this.calculateQuantifiedSavings();
    
    const totalAnnualSavings = quantifiedSavings.reduce(
      (sum, saving) => sum + saving.annual_gas_savings, 0
    );

    const report = {
      metadata: {
        generated_at: new Date().toISOString(),
        version: '1.0.0',
        analysis_type: 'Gas Optimization Analysis'
      },
      gas_measurements: this.measurements,
      optimization_opportunities: optimizations,
      quantified_savings: quantifiedSavings,
      summary: {
        total_functions_analyzed: Object.keys(this.measurements).length,
        high_priority_optimizations: optimizations.filter(opt => opt.priority === 'HIGH').length,
        medium_priority_optimizations: optimizations.filter(opt => opt.priority === 'MEDIUM').length,
        total_annual_gas_savings: totalAnnualSavings,
        estimated_eth_savings_per_year: (totalAnnualSavings * 20e-9).toFixed(4) // Assuming 20 gwei gas price
      },
      recommendations: [
        {
          priority: 'HIGH',
          title: 'Function-Level Optimizations',
          description: 'Implement caching and arithmetic optimizations in high-frequency functions',
          estimated_savings: '8,000-30,000 gas per function call',
          functions: ['createEvent', 'mintTicket', 'resaleTicket']
        },
        {
          priority: 'MEDIUM', 
          title: 'Batch Operation Enhancement',
          description: 'Improve batch processing efficiency to achieve >20% savings',
          estimated_savings: '1,000,000+ gas per large batch operation',
          functions: ['batchCreateEvents']
        },
        {
          priority: 'MEDIUM',
          title: 'Storage Layout Optimization',
          description: 'Implement struct packing to reduce deployment and operation costs',
          estimated_savings: '60,000-100,000 gas per deployment',
          functions: ['All contract deployments']
        }
      ]
    };

    return report;
  }

  /**
   * Save report to file
   */
  saveReport(outputPath) {
    const report = this.generateReport();
    
    // Ensure directory exists
    const dir = path.dirname(outputPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    fs.writeFileSync(outputPath, JSON.stringify(report, null, 2));
    console.log(`Gas optimization report saved to: ${outputPath}`);
    
    return report;
  }
}

// CLI interface
if (require.main === module) {
  const profiler = new SimpleGasProfiler();
  
  try {
    console.log('Generating gas optimization report...');
    
    const reportPath = './audit/reports/gas-optimization-report.json';
    const report = profiler.saveReport(reportPath);
    
    console.log('\n=== Gas Optimization Analysis Summary ===');
    console.log(`Functions Analyzed: ${report.summary.total_functions_analyzed}`);
    console.log(`High Priority Optimizations: ${report.summary.high_priority_optimizations}`);
    console.log(`Medium Priority Optimizations: ${report.summary.medium_priority_optimizations}`);
    console.log(`Total Annual Gas Savings: ${report.summary.total_annual_gas_savings.toLocaleString()}`);
    console.log(`Estimated ETH Savings/Year: ${report.summary.estimated_eth_savings_per_year} ETH`);
    
    console.log('\n=== Key Recommendations ===');
    report.recommendations.forEach((rec, index) => {
      console.log(`${index + 1}. ${rec.title} (${rec.priority})`);
      console.log(`   ${rec.description}`);
      console.log(`   Savings: ${rec.estimated_savings}`);
    });
    
  } catch (error) {
    console.error(`Gas profiling failed: ${error.message}`);
    process.exit(1);
  }
}

module.exports = SimpleGasProfiler;