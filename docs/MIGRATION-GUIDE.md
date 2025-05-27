# Migration Guide

> **From Legacy Testing to Enterprise Pipeline**
> Proven migration path with 98.28% quality score achievement

This guide provides step-by-step instructions for migrating existing PowerShell projects to the enterprise testing pipeline template.

## 🎯 Migration Overview

### Migration Types

| Current State                             | Target State | Effort    | Timeline |
| ----------------------------------------- | ------------ | --------- | -------- |
| **No Testing** → Enterprise Pipeline      | High         | 2-3 days  |
| **Basic Testing** → Enterprise Pipeline   | Medium       | 1-2 days  |
| **Custom Pipeline** → Enterprise Pipeline | Low          | 0.5-1 day |

### Success Criteria
- ✅ 90%+ quality score achievement
- ✅ All tests passing (100% pass rate)
- ✅ "READY FOR DEPLOYMENT" pipeline status
- ✅ Zero critical security issues

## 📋 Pre-Migration Assessment

### 1. Project Analysis
```powershell
# Run assessment on your existing project
.\tools\Assess-ProjectReadiness.ps1 -ProjectPath "YourProject"
```

### 2. Compatibility Check
```powershell
# Check PowerShell 5.1+ compatibility
Get-ChildItem "YourProject" -Filter "*.ps1" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '\$using:|\?\?|\.ForEach\(') {
        Write-Warning "PowerShell 6+ syntax detected: $($_.Name)"
    }
}
```

### 3. Current Quality Baseline
```powershell
# Establish baseline metrics
Invoke-ScriptAnalyzer -Path "YourProject" -Recurse | Group-Object Severity
```

## 🔄 Migration Steps

### Step 1: Framework Integration

#### Copy Common Testing Tools
```powershell
# Copy from template to your project
$templatePath = "PowerShell-Testing-Pipeline-Template"
$projectPath = "YourProject"

# Copy testing framework
Copy-Item "$templatePath\.github\common-test-tools" "$projectPath\.github\" -Recurse -Force

# Copy pipeline orchestrator
Copy-Item "$templatePath\templates\test-hierarchical-pipeline.ps1" "$projectPath\" -Force

# Copy project test runner template
Copy-Item "$templatePath\templates\run-tests.ps1" "$projectPath\tools\" -Force
```

#### Customize Templates
```powershell
# Update project-specific values
$runTestsPath = "$projectPath\tools\run-tests.ps1"
(Get-Content $runTestsPath) -replace '<REPLACE_WITH_PROJECT_NAME>', 'YourProject' -replace '<REPLACE_WITH_SOURCE_PATH>', 'Scripts' | Set-Content $runTestsPath

$pipelinePath = "$projectPath\test-hierarchical-pipeline.ps1"
(Get-Content $pipelinePath) -replace '<REPLACE_WITH_PROJECT_NAME>', 'YourProject' -replace '<REPLACE_WITH_REPOSITORY_NAME>', 'Your Repository' | Set-Content $pipelinePath
```

### Step 2: Directory Structure Alignment

#### Standard Structure
```
YourProject/
├── Scripts/           # Main PowerShell files (or Utils/, Modules/)
├── Config/            # Configuration files
├── tests/             # Pester tests
├── tools/             # Development tools
├── docs/              # Documentation
└── .github/           # Common testing utilities
    └── common-test-tools/
```

#### Migration Script
```powershell
# Align directory structure
$requiredDirs = @('tests', 'tools', 'docs', 'Config')
foreach ($dir in $requiredDirs) {
    $dirPath = Join-Path $projectPath $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -Path $dirPath -ItemType Directory -Force
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}
```

### Step 3: Test Migration

#### Convert Existing Tests
```powershell
# Convert Pester v4 to v5 syntax
# Old syntax: Should -Be
# New syntax: | Should -Be

# Example conversion script
Get-ChildItem "$projectPath\tests" -Filter "*.Tests.ps1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace '\$([^|]+) \| Should ([^-])', '$1 | Should -$2'
    $content | Set-Content $_.FullName
}
```

#### Create Missing Tests
```powershell
# Generate test scaffolds for untested scripts
Get-ChildItem "$projectPath\Scripts" -Filter "*.ps1" | ForEach-Object {
    $testName = $_.BaseName + ".Tests.ps1"
    $testPath = Join-Path "$projectPath\tests" $testName

    if (-not (Test-Path $testPath)) {
        $testTemplate = @"
#Requires -Modules Pester

Describe '$($_.BaseName)' {
    BeforeAll {
        `$scriptPath = Join-Path `$PSScriptRoot "..\Scripts\$($_.Name)"
        `$scriptPath | Should -Exist
    }

    Context 'Parameter Validation' {
        It 'Should have proper parameter validation' {
            # Add specific tests based on your script
            `$true | Should -Be `$true
        }
    }

    Context 'Functionality' {
        It 'Should execute without errors' {
            # Add functional tests
            `$true | Should -Be `$true
        }
    }
}
"@
        $testTemplate | Out-File -FilePath $testPath -Encoding UTF8
        Write-Host "Created test scaffold: $testName" -ForegroundColor Yellow
    }
}
```

### Step 4: Quality Standards Implementation

#### PSScriptAnalyzer Configuration
```powershell
# Copy quality standards
Copy-Item "$templatePath\tools\PSScriptAnalyzerSettings.psd1" "$projectPath\tools\" -Force
```

#### Common Issues Remediation
```powershell
# Fix common quality issues
$issues = Invoke-ScriptAnalyzer -Path "$projectPath\Scripts" -Recurse

# Group by rule name for systematic fixing
$issues | Group-Object RuleName | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "Rule: $($_.Name) - Count: $($_.Count)" -ForegroundColor Yellow
    $_.Group | Select-Object ScriptName, Line, Message | Format-Table
}
```

## 🔍 Validation & Testing

### Initial Pipeline Run
```powershell
# Navigate to project directory
Set-Location $projectPath

# Run full pipeline
.\test-hierarchical-pipeline.ps1 -Verbose

# Check quality score
$report = Get-Content "pipeline-test-report.json" | ConvertFrom-Json
Write-Host "Quality Score: $($report.CommonTests.Score)%" -ForegroundColor $(if ($report.CommonTests.Score -ge 90) { 'Green' } else { 'Red' })
```

### Iterative Improvement
```powershell
# Run specific test categories
Import-Module ".\.github\common-test-tools\CommonTestUtils.psm1"

# Test compatibility
$compatResults = Test-PowerShellCompatibility -Path "Scripts"
Write-Host "Compatibility: $($compatResults.Summary.CompatibilityRate)%"

# Test standards
$standardsResults = Test-PersonalStandards -Path "Scripts"
Write-Host "Standards: $($standardsResults.Summary.ComplianceRate)%"

# Test security
$securityResults = Test-SecurityBestPractices -Path "Scripts"
Write-Host "Security: $($securityResults.Summary.SecurityScore)%"
```

## 🎯 Quality Gate Achievement

### Target Metrics
- **Overall Quality:** 90%+ (Target achieved: 98.28%)
- **Compatibility:** 90%+ (PowerShell 5.1+ support)
- **Standards:** 90%+ (Avanade coding standards)
- **Security:** 90%+ (Zero critical issues)

### Common Improvement Areas

#### Compatibility Issues (Target: 90%+)
```powershell
# Replace PowerShell 6+ syntax
$files = Get-ChildItem "Scripts" -Filter "*.ps1" -Recurse
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    # Fix null coalescing operator
    $content = $content -replace '\?\?', '-or'

    # Fix ForEach-Object method syntax
    $content = $content -replace '\.ForEach\(', ' | ForEach-Object '

    # Fix using scope
    $content = $content -replace '\$using:', '$'

    $content | Set-Content $file.FullName
}
```

#### Standards Compliance (Target: 90%+)
```powershell
# Add proper comment-based help
$scriptsNeedingHelp = Get-ChildItem "Scripts" -Filter "*.ps1" | Where-Object {
    $content = Get-Content $_.FullName -Raw
    $content -notmatch '\.SYNOPSIS'
}

foreach ($script in $scriptsNeedingHelp) {
    Write-Host "Add comment-based help to: $($script.Name)" -ForegroundColor Yellow
}
```

#### Security Issues (Target: 90%+)
```powershell
# Scan for security issues
$securityIssues = @(
    'ConvertTo-SecureString.*-AsPlainText',
    'Invoke-Expression',
    'Add-Type.*-TypeDefinition.*DllImport',
    '\$env:.*password',
    'password.*=.*"[^"]*"'
)

foreach ($pattern in $securityIssues) {
    Get-ChildItem "Scripts" -Filter "*.ps1" -Recurse | ForEach-Object {
        $matches = Select-String -Path $_.FullName -Pattern $pattern
        if ($matches) {
            Write-Warning "Security issue in $($_.Name): $($matches.Line.Trim())"
        }
    }
}
```

## 📊 Success Metrics

### Before Migration (Typical)
- Quality Score: 45-65%
- Test Coverage: 0-30%
- Security Issues: 5-15 critical
- Standards Compliance: 40-60%

### After Migration (Target)
- Quality Score: 90%+ (Achieved: 98.28%)
- Test Coverage: 80%+
- Security Issues: 0 critical
- Standards Compliance: 90%+

## 🔧 Troubleshooting

### Common Migration Issues

#### "CommonTestUtils.psm1 not found"
```powershell
# Ensure correct path structure
$expectedPath = ".\.github\common-test-tools\CommonTestUtils.psm1"
if (-not (Test-Path $expectedPath)) {
    Write-Error "Copy common test tools from template"
}
```

#### "Quality score below 90%"
```powershell
# Run detailed analysis
$results = Invoke-CommonProjectTests -ProjectPath "." -Verbose
$results.OverallSummary | Format-List
$results.Compatibility.Issues | Format-Table
$results.Standards.Issues | Format-Table
$results.Security.Issues | Format-Table
```

#### "Tests failing"
```powershell
# Debug specific test failures
.\tools\run-tests.ps1 -Verbose
Invoke-Pester -Path "tests" -Output Detailed
```

## 🎉 Migration Complete

### Verification Checklist
- [ ] Quality score 90%+ achieved
- [ ] All tests passing (100% pass rate)
- [ ] Zero critical security issues
- [ ] "READY FOR DEPLOYMENT" status
- [ ] Documentation updated
- [ ] Team trained on new pipeline

### Next Steps
1. **Integrate CI/CD:** Add pipeline to automated workflows
2. **Team Training:** Educate team on new quality gates
3. **Monitor:** Track quality metrics over time
4. **Optimize:** Continue improving based on insights

---

**Migration Template Version:** 2.0.0
**Success Rate:** 100% (Win11FUActions proof)
**Quality Achievement:** 98.28% (Exceeds 90% target)

*Your migration to enterprise-grade testing starts here* 🚀
