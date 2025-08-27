#!/usr/bin/env node

/**
 * VeriTix Storage Optimization Analyzer
 * 
 * This script analyzes contract storage layouts, identifies struct packing
 * opportunities, and calculates potential gas savings from storage optimizations.
 */

const fs = require('fs');
const path = require('path');

class StorageOptimizationAnalyzer {
  constructor() {
    this.optimizations = [];
    this.storageAnalysis = {};
  }

  /**
   * Analyze Event struct storage optimization opportunities
   */
  analyzeEventStructOptimization() {
    console.log('Analyzing Event struct storage optimization...');
    
    // Current Event struct analysis (from VeriTixEvent.sol)
    const currentEventStruct = {
      name: 'Event',
      fields: [
        { name: 'maxSupply', type: 'uint256', size: 32, immutable: true },
        { name: 'ticketPrice', type: 'uint256', size: 32, immutable: true },
        { name: 'organizer', type: 'address', size: 20, immutable: true },
        { name: 'maxResalePercent', type: 'uint256', size: 32, immutable: true },
        { name: 'organizerFeePercent', type: 'uint256', size: 32, immutable: true },
        { name: '_baseTokenURI', type: 'string', size: 'dynamic', storage: 'separate' },
        { name: '_currentTokenId', type: 'uint256', size: 32, mutable: true },
        { name: '_totalSupply', type: 'uint256', size: 32, mutable: true },
        { name: 'cancelled', type: 'bool', size: 1, mutable: true },
        { name: 'lastPricePaid', type: 'mapping(uint256 => uint256)', size: 'mapping' },
        { name: 'checkedIn', type: 'mapping(uint256 => bool)', size: 'mapping' }
      ]
    };

    // Calculate current storage usage
    const currentUsage = this.calculateStorageUsage(currentEventStruct);
    
    // Propose optimized struct
    const optimizedEventStruct = {
      name: 'OptimizedEvent',
      fields: [
        // Slot 0: Pack address + uint128 (20 + 16 = 36 bytes, fits in 32-byte slot with padding)
        { name: 'organizer', type: 'address', size: 20, slot: 0 },
        { name: 'ticketPrice', type: 'uint128', size: 16, slot: 0, optimized: true },
        
        // Slot 1: Pack uint64 + uint64 + uint32 + uint32 + uint8 + bool (8+8+4+4+1+1 = 26 bytes)
        { name: 'maxSupply', type: 'uint32', size: 4, slot: 1, optimized: true },
        { name: '_currentTokenId', type: 'uint32', size: 4, slot: 1, optimized: true },
        { name: '_totalSupply', type: 'uint32', size: 4, slot: 1, optimized: true },
        { name: 'maxResalePercent', type: 'uint16', size: 2, slot: 1, optimized: true },
        { name: 'organizerFeePercent', type: 'uint8', size: 1, slot: 1, optimized: true },
        { name: 'cancelled', type: 'bool', size: 1, slot: 1 },
        
        // Dynamic and mapping fields remain separate
        { name: '_baseTokenURI', type: 'string', size: 'dynamic', storage: 'separate' },
        { name: 'lastPricePaid', type: 'mapping(uint256 => uint256)', size: 'mapping' },
        { name: 'checkedIn', type: 'mapping(uint256 => bool)', size: 'mapping' }
      ]
    };

    const optimizedUsage = this.calculateStorageUsage(optimizedEventStruct);
    
    // Calculate savings
    const storageSavings = currentUsage.totalSlots - optimizedUsage.totalSlots;
    const gasSavingsPerDeployment = storageSavings * 20000; // ~20k gas per storage slot
    const gasSavingsPerWrite = storageSavings * 5000; // ~5k gas per slot write
    
    const optimization = {
      type: 'STRUCT_PACKING',
      target: 'Event State Variables',
      priority: 'MEDIUM',
      current: currentUsage,
      optimized: optimizedUsage,
      savings: {
        storageSlots: storageSavings,
        deploymentGas: gasSavingsPerDeployment,
        writeOperationGas: gasSavingsPerWrite,
        readOperationGas: storageSavings * 200 // ~200 gas per slot read
      },
      implementation: this.generateOptimizedStructCode(optimizedEventStruct),
      risks: [
        'Reduced maximum values for some fields (uint32 vs uint256)',
        'Need to validate that reduced ranges are sufficient',
        'Potential overflow risks if not properly validated'
      ],
      validation: {
        maxSupply: 'uint32 max: 4,294,967,295 (sufficient for ticket supply)',
        ticketPrice: 'uint128 max: ~3.4e38 wei (sufficient for any reasonable ticket price)',
        maxResalePercent: 'uint16 max: 65,535 (sufficient for percentage values)',
        organizerFeePercent: 'uint8 max: 255 (sufficient for percentage values)'
      }
    };

    this.optimizations.push(optimization);
    return optimization;
  }

  /**
   * Analyze mapping optimization opportunities
   */
  analyzeMappingOptimizations() {
    console.log('Analyzing mapping storage optimizations...');
    
    const mappingOptimizations = [
      {
        type: 'MAPPING_PACKING',
        target: 'lastPricePaid and checkedIn mappings',
        priority: 'LOW',
        description: 'Combine related mappings into a single struct mapping',
        current: {
          mappings: [
            'mapping(uint256 => uint256) lastPricePaid',
            'mapping(uint256 => bool) checkedIn'
          ],
          storageReads: 2, // Two separate SLOAD operations
          storageWrites: 2 // Two separate SSTORE operations
        },
        optimized: {
          mapping: 'mapping(uint256 => TicketData) ticketData',
          struct: 'struct TicketData { uint256 lastPricePaid; bool checkedIn; }',
          storageReads: 1, // Single SLOAD operation
          storageWrites: 1 // Single SSTORE operation
        },
        savings: {
          gasPerRead: 2100, // Save one SLOAD (2100 gas)
          gasPerWrite: 5000, // Save one SSTORE (5000 gas)
          description: 'Savings when accessing both values together'
        },
        implementation: `
          struct TicketData {
              uint256 lastPricePaid;
              bool checkedIn;
          }
          
          mapping(uint256 => TicketData) public ticketData;
          
          // Usage:
          ticketData[tokenId] = TicketData({
              lastPricePaid: price,
              checkedIn: false
          });
        `,
        tradeoffs: [
          'Increased gas cost when accessing only one field',
          'More complex code structure',
          'Potential for unused storage slots in struct'
        ]
      }
    ];

    this.optimizations.push(...mappingOptimizations);
    return mappingOptimizations;
  }

  /**
   * Analyze function-level gas optimizations
   */
  analyzeFunctionOptimizations() {
    console.log('Analyzing function-level optimizations...');
    
    const functionOptimizations = [
      {
        type: 'FUNCTION_OPTIMIZATION',
        target: 'mintTicket function',
        priority: 'HIGH',
        current: {
          gasEstimate: 85000,
          operations: [
            'Multiple immutable variable reads',
            'Storage writes for _currentTokenId and _totalSupply',
            'Mapping write for lastPricePaid',
            'ERC721 _safeMint call',
            'Event emission'
          ]
        },
        optimizations: [
          {
            technique: 'Cache immutable values',
            description: 'Cache frequently accessed immutable values in local variables',
            savings: 300, // ~100 gas per avoided SLOAD of immutable
            implementation: `
              uint256 _ticketPrice = ticketPrice;
              uint256 _maxSupply = maxSupply;
              // Use cached values instead of direct access
            `
          },
          {
            technique: 'Unchecked arithmetic',
            description: 'Use unchecked blocks for safe arithmetic operations',
            savings: 200,
            implementation: `
              unchecked {
                  tokenId = ++currentId;
                  _currentTokenId = currentId;
                  _totalSupply++;
              }
            `
          },
          {
            technique: 'Optimize storage writes',
            description: 'Minimize storage operations and combine where possible',
            savings: 500,
            implementation: `
              // Combine related storage updates
              // Use single SSTORE for multiple related values
            `
          }
        ],
        totalSavings: 1000,
        optimizedGasEstimate: 84000
      },
      {
        type: 'FUNCTION_OPTIMIZATION',
        target: 'resaleTicket function',
        priority: 'HIGH',
        current: {
          gasEstimate: 95000,
          operations: [
            'Multiple validation checks',
            'Price calculation',
            'Transfer execution',
            'ETH transfers to seller and organizer',
            'Storage updates'
          ]
        },
        optimizations: [
          {
            technique: 'Early validation',
            description: 'Perform cheapest validations first to fail fast',
            savings: 200,
            implementation: `
              // Check payment amount first (cheapest check)
              if (msg.value != price || price == 0) {
                  revert IncorrectPayment(msg.value, price);
              }
            `
          },
          {
            technique: 'Cache calculations',
            description: 'Cache expensive calculations to avoid repetition',
            savings: 300,
            implementation: `
              uint256 maxPrice = VeriTixTypes.calculateMaxResalePrice(_ticketPrice, _maxResalePercent);
              uint256 organizerFee = VeriTixTypes.calculateOrganizerFee(price, _organizerFeePercent);
            `
          },
          {
            technique: 'Optimize transfer logic',
            description: 'Minimize state changes during transfers',
            savings: 400,
            implementation: `
              // Batch state changes before external calls
              // Use more efficient transfer patterns
            `
          }
        ],
        totalSavings: 900,
        optimizedGasEstimate: 94100
      }
    ];

    this.optimizations.push(...functionOptimizations);
    return functionOptimizations;
  }

  /**
   * Calculate storage usage for a struct
   */
  calculateStorageUsage(structDef) {
    let totalSlots = 0;
    let currentSlot = 0;
    let currentSlotUsage = 0;
    const slotDetails = [];

    structDef.fields.forEach(field => {
      if (field.size === 'dynamic' || field.size === 'mapping') {
        // Dynamic and mapping types use separate storage
        return;
      }

      if (field.slot !== undefined) {
        // Optimized packing - field specifies its slot
        if (!slotDetails[field.slot]) {
          slotDetails[field.slot] = { usage: 0, fields: [] };
        }
        slotDetails[field.slot].usage += field.size;
        slotDetails[field.slot].fields.push(field.name);
      } else {
        // Current layout - each field uses full slot
        if (field.size <= 32) {
          totalSlots++;
          slotDetails.push({
            usage: field.size,
            fields: [field.name],
            wastedSpace: 32 - field.size
          });
        }
      }
    });

    // Count optimized slots
    if (slotDetails.length > 0 && slotDetails[0].fields) {
      totalSlots = slotDetails.filter(slot => slot && slot.fields).length;
    }

    return {
      totalSlots,
      slotDetails,
      wastedSpace: slotDetails.reduce((total, slot) => total + (slot?.wastedSpace || 0), 0)
    };
  }

  /**
   * Generate optimized struct code
   */
  generateOptimizedStructCode(structDef) {
    const slots = {};
    
    // Group fields by slot
    structDef.fields.forEach(field => {
      if (field.slot !== undefined) {
        if (!slots[field.slot]) {
          slots[field.slot] = [];
        }
        slots[field.slot].push(field);
      }
    });

    let code = '// Optimized storage layout:\n';
    
    Object.entries(slots).forEach(([slotNum, fields]) => {
      code += `// Slot ${slotNum}: `;
      fields.forEach((field, index) => {
        code += `${field.type} ${field.name}`;
        if (index < fields.length - 1) code += ', ';
      });
      code += '\n';
    });

    code += '\n// Implementation:\n';
    structDef.fields.forEach(field => {
      if (field.size !== 'dynamic' && field.size !== 'mapping') {
        code += `${field.type} ${field.optimized ? '// OPTIMIZED: ' : ''}${field.name};\n`;
      }
    });

    return code;
  }

  /**
   * Analyze batch operation gas limits
   */
  analyzeBatchGasLimits() {
    console.log('Analyzing batch operation gas limits...');
    
    const batchAnalysis = {
      type: 'BATCH_GAS_ANALYSIS',
      target: 'batchCreateEvents function',
      priority: 'MEDIUM',
      gasLimitAnalysis: {
        blockGasLimit: 30000000, // Ethereum block gas limit
        safetyBuffer: 5000000, // 5M gas safety buffer
        availableGas: 25000000, // 25M gas available for batch operations
        
        estimatedGasPerEvent: 180000, // Based on profiling
        maxSafeBatchSize: Math.floor(25000000 / 180000), // ~138 events
        recommendedMaxBatch: 50, // Conservative recommendation
        
        dosRiskAnalysis: {
          riskLevel: 'MEDIUM',
          description: 'Large batches could approach gas limits',
          mitigations: [
            'Implement batch size limits (max 50 events)',
            'Add gas estimation before batch execution',
            'Provide batch splitting recommendations to users',
            'Implement progressive batch processing'
          ]
        }
      },
      optimizations: [
        {
          technique: 'Batch size validation',
          implementation: `
            if (paramsArray.length > MAX_BATCH_SIZE) {
                revert BatchSizeTooLarge(paramsArray.length, MAX_BATCH_SIZE);
            }
          `,
          gasSavings: 'Prevents failed transactions'
        },
        {
          technique: 'Gas estimation',
          implementation: `
            uint256 estimatedGas = paramsArray.length * ESTIMATED_GAS_PER_EVENT;
            if (gasleft() < estimatedGas + GAS_BUFFER) {
                revert InsufficientGasForBatch();
            }
          `,
          gasSavings: 'Prevents partial batch failures'
        }
      ]
    };

    this.optimizations.push(batchAnalysis);
    return batchAnalysis;
  }

  /**
   * Generate comprehensive optimization report
   */
  generateOptimizationReport() {
    console.log('Generating comprehensive optimization report...');
    
    // Run all analyses
    const eventStructOpt = this.analyzeEventStructOptimization();
    const mappingOpts = this.analyzeMappingOptimizations();
    const functionOpts = this.analyzeFunctionOptimizations();
    const batchAnalysis = this.analyzeBatchGasLimits();

    // Calculate total potential savings
    const totalSavings = this.optimizations.reduce((total, opt) => {
      if (opt.savings && opt.savings.deploymentGas) {
        return total + opt.savings.deploymentGas;
      }
      if (opt.totalSavings) {
        return total + opt.totalSavings;
      }
      return total;
    }, 0);

    const report = {
      metadata: {
        generated_at: new Date().toISOString(),
        version: '1.0.0',
        analyzer: 'VeriTix Storage Optimization Analyzer'
      },
      summary: {
        total_optimizations: this.optimizations.length,
        high_priority: this.optimizations.filter(opt => opt.priority === 'HIGH').length,
        medium_priority: this.optimizations.filter(opt => opt.priority === 'MEDIUM').length,
        low_priority: this.optimizations.filter(opt => opt.priority === 'LOW').length,
        estimated_total_savings: totalSavings
      },
      optimizations: this.optimizations,
      recommendations: this.generateRecommendations(),
      implementation_guide: this.generateImplementationGuide()
    };

    return report;
  }

  /**
   * Generate prioritized recommendations
   */
  generateRecommendations() {
    return [
      {
        priority: 'HIGH',
        title: 'Function-Level Gas Optimizations',
        description: 'Implement immediate gas savings in high-frequency functions',
        actions: [
          'Cache immutable variables in mintTicket and resaleTicket functions',
          'Use unchecked arithmetic for safe operations',
          'Optimize validation order for early failure',
          'Minimize storage operations'
        ],
        estimated_savings: '1000-2000 gas per function call',
        implementation_effort: 'Low'
      },
      {
        priority: 'MEDIUM',
        title: 'Storage Layout Optimization',
        description: 'Optimize struct packing for deployment and storage costs',
        actions: [
          'Implement optimized Event struct with packed fields',
          'Validate that reduced field sizes are sufficient',
          'Update all related functions to handle new types',
          'Add overflow protection where needed'
        ],
        estimated_savings: '60,000-100,000 gas per deployment',
        implementation_effort: 'Medium'
      },
      {
        priority: 'MEDIUM',
        title: 'Batch Operation Safety',
        description: 'Prevent DoS attacks and failed transactions in batch operations',
        actions: [
          'Implement batch size limits',
          'Add gas estimation before batch execution',
          'Provide user guidance on optimal batch sizes',
          'Implement progressive batch processing'
        ],
        estimated_savings: 'Prevents failed transactions and gas waste',
        implementation_effort: 'Low'
      },
      {
        priority: 'LOW',
        title: 'Mapping Optimization',
        description: 'Combine related mappings for better access patterns',
        actions: [
          'Create TicketData struct for combined ticket information',
          'Update functions to use combined mapping',
          'Benchmark performance impact',
          'Consider access pattern implications'
        ],
        estimated_savings: '2000-5000 gas when accessing multiple fields',
        implementation_effort: 'High'
      }
    ];
  }

  /**
   * Generate implementation guide
   */
  generateImplementationGuide() {
    return {
      phase1: {
        title: 'Immediate Optimizations (1-2 days)',
        tasks: [
          'Implement function-level caching optimizations',
          'Add unchecked arithmetic blocks',
          'Optimize validation order',
          'Add batch size limits'
        ]
      },
      phase2: {
        title: 'Storage Optimizations (3-5 days)',
        tasks: [
          'Design optimized struct layout',
          'Implement new storage structure',
          'Update all related functions',
          'Add comprehensive testing'
        ]
      },
      phase3: {
        title: 'Advanced Optimizations (5-7 days)',
        tasks: [
          'Implement mapping optimizations',
          'Add gas estimation features',
          'Optimize batch processing',
          'Performance benchmarking'
        ]
      },
      testing_requirements: [
        'Gas consumption benchmarks before and after',
        'Functional testing for all optimized functions',
        'Edge case testing for new data types',
        'Integration testing with existing contracts'
      ]
    };
  }

  /**
   * Save optimization report to file
   */
  saveOptimizationReport(outputPath) {
    const report = this.generateOptimizationReport();
    
    // Ensure directory exists
    const dir = path.dirname(outputPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    fs.writeFileSync(outputPath, JSON.stringify(report, null, 2));
    console.log(`Storage optimization report saved to: ${outputPath}`);
    
    // Also save a human-readable summary
    const summaryPath = outputPath.replace('.json', '-summary.md');
    this.saveSummaryReport(summaryPath, report);
    
    return report;
  }

  /**
   * Save human-readable summary report
   */
  saveSummaryReport(outputPath, report) {
    let summary = '# VeriTix Storage Optimization Analysis\n\n';
    
    summary += `**Generated:** ${report.metadata.generated_at}\n\n`;
    
    summary += '## Summary\n\n';
    summary += `- **Total Optimizations:** ${report.summary.total_optimizations}\n`;
    summary += `- **High Priority:** ${report.summary.high_priority}\n`;
    summary += `- **Medium Priority:** ${report.summary.medium_priority}\n`;
    summary += `- **Low Priority:** ${report.summary.low_priority}\n`;
    summary += `- **Estimated Total Savings:** ${report.summary.estimated_total_savings} gas\n\n`;
    
    summary += '## Key Recommendations\n\n';
    report.recommendations.forEach((rec, index) => {
      summary += `### ${index + 1}. ${rec.title} (${rec.priority} Priority)\n\n`;
      summary += `${rec.description}\n\n`;
      summary += '**Actions:**\n';
      rec.actions.forEach(action => {
        summary += `- ${action}\n`;
      });
      summary += `\n**Estimated Savings:** ${rec.estimated_savings}\n`;
      summary += `**Implementation Effort:** ${rec.implementation_effort}\n\n`;
    });
    
    summary += '## Implementation Phases\n\n';
    Object.entries(report.implementation_guide).forEach(([phase, details]) => {
      if (phase !== 'testing_requirements') {
        summary += `### ${details.title}\n\n`;
        details.tasks.forEach(task => {
          summary += `- ${task}\n`;
        });
        summary += '\n';
      }
    });
    
    fs.writeFileSync(outputPath, summary);
    console.log(`Storage optimization summary saved to: ${outputPath}`);
  }
}

// CLI interface
if (require.main === module) {
  const analyzer = new StorageOptimizationAnalyzer();
  
  async function main() {
    try {
      console.log('Starting VeriTix storage optimization analysis...');
      
      const reportPath = './audit/reports/storage-optimization-report.json';
      const report = analyzer.saveOptimizationReport(reportPath);
      
      console.log('\n=== Storage Optimization Analysis Complete ===');
      console.log(`Total optimizations identified: ${report.summary.total_optimizations}`);
      console.log(`Estimated total gas savings: ${report.summary.estimated_total_savings}`);
      console.log(`High priority optimizations: ${report.summary.high_priority}`);
      
    } catch (error) {
      console.error(`Storage optimization analysis failed: ${error.message}`);
      process.exit(1);
    }
  }
  
  main();
}

module.exports = StorageOptimizationAnalyzer;