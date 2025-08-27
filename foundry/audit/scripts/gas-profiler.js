#!/usr/bin/env node

/**
 * VeriTix Gas Profiling and Optimization Measurement Tool
 * 
 * This script analyzes gas consumption patterns, identifies optimization
 * opportunities, and tracks gas savings from implemented optimizations.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class GasProfiler {
  constructor() {
    this.profiles = {};
    this.baselines = {};
    this.optimizations = [];
  }

  /**
   * Run comprehensive gas profiling for all contract functions
   */
  async profileAllFunctions() {
    console.log('Starting comprehensive gas profiling...');
    
    try {
      // Run gas optimization test suite
      console.log('Running gas optimization test suite...');
      const gasOptReport = execSync('forge test --match-contract GasOptimizationTest --gas-report', { 
        cwd: process.cwd(),
        encoding: 'utf8'
      });
      
      console.log('Gas optimization tests completed');
      
      // Run general forge test with gas reporting
      const gasReport = execSync('forge test --gas-report --json', { 
        cwd: process.cwd(),
        encoding: 'utf8'
      });
      
      const testResults = JSON.parse(gasReport);
      this.processTestResults(testResults);
      
      // Run specific gas benchmarks
      await this.runGasBenchmarks();
      
      // Parse gas optimization test results
      this.parseGasOptimizationResults(gasOptReport);
      
      console.log('Gas profiling completed successfully');
    } catch (error) {
      console.error(`Gas profiling failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Process forge test results to extract gas consumption data
   */
  processTestResults(testResults) {
    Object.entries(testResults).forEach(([testFile, results]) => {
      if (results.test_results) {
        Object.entries(results.test_results).forEach(([testName, testData]) => {
          if (testData.gas_used) {
            this.profiles[testName] = {
              gas_used: testData.gas_used,
              test_file: testFile,
              status: testData.status,
              execution_time: testData.execution_time
            };
          }
        });
      }
    });
  }

  /**
   * Run specific gas benchmarks for critical functions
   */
  async runGasBenchmarks() {
    const benchmarks = [
      'test_GasBenchmark_BuyTicket_Single',
      'test_GasBenchmark_BuyTicket_Batch',
      'test_GasBenchmark_RefundTicket',
      'test_GasBenchmark_CreateEvent',
      'test_GasBenchmark_TransferTicket',
      'test_GasBenchmark_CheckIn'
    ];

    for (const benchmark of benchmarks) {
      try {
        const result = execSync(`forge test --match-test ${benchmark} --gas-report`, {
          cwd: process.cwd(),
          encoding: 'utf8'
        });
        
        // Parse gas usage from output
        const gasMatch = result.match(/gas:\s*(\d+)/);
        if (gasMatch) {
          this.profiles[benchmark] = {
            gas_used: parseInt(gasMatch[1]),
            benchmark: true,
            timestamp: new Date().toISOString()
          };
        }
      } catch (error) {
        console.warn(`Benchmark ${benchmark} failed: ${error.message}`);
      }
    }
  }

  /**
   * Analyze gas consumption patterns and identify optimization opportunities
   */
  analyzeOptimizationOpportunities() {
    const opportunities = [];
    
    // Analyze function-level gas consumption
    Object.entries(this.profiles).forEach(([testName, profile]) => {
      const gasUsed = profile.gas_used;
      
      // High gas consumption functions (>100k gas)
      if (gasUsed > 100000) {
        opportunities.push({
          type: 'HIGH_GAS_FUNCTION',
          function: this.extractFunctionName(testName),
          current_gas: gasUsed,
          priority: 'HIGH',
          potential_savings: Math.floor(gasUsed * 0.15), // Estimate 15% savings
          recommendations: [
            'Review storage operations for optimization',
            'Consider batch operations where applicable',
            'Optimize external calls and state changes'
          ]
        });
      }
      
      // Medium gas consumption functions (50k-100k gas)
      if (gasUsed > 50000 && gasUsed <= 100000) {
        opportunities.push({
          type: 'MEDIUM_GAS_FUNCTION',
          function: this.extractFunctionName(testName),
          current_gas: gasUsed,
          priority: 'MEDIUM',
          potential_savings: Math.floor(gasUsed * 0.10), // Estimate 10% savings
          recommendations: [
            'Review loop optimizations',
            'Consider storage slot packing',
            'Optimize conditional logic'
          ]
        });
      }
    });

    // Identify batch operation optimization opportunities
    const batchOpportunities = this.identifyBatchOptimizations();
    opportunities.push(...batchOpportunities);

    // Identify storage optimization opportunities
    const storageOpportunities = this.identifyStorageOptimizations();
    opportunities.push(...storageOpportunities);

    return opportunities;
  }

  /**
   * Identify batch operation optimization opportunities
   */
  identifyBatchOptimizations() {
    const opportunities = [];
    
    // Compare single vs batch operations
    const singleBuyGas = this.profiles['test_GasBenchmark_BuyTicket_Single']?.gas_used;
    const batchBuyGas = this.profiles['test_GasBenchmark_BuyTicket_Batch']?.gas_used;
    
    if (singleBuyGas && batchBuyGas) {
      const expectedBatchGas = singleBuyGas * 5; // Assuming 5 tickets in batch
      const actualSavings = expectedBatchGas - batchBuyGas;
      const savingsPercentage = (actualSavings / expectedBatchGas) * 100;
      
      if (savingsPercentage < 20) { // Less than 20% savings indicates optimization opportunity
        opportunities.push({
          type: 'BATCH_OPTIMIZATION',
          function: 'batchBuyTickets',
          current_batch_gas: batchBuyGas,
          single_operation_gas: singleBuyGas,
          current_savings_percentage: savingsPercentage.toFixed(2),
          priority: 'MEDIUM',
          potential_additional_savings: Math.floor((20 - savingsPercentage) * expectedBatchGas / 100),
          recommendations: [
            'Optimize batch processing loops',
            'Reduce redundant storage operations',
            'Implement more efficient batch validation'
          ]
        });
      }
    }

    return opportunities;
  }

  /**
   * Identify storage optimization opportunities
   */
  identifyStorageOptimizations() {
    const opportunities = [];
    
    // Analyze Event struct storage efficiency
    opportunities.push({
      type: 'STORAGE_OPTIMIZATION',
      target: 'Event struct',
      priority: 'LOW',
      potential_savings: 5000, // Estimated savings per event creation
      recommendations: [
        'Pack Event struct fields to minimize storage slots',
        'Use smaller data types where possible (uint128 vs uint256)',
        'Reorder struct fields for optimal packing'
      ],
      implementation: `
        struct Event {
            string name;           // Dynamic, separate slot
            string description;    // Dynamic, separate slot  
            address organizer;     // 20 bytes
            uint128 ticketPrice;   // 16 bytes - fits with organizer
            uint64 startTime;      // 8 bytes
            uint64 endTime;        // 8 bytes - fits with startTime
            uint32 maxTickets;     // 4 bytes
            uint32 ticketsSold;    // 4 bytes - fits with maxTickets
            bool transfersAllowed; // 1 byte
            uint8 transferFeePercent; // 1 byte - fits with transfersAllowed
        }
      `
    });

    return opportunities;
  }

  /**
   * Extract function name from test name
   */
  extractFunctionName(testName) {
    // Extract function name from test naming patterns
    const patterns = [
      /test_(\w+)_/,
      /test(\w+)/,
      /benchmark_(\w+)/i
    ];
    
    for (const pattern of patterns) {
      const match = testName.match(pattern);
      if (match) {
        return match[1];
      }
    }
    
    return testName;
  }

  /**
   * Load baseline gas measurements for comparison
   */
  loadBaselines(baselinePath) {
    try {
      if (fs.existsSync(baselinePath)) {
        this.baselines = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
        console.log(`Loaded gas baselines from ${baselinePath}`);
      } else {
        console.log('No baseline file found, current measurements will be used as baseline');
      }
    } catch (error) {
      console.error(`Error loading baselines: ${error.message}`);
    }
  }

  /**
   * Save current measurements as baseline
   */
  saveBaselines(baselinePath) {
    try {
      const baselineData = {
        timestamp: new Date().toISOString(),
        profiles: this.profiles,
        metadata: {
          version: '1.0.0',
          total_functions: Object.keys(this.profiles).length
        }
      };
      
      fs.writeFileSync(baselinePath, JSON.stringify(baselineData, null, 2));
      console.log(`Gas baselines saved to ${baselinePath}`);
    } catch (error) {
      console.error(`Error saving baselines: ${error.message}`);
    }
  }

  /**
   * Compare current measurements with baselines
   */
  compareWithBaselines() {
    if (!this.baselines.profiles) {
      return { message: 'No baselines available for comparison' };
    }

    const comparisons = {};
    const improvements = [];
    const regressions = [];

    Object.entries(this.profiles).forEach(([testName, currentProfile]) => {
      const baselineProfile = this.baselines.profiles[testName];
      
      if (baselineProfile) {
        const currentGas = currentProfile.gas_used;
        const baselineGas = baselineProfile.gas_used;
        const difference = currentGas - baselineGas;
        const percentageChange = ((difference / baselineGas) * 100).toFixed(2);
        
        comparisons[testName] = {
          current_gas: currentGas,
          baseline_gas: baselineGas,
          difference: difference,
          percentage_change: parseFloat(percentageChange),
          status: difference < 0 ? 'IMPROVED' : difference > 0 ? 'REGRESSED' : 'UNCHANGED'
        };

        if (difference < -1000) { // Significant improvement (>1k gas saved)
          improvements.push({
            function: this.extractFunctionName(testName),
            gas_saved: Math.abs(difference),
            percentage_improvement: Math.abs(parseFloat(percentageChange))
          });
        } else if (difference > 1000) { // Significant regression (>1k gas increase)
          regressions.push({
            function: this.extractFunctionName(testName),
            gas_increase: difference,
            percentage_regression: parseFloat(percentageChange)
          });
        }
      }
    });

    return {
      comparisons,
      improvements,
      regressions,
      summary: {
        total_comparisons: Object.keys(comparisons).length,
        improvements_count: improvements.length,
        regressions_count: regressions.length,
        total_gas_saved: improvements.reduce((sum, imp) => sum + imp.gas_saved, 0),
        total_gas_increased: regressions.reduce((sum, reg) => sum + reg.gas_increase, 0)
      }
    };
  }

  /**
   * Parse gas optimization test results
   */
  parseGasOptimizationResults(gasOptOutput) {
    console.log('Parsing gas optimization test results...');
    
    // Extract gas measurements from test output
    const gasLines = gasOptOutput.split('\n').filter(line => 
      line.includes('Gas used for') || line.includes('gas:')
    );
    
    gasLines.forEach(line => {
      const gasMatch = line.match(/Gas used for (.+?):\s*(\d+)/);
      if (gasMatch) {
        const [, operation, gasUsed] = gasMatch;
        this.profiles[`GasOpt_${operation.replace(/\s+/g, '_')}`] = {
          gas_used: parseInt(gasUsed),
          test_type: 'gas_optimization',
          operation: operation,
          timestamp: new Date().toISOString()
        };
      }
    });
  }

  /**
   * Generate comprehensive gas optimization report
   */
  generateOptimizationReport() {
    const opportunities = this.analyzeOptimizationOpportunities();
    const baselineComparison = this.compareWithBaselines();
    const quantifiedSavings = this.calculateQuantifiedSavings();
    
    const report = {
      metadata: {
        generated_at: new Date().toISOString(),
        version: '1.0.0',
        total_functions_analyzed: Object.keys(this.profiles).length
      },
      gas_profiles: this.profiles,
      optimization_opportunities: opportunities,
      baseline_comparison: baselineComparison,
      quantified_savings: quantifiedSavings,
      recommendations: this.generateOptimizationRecommendations(opportunities),
      summary: {
        total_optimization_opportunities: opportunities.length,
        potential_total_savings: opportunities.reduce((sum, opp) => sum + (opp.potential_savings || 0), 0),
        high_priority_optimizations: opportunities.filter(opp => opp.priority === 'HIGH').length,
        medium_priority_optimizations: opportunities.filter(opp => opp.priority === 'MEDIUM').length,
        low_priority_optimizations: opportunities.filter(opp => opp.priority === 'LOW').length
      }
    };

    return report;
  }

  /**
   * Calculate quantified gas savings for each optimization recommendation
   */
  calculateQuantifiedSavings() {
    const savings = [];
    
    // Analyze function-level optimizations
    Object.entries(this.profiles).forEach(([testName, profile]) => {
      const gasUsed = profile.gas_used;
      
      if (testName.includes('mintTicket') || testName.includes('MintTicket')) {
        savings.push({
          function: 'mintTicket',
          current_gas: gasUsed,
          optimization_type: 'function_caching',
          estimated_savings: Math.floor(gasUsed * 0.05), // 5% savings from caching
          annual_savings: Math.floor(gasUsed * 0.05 * 10000), // Assuming 10k mints per year
          implementation: 'Cache immutable variables, use unchecked arithmetic'
        });
      }
      
      if (testName.includes('resaleTicket') || testName.includes('ResaleTicket')) {
        savings.push({
          function: 'resaleTicket',
          current_gas: gasUsed,
          optimization_type: 'validation_optimization',
          estimated_savings: Math.floor(gasUsed * 0.08), // 8% savings from optimized validation
          annual_savings: Math.floor(gasUsed * 0.08 * 2000), // Assuming 2k resales per year
          implementation: 'Optimize validation order, cache calculations'
        });
      }
      
      if (testName.includes('createEvent') || testName.includes('CreateEvent')) {
        savings.push({
          function: 'createEvent',
          current_gas: gasUsed,
          optimization_type: 'storage_packing',
          estimated_savings: Math.floor(gasUsed * 0.12), // 12% savings from storage optimization
          annual_savings: Math.floor(gasUsed * 0.12 * 500), // Assuming 500 events per year
          implementation: 'Optimize struct packing, reduce storage operations'
        });
      }
    });
    
    // Calculate batch operation efficiency
    const batchGas = this.profiles['GasOpt_batch_event_creation_3_events']?.gas_used;
    const individualGas = this.profiles['GasOpt_individual_operations_3']?.gas_used;
    
    if (batchGas && individualGas) {
      const currentSavings = individualGas - batchGas;
      const currentSavingsPercent = (currentSavings / individualGas) * 100;
      const targetSavingsPercent = 25; // Target 25% savings for batch operations
      
      if (currentSavingsPercent < targetSavingsPercent) {
        const additionalSavings = Math.floor((targetSavingsPercent - currentSavingsPercent) * individualGas / 100);
        savings.push({
          function: 'batchCreateEvents',
          current_gas: batchGas,
          current_savings_percent: currentSavingsPercent.toFixed(2),
          target_savings_percent: targetSavingsPercent,
          additional_savings_potential: additionalSavings,
          optimization_type: 'batch_optimization',
          implementation: 'Optimize batch processing loops, reduce redundant operations'
        });
      }
    }
    
    return savings;
  }

  /**
   * Generate optimization recommendations based on analysis
   */
  generateOptimizationRecommendations(opportunities) {
    const recommendations = [];

    // High-priority recommendations
    const highPriorityOpps = opportunities.filter(opp => opp.priority === 'HIGH');
    if (highPriorityOpps.length > 0) {
      recommendations.push({
        priority: 'HIGH',
        title: 'Critical Gas Optimization Required',
        description: `${highPriorityOpps.length} functions consume excessive gas (>100k per call)`,
        action_items: [
          'Review and optimize high-gas functions immediately',
          'Implement storage optimizations',
          'Consider architectural changes for gas efficiency'
        ],
        estimated_savings: highPriorityOpps.reduce((sum, opp) => sum + (opp.potential_savings || 0), 0)
      });
    }

    // Batch optimization recommendations
    const batchOpps = opportunities.filter(opp => opp.type === 'BATCH_OPTIMIZATION');
    if (batchOpps.length > 0) {
      recommendations.push({
        priority: 'MEDIUM',
        title: 'Batch Operation Optimization',
        description: 'Batch operations can be further optimized for better gas efficiency',
        action_items: [
          'Optimize batch processing loops',
          'Reduce redundant operations in batch functions',
          'Implement more efficient batch validation'
        ],
        estimated_savings: batchOpps.reduce((sum, opp) => sum + (opp.potential_additional_savings || 0), 0)
      });
    }

    // Storage optimization recommendations
    const storageOpps = opportunities.filter(opp => opp.type === 'STORAGE_OPTIMIZATION');
    if (storageOpps.length > 0) {
      recommendations.push({
        priority: 'LOW',
        title: 'Storage Structure Optimization',
        description: 'Struct packing and storage optimizations can reduce deployment and operation costs',
        action_items: [
          'Implement struct packing for Event and other structs',
          'Use appropriate data types (uint128 vs uint256)',
          'Reorder struct fields for optimal storage slot usage'
        ],
        estimated_savings: storageOpps.reduce((sum, opp) => sum + (opp.potential_savings || 0), 0)
      });
    }

    return recommendations;
  }

  /**
   * Save optimization report to file
   */
  saveOptimizationReport(outputPath) {
    const report = this.generateOptimizationReport();
    fs.writeFileSync(outputPath, JSON.stringify(report, null, 2));
    console.log(`Gas optimization report saved to: ${outputPath}`);
    return report;
  }
}

// CLI interface
if (require.main === module) {
  const profiler = new GasProfiler();
  
  async function main() {
    try {
      // Load existing baselines
      const baselinePath = './audit/baselines/gas-baseline.json';
      profiler.loadBaselines(baselinePath);
      
      // Run comprehensive gas profiling
      await profiler.profileAllFunctions();
      
      // Generate and save optimization report
      const reportPath = './audit/reports/gas-optimization-report.json';
      const report = profiler.saveOptimizationReport(reportPath);
      
      // Save current measurements as new baseline if no baseline exists
      if (!fs.existsSync(baselinePath)) {
        profiler.saveBaselines(baselinePath);
      }
      
      // Display summary
      console.log('\n=== Gas Optimization Summary ===');
      console.log(`Total Functions Analyzed: ${report.summary.total_optimization_opportunities}`);
      console.log(`Potential Total Savings: ${report.summary.potential_total_savings} gas`);
      console.log(`High Priority Optimizations: ${report.summary.high_priority_optimizations}`);
      console.log(`Medium Priority Optimizations: ${report.summary.medium_priority_optimizations}`);
      console.log(`Low Priority Optimizations: ${report.summary.low_priority_optimizations}`);
      
      if (report.baseline_comparison.summary) {
        console.log('\n=== Baseline Comparison ===');
        console.log(`Total Gas Saved: ${report.baseline_comparison.summary.total_gas_saved}`);
        console.log(`Total Gas Increased: ${report.baseline_comparison.summary.total_gas_increased}`);
        console.log(`Improvements: ${report.baseline_comparison.summary.improvements_count}`);
        console.log(`Regressions: ${report.baseline_comparison.summary.regressions_count}`);
      }
      
    } catch (error) {
      console.error(`Gas profiling failed: ${error.message}`);
      process.exit(1);
    }
  }
  
  main();
}

module.exports = GasProfiler;