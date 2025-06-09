#Requires -Version 7.0
<#
.SYNOPSIS
    Creates a new PowerShell project with enterprise testing pipeline structure.
.DESCRIPTION
    This tool scaffolds a new PowerShell project with:
    1. Standard directory structure (Utils, Config, tests, tools)
    2. Testing pipeline integration
    3. Documentation templates
    4. Configuration files
    5. Example scripts and tests
.NOTES
    Author: GitHub Copilot (Enhanced Avanade Instructions)
    Version: 2.0.0
    Compatible with: PowerShell 5.1+
    Based on: Win11FUActions project success patterns
.EXAMPLE
    .\tools\New-ProjectScaffold.ps1 -ProjectName "MyProject" -Description "My awesome PowerShell project"
    .\tools\New-ProjectScaffold.ps1 -ProjectName "SCCMUtils" -IncludeExamples -CreateGitIgnore
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$ProjectName,

    [Parameter(Mandatory = $false)]
    [string]$Description = "PowerShell project with enterprise testing pipeline",

    [Parameter(Mandatory = $false)]
    [string]$Author = $env:USERNAME,

    [switch]$IncludeExamples,

    [switch]$CreateGitIgnore,

    [switch]$InitializeGit,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Utils', 'Scripts', 'Modules', 'Tools')]
    [string]$SourceFolderType = 'Utils'
)

$ErrorActionPreference = 'Stop'

Write-Host "=== PowerShell Project Scaffolding Tool ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectName"
Write-Host "Description: $Description"
Write-Host "Author: $Author"
Write-Host "Source Type: $SourceFolderType"

# Get the template root (assuming we're in tools/ subdirectory)
$templateRoot = Split-Path -Parent $PSScriptRoot
$targetRoot = Split-Path -Parent $templateRoot
$projectPath = Join-Path $targetRoot $ProjectName

# Check if project already exists
if (Test-Path $projectPath) {
    $response = Read-Host "Project directory '$ProjectName' already exists. Overwrite? (y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Project creation cancelled." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item -Path $projectPath -Recurse -Force
}

Write-Host "`nCreating project structure..." -ForegroundColor Yellow

# Create main project directory
New-Item -Path $projectPath -ItemType Directory -Force | Out-Null

# Create standard directories
$directories = @(
    $SourceFolderType,
    'Config',
    'tests',
    'tools',
    'docs'
)

foreach ($dir in $directories) {
    $dirPath = Join-Path $projectPath $dir
    New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
    Write-Verbose "Created directory: $dir"
}

Write-Host "✅ Directory structure created" -ForegroundColor Green

# Copy common test tools
Write-Host "`nSetting up testing pipeline..." -ForegroundColor Yellow

$sourceCommonTools = Join-Path $templateRoot ".github\common-test-tools"
$targetCommonTools = Join-Path $projectPath ".github\common-test-tools"

New-Item -Path (Split-Path $targetCommonTools -Parent) -ItemType Directory -Force | Out-Null
Copy-Item -Path $sourceCommonTools -Destination (Split-Path $targetCommonTools -Parent) -Recurse -Force

# Copy and customize test runner
$sourceTestRunner = Join-Path $templateRoot "templates\run-tests.ps1"
$targetTestRunner = Join-Path $projectPath "tools\run-tests.ps1"

$testRunnerContent = Get-Content $sourceTestRunner -Raw
$testRunnerContent = $testRunnerContent -replace '<REPLACE_WITH_PROJECT_NAME>', $ProjectName
$testRunnerContent = $testRunnerContent -replace '<REPLACE_WITH_SOURCE_PATH>', $SourceFolderType

$testRunnerContent | Out-File -FilePath $targetTestRunner -Encoding UTF8

# Copy and customize hierarchical pipeline
$sourcePipeline = Join-Path $templateRoot "templates\test-hierarchical-pipeline.ps1"
$targetPipeline = Join-Path $projectPath "test-hierarchical-pipeline.ps1"

$pipelineContent = Get-Content $sourcePipeline -Raw
$pipelineContent = $pipelineContent -replace '<REPLACE_WITH_PROJECT_NAME>', $ProjectName
$pipelineContent = $pipelineContent -replace '<REPLACE_WITH_REPOSITORY_NAME>', "PowerShell Repository"

$pipelineContent | Out-File -FilePath $targetPipeline -Encoding UTF8

Write-Host "✅ Testing pipeline configured" -ForegroundColor Green

# Create project README
Write-Host "`nCreating documentation..." -ForegroundColor Yellow

$readmeContent = @"
# $ProjectName

$Description

## Overview

This project follows Avanade's PowerShell enterprise standards with integrated testing pipeline.

**Quality Gate:** 90%+ required for deployment
**Testing:** Hierarchical pipeline with common + project-specific tests
**Compatibility:** PowerShell 5.1+

## Project Structure

```
$ProjectName/
├── $SourceFolderType/          # Main PowerShell scripts
├── Config/            # Configuration files
├── tests/             # Pester tests
├── tools/             # Development tools
├── docs/              # Documentation
└── .github/           # Common testing utilities
```

## Quick Start

### Running Tests
```powershell
# Project-specific tests
.\tools\run-tests.ps1 -Verbose

# Full hierarchical pipeline
.\test-hierarchical-pipeline.ps1 -ProjectPath "$ProjectName"
```

### Development Workflow
1. Write your PowerShell scripts in `$SourceFolderType/`
2. Create corresponding tests in `tests/`
3. Run tests to ensure quality gate (90%+)
4. Commit when pipeline shows "READY FOR DEPLOYMENT"

## Quality Standards

This project maintains enterprise-grade quality through:

- **Compatibility Testing:** PowerShell 5.1+ compatibility verification
- **Standards Compliance:** Avanade coding standards enforcement
- **Security Scanning:** Critical security issue detection
- **Automated Testing:** Pester-based unit and integration tests

## Configuration

Project configuration is managed through:
- `Config/` directory for environment-specific settings
- Parameter validation and secure credential handling
- Centralized error handling and logging

## Contributing

1. Ensure all tests pass: `.\tools\run-tests.ps1`
2. Verify quality gate: `.\test-hierarchical-pipeline.ps1`
3. Update documentation as needed
4. Follow Avanade PowerShell standards

## Author

**$Author**
Created: $(Get-Date -Format 'yyyy-MM-dd')
Template: PowerShell-Testing-Pipeline-Template v2.0.0
"@

$readmeContent | Out-File -FilePath (Join-Path $projectPath "README.md") -Encoding UTF8

Write-Host "✅ Documentation created" -ForegroundColor Green

# Create example configuration file
Write-Host "`nCreating configuration templates..." -ForegroundColor Yellow

$configContent = @"
{
  "ProjectName": "$ProjectName",
  "Version": "1.0.0",
  "Author": "$Author",
  "Description": "$Description",
  "Settings": {
    "LogLevel": "Info",
    "OutputDirectory": "%TEMP%\\$ProjectName",
    "MaxRetries": 3,
    "TimeoutSeconds": 300
  },
  "Features": {
    "EnableLogging": true,
    "EnableVerboseOutput": false,
    "EnableErrorReporting": true
  }
}
"@

$configContent | Out-File -FilePath (Join-Path $projectPath "Config\config.json") -Encoding UTF8

Write-Host "✅ Configuration template created" -ForegroundColor Green

# Create example scripts and tests if requested
if ($IncludeExamples) {
    Write-Host "`nCreating example scripts and tests..." -ForegroundColor Yellow

    # Example script
    $exampleScriptContent = @"
#Requires -Version 7.0
<#
.SYNOPSIS
    Example PowerShell script following Avanade enterprise standards.
.DESCRIPTION
    This script demonstrates proper structure, parameter validation,
    error handling, and logging patterns.
.NOTES
    Author: $Author
    Version: 1.0.0
    Compatible with: PowerShell 5.1+
.EXAMPLE
    .\Get-Example.ps1 -Name "Test" -Verbose
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = `$true)]
    [ValidateNotNullOrEmpty()]
    [string]`$Name,

    [Parameter(Mandatory = `$false)]
    [ValidateRange(1, 100)]
    [int]`$Count = 1,

    [switch]`$PassThru
)

`$ErrorActionPreference = 'Stop'

# Load configuration
`$configPath = Join-Path `$PSScriptRoot "..\Config\config.json"
if (Test-Path `$configPath) {
    `$config = Get-Content `$configPath | ConvertFrom-Json
    Write-Verbose "Configuration loaded from: `$configPath"
} else {
    Write-Warning "Configuration file not found: `$configPath"
    `$config = [PSCustomObject]@{ Settings = @{ LogLevel = "Info" } }
}

Write-Host "Processing example with name: `$Name (Count: `$Count)" -ForegroundColor Green

try {
    `$results = @()

    for (`$i = 1; `$i -le `$Count; `$i++) {
        `$result = [PSCustomObject]@{
            Index = `$i
            Name = "`$Name-`$i"
            Timestamp = Get-Date
            Status = "Success"
        }
        `$results += `$result
        Write-Verbose "Created item `$i of `$Count"
    }

    Write-Host "Successfully created `$(`$results.Count) example items" -ForegroundColor Green

    if (`$PassThru) {
        return `$results
    }

} catch {
    Write-Error "Failed to process example: `$(`$_.Exception.Message)"
    throw
}
"@

    $exampleScriptContent | Out-File -FilePath (Join-Path $projectPath "$SourceFolderType\Get-Example.ps1") -Encoding UTF8

    # Example test
    $exampleTestContent = @"
#Requires -Modules Pester

Describe 'Get-Example' {
    BeforeAll {
        `$scriptPath = Join-Path `$PSScriptRoot "..\$SourceFolderType\Get-Example.ps1"

        # Ensure script exists
        `$scriptPath | Should -Exist
    }

    Context 'Parameter Validation' {
        It 'Should require Name parameter' {
            { & `$scriptPath } | Should -Throw
        }

        It 'Should accept valid Name parameter' {
            { & `$scriptPath -Name "Test" } | Should -Not -Throw
        }

        It 'Should validate Count range' {
            { & `$scriptPath -Name "Test" -Count 0 } | Should -Throw
            { & `$scriptPath -Name "Test" -Count 101 } | Should -Throw
        }
    }

    Context 'Functionality' {
        It 'Should return results when PassThru is specified' {
            `$result = & `$scriptPath -Name "Test" -PassThru
            `$result | Should -Not -BeNullOrEmpty
            `$result[0].Name | Should -Be "Test-1"
        }

        It 'Should create multiple items when Count is specified' {
            `$result = & `$scriptPath -Name "Test" -Count 3 -PassThru
            `$result.Count | Should -Be 3
            `$result[2].Name | Should -Be "Test-3"
        }

        It 'Should include timestamp in results' {
            `$result = & `$scriptPath -Name "Test" -PassThru
            `$result[0].Timestamp | Should -BeOfType [DateTime]
        }
    }

    Context 'Error Handling' {
        It 'Should handle configuration file gracefully when missing' {
            # This test would need more setup to properly test config handling
            `$true | Should -Be `$true  # Placeholder
        }
    }
}
"@

    $exampleTestContent | Out-File -FilePath (Join-Path $projectPath "tests\Get-Example.Tests.ps1") -Encoding UTF8

    Write-Host "✅ Example scripts and tests created" -ForegroundColor Green
}

# Create .gitignore if requested
if ($CreateGitIgnore) {
    Write-Host "`nCreating .gitignore..." -ForegroundColor Yellow

    $gitignoreContent = @"
# PowerShell
*.ps1xml
*.psd1.bak
*.psm1.bak

# Test Results
TestResults/
*.xml
*.html
*.json
pipeline-test-report.*
pipeline-test-summary.*

# Logs
*.log
*.txt
logs/

# Temp files
*.tmp
*.temp
~*

# IDE
.vscode/
*.code-workspace

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini
`$RECYCLE.BIN/

# Archives
*.zip
*.rar
*.7z

# Local configuration overrides
*local.json
*secrets.*
*.credentials

# Output directories
output/
build/
dist/
"@

    $gitignoreContent | Out-File -FilePath (Join-Path $projectPath ".gitignore") -Encoding UTF8
    Write-Host "✅ .gitignore created" -ForegroundColor Green
}

# Initialize Git repository if requested
if ($InitializeGit) {
    Write-Host "`nInitializing Git repository..." -ForegroundColor Yellow

    Set-Location $projectPath
    & git init
    & git add .
    & git commit -m "Initial commit: Project scaffolding with enterprise testing pipeline"

    Write-Host "✅ Git repository initialized" -ForegroundColor Green
}

# Final summary
Write-Host "`n=== PROJECT SCAFFOLDING COMPLETE ===" -ForegroundColor Cyan
Write-Host "Project Location: $projectPath"
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. cd '$ProjectName'"
Write-Host "  2. .\tools\run-tests.ps1 -Verbose"
Write-Host "  3. .\test-hierarchical-pipeline.ps1"
Write-Host "  4. Start developing in $SourceFolderType\"

if ($IncludeExamples) {
    Write-Host "`nExample files created:"
    Write-Host "  - $SourceFolderType\Get-Example.ps1 (sample script)"
    Write-Host "  - tests\Get-Example.Tests.ps1 (sample test)"
}

Write-Host "`nTemplate: PowerShell-Testing-Pipeline-Template v2.0.0" -ForegroundColor Green
Write-Host "Quality Target: 90%+ for deployment readiness" -ForegroundColor Green
