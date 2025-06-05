@{
    RootModule = 'KeyTabTools.psm1'
    ModuleVersion = '1.2.0'
    GUID = '325f7f9a-87be-42ec-ba96-c5e423718284'
    Author = 'TRAB'
    CompanyName = ''
    Copyright = ''
    Description = 'Utility functions for creating offline keytab files.'
    FunctionsToExport = @('Get-MD4','Get-PBKDF2','Encrypt-AES','Get-AES128Key','Get-AES256Key','Get-HexStringFromByteArray','Get-ByteArrayFromHexString','Get-BytesBigEndian','Get-PrincipalType','Create-KeyTabEntry')
    PowerShellVersion = '5.1'
}
