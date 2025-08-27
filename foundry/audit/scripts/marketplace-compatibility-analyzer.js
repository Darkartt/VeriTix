#!/usr/bin/env node

/**
 * @title Marketplace Compatibility Analyzer
 * @dev Analyzes VeriTix contracts for NFT marketplace compatibility
 * @notice Checks OpenSea, LooksRare, and other major marketplace requirements
 */

const fs = require('fs');
const path = require('path');

class MarketplaceCompatibilityAnalyzer {
    constructor() {
        this.results = {
            overallScore: 0,
            marketplaceCompatibility: {},
            interfaceCompliance: {},
            metadataStandards: {},
            transferMechanisms: {},
            recommendations: []
        };
    }

    /**
     * Analyze contract for marketplace compatibility
     */
    async analyzeContract(contractPath) {
        console.log(`🔍 Analyzing marketplace compatibility for: ${contractPath}`);
        
        const contractContent = fs.readFileSync(contractPath, 'utf8');
        
        // Analyze different aspects
        this.analyzeInterfaceCompliance(contractContent);
        this.analyzeMetadataStandards(contractContent);
        this.analyzeTransferMechanisms(contractContent);
        this.analyzeMarketplaceSpecificRequirements(contractContent);
        
        // Calculate overall score
        this.calculateOverallScore();
        
        return this.results;
    }

    /**
     * Check ERC721 and related interface compliance
     */
    analyzeInterfaceCompliance(contractContent) {
        console.log('📋 Analyzing interface compliance...');
        
        const compliance = {
            erc165: false,
            erc721: false,
            erc721Metadata: false,
            erc721Enumerable: false,
            customInterfaces: []
        };

        // Check ERC165 support
        if (contractContent.includes('supportsInterface') && 
            contractContent.includes('IERC165')) {
            compliance.erc165 = true;
        }

        // Check ERC721 implementation
        if (contractContent.includes('ERC721') && 
            contractContent.includes('IERC721')) {
            compliance.erc721 = true;
        }

        // Check ERC721Metadata
        if (contractContent.includes('tokenURI') && 
            contractContent.includes('name()') && 
            contractContent.includes('symbol()')) {
            compliance.erc721Metadata = true;
        }

        // Check for totalSupply (ERC721Enumerable-like)
        if (contractContent.includes('totalSupply')) {
            compliance.erc721Enumerable = true;
        }

        // Check custom interfaces
        const customInterfaceMatches = contractContent.match(/interface\s+I\w+/g);
        if (customInterfaceMatches) {
            compliance.customInterfaces = customInterfaceMatches;
        }

        this.results.interfaceCompliance = compliance;
        
        // Add recommendations
        if (!compliance.erc165) {
            this.results.recommendations.push({
                severity: 'HIGH',
                category: 'Interface Compliance',
                issue: 'Missing ERC165 interface support',
                recommendation: 'Implement supportsInterface function for proper interface detection'
            });
        }

        if (!compliance.erc721Metadata) {
            this.results.recommendations.push({
                severity: 'CRITICAL',
                category: 'Interface Compliance',
                issue: 'Missing ERC721Metadata implementation',
                recommendation: 'Implement name(), symbol(), and tokenURI() functions'
            });
        }
    }

    /**
     * Analyze metadata standards compliance
     */
    analyzeMetadataStandards(contractContent) {
        console.log('🏷️  Analyzing metadata standards...');
        
        const standards = {
            hasBaseURI: false,
            hasTokenURI: false,
            hasMetadataStructure: false,
            hasCollectionMetadata: false,
            opensea: {
                contractURI: false,
                royaltyInfo: false,
                operatorFilter: false
            }
        };

        // Check base URI implementation
        if (contractContent.includes('_baseURI') || contractContent.includes('baseURI')) {
            standards.hasBaseURI = true;
        }

        // Check tokenURI implementation
        if (contractContent.includes('function tokenURI') && 
            contractContent.includes('string memory')) {
            standards.hasTokenURI = true;
        }

        // Check for structured metadata
        if (contractContent.includes('TicketMetadata') || 
            contractContent.includes('getTicketMetadata')) {
            standards.hasMetadataStructure = true;
        }

        // Check for collection metadata
        if (contractContent.includes('CollectionMetadata') || 
            contractContent.includes('getCollectionMetadata')) {
            standards.hasCollectionMetadata = true;
        }

        // Check OpenSea specific features
        if (contractContent.includes('contractURI')) {
            standards.opensea.contractURI = true;
        }

        if (contractContent.includes('royaltyInfo') || 
            contractContent.includes('EIP2981')) {
            standards.opensea.royaltyInfo = true;
        }

        this.results.metadataStandards = standards;

        // Add recommendations
        if (!standards.hasTokenURI) {
            this.results.recommendations.push({
                severity: 'CRITICAL',
                category: 'Metadata Standards',
                issue: 'Missing tokenURI implementation',
                recommendation: 'Implement tokenURI function returning valid metadata URI'
            });
        }

        if (!standards.opensea.contractURI) {
            this.results.recommendations.push({
                severity: 'MEDIUM',
                category: 'OpenSea Compatibility',
                issue: 'Missing contractURI for collection metadata',
                recommendation: 'Implement contractURI function for collection-level metadata'
            });
        }

        if (!standards.opensea.royaltyInfo) {
            this.results.recommendations.push({
                severity: 'LOW',
                category: 'Marketplace Features',
                issue: 'Missing royalty information (EIP-2981)',
                recommendation: 'Consider implementing EIP-2981 for automatic royalty distribution'
            });
        }
    }

    /**
     * Analyze transfer mechanisms and restrictions
     */
    analyzeTransferMechanisms(contractContent) {
        console.log('🔄 Analyzing transfer mechanisms...');
        
        const mechanisms = {
            hasTransferRestrictions: false,
            hasControlledResale: false,
            hasApprovalMechanism: true,
            hasSafeTransfer: false,
            transferMethod: 'unknown'
        };

        // Check for transfer restrictions
        if (contractContent.includes('TransfersDisabled') || 
            contractContent.includes('_allowTransfer')) {
            mechanisms.hasTransferRestrictions = true;
            mechanisms.transferMethod = 'controlled';
        }

        // Check for controlled resale
        if (contractContent.includes('resaleTicket') || 
            contractContent.includes('resale')) {
            mechanisms.hasControlledResale = true;
        }

        // Check for safe transfer implementation
        if (contractContent.includes('safeTransferFrom')) {
            mechanisms.hasSafeTransfer = true;
        }

        // Check approval mechanism
        if (contractContent.includes('approve') && 
            contractContent.includes('setApprovalForAll')) {
            mechanisms.hasApprovalMechanism = true;
        }

        this.results.transferMechanisms = mechanisms;

        // Add recommendations based on transfer restrictions
        if (mechanisms.hasTransferRestrictions && !mechanisms.hasControlledResale) {
            this.results.recommendations.push({
                severity: 'HIGH',
                category: 'Transfer Mechanisms',
                issue: 'Transfer restrictions without alternative mechanism',
                recommendation: 'Provide controlled resale mechanism for marketplace compatibility'
            });
        }

        if (mechanisms.hasControlledResale) {
            this.results.recommendations.push({
                severity: 'INFO',
                category: 'Transfer Mechanisms',
                issue: 'Custom resale mechanism detected',
                recommendation: 'Ensure marketplace integration documentation explains custom transfer flow'
            });
        }
    }

    /**
     * Analyze specific marketplace requirements
     */
    analyzeMarketplaceSpecificRequirements(contractContent) {
        console.log('🏪 Analyzing marketplace-specific requirements...');
        
        const marketplaces = {
            opensea: {
                compatible: false,
                issues: [],
                score: 0
            },
            looksrare: {
                compatible: false,
                issues: [],
                score: 0
            },
            foundation: {
                compatible: false,
                issues: [],
                score: 0
            },
            superrare: {
                compatible: false,
                issues: [],
                score: 0
            }
        };

        // OpenSea compatibility analysis
        this.analyzeOpenSeaCompatibility(contractContent, marketplaces.opensea);
        
        // LooksRare compatibility analysis
        this.analyzeLooksRareCompatibility(contractContent, marketplaces.looksrare);
        
        // Foundation compatibility analysis
        this.analyzeFoundationCompatibility(contractContent, marketplaces.foundation);
        
        // SuperRare compatibility analysis
        this.analyzeSuperRareCompatibility(contractContent, marketplaces.superrare);

        this.results.marketplaceCompatibility = marketplaces;
    }

    /**
     * Analyze OpenSea specific compatibility
     */
    analyzeOpenSeaCompatibility(contractContent, opensea) {
        let score = 0;
        const maxScore = 10;

        // Basic ERC721 compliance (required)
        if (contractContent.includes('ERC721')) {
            score += 3;
        } else {
            opensea.issues.push('Missing ERC721 implementation');
        }

        // Metadata support (required)
        if (contractContent.includes('tokenURI')) {
            score += 2;
        } else {
            opensea.issues.push('Missing tokenURI function');
        }

        // Interface support (required)
        if (contractContent.includes('supportsInterface')) {
            score += 2;
        } else {
            opensea.issues.push('Missing interface support detection');
        }

        // Collection metadata (recommended)
        if (contractContent.includes('contractURI')) {
            score += 1;
        } else {
            opensea.issues.push('Missing contractURI for collection metadata');
        }

        // Royalty support (recommended)
        if (contractContent.includes('royaltyInfo')) {
            score += 1;
        } else {
            opensea.issues.push('Missing royalty information (EIP-2981)');
        }

        // Transfer restrictions handling (special case for VeriTix)
        if (contractContent.includes('resaleTicket')) {
            score += 1;
            opensea.issues.push('Custom transfer mechanism - requires special integration');
        }

        opensea.score = score;
        opensea.compatible = score >= 7; // 70% threshold
    }

    /**
     * Analyze LooksRare compatibility
     */
    analyzeLooksRareCompatibility(contractContent, looksrare) {
        let score = 0;
        const maxScore = 8;

        // Basic ERC721 compliance
        if (contractContent.includes('ERC721')) {
            score += 3;
        } else {
            looksrare.issues.push('Missing ERC721 implementation');
        }

        // Metadata support
        if (contractContent.includes('tokenURI')) {
            score += 2;
        } else {
            looksrare.issues.push('Missing tokenURI function');
        }

        // Standard transfer mechanism
        if (!contractContent.includes('TransfersDisabled')) {
            score += 2;
        } else {
            looksrare.issues.push('Transfer restrictions may prevent marketplace integration');
        }

        // Royalty support
        if (contractContent.includes('royaltyInfo')) {
            score += 1;
        } else {
            looksrare.issues.push('Missing royalty support');
        }

        looksrare.score = score;
        looksrare.compatible = score >= 6; // 75% threshold
    }

    /**
     * Analyze Foundation compatibility
     */
    analyzeFoundationCompatibility(contractContent, foundation) {
        let score = 0;
        const maxScore = 6;

        // ERC721 compliance
        if (contractContent.includes('ERC721')) {
            score += 2;
        }

        // Metadata
        if (contractContent.includes('tokenURI')) {
            score += 2;
        }

        // Standard transfers (Foundation prefers standard mechanisms)
        if (!contractContent.includes('TransfersDisabled')) {
            score += 2;
        } else {
            foundation.issues.push('Custom transfer restrictions not compatible');
        }

        foundation.score = score;
        foundation.compatible = score >= 5; // High threshold due to curated nature
    }

    /**
     * Analyze SuperRare compatibility
     */
    analyzeSuperRareCompatibility(contractContent, superrare) {
        let score = 0;
        const maxScore = 6;

        // Basic compliance
        if (contractContent.includes('ERC721')) {
            score += 2;
        }

        if (contractContent.includes('tokenURI')) {
            score += 2;
        }

        // SuperRare typically requires standard transfers
        if (!contractContent.includes('TransfersDisabled')) {
            score += 2;
        } else {
            superrare.issues.push('Custom transfer mechanism not supported');
        }

        superrare.score = score;
        superrare.compatible = score >= 5;
    }

    /**
     * Calculate overall compatibility score
     */
    calculateOverallScore() {
        let totalScore = 0;
        let maxScore = 0;

        // Interface compliance (30% weight)
        const interfaceScore = Object.values(this.results.interfaceCompliance)
            .filter(v => typeof v === 'boolean')
            .reduce((sum, val) => sum + (val ? 1 : 0), 0);
        totalScore += interfaceScore * 0.3;
        maxScore += 4 * 0.3;

        // Metadata standards (25% weight)
        const metadataScore = Object.values(this.results.metadataStandards)
            .filter(v => typeof v === 'boolean')
            .reduce((sum, val) => sum + (val ? 1 : 0), 0);
        totalScore += metadataScore * 0.25;
        maxScore += 4 * 0.25;

        // Transfer mechanisms (20% weight)
        const transferScore = Object.values(this.results.transferMechanisms)
            .filter(v => typeof v === 'boolean')
            .reduce((sum, val) => sum + (val ? 1 : 0), 0);
        totalScore += transferScore * 0.2;
        maxScore += 5 * 0.2;

        // Marketplace compatibility (25% weight)
        const marketplaceScores = Object.values(this.results.marketplaceCompatibility)
            .map(m => m.score / 10) // Normalize to 0-1
            .reduce((sum, score) => sum + score, 0) / 4; // Average
        totalScore += marketplaceScores * 0.25;
        maxScore += 1 * 0.25;

        this.results.overallScore = Math.round((totalScore / maxScore) * 100);
    }

    /**
     * Generate comprehensive report
     */
    generateReport() {
        const report = {
            timestamp: new Date().toISOString(),
            summary: {
                overallScore: this.results.overallScore,
                status: this.getStatusFromScore(this.results.overallScore),
                totalRecommendations: this.results.recommendations.length,
                criticalIssues: this.results.recommendations.filter(r => r.severity === 'CRITICAL').length
            },
            interfaceCompliance: this.results.interfaceCompliance,
            metadataStandards: this.results.metadataStandards,
            transferMechanisms: this.results.transferMechanisms,
            marketplaceCompatibility: this.results.marketplaceCompatibility,
            recommendations: this.results.recommendations,
            marketplaceReadiness: this.generateMarketplaceReadiness()
        };

        return report;
    }

    /**
     * Generate marketplace readiness assessment
     */
    generateMarketplaceReadiness() {
        const readiness = {};
        
        Object.entries(this.results.marketplaceCompatibility).forEach(([marketplace, data]) => {
            readiness[marketplace] = {
                ready: data.compatible,
                score: `${data.score}/10`,
                status: data.compatible ? 'READY' : 'NEEDS_WORK',
                blockers: data.issues.filter(issue => 
                    issue.includes('Missing ERC721') || 
                    issue.includes('Missing tokenURI')
                ),
                warnings: data.issues.filter(issue => 
                    !issue.includes('Missing ERC721') && 
                    !issue.includes('Missing tokenURI')
                )
            };
        });

        return readiness;
    }

    /**
     * Get status from numerical score
     */
    getStatusFromScore(score) {
        if (score >= 90) return 'EXCELLENT';
        if (score >= 80) return 'GOOD';
        if (score >= 70) return 'ACCEPTABLE';
        if (score >= 60) return 'NEEDS_IMPROVEMENT';
        return 'POOR';
    }
}

// Main execution
async function main() {
    const analyzer = new MarketplaceCompatibilityAnalyzer();
    
    try {
        // Analyze VeriTixEvent contract
        const eventContractPath = path.join(__dirname, '../../src/VeriTixEvent.sol');
        const results = await analyzer.analyzeContract(eventContractPath);
        
        // Generate report
        const report = analyzer.generateReport();
        
        // Save report
        const reportPath = path.join(__dirname, '../marketplace-compatibility-report.json');
        fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
        
        // Generate summary
        console.log('\n📊 MARKETPLACE COMPATIBILITY ANALYSIS COMPLETE');
        console.log('='.repeat(50));
        console.log(`Overall Score: ${report.summary.overallScore}/100 (${report.summary.status})`);
        console.log(`Total Recommendations: ${report.summary.totalRecommendations}`);
        console.log(`Critical Issues: ${report.summary.criticalIssues}`);
        
        console.log('\n🏪 Marketplace Readiness:');
        Object.entries(report.marketplaceReadiness).forEach(([marketplace, readiness]) => {
            const status = readiness.ready ? '✅' : '❌';
            console.log(`  ${status} ${marketplace.toUpperCase()}: ${readiness.status} (${readiness.score})`);
        });
        
        console.log('\n📋 Top Recommendations:');
        report.recommendations
            .filter(r => r.severity === 'CRITICAL' || r.severity === 'HIGH')
            .slice(0, 5)
            .forEach((rec, index) => {
                console.log(`  ${index + 1}. [${rec.severity}] ${rec.issue}`);
                console.log(`     → ${rec.recommendation}`);
            });
        
        console.log(`\n📄 Full report saved to: ${reportPath}`);
        
    } catch (error) {
        console.error('❌ Analysis failed:', error.message);
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main();
}

module.exports = { MarketplaceCompatibilityAnalyzer };