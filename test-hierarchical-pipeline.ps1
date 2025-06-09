#Requires -Version 7.0
<#
.SYNOPSIS
    Demonstrates the hierarchical testing pipeline for PowerShell repository.
.DESCRIPTION
    This script shows how the hierarchical testing pipeline works:
    1. Repository-level common tests (standards, security, compatibility)
    2. Project-specific tests (functionality, integration)
    3. Consolidated reporting and decision making
.NOTES
    Author: GitHub Copilot (Enhanced Avanade Instructions)
    Version: 1.0.0
    Compatible with: PowerShell 5.1+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = "Win11FUActions",

    [switch]$RunProjectTests = $true,

    [switch]$GenerateReport = $true
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
    exit 1
}

Write-Host "`n=== HIERARCHICAL TESTING PIPELINE DEMONSTRATION ===" -ForegroundColor Cyan
Write-Host "Repository: PowerShell Scripts Collection"
Write-Host "Target Project: $ProjectPath"
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Step 1: Repository-Level Common Tests
Write-Host "`n--- STEP 1: Repository-Level Common Tests ---" -ForegroundColor Yellow
$projectFullPath = Join-Path $PSScriptRoot $ProjectPath

if (-not (Test-Path $projectFullPath)) {
    Write-Error "Project path not found: $projectFullPath"
    exit 1
}

$commonResults = Invoke-CommonProjectTests -ProjectPath $projectFullPath -Verbose

Write-Host "`nCOMMON TESTS SUMMARY:" -ForegroundColor Magenta
Write-Host "- Overall Score: $($commonResults.OverallSummary.AverageScore)%"
Write-Host "- Recommendation: $($commonResults.OverallSummary.RecommendedAction)"
Write-Host "- Critical Security Issues: $($commonResults.OverallSummary.HasCriticalSecurityIssues)"

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
    }
    $projectTestResult = "SKIPPED"
}

# Step 3: Hierarchical Decision Making
Write-Host "`n--- STEP 3: Hierarchical Test Results & Decisions ---" -ForegroundColor Yellow

$canDeploy = $false
$criticalIssues = @()
$warnings = @()

# Evaluate common test results
if ($commonResults.OverallSummary.AverageScore -lt 50) {
    $criticalIssues += "Common tests failed with score: $($commonResults.OverallSummary.AverageScore)%"
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
} else {
    Write-Host "`n❌ PIPELINE RESULT: NOT READY FOR DEPLOYMENT" -ForegroundColor Red
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
}

Write-Host "`n=== HIERARCHICAL TESTING PIPELINE COMPLETE ===" -ForegroundColor Cyan

# Exit with appropriate code
if ($canDeploy) {
    exit 0
} else {
    exit 1
}
