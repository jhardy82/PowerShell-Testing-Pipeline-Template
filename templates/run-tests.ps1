#Requires -Version 7.0
<#
.SYNOPSIS
    Project-specific test runner template for PowerShell projects.
.DESCRIPTION
    This template provides a standardized approach to running project-specific tests:
    1. Pester test discovery and execution
    2. Code coverage analysis (optional)
    3. Test result reporting in multiple formats
    4. Integration with hierarchical pipeline
.NOTES
    Author: GitHub Copilot (Enhanced Avanade Instructions)
    Version: 2.0.0 (Template)
    Compatible with: PowerShell 5.1+, Pester 5.x
    Template Origin: Win11FUActions project (100% test pass rate)
.EXAMPLE
    .\tools\run-tests.ps1 -Verbose
    .\tools\run-tests.ps1 -IncludeCoverage -OutputFormat NUnitXml
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestPath = "tests",

    [Parameter(Mandatory = $false)]
    [ValidateSet('NUnitXml', 'JUnitXml', 'Console', 'All')]
    [string]$OutputFormat = 'Console',

    [switch]$IncludeCoverage,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "TestResults",

    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'

# Project Configuration
$ProjectName = "<REPLACE_WITH_PROJECT_NAME>"
$SourcePath = "<REPLACE_WITH_SOURCE_PATH>"  # e.g., "Utils", "Scripts", "src"

Write-Host "=== PROJECT-SPECIFIC TEST RUNNER ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectName"
Write-Host "Test Path: $TestPath"
Write-Host "Output Format: $OutputFormat"
Write-Host "Coverage: $(if ($IncludeCoverage) { 'Enabled' } else { 'Disabled' })"
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Ensure we're in the correct directory
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
Set-Location $projectRoot

Write-Verbose "Script Root: $scriptRoot"
Write-Verbose "Project Root: $projectRoot"

# Check for Pester module
$pesterModule = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
if (-not $pesterModule) {
    Write-Error "Pester module not found. Please install Pester: Install-Module -Name Pester -Force"
}

$pesterVersion = $pesterModule.Version
Write-Host "Using Pester Version: $pesterVersion" -ForegroundColor Green

if ($pesterVersion.Major -lt 5) {
    Write-Warning "Pester version 5.x or higher is recommended for best results"
}

# Ensure test directory exists
$testFullPath = Join-Path $projectRoot $TestPath
if (-not (Test-Path $testFullPath)) {
    Write-Error "Test directory not found: $testFullPath"
}

# Discover test files
$testFiles = Get-ChildItem -Path $testFullPath -Filter "*.Tests.ps1" -Recurse
if ($testFiles.Count -eq 0) {
    Write-Warning "No test files found matching pattern '*.Tests.ps1' in: $testFullPath"
    exit 0
}

Write-Host "Found $($testFiles.Count) test file(s):" -ForegroundColor Yellow
$testFiles | ForEach-Object { Write-Host "  - $($_.Name)" }

# Prepare output directory
if ($OutputFormat -ne 'Console' -or $IncludeCoverage) {
    $outputFullPath = Join-Path $projectRoot $OutputDirectory
    if (-not (Test-Path $outputFullPath)) {
        New-Item -Path $outputFullPath -ItemType Directory -Force | Out-Null
        Write-Verbose "Created output directory: $outputFullPath"
    }
}

# Configure Pester
$pesterConfig = @{
    Run = @{
        Path = $testFullPath
        PassThru = $true
    }
    Output = @{
        Verbosity = 'Detailed'
    }
}

# Configure test result output
if ($OutputFormat -in @('NUnitXml', 'All')) {
    $nunitPath = Join-Path $outputFullPath "Test-Results-NUnit.xml"
    $pesterConfig.TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = $nunitPath
    }
    Write-Verbose "NUnit XML output: $nunitPath"
}

if ($OutputFormat -in @('JUnitXml', 'All')) {
    $junitPath = Join-Path $outputFullPath "Test-Results-JUnit.xml"
    if ($OutputFormat -eq 'JUnitXml') {
        $pesterConfig.TestResult = @{
            Enabled = $true
            OutputFormat = 'JUnitXml'
            OutputPath = $junitPath
        }
    }
    Write-Verbose "JUnit XML output: $junitPath"
}

# Configure code coverage (if requested)
if ($IncludeCoverage) {
    $sourceFullPath = Join-Path $projectRoot $SourcePath
    if (Test-Path $sourceFullPath) {
        $coverageFiles = Get-ChildItem -Path $sourceFullPath -Filter "*.ps1" -Recurse | Where-Object { $_.Name -notlike "*.Tests.ps1" }

        if ($coverageFiles.Count -gt 0) {
            $pesterConfig.CodeCoverage = @{
                Enabled = $true
                Path = $coverageFiles.FullName
                OutputFormat = 'JaCoCo'
                OutputPath = Join-Path $outputFullPath "Coverage.xml"
            }
            Write-Host "Code coverage enabled for $($coverageFiles.Count) source file(s)" -ForegroundColor Green
        } else {
            Write-Warning "No source files found for coverage analysis in: $sourceFullPath"
        }
    } else {
        Write-Warning "Source path not found for coverage analysis: $sourceFullPath"
    }
}

# Execute tests
Write-Host "`n--- EXECUTING TESTS ---" -ForegroundColor Yellow
try {
    $testResults = Invoke-Pester -Configuration $pesterConfig

    # Display summary
    Write-Host "`n--- TEST SUMMARY ---" -ForegroundColor Magenta
    Write-Host "Total Tests: $($testResults.TotalCount)"
    Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { 'Green' } else { 'Red' })
    Write-Host "Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Duration: $($testResults.Duration.TotalSeconds) seconds"

    if ($testResults.CodeCoverage) {
        $coveragePercent = [Math]::Round(($testResults.CodeCoverage.CoveragePercent), 2)
        Write-Host "Code Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { 'Green' } elseif ($coveragePercent -ge 60) { 'Yellow' } else { 'Red' })
    }

    # Check for failures
    if ($testResults.FailedCount -gt 0) {
        Write-Host "`nFAILED TESTS:" -ForegroundColor Red
        $testResults.Failed | ForEach-Object {
            Write-Host "  - $($_.Name): $($_.ErrorRecord.Exception.Message)" -ForegroundColor Red
        }

        Write-Error "Test execution failed: $($testResults.FailedCount) test(s) failed"
    } else {
        Write-Host "`n✅ ALL TESTS PASSED" -ForegroundColor Green
    }

    # Generate summary report
    if ($OutputFormat -ne 'Console' -or $IncludeCoverage) {
        $summaryPath = Join-Path $outputFullPath "TestSummary.json"
        $summary = @{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Project = $ProjectName
            TestResults = @{
                Total = $testResults.TotalCount
                Passed = $testResults.PassedCount
                Failed = $testResults.FailedCount
                Skipped = $testResults.SkippedCount
                Duration = $testResults.Duration.TotalSeconds
            }
            Coverage = if ($testResults.CodeCoverage) {
                @{
                    Enabled = $true
                    Percentage = $coveragePercent
                    CommandsAnalyzed = $testResults.CodeCoverage.CommandsAnalyzedCount
                    CommandsExecuted = $testResults.CodeCoverage.CommandsExecutedCount
                }
            } else {
                @{ Enabled = $false }
            }
            Success = ($testResults.FailedCount -eq 0)
        }

        $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryPath -Encoding UTF8
        Write-Host "Test summary saved to: $summaryPath" -ForegroundColor Green
    }

    if ($PassThru) {
        return $testResults
    }

} catch {
    Write-Error "Test execution failed with error: $($_.Exception.Message)"
    throw
}

Write-Host "`n=== PROJECT TEST EXECUTION COMPLETE ===" -ForegroundColor Cyan
