@{
    RootModule = 'KeyTabTools.psm1'
    ModuleVersion = '1.3.0'
    GUID = '325f7f9a-87be-42ec-ba96-c5e423718284'
    Author = 'waikinw'
    CompanyName = ''
    Copyright = '(c) 2020 Adam Burford, (c) 2024 waikinw. All rights reserved.'
    Description = 'Cross-platform PowerShell utility for generating offline Kerberos keytab files. Supports RC4-HMAC, AES-128, and AES-256 encryption. Works on Windows, Linux, and macOS as an alternative to ktpass. Based on original work by Adam Burford.'

    # Minimum PowerShell version
    PowerShellVersion = '5.1'

    # Functions to export
    FunctionsToExport = @(
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
        'Get-KeyTabEntries',
        'Invoke-KeyTabTools'
    )

    # Cmdlets to export (none)
    CmdletsToExport = @()

    # Variables to export (none)
    VariablesToExport = @()

    # Aliases to export (none)
    AliasesToExport = @()

    # Private data to pass to the module
    PrivateData = @{
        PSData = @{
            # Tags for module discovery
            Tags = @('Kerberos', 'KeyTab', 'ActiveDirectory', 'AD', 'Security', 'Authentication', 'Cross-Platform', 'ktpass', 'AES', 'RC4', 'Linux', 'macOS', 'Windows')

            # License URL
            LicenseUri = 'https://github.com/waikinw/PSKeyTab/blob/main/LICENSE'

            # Project URL
            ProjectUri = 'https://github.com/waikinw/PSKeyTab'

            # Release notes
            ReleaseNotes = 'https://github.com/waikinw/PSKeyTab/blob/main/CHANGELOG.md'

            # Icon URL
            # IconUri = ''

            # Prerelease string (comment out for stable releases)
            # Prerelease = 'preview'
        }
    }
}
