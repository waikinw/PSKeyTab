# KeyTabTools

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/KeyTabTools)](https://www.powershellgallery.com/packages/KeyTabTools)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/KeyTabTools)](https://www.powershellgallery.com/packages/KeyTabTools)
[![CI Status](https://github.com/waikinw/PSKeyTab/actions/workflows/pester.yml/badge.svg)](https://github.com/waikinw/PSKeyTab/actions/workflows/pester.yml)

Cross-platform PowerShell utility for generating offline keytab files for Active Directory accounts. Works on Windows, Linux, and macOS as an alternative to `ktpass`.

**[View Full Documentation on GitHub](https://github.com/waikinw/PSKeyTab)**

## Features

- **Offline keytab generation** - No Active Directory connection required
- **Multiple encryption types** - RC4-HMAC, AES-128, and AES-256 (default)
- **Cross-platform** - Works on Windows, Linux, and macOS with PowerShell 5.1+
- **Batch processing support** - Can be scripted for multiple accounts
- **Flexible configuration** - Custom SALTs, KVNOs, and principal types

## Quick Start

### Installation

```powershell
Install-Module -Name KeyTabTools -Scope CurrentUser
Import-Module KeyTabTools
```

### Basic Usage

```powershell
# User account keytab (default: AES256)
Invoke-KeyTabTools `
    -Realm 'EXAMPLE.COM' `
    -Principal 'username' `
    -Password 'UserPassword123' `
    -File './user.keytab' `
    -NoPrompt

# Service account with multiple encryption types
Invoke-KeyTabTools `
    -Realm 'EXAMPLE.COM' `
    -Principal 'http/server.example.com' `
    -Password 'ServicePassword456' `
    -PType 'KRB5_NT_SRV_HST' `
    -RC4 -AES128 -AES256 `
    -File './service.keytab' `
    -NoPrompt
```

### Running as a Script

```powershell
# Download and run directly (no installation needed)
./KeyTabTools.ps1 -Realm EXAMPLE.COM -Principal user@example.com

# Service principal with AES256 and AES128
./KeyTabTools.ps1 `
    -Realm DEV.HOME `
    -Principal http/AppService `
    -AES256 -AES128 `
    -File ./app.keytab
```

## Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-Realm` | Kerberos realm (domain, converted to uppercase) | Required |
| `-Principal` | Principal name (case-sensitive for AES) | Required |
| `-Password` | Account password (prompted if not provided) | Required |
| `-File` | Output keytab file path | `./login.keytab` |
| `-KVNO` | Key version number (1-255) | `1` |
| `-PType` | Principal type | `KRB5_NT_PRINCIPAL` |
| `-RC4` | Generate RC4-HMAC key | Not set |
| `-AES128` | Generate AES-128 key | Not set |
| `-AES256` | Generate AES-256 key | **Default** |
| `-Append` | Append to existing keytab | Not set |
| `-NoPrompt` | Don't prompt before writing (batch mode) | Not set |
| `-Quiet` | Suppress text output | Not set |

## Principal Types

- **KRB5_NT_PRINCIPAL** - Standard user account (default)
- **KRB5_NT_SRV_INST** - Service instance
- **KRB5_NT_SRV_HST** - Service with hostname
- **KRB5_NT_UID** - UID-based principal

## Common Use Cases

### Batch Processing

```powershell
# Process multiple accounts from CSV
Import-Csv accounts.csv | ForEach-Object {
    Invoke-KeyTabTools `
        -Realm $_.Realm `
        -Principal $_.Principal `
        -Password $_.Password `
        -File "$($_.Principal).keytab" `
        -NoPrompt -Quiet
}
```

### Custom KVNO

```powershell
# Specify custom key version number
Invoke-KeyTabTools `
    -Realm 'CORP.LOCAL' `
    -Principal 'sqlservice' `
    -Password 'DbP@ssword!' `
    -KVNO 5 `
    -File './sql.keytab' `
    -NoPrompt
```

### Append to Existing Keytab

```powershell
# Add entry to existing keytab file
Invoke-KeyTabTools `
    -Realm 'EXAMPLE.COM' `
    -Principal 'another-user' `
    -Password 'AnotherP@ss!' `
    -File './combined.keytab' `
    -Append -NoPrompt
```

## Important Notes

### Case Sensitivity
- **Realm**: Always converted to UPPERCASE (Kerberos standard)
- **Principal**: Case-sensitive for AES encryption! Must match AD exactly.

### SALT Calculation
For AES encryption, the SALT is critical:
- **User accounts**: `REALM + principal` (e.g., `EXAMPLE.COMjohn.doe`)
- **Computer accounts**: `REALM + "host" + hostname + "." + realm` (lowercase parts)
- The script automatically generates the SALT unless you specify `-SALT`
- Minimum SALT length for AES is 8 bytes

## Troubleshooting

### Authentication Fails
1. **Check principal case** - Must match AD exactly (case-sensitive for AES)
2. **Verify SALT** - Must match AD's SALT calculation
3. **Check KVNO** - Should match the key version in AD
4. **Try RC4** - If AES fails, RC4 is less strict about SALT

### Testing a Keytab

```bash
# On Linux/macOS with MIT Kerberos
klist -kte your.keytab
kinit -kt your.keytab principal@REALM.COM
klist
```

## Exported Functions

When imported as a module:

**Main Function:**
- `Invoke-KeyTabTools` - Generate keytab files

**Cryptographic Functions:**
- `Get-MD4`, `Get-PBKDF2`, `Protect-Aes`
- `Get-AES128Key`, `Get-AES256Key`

**Utility Functions:**
- `Get-HexStringFromByteArray`, `Get-ByteArrayFromHexString`
- `Get-BytesBigEndian`, `Get-PrincipalType`
- `New-KeyTabEntry`

## Testing

```powershell
# Install Pester if needed
Install-Module Pester -Force -Scope CurrentUser

# Run all tests
Invoke-Pester

# Run with detailed output
Invoke-Pester -Output Detailed
```

## Resources

- **Full Documentation**: [GitHub Repository](https://github.com/waikinw/PSKeyTab)
- **Contributing**: [CONTRIBUTING.md](https://github.com/waikinw/PSKeyTab/blob/main/CONTRIBUTING.md)
- **Changelog**: [CHANGELOG.md](https://github.com/waikinw/PSKeyTab/blob/main/CHANGELOG.md)
- **Release Guide**: [RELEASE.md](https://github.com/waikinw/PSKeyTab/blob/main/RELEASE.md)

## License

MIT License - see [LICENSE](https://github.com/waikinw/PSKeyTab/blob/main/LICENSE)

## Credits

**Original Author**: [Adam Burford (TRAB)](https://github.com/TheRealAdamBurford)
**Current Maintainer**: [waikinw](https://github.com/waikinw)

This is a derivative work based on [Create-KeyTab](https://github.com/TheRealAdamBurford/Create-KeyTab) with significant enhancements including comprehensive testing, PowerShell Gallery publication support, enhanced documentation, and CI/CD automation.

## References

- [RFC 3961 - Kerberos Encryption Types](https://tools.ietf.org/html/rfc3961)
- [MS-KILE - Kerberos Protocol Extensions](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-kile/)
- [MIT Kerberos Documentation](https://web.mit.edu/kerberos/krb5-latest/doc/)
