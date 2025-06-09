#Requires -Version 7.0
<#
.SYNOPSIS
    Enterprise hierarchical testing pipeline template for PowerShell repositories.
.DESCRIPTION
    This template demonstrates the comprehensive hierarchical testing pipeline:
    1. Repository-level common tests (standards, security, compatibility)
    2. Project-specific tests (functionality, integration)
    3. Consolidated reporting and decision making
    4. Quality scoring and deployment gates
.NOTES
    Author: GitHub Copilot (Enhanced Avanade Instructions)
    Version: 2.0.0 (Template)
    Compatible with: PowerShell 5.1+
    Template Origin: Win11FUActions project (98.28% quality score)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = "<REPLACE_WITH_PROJECT_NAME>",

    [switch]$RunProjectTests = $true,

    [switch]$GenerateReport = $true,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 100)]
    [int]$MinimumQualityScore = 90
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Import common testing utilities
$commonTestModulePath = Join-Path $PSScriptRoot ".github\common-test-tools\CommonTestUtils.psm1"
if (Test-Path $commonTestModulePath) {
    Import-Module $commonTestModulePath -Force
    Write-Host "[INIT] Common testing utilities loaded successfully" -ForegroundColor Green
} else {
    Write-Error "Common testing utilities not found at: $commonTestModulePath"
    Write-Host "Please ensure you have copied CommonTestUtils.psm1 from the template" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== HIERARCHICAL TESTING PIPELINE ===" -ForegroundColor Cyan
Write-Host "Repository: <REPLACE_WITH_REPOSITORY_NAME>"
Write-Host "Target Project: $ProjectPath"
Write-Host "Quality Gate: $MinimumQualityScore%"
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Step 1: Repository-Level Common Tests
Write-Host "`n--- STEP 1: Repository-Level Common Tests ---" -ForegroundColor Yellow
$projectFullPath = Join-Path $PSScriptRoot $ProjectPath

if (-not (Test-Path $projectFullPath)) {
    Write-Error "Project path not found: $projectFullPath"
    Write-Host "Available directories:" -ForegroundColor Yellow
    Get-ChildItem $PSScriptRoot -Directory | ForEach-Object { Write-Host "  - $($_.Name)" }
    exit 1
}

$commonResults = Invoke-CommonProjectTests -ProjectPath $projectFullPath -Verbose

Write-Host "`nCOMMON TESTS SUMMARY:" -ForegroundColor Magenta
Write-Host "- Overall Score: $($commonResults.OverallSummary.AverageScore)%"
Write-Host "- Recommendation: $($commonResults.OverallSummary.RecommendedAction)"
Write-Host "- Critical Security Issues: $($commonResults.OverallSummary.HasCriticalSecurityIssues)"

# Quality Gate Check
$qualityGatePassed = $commonResults.OverallSummary.AverageScore -ge $MinimumQualityScore
if ($qualityGatePassed) {
    Write-Host "[QUALITY GATE] ✅ PASSED ($($commonResults.OverallSummary.AverageScore)% >= $MinimumQualityScore%)" -ForegroundColor Green
} else {
    Write-Host "[QUALITY GATE] ❌ FAILED ($($commonResults.OverallSummary.AverageScore)% < $MinimumQualityScore%)" -ForegroundColor Red
}

# Step 2: Project-Specific Tests (if available)
Write-Host "`n--- STEP 2: Project-Specific Tests ---" -ForegroundColor Yellow
$projectTestRunner = Join-Path $projectFullPath "tools\run-tests.ps1"
$projectTestsAvailable = Test-Path $projectTestRunner

if ($projectTestsAvailable -and $RunProjectTests) {
    Write-Host "Found project-specific test runner: $projectTestRunner"
    try {
        Write-Host "Executing project-specific tests..."
        & $projectTestRunner -Verbose
        $projectTestResult = "PASSED"
        Write-Host "[SUCCESS] Project-specific tests completed successfully" -ForegroundColor Green
    } catch {
        $projectTestResult = "FAILED"
        Write-Warning "[WARNING] Project-specific tests encountered issues: $($_.Exception.Message)"
    }
} else {
    if (-not $projectTestsAvailable) {
        Write-Host "[INFO] No project-specific test runner found at: $projectTestRunner" -ForegroundColor Yellow
        Write-Host "[SUGGESTION] Create a tools\run-tests.ps1 file to enable project-specific testing" -ForegroundColor Cyan
    }
    $projectTestResult = "SKIPPED"
}

# Step 3: Hierarchical Decision Making
Write-Host "`n--- STEP 3: Hierarchical Test Results & Decisions ---" -ForegroundColor Yellow

$canDeploy = $false
$criticalIssues = @()
$warnings = @()

# Evaluate common test results
if (-not $qualityGatePassed) {
    $criticalIssues += "Quality gate failed: $($commonResults.OverallSummary.AverageScore)% < $MinimumQualityScore%"
}

if ($commonResults.OverallSummary.HasCriticalSecurityIssues) {
    $criticalIssues += "Critical security issues detected"
}

# Evaluate project test results
switch ($projectTestResult) {
    "FAILED" { $criticalIssues += "Project-specific tests failed" }
    "SKIPPED" { $warnings += "Project-specific tests not available or skipped" }
    "PASSED" { Write-Host "[PASS] Project-specific tests passed" -ForegroundColor Green }
}

# Final decision
if ($criticalIssues.Count -eq 0) {
    $canDeploy = $true
    Write-Host "`n🎉 PIPELINE RESULT: READY FOR DEPLOYMENT" -ForegroundColor Green
    Write-Host "Quality Score: $($commonResults.OverallSummary.AverageScore)% (Target: $MinimumQualityScore%+)" -ForegroundColor Green
} else {
    Write-Host "`n❌ PIPELINE RESULT: NOT READY FOR DEPLOYMENT" -ForegroundColor Red
    Write-Host "Quality Score: $($commonResults.OverallSummary.AverageScore)% (Target: $MinimumQualityScore%+)" -ForegroundColor Red
}

Write-Host "`nDETAILED RESULTS:" -ForegroundColor Cyan
if ($criticalIssues.Count -gt 0) {
    Write-Host "Critical Issues:" -ForegroundColor Red
    $criticalIssues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if ($warnings.Count -gt 0) {
    Write-Host "Warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

# Step 4: Generate Report (optional)
if ($GenerateReport) {
    Write-Host "`n--- STEP 4: Generating Test Report ---" -ForegroundColor Yellow

    $reportData = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Project = $ProjectPath
        QualityGate = @{
            MinimumScore = $MinimumQualityScore
            ActualScore = $commonResults.OverallSummary.AverageScore
            Passed = $qualityGatePassed
        }
        CommonTests = @{
            Score = $commonResults.OverallSummary.AverageScore
            Recommendation = $commonResults.OverallSummary.RecommendedAction
            HasSecurityIssues = $commonResults.OverallSummary.HasCriticalSecurityIssues
            CompatibilityRate = if ($commonResults.Compatibility) { $commonResults.Compatibility.Summary.CompatibilityRate } else { "N/A" }
            StandardsCompliance = if ($commonResults.Standards) { $commonResults.Standards.Summary.ComplianceRate } else { "N/A" }
            SecurityScore = if ($commonResults.Security) { $commonResults.Security.Summary.SecurityScore } else { "N/A" }
        }
        ProjectTests = @{
            Available = $projectTestsAvailable
            Result = $projectTestResult
        }
        Pipeline = @{
            CanDeploy = $canDeploy
            CriticalIssues = $criticalIssues
            Warnings = $warnings
        }
    }

    $reportPath = Join-Path $PSScriptRoot "pipeline-test-report.json"
    $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "Report saved to: $reportPath" -ForegroundColor Green

    # Also generate markdown summary
    $markdownPath = Join-Path $PSScriptRoot "pipeline-test-summary.md"
    $markdownContent = @"
# Pipeline Test Summary

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Project:** $ProjectPath
**Quality Gate:** $MinimumQualityScore%

## Results

- **Overall Score:** $($commonResults.OverallSummary.AverageScore)%
- **Quality Gate:** $(if ($qualityGatePassed) { "✅ PASSED" } else { "❌ FAILED" })
- **Deployment Status:** $(if ($canDeploy) { "🎉 READY" } else { "❌ NOT READY" })

## Test Breakdown

### Common Tests
- **Compatibility:** $($commonResults.Compatibility.Summary.CompatibilityRate)%
- **Standards Compliance:** $($commonResults.Standards.Summary.ComplianceRate)%
- **Security Score:** $($commonResults.Security.Summary.SecurityScore)%

### Project Tests
- **Available:** $(if ($projectTestsAvailable) { "Yes" } else { "No" })
- **Result:** $projectTestResult

$(if ($criticalIssues.Count -gt 0) {
"## Critical Issues
$($criticalIssues | ForEach-Object { "- $_" } | Out-String)"
})

$(if ($warnings.Count -gt 0) {
"## Warnings
$($warnings | ForEach-Object { "- $_" } | Out-String)"
})
"@
    $markdownContent | Out-File -FilePath $markdownPath -Encoding UTF8
    Write-Host "Markdown summary saved to: $markdownPath" -ForegroundColor Green
}

Write-Host "`n=== HIERARCHICAL TESTING PIPELINE COMPLETE ===" -ForegroundColor Cyan
Write-Host "Template Version: 2.0.0 (Based on Win11FUActions success)" -ForegroundColor Cyan

# Exit with appropriate code
if ($canDeploy) {
    exit 0
} else {
    exit 1
}
