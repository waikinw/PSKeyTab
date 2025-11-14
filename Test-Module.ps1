<#
.SYNOPSIS
    Quick verification script to test if the KeyTabTools module is working.

.DESCRIPTION
    This script runs a basic smoke test to verify that the module can be
    imported and the main functions are accessible.

.EXAMPLE
    .\Test-Module.ps1
#>

[CmdletBinding()]
param()

Write-Host "KeyTabTools Module Verification" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Import Module
Write-Host "[1/5] Testing module import..." -NoNewline
try {
    Import-Module $PSScriptRoot/KeyTabTools.psd1 -Force -ErrorAction Stop
    $module = Get-Module KeyTabTools
    if ($module) {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL - Module not loaded" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Test 2: Check exported functions
Write-Host "[2/5] Testing exported functions..." -NoNewline
$expectedFunctions = @(
    'Get-MD4',
    'Get-PBKDF2',
    'Protect-Aes',
    'Get-AES128Key',
    'Get-AES256Key',
    'Get-HexStringFromByteArray',
    'Get-ByteArrayFromHexString',
    'Get-BytesBigEndian',
    'Get-PrincipalType',
    'New-KeyTabEntry',
    'Invoke-KeyTabTools'
)

$missing = @()
foreach ($func in $expectedFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $missing += $func
    }
}

if ($missing.Count -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Missing functions: $($missing -join ', ')" -ForegroundColor Red
    exit 1
}

# Test 3: Test basic cryptographic functions
Write-Host "[3/5] Testing cryptographic functions..." -NoNewline
try {
    # Test Get-MD4
    $md4Result = Get-MD4 -String 'abc'
    if ($md4Result -ne 'a448017aaf21d8525fc10ae87aa6729d') {
        throw "MD4 hash incorrect"
    }

    # Test hex conversion
    $bytes = @(0x0A, 0x0B, 0x0C)
    $hex = Get-HexStringFromByteArray -Data $bytes
    if ($hex -ne '0A0B0C') {
        throw "Hex conversion failed"
    }

    Write-Host " PASS" -ForegroundColor Green
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 4: Test keytab entry generation
Write-Host "[4/5] Testing keytab entry generation..." -NoNewline
try {
    $entry = New-KeyTabEntry `
        -PasswordString 'testpassword' `
        -RealmString 'EXAMPLE.COM' `
        -Components @('testuser') `
        -SALT 'EXAMPLE.COMtestuser' `
        -KVNO 1 `
        -PrincipalType 'KRB5_NT_PRINCIPAL' `
        -EncryptionKeyType 'AES256'

    if (-not $entry.KeytabEntry) {
        throw "KeytabEntry is null"
    }

    Write-Host " PASS" -ForegroundColor Green
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 5: Test keytab file creation
Write-Host "[5/5] Testing keytab file creation..." -NoNewline
try {
    $testFile = Join-Path $env:TEMP "test-$(Get-Random).keytab"

    Invoke-KeyTabTools `
        -Realm 'EXAMPLE.COM' `
        -Principal 'testuser' `
        -Password 'TestPassword123' `
        -File $testFile `
        -NoPrompt `
        -Quiet

    if (-not (Test-Path $testFile)) {
        throw "Keytab file was not created"
    }

    $fileBytes = [System.IO.File]::ReadAllBytes($testFile)
    if ($fileBytes[0] -ne 0x05 -or $fileBytes[1] -ne 0x02) {
        throw "Invalid keytab file header"
    }

    # Cleanup
    Remove-Item $testFile -Force

    Write-Host " PASS" -ForegroundColor Green
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $testFile) {
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

Write-Host ""
Write-Host "All tests passed! The module is working correctly." -ForegroundColor Green
Write-Host ""
Write-Host "To run the full Pester test suite, run:" -ForegroundColor Yellow
Write-Host "  Invoke-Pester" -ForegroundColor Yellow
