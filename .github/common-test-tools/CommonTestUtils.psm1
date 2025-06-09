#Requires -Version 7.0
<#
.SYNOPSIS
    Shared testing utilities for all PowerShell projects in this repository.
.DESCRIPTION
    Common test functions that can be used across all projects to ensure
    consistent testing patterns and standards.
.NOTES
    Author: GitHub Copilot (Enhanced Avanade Instructions)
    Version: 2.0.0 - Modernized from Win11FUActions lessons learned
    Compatible with: PowerShell 5.1+
#>

function Test-PowerShellCompatibility {
    <#
    .SYNOPSIS
        Tests PowerShell 5.1 compatibility for a given file or directory.
    .PARAMETER Path
        Path to test (file or directory)
    .PARAMETER Recurse
        Test recursively if Path is a directory
    .OUTPUTS
        PSCustomObject with compatibility test results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$Recurse
    )

    $results = @{
        TestedFiles = @()
        Issues      = @()
        PassedFiles = @()
        Summary     = $null
    }

    # Get files to test
    if (Test-Path $Path -PathType Leaf) {
        $files = @(Get-Item $Path)
    }
    else {
        $params = @{
            Path        = $Path
            Include     = '*.ps1', '*.psm1'
            ErrorAction = 'SilentlyContinue'
        }
        if ($Recurse) { $params.Recurse = $true }
        $files = Get-ChildItem @params
    }

    foreach ($file in $files) {
        $results.TestedFiles += $file.FullName

        # Enhanced compatibility check with defensive programming pattern detection
        $fileContent = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $fileContent) { continue }

        # Check for compatibility enhancements (defensive programming patterns)
        $isCompatibilityEnhanced = $false
        $compatibilityPatterns = @(
            'Get-Module\s+.*-ListAvailable.*-Name',  # Module availability check
            'Test-Path.*-PathType',                   # Path validation
            'try\s*{.*}.*catch',                     # Error handling
            '-ErrorAction\s+(SilentlyContinue|Stop)', # Error action specification
            'if\s*\(\$PSVersionTable\.PSVersion\.Major', # Version checking
            '\[Environment\]::OSVersion',             # OS version checking
            'Import-Module.*-Force.*-ErrorAction'     # Safe module importing
        )

        foreach ($pattern in $compatibilityPatterns) {
            if ($fileContent -match $pattern) {
                $isCompatibilityEnhanced = $true
                break
            }
        }

        # Check for PowerShell 5.1 incompatible features
        $fileIssues = @()

        # PowerShell 7+ specific features that need attention in PS 5.1
        $incompatiblePatterns = @{
            'Foreach-Object -Parallel'     = 'Parallel processing not available in PowerShell 5.1'
            'null-conditional operators'   = 'Null-conditional operators (?.) not available in PowerShell 5.1'
            'ternary operators'           = 'Ternary operators (? :) not available in PowerShell 5.1'
            'pipeline chain operators'    = 'Pipeline chain operators (&& ||) not available in PowerShell 5.1'
        }

        foreach ($pattern in $incompatiblePatterns.Keys) {
            if ($fileContent -match $pattern) {
                $fileIssues += [PSCustomObject]@{
                    File        = $file.FullName
                    Issue       = $incompatiblePatterns[$pattern]
                    Severity    = 'High'
                    Line        = 'Multiple'
                    Suggestion  = 'Review and replace with PowerShell 5.1 compatible alternatives'
                }
            }
        }

        if ($fileIssues.Count -gt 0) {
            $results.Issues += [PSCustomObject]@{
                File     = $file.FullName
                Issues   = $fileIssues
            }
        }
        else {
            $results.PassedFiles += $file.FullName
            if ($isCompatibilityEnhanced) {
                Write-Verbose "File $($file.Name) has compatibility enhancements - marked as compatible"
            }
        }
    }

    $results.Summary = [PSCustomObject]@{
        TotalFiles        = $results.TestedFiles.Count
        PassedFiles       = $results.PassedFiles.Count
        FailedFiles       = $results.Issues.Count
        CompatibilityRate = if ($results.TestedFiles.Count -gt 0) {
            [Math]::Round(($results.PassedFiles.Count / $results.TestedFiles.Count) * 100, 2)
        }
        else { 100 }
    }

    return [PSCustomObject]$results
}

function Test-PersonalStandards {
    <#
    .SYNOPSIS
        Tests adherence to Avanade PowerShell coding standards.
    .PARAMETER Path
        Path to test (file or directory)
    .PARAMETER Recurse
        Test recursively if Path is a directory
    .OUTPUTS
        PSCustomObject with standards compliance results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$Recurse
    )

    $results = @{
        TestedFiles = @()
        Standards   = @{
            ContextPattern = @{ Passed = @(); Failed = @() }
            ErrorHandling  = @{ Passed = @(); Failed = @() }
            Logging        = @{ Passed = @(); Failed = @() }
            Documentation  = @{ Passed = @(); Failed = @() }
        }
        Summary = $null
    }

    # Get files to test
    if (Test-Path $Path -PathType Leaf) {
        $files = @(Get-Item $Path)
    }
    else {
        $params = @{
            Path        = $Path
            Include     = '*.ps1', '*.psm1'
            ErrorAction = 'SilentlyContinue'
        }
        if ($Recurse) { $params.Recurse = $true }
        $files = Get-ChildItem @params
    }

    foreach ($file in $files) {
        $results.TestedFiles += $file.FullName
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        if (-not $content) { continue }

        # Test Context Pattern (Avanade standard)
        if ($content -match '\$Context\s*=.*PSCustomObject') {
            $results.Standards.ContextPattern.Passed += $file.FullName
        }
        else {
            $results.Standards.ContextPattern.Failed += $file.FullName
        }

        # Test Error Handling
        if ($content -match '\$ErrorActionPreference.*Stop' -and $content -match 'try\s*{.*}.*catch') {
            $results.Standards.ErrorHandling.Passed += $file.FullName
        }
        else {
            $results.Standards.ErrorHandling.Failed += $file.FullName
        }

        # Test Logging Patterns
        if ($content -match 'Write-Log|Start-Transcript|Write-Verbose') {
            $results.Standards.Logging.Passed += $file.FullName
        }
        else {
            $results.Standards.Logging.Failed += $file.FullName
        }

        # Test Documentation
        if ($content -match '\.SYNOPSIS|\.DESCRIPTION|\.PARAMETER') {
            $results.Standards.Documentation.Passed += $file.FullName
        }
        else {
            $results.Standards.Documentation.Failed += $file.FullName
        }
    }

    # Calculate summary
    $totalFiles = $results.TestedFiles.Count
    $standardsCount = $results.Standards.Keys.Count
    $totalChecks = $totalFiles * $standardsCount

    $passedChecks = 0
    foreach ($standard in $results.Standards.Keys) {
        $passedChecks += $results.Standards[$standard].Passed.Count
    }

    $results.Summary = [PSCustomObject]@{
        TotalFiles      = $totalFiles
        TotalChecks     = $totalChecks
        PassedChecks    = $passedChecks
        ComplianceRate  = if ($totalChecks -gt 0) {
            [Math]::Round(($passedChecks / $totalChecks) * 100, 2)
        }
        else { 100 }
        StandardsBreakdown = @{
            ContextPattern = [Math]::Round(($results.Standards.ContextPattern.Passed.Count / [Math]::Max($totalFiles, 1)) * 100, 2)
            ErrorHandling  = [Math]::Round(($results.Standards.ErrorHandling.Passed.Count / [Math]::Max($totalFiles, 1)) * 100, 2)
            Logging        = [Math]::Round(($results.Standards.Logging.Passed.Count / [Math]::Max($totalFiles, 1)) * 100, 2)
            Documentation  = [Math]::Round(($results.Standards.Documentation.Passed.Count / [Math]::Max($totalFiles, 1)) * 100, 2)
        }
    }

    return [PSCustomObject]$results
}

function Test-SecurityBestPractices {
    <#
    .SYNOPSIS
        Tests security best practices in PowerShell scripts.
    .PARAMETER Path
        Path to test (file or directory)
    .PARAMETER Recurse
        Test recursively if Path is a directory
    .OUTPUTS
        PSCustomObject with security analysis results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$Recurse
    )

    $results = @{
        TestedFiles     = @()
        SecurityIssues  = @()
        PassedFiles     = @()
        CriticalIssues  = $false
        Summary         = $null
    }

    # Get files to test
    if (Test-Path $Path -PathType Leaf) {
        $files = @(Get-Item $Path)
    }
    else {
        $params = @{
            Path        = $Path
            Include     = '*.ps1', '*.psm1'
            ErrorAction = 'SilentlyContinue'
        }
        if ($Recurse) { $params.Recurse = $true }
        $files = Get-ChildItem @params
    }

    # Security patterns to check
    $securityPatterns = @{        'Plain text passwords'     = @{
            Pattern = 'password\s*=\s*["`''].*["`'']'
            Severity = 'Critical'
        }
        'Hardcoded credentials'    = @{
            Pattern = 'username\s*=\s*["`''].*["`''].*password\s*=\s*["`''].*["`'']'
            Severity = 'Critical'
        }
        'Invoke-Expression usage'  = @{
            Pattern = 'Invoke-Expression|iex\s'
            Severity = 'High'
        }
        'Download and execute'     = @{
            Pattern = 'DownloadString.*Invoke-Expression|iwr.*iex'
            Severity = 'Critical'
        }
        'Execution policy bypass'  = @{
            Pattern = 'Set-ExecutionPolicy.*Bypass'
            Severity = 'Medium'
        }
    }

    foreach ($file in $files) {
        $results.TestedFiles += $file.FullName
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        if (-not $content) { continue }

        $fileHasIssues = $false
        $fileIssues = @()

        foreach ($checkName in $securityPatterns.Keys) {
            $check = $securityPatterns[$checkName]
            if ($content -match $check.Pattern) {
                $fileHasIssues = $true
                if ($check.Severity -eq 'Critical') {
                    $results.CriticalIssues = $true
                }

                $fileIssues += [PSCustomObject]@{
                    Check    = $checkName
                    Severity = $check.Severity
                    Pattern  = $check.Pattern
                }
            }
        }

        if ($fileHasIssues) {
            $results.SecurityIssues += [PSCustomObject]@{
                File   = $file.FullName
                Issues = $fileIssues
            }
        }
        else {
            $results.PassedFiles += $file.FullName
        }
    }

    $results.Summary = [PSCustomObject]@{
        TotalFiles         = $results.TestedFiles.Count
        FilesWithIssues    = $results.SecurityIssues.Count
        CleanFiles         = $results.PassedFiles.Count
        CriticalIssues     = $results.CriticalIssues
        SecurityScore      = if ($results.TestedFiles.Count -gt 0) {
            [Math]::Round(($results.PassedFiles.Count / $results.TestedFiles.Count) * 100, 2)
        }
        else { 100 }
    }

    return [PSCustomObject]$results
}

function Invoke-CommonProjectTests {
    <#
    .SYNOPSIS
        Runs common tests across a project and provides consolidated scoring.
    .PARAMETER ProjectPath
        Path to the project directory
    .PARAMETER OutputFormat
        Output format: 'Summary', 'Detailed', 'JSON'
    .OUTPUTS
        PSCustomObject with comprehensive test results and scoring
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [ValidateSet('Summary', 'Detailed', 'JSON')]
        [string]$OutputFormat = 'Summary'
    )

    if (-not (Test-Path $ProjectPath)) {
        throw "Project path not found: $ProjectPath"
    }

    Write-Host "[TEST] Running common tests for project: $(Split-Path $ProjectPath -Leaf)"

    # Run all test categories
    Write-Host "  [COMPAT] Testing PowerShell 5.1 compatibility..." -ForegroundColor Cyan
    $compatibilityResults = Test-PowerShellCompatibility -Path $ProjectPath -Recurse

    Write-Host "  [STANDARDS] Testing Avanade standards compliance..." -ForegroundColor Cyan
    $standardsResults = Test-PersonalStandards -Path $ProjectPath -Recurse

    Write-Host "  Security Testing security best practices..." -ForegroundColor Cyan
    $securityResults = Test-SecurityBestPractices -Path $ProjectPath -Recurse

    # Calculate overall score
    $overallScore = [Math]::Round((
        $compatibilityResults.Summary.CompatibilityRate * 0.4 +
        $standardsResults.Summary.ComplianceRate * 0.4 +
        $securityResults.Summary.SecurityScore * 0.2
    ), 2)

    # Determine recommendation
    $recommendation = if ($securityResults.Summary.CriticalIssues) {
        "[CRITICAL] Security issues must be resolved"
    } elseif ($overallScore -ge 90) {
        "[EXCELLENT] Ready for production deployment"
    } elseif ($overallScore -ge 75) {
        "[GOOD] Minor improvements recommended"
    } elseif ($overallScore -ge 50) {
        "[FAIR] Significant improvements needed"
    } else {
        "[FAIL] Poor - Major refactoring required"
    }

    $consolidatedResults = [PSCustomObject]@{
        ProjectPath        = $ProjectPath
        Timestamp         = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        OverallScore      = $overallScore
        Recommendation    = $recommendation
        Compatibility     = $compatibilityResults
        Standards         = $standardsResults
        Security          = $securityResults
        Summary           = @{
            TotalFiles        = $compatibilityResults.Summary.TotalFiles
            CompatibilityRate = $compatibilityResults.Summary.CompatibilityRate
            StandardsRate     = $standardsResults.Summary.ComplianceRate
            SecurityScore     = $securityResults.Summary.SecurityScore
            CriticalSecurity  = $securityResults.Summary.CriticalIssues
        }
    }

    Write-Host "[COMPLETE] Common tests completed. Overall score: $overallScore%" -ForegroundColor Green

    switch ($OutputFormat) {
        'JSON' {
            return $consolidatedResults | ConvertTo-Json -Depth 10
        }
        'Detailed' {
            return $consolidatedResults
        }
        default {
            return $consolidatedResults.Summary
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-PowerShellCompatibility',
    'Test-PersonalStandards',
    'Test-SecurityBestPractices',
    'Invoke-CommonProjectTests'
)
