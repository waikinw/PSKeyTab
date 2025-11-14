# KeyTabTools

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/KeyTabTools?label=PowerShell%20Gallery&logo=powershell)](https://www.powershellgallery.com/packages/KeyTabTools)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/KeyTabTools?label=Downloads)](https://www.powershellgallery.com/packages/KeyTabTools)
[![CI Status](https://github.com/waikinw/PSKeyTab/actions/workflows/pester.yml/badge.svg)](https://github.com/waikinw/PSKeyTab/actions/workflows/pester.yml)
[![License](https://img.shields.io/github/license/waikinw/PSKeyTab)](https://github.com/waikinw/PSKeyTab/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)](https://github.com/waikinw/PSKeyTab)

KeyTabTools is a PowerShell utility for generating offline keytab files for Active Directory accounts. It provides a cross-platform alternative to Microsoft's `ktpass` tool and works on Windows, Linux, and macOS.

## Features

- **Offline keytab generation** - No Active Directory connection required
- **Multiple encryption types** - RC4-HMAC, AES-128, and AES-256 (default)
- **Cross-platform** - Works on Windows, Linux, and macOS with PowerShell 5.1+
- **Batch processing support** - Can be scripted for multiple accounts
- **Flexible configuration** - Custom SALTs, KVNOs, and principal types

## Requirements

- PowerShell 5.1 or later
- Knowledge of the account password and UPN or service principal name

## Installation

### Option 1: PowerShell Gallery (Recommended)

```powershell
# Install from PowerShell Gallery
Install-Module -Name KeyTabTools -Scope CurrentUser

# Import the module
Import-Module KeyTabTools

# Verify installation
Get-Command -Module KeyTabTools
```

### Option 2: Download Release

1. Download the latest release from [GitHub Releases](https://github.com/waikinw/PSKeyTab/releases)
2. Extract the ZIP file
3. Import the module:

```powershell
Import-Module ./KeyTabTools/KeyTabTools.psd1
```

### Option 3: Clone from GitHub

```powershell
git clone https://github.com/waikinw/PSKeyTab.git
cd PSKeyTab
Import-Module ./KeyTabTools.psd1
```

### Option 4: Run as Script (No Installation)

```powershell
# Download KeyTabTools.ps1 and run directly
./KeyTabTools.ps1 -Realm DEV.HOME -Principal http/AppService -Password YourPassword
```

## Quick Start

### Verify the Module Works

```powershell
# Run the verification script
./Test-Module.ps1
```

### Basic Usage

```powershell
# Import the module
Import-Module ./KeyTabTools.psd1

# Generate a keytab for a user account (default: AES256)
Invoke-KeyTabTools `
    -Realm 'EXAMPLE.COM' `
    -Principal 'username' `
    -Password 'UserPassword123' `
    -File './user.keytab' `
    -NoPrompt

# Generate a keytab for a service account
Invoke-KeyTabTools `
    -Realm 'EXAMPLE.COM' `
    -Principal 'http/server.example.com' `
    -Password 'ServicePassword456' `
    -PType 'KRB5_NT_SRV_HST' `
    -File './service.keytab' `
    -NoPrompt
```

### Running as a Script

```powershell
# Basic user account keytab
./KeyTabTools.ps1 -Realm EXAMPLE.COM -Principal user@example.com

# Service principal with AES256 and AES128
./KeyTabTools.ps1 `
    -Realm DEV.HOME `
    -Principal http/AppService `
    -AES256 `
    -AES128 `
    -File ./app.keytab

# All encryption types
./KeyTabTools.ps1 `
    -Realm PROD.EXAMPLE.COM `
    -Principal servicename `
    -RC4 `
    -AES128 `
    -AES256 `
    -NoPrompt `
    -Quiet
```

## Usage Examples

### Example 1: User Account Keytab

```powershell
# Create a keytab for a user account with default AES256 encryption
Invoke-KeyTabTools `
    -Realm 'CONTOSO.COM' `
    -Principal 'john.doe' `
    -Password 'P@ssw0rd!' `
    -File 'C:\keytabs\john.keytab' `
    -NoPrompt `
    -Quiet
```

### Example 2: Service Principal with Multiple Encryption Types

```powershell
# Create a keytab with RC4, AES128, and AES256 for compatibility
Invoke-KeyTabTools `
    -Realm 'EXAMPLE.COM' `
    -Principal 'HTTP/webserver.example.com' `
    -Password 'ServiceP@ss123' `
    -PType 'KRB5_NT_SRV_HST' `
    -RC4 `
    -AES128 `
    -AES256 `
    -File './web-service.keytab' `
    -NoPrompt
```

### Example 3: Custom KVNO

```powershell
# Specify a custom key version number (KVNO)
Invoke-KeyTabTools `
    -Realm 'CORP.LOCAL' `
    -Principal 'sqlservice' `
    -Password 'DbP@ssword!' `
    -KVNO 5 `
    -File './sql.keytab' `
    -NoPrompt
```

### Example 4: Append to Existing Keytab

```powershell
# Append a new entry to an existing keytab file
Invoke-KeyTabTools `
    -Realm 'EXAMPLE.COM' `
    -Principal 'another-user' `
    -Password 'AnotherP@ss!' `
    -File './combined.keytab' `
    -Append `
    -NoPrompt
```

### Example 5: Custom SALT

```powershell
# Use a custom SALT (advanced usage)
Invoke-KeyTabTools `
    -Realm 'EXAMPLE.COM' `
    -Principal 'user' `
    -Password 'P@ssw0rd!' `
    -SALT 'EXAMPLE.COMcustomuser' `
    -File './custom.keytab' `
    -NoPrompt
```

### Example 6: Batch Processing with Pipeline

```powershell
# Process multiple accounts from a CSV
Import-Csv accounts.csv | ForEach-Object {
    Invoke-KeyTabTools `
        -Realm $_.Realm `
        -Principal $_.Principal `
        -Password $_.Password `
        -File "$($_.Principal).keytab" `
        -NoPrompt `
        -Quiet
}
```

### Example 7: Using Helper Functions

```powershell
# Import the module to access helper functions
Import-Module ./KeyTabTools.psd1

# Generate an AES256 key for inspection
$key = Get-AES256Key -PasswordString 'password' -SALT 'EXAMPLE.COMuser'
Write-Host "AES256 Key: $key"

# Create a custom keytab entry
$entry = New-KeyTabEntry `
    -PasswordString 'password' `
    -RealmString 'EXAMPLE.COM' `
    -Components @('user') `
    -SALT 'EXAMPLE.COMuser' `
    -KVNO 1 `
    -PrincipalType 'KRB5_NT_PRINCIPAL' `
    -EncryptionKeyType 'AES256'

Write-Host "Key Block: $($entry.KeyBlock)"
```

## Parameters

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `-Realm` | Kerberos realm (domain). Will be converted to uppercase. Example: `EXAMPLE.COM` |
| `-Principal` | Principal name (case-sensitive for AES). Example: `username` or `http/server.example.com` |
| `-Password` | Account password. If not provided, you'll be prompted securely. |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-File` | Output keytab file path | `./login.keytab` |
| `-KVNO` | Key version number (1-255) | `1` |
| `-PType` | Principal type: `KRB5_NT_PRINCIPAL`, `KRB5_NT_SRV_INST`, `KRB5_NT_SRV_HST`, `KRB5_NT_UID` | `KRB5_NT_PRINCIPAL` |
| `-RC4` | Generate RC4-HMAC key | Not set |
| `-AES128` | Generate AES-128 key | Not set |
| `-AES256` | Generate AES-256 key | **Default if no encryption type specified** |
| `-SALT` | Custom Kerberos SALT value | Auto-generated: `REALM + Principal` |
| `-Append` | Append to existing keytab file | Not set (overwrites) |
| `-Quiet` | Suppress text output | Not set |
| `-NoPrompt` | Don't prompt before writing file (batch mode) | Not set |

## Principal Types

- **KRB5_NT_PRINCIPAL** - Standard user account (default)
- **KRB5_NT_SRV_INST** - Service instance
- **KRB5_NT_SRV_HST** - Service with hostname
- **KRB5_NT_UID** - UID-based principal

## Important Notes

### Case Sensitivity

- **Realm**: Always converted to UPPERCASE (Kerberos standard)
- **Principal**: Case-sensitive for AES encryption! Must match AD exactly.

### SALT Calculation

For AES encryption, the SALT is critical:
- **User accounts**: `REALM + principal` (e.g., `EXAMPLE.COMjohn.doe`)
- **Computer accounts**: `REALM + "host" + hostname + "." + realm` (lowercase parts)
- The script automatically generates the SALT unless you specify `-SALT`

### Minimum SALT Length

The SALT for AES must be at least 8 bytes. If your `principal@domain.com` is less than 8 characters without the `@`, you should:
- Use RC4 encryption instead, or
- Increase the principal name length, or
- Use a custom SALT

## Testing

### Run Quick Verification

```powershell
./Test-Module.ps1
```

### Run Full Test Suite

```powershell
# Install Pester if not already installed
Install-Module Pester -Force -Scope CurrentUser

# Run all tests
Invoke-Pester

# Run specific test
Invoke-Pester -TagFilter 'Integration'
```

### Run Tests with Detailed Output

```powershell
Invoke-Pester -Output Detailed
```

## Exported Functions

When imported as a module, the following functions are available:

### Main Function
- `Invoke-KeyTabTools` - Generate keytab files

### Cryptographic Functions
- `Get-MD4` - Calculate MD4 hash (for RC4)
- `Get-PBKDF2` - Derive keys using PBKDF2
- `Protect-Aes` - AES encryption helper
- `Get-AES128Key` - Generate AES-128 key
- `Get-AES256Key` - Generate AES-256 key

### Utility Functions
- `Get-HexStringFromByteArray` - Convert bytes to hex string
- `Get-ByteArrayFromHexString` - Convert hex string to bytes
- `Get-BytesBigEndian` - Convert integers to big-endian bytes
- `Get-PrincipalType` - Get principal type numeric value
- `New-KeyTabEntry` - Create a single keytab entry

## Troubleshooting

### "Module not found" Error

```powershell
# Use full path
Import-Module C:\Full\Path\To\KeyTabTools.psd1
```

### Authentication Fails with Generated Keytab

1. **Check principal case** - Principal must match AD exactly (case-sensitive for AES)
2. **Verify SALT** - Must match AD's SALT calculation
3. **Check KVNO** - Should match the key version in AD
4. **Try RC4** - If AES fails, RC4 is less strict about SALT

### Testing a Keytab File

```bash
# On Linux/macOS with MIT Kerberos
klist -kte your.keytab

# Test authentication
kinit -kt your.keytab principal@REALM.COM
klist
```

```powershell
# On Windows
# Use a Java/Kerberos tool or ktpass /princ command
```

## Advanced Usage

### Integration with Active Directory Queries

```powershell
# Generate keytabs for multiple AD service accounts
Import-Module ActiveDirectory
Import-Module ./KeyTabTools.psd1

Get-ADServiceAccount -Filter * | ForEach-Object {
    $upn = $_.UserPrincipalName
    $principal = $upn.Split('@')[0]
    $realm = $upn.Split('@')[1].ToUpper()

    # You would need to get/reset the password securely
    Invoke-KeyTabTools `
        -Realm $realm `
        -Principal $principal `
        -Password 'GetPasswordSecurely' `
        -File ".\$principal.keytab" `
        -NoPrompt `
        -Quiet
}
```

### Custom Keytab Entry Generation

```powershell
Import-Module ./KeyTabTools.psd1

# Create custom entries with specific settings
$entries = @()
$entries += New-KeyTabEntry `
    -PasswordString 'password' `
    -RealmString 'EXAMPLE.COM' `
    -Components @('service1') `
    -KVNO 1 `
    -PrincipalType 'KRB5_NT_PRINCIPAL' `
    -EncryptionKeyType 'AES256'

$entries += New-KeyTabEntry `
    -PasswordString 'password' `
    -RealmString 'EXAMPLE.COM' `
    -Components @('service2') `
    -KVNO 1 `
    -PrincipalType 'KRB5_NT_PRINCIPAL' `
    -EncryptionKeyType 'AES256'

# Manually build keytab file
$fileBytes = @(0x05, 0x02)  # Version header
foreach ($entry in $entries) {
    $fileBytes += $entry.KeytabEntry
}
[System.IO.File]::WriteAllBytes('custom.keytab', $fileBytes)
```

## Publishing & Releases

### For Maintainers

This module is published to [PowerShell Gallery](https://www.powershellgallery.com/packages/KeyTabTools) automatically via GitHub Actions.

**To create a new release:**

1. Update version in `KeyTabTools.psd1`
2. Update `CHANGELOG.md`
3. Commit and push changes
4. Create and push a version tag:
   ```bash
   git tag v1.3.0
   git push origin v1.3.0
   ```

The automated workflows will:
- Run all tests
- Create a GitHub release with artifacts
- You can then manually trigger PowerShell Gallery publishing from GitHub Actions

See [RELEASE.md](RELEASE.md) for detailed publishing instructions.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to submit issues and pull requests.

## References

- [RFC 3961 - Kerberos Encryption Types](https://tools.ietf.org/html/rfc3961)
- [MS-KILE - Kerberos Protocol Extensions](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-kile/)
- [MIT Kerberos Documentation](https://web.mit.edu/kerberos/krb5-latest/doc/)
- [Keytab File Format](http://www.ioplex.com/utilities/keytab.txt)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors and Attribution

### Project History

This is a **derivative work** based on Adam Burford's [Create-KeyTab](https://github.com/TheRealAdamBurford/Create-KeyTab) project, developed as a standalone repository (not a GitHub fork) to enable independent evolution with significant enhancements for PowerShell Gallery publication and modern DevOps practices.

The project maintains the original MIT license and fully credits the original author while pursuing an independent development path focused on production-ready module distribution, comprehensive testing, and community accessibility.

### Current Maintainer

- [waikinw](https://github.com/waikinw) - Current maintainer and primary contributor

### Original Author

- [Adam Burford (TRAB)](https://github.com/TheRealAdamBurford) - Original author and creator
- LinkedIn: https://www.linkedin.com/in/adamburford
- Original repository: https://github.com/TheRealAdamBurford/Create-KeyTab

### Credits

- MD4 implementation by Larry.Song@outlook.com
- Various cryptographic algorithm references (see source code comments)

### Enhancements Over Original

This project builds upon Adam Burford's excellent foundation with significant enhancements including:
- Comprehensive test coverage (60+ tests)
- PowerShell Gallery publication support
- Enhanced documentation and examples
- CI/CD automation
- Module structure improvements
- Cross-platform verification

## Contributors

See [GitHub contributors](https://github.com/waikinw/PSKeyTab/graphs/contributors) for a complete list of contributors.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
