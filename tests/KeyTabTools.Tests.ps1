Import-Module $PSScriptRoot/../KeyTabTools.psd1
Describe 'Get-HexStringFromByteArray' {
    It 'converts byte array to uppercase hex' {
        $bytes = 0x0A,0x0B,0x0C
        (Get-HexStringFromByteArray -Data $bytes) | Should -Be '0A0B0C'
    }
}
