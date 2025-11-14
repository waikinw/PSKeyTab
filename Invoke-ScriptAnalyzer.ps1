<#
.SYNOPSIS
    Runs PSScriptAnalyzer on the KeyTabTools module for code quality checks.

.DESCRIPTION
    This script installs PSScriptAnalyzer if needed and runs it against all
    PowerShell files in the project, checking for best practices and potential
    issues.

.EXAMPLE
    .\Invoke-ScriptAnalyzer.ps1
#>

[CmdletBinding()]
param(
    [switch]$Fix
)

Write-Host "PSScriptAnalyzer Code Quality Check" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if PSScriptAnalyzer is installed
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "PSScriptAnalyzer not found. Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -ErrorAction Stop
        Write-Host "PSScriptAnalyzer installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to install PSScriptAnalyzer: $_" -ForegroundColor Red
        exit 1
    }
}

Import-Module PSScriptAnalyzer

Write-Host "Analyzing PowerShell files..." -ForegroundColor Cyan
Write-Host ""

# Get all PowerShell files
$files = @(
    "$PSScriptRoot/KeyTabTools.ps1",
    "$PSScriptRoot/KeyTabTools.psm1",
    "$PSScriptRoot/tests/KeyTabTools.Tests.ps1",
    "$PSScriptRoot/Test-Module.ps1"
)

$totalIssues = 0
$errorCount = 0
$warningCount = 0
$informationCount = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        $relativePath = (Resolve-Path -Relative $file).TrimStart('.\')
        Write-Host "Checking: $relativePath" -ForegroundColor White

        if ($Fix) {
            $results = Invoke-ScriptAnalyzer -Path $file -Fix
        } else {
            $results = Invoke-ScriptAnalyzer -Path $file
        }

        if ($results) {
            $totalIssues += $results.Count

            foreach ($result in $results) {
                switch ($result.Severity) {
                    'Error' {
                        Write-Host "  [ERROR] " -ForegroundColor Red -NoNewline
                        $errorCount++
                    }
                    'Warning' {
                        Write-Host "  [WARN]  " -ForegroundColor Yellow -NoNewline
                        $warningCount++
                    }
                    'Information' {
                        Write-Host "  [INFO]  " -ForegroundColor Cyan -NoNewline
                        $informationCount++
                    }
                }

                Write-Host "$($result.RuleName): $($result.Message)" -ForegroundColor Gray
                Write-Host "          Line $($result.Line): $($result.Extent.Text.Substring(0, [Math]::Min(60, $result.Extent.Text.Length)))" -ForegroundColor DarkGray
            }
            Write-Host ""
        } else {
            Write-Host "  No issues found." -ForegroundColor Green
            Write-Host ""
        }
    }
}

Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "Total Issues: $totalIssues" -ForegroundColor White
Write-Host "  Errors:      $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Warnings:    $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { 'Yellow' } else { 'Green' })
Write-Host "  Information: $informationCount" -ForegroundColor Cyan
Write-Host ""

if ($Fix) {
    Write-Host "Fixable issues have been automatically corrected." -ForegroundColor Green
    Write-Host "Please review the changes before committing." -ForegroundColor Yellow
}

if ($errorCount -gt 0) {
    Write-Host "FAILED: Please fix the errors before committing." -ForegroundColor Red
    exit 1
} elseif ($totalIssues -eq 0) {
    Write-Host "PASSED: Code quality check successful!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "PASSED with warnings. Consider addressing warnings for better code quality." -ForegroundColor Yellow
    exit 0
}
