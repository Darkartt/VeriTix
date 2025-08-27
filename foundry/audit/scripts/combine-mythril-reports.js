#!/usr/bin/env node

/**
 * Mythril Report Combiner
 * 
 * This script combines individual Mythril analysis reports into a single
 * comprehensive report for processing by the vulnerability classifier.
 */

const fs = require('fs');
const path = require('path');

function combineReports(reportsDir) {
  const combinedReport = {
    metadata: {
      generated_at: new Date().toISOString(),
      tool: 'mythril',
      version: '1.0.0'
    },
    issues: [],
    contracts_analyzed: []
  };

  try {
    // Find all Mythril report files
    const files = fs.readdirSync(reportsDir);
    const mythrilFiles = files.filter(file => 
      file.endsWith('-mythril-report.json') && file !== 'mythril-report.json'
    );

    mythrilFiles.forEach(file => {
      const filePath = path.join(reportsDir, file);
      const contractName = file.replace('-mythril-report.json', '');
      
      try {
        const reportContent = fs.readFileSync(filePath, 'utf8');
        
        // Handle different Mythril output formats
        let report;
        try {
          report = JSON.parse(reportContent);
        } catch (parseError) {
          // If JSON parsing fails, try to extract issues from text output
          report = parseTextOutput(reportContent);
        }

        if (report && report.issues) {
          // Add contract context to each issue
          report.issues.forEach(issue => {
            issue.contract = contractName;
            issue.source_file = `src/${contractName}.sol`;
          });
          
          combinedReport.issues.push(...report.issues);
        } else if (report && Array.isArray(report)) {
          // Handle case where report is directly an array of issues
          report.forEach(issue => {
            issue.contract = contractName;
            issue.source_file = `src/${contractName}.sol`;
          });
          
          combinedReport.issues.push(...report);
        }

        combinedReport.contracts_analyzed.push(contractName);
        
      } catch (error) {
        console.warn(`Warning: Could not process ${file}: ${error.message}`);
      }
    });

    // Remove duplicates based on title and description
    combinedReport.issues = removeDuplicateIssues(combinedReport.issues);
    
    // Sort issues by severity
    combinedReport.issues.sort((a, b) => {
      const severityOrder = { 'High': 0, 'Medium': 1, 'Low': 2 };
      return (severityOrder[a.severity] || 3) - (severityOrder[b.severity] || 3);
    });

    combinedReport.summary = {
      total_issues: combinedReport.issues.length,
      contracts_analyzed: combinedReport.contracts_analyzed.length,
      severity_breakdown: getSeverityBreakdown(combinedReport.issues)
    };

    return combinedReport;

  } catch (error) {
    console.error(`Error combining Mythril reports: ${error.message}`);
    return {
      metadata: {
        generated_at: new Date().toISOString(),
        tool: 'mythril',
        version: '1.0.0',
        error: error.message
      },
      issues: [],
      contracts_analyzed: []
    };
  }
}

function parseTextOutput(textOutput) {
  // Basic text parsing for Mythril output when JSON parsing fails
  const issues = [];
  
  // This is a simplified parser - in practice, you might need more sophisticated parsing
  const lines = textOutput.split('\n');
  let currentIssue = null;
  
  lines.forEach(line => {
    line = line.trim();
    
    // Look for issue indicators
    if (line.includes('SWC-') || line.includes('Severity:')) {
      if (currentIssue) {
        issues.push(currentIssue);
      }
      
      currentIssue = {
        title: 'Mythril Finding',
        description: '',
        severity: 'Medium',
        swc_id: '',
        filename: '',
        lineno: 0
      };
    }
    
    if (currentIssue) {
      if (line.includes('SWC-')) {
        const swcMatch = line.match(/SWC-(\d+)/);
        if (swcMatch) {
          currentIssue.swc_id = `SWC-${swcMatch[1]}`;
        }
      }
      
      if (line.includes('Severity:')) {
        const severityMatch = line.match(/Severity:\s*(\w+)/);
        if (severityMatch) {
          currentIssue.severity = severityMatch[1];
        }
      }
      
      if (line.includes('Title:')) {
        currentIssue.title = line.replace('Title:', '').trim();
      }
      
      if (line.length > 0 && !line.includes(':')) {
        currentIssue.description += line + ' ';
      }
    }
  });
  
  if (currentIssue) {
    issues.push(currentIssue);
  }
  
  return { issues };
}

function removeDuplicateIssues(issues) {
  const seen = new Set();
  return issues.filter(issue => {
    const key = `${issue.title}-${issue.swc_id}-${issue.severity}`;
    if (seen.has(key)) {
      return false;
    }
    seen.add(key);
    return true;
  });
}

function getSeverityBreakdown(issues) {
  const breakdown = { High: 0, Medium: 0, Low: 0 };
  
  issues.forEach(issue => {
    if (breakdown.hasOwnProperty(issue.severity)) {
      breakdown[issue.severity]++;
    }
  });
  
  return breakdown;
}

// CLI interface
if (require.main === module) {
  const reportsDir = process.argv[2] || './audit/reports/mythril';
  
  if (!fs.existsSync(reportsDir)) {
    console.error(`Reports directory does not exist: ${reportsDir}`);
    process.exit(1);
  }
  
  const combinedReport = combineReports(reportsDir);
  console.log(JSON.stringify(combinedReport, null, 2));
}

module.exports = { combineReports };