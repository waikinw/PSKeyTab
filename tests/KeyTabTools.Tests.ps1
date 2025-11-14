Import-Module $PSScriptRoot/../KeyTabTools.psd1 -Force

Describe 'Module Import' {
    It 'imports the module successfully' {
        $module = Get-Module KeyTabTools
        $module | Should -Not -BeNullOrEmpty
        $module.Name | Should -Be 'KeyTabTools'
    }

    It 'exports all expected functions' {
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
            'Get-KeyTabEntries',
            'Invoke-KeyTabTools'
        )

        $module = Get-Module KeyTabTools
        foreach ($func in $expectedFunctions) {
            $module.ExportedFunctions.Keys | Should -Contain $func
        }
    }
}

Describe 'Get-HexStringFromByteArray' {
    It 'converts byte array to uppercase hex' {
        $bytes = 0x0A,0x0B,0x0C
        (Get-HexStringFromByteArray -Data $bytes) | Should -Be '0A0B0C'
    }

    It 'converts empty byte array' {
        $bytes = @()
        (Get-HexStringFromByteArray -Data $bytes) | Should -Be ''
    }

    It 'converts single byte' {
        $bytes = @(0xFF)
        (Get-HexStringFromByteArray -Data $bytes) | Should -Be 'FF'
    }

    It 'handles zero bytes' {
        $bytes = @(0x00, 0x00)
        (Get-HexStringFromByteArray -Data $bytes) | Should -Be '0000'
    }
}

Describe 'Get-ByteArrayFromHexString' {
    It 'converts hex string to byte array' {
        $result = Get-ByteArrayFromHexString -HexString '0A0B0C'
        $result.Count | Should -Be 3
        $result[0] | Should -Be 0x0A
        $result[1] | Should -Be 0x0B
        $result[2] | Should -Be 0x0C
    }

    It 'converts uppercase hex string' {
        $result = Get-ByteArrayFromHexString -HexString 'FF'
        $result[0] | Should -Be 0xFF
    }

    It 'converts lowercase hex string' {
        $result = Get-ByteArrayFromHexString -HexString 'ff'
        $result[0] | Should -Be 0xFF
    }

    It 'roundtrips with Get-HexStringFromByteArray' {
        $original = 'DEADBEEF'
        $bytes = Get-ByteArrayFromHexString -HexString $original
        $result = Get-HexStringFromByteArray -Data $bytes
        $result | Should -Be $original
    }
}

Describe 'Get-BytesBigEndian' {
    It 'converts 16-bit integer to big endian bytes' {
        $result = Get-BytesBigEndian -Value 256 -BitSize 16
        $result.Count | Should -Be 2
        $result[0] | Should -Be 0x01
        $result[1] | Should -Be 0x00
    }

    It 'converts 32-bit integer to big endian bytes' {
        $result = Get-BytesBigEndian -Value 16909060 -BitSize 32
        $result.Count | Should -Be 4
        # 16909060 = 0x01020304
        $result[0] | Should -Be 0x01
        $result[1] | Should -Be 0x02
        $result[2] | Should -Be 0x03
        $result[3] | Should -Be 0x04
    }

    It 'handles zero value' {
        $result = Get-BytesBigEndian -Value 0 -BitSize 16
        $result[0] | Should -Be 0x00
        $result[1] | Should -Be 0x00
    }
}

Describe 'Get-PrincipalType' {
    It 'returns correct bytes for KRB5_NT_PRINCIPAL' {
        $result = Get-PrincipalType -PrincipalType 'KRB5_NT_PRINCIPAL'
        $result.Count | Should -Be 4
        $result[0] | Should -Be 0x00
        $result[1] | Should -Be 0x00
        $result[2] | Should -Be 0x00
        $result[3] | Should -Be 0x01
    }

    It 'returns correct bytes for KRB5_NT_SRV_INST' {
        $result = Get-PrincipalType -PrincipalType 'KRB5_NT_SRV_INST'
        $result[3] | Should -Be 0x02
    }

    It 'returns correct bytes for KRB5_NT_SRV_HST' {
        $result = Get-PrincipalType -PrincipalType 'KRB5_NT_SRV_HST'
        $result[3] | Should -Be 0x03
    }

    It 'returns correct bytes for KRB5_NT_UID' {
        $result = Get-PrincipalType -PrincipalType 'KRB5_NT_UID'
        $result[3] | Should -Be 0x05
    }
}

Describe 'Get-MD4' {
    It 'computes MD4 hash from string' {
        # Known MD4 hash of 'abc' (from RFC 1320)
        $result = Get-MD4 -String 'abc'
        $result | Should -Be 'a448017aaf21d8525fc10ae87aa6729d'
    }

    It 'computes MD4 hash from byte array' {
        $bytes = [byte[]]@(0x61, 0x62, 0x63)  # 'abc' in ASCII
        $result = Get-MD4 -ByteArray $bytes
        $result | Should -Be 'a448017aaf21d8525fc10ae87aa6729d'
    }

    It 'returns uppercase when UpperCase switch is used' {
        $result = Get-MD4 -String 'abc' -UpperCase
        $result | Should -Be 'A448017AAF21D8525FC10AE87AA6729D'
    }

    It 'handles empty string' {
        $result = Get-MD4 -String ''
        $result | Should -Not -BeNullOrEmpty
        $result.Length | Should -Be 32  # MD4 always produces 128-bit hash (32 hex chars)
    }
}

Describe 'Get-PBKDF2' {
    It 'generates 16-byte key' {
        $result = Get-PBKDF2 -PasswordString 'password' -SALT 'EXAMPLE.COMuser' -KeySize 16
        $result.Count | Should -Be 16
    }

    It 'generates 32-byte key' {
        $result = Get-PBKDF2 -PasswordString 'password' -SALT 'EXAMPLE.COMuser' -KeySize 32
        $result.Count | Should -Be 32
    }

    It 'produces different keys for different salts' {
        $key1 = Get-PBKDF2 -PasswordString 'password' -SALT 'SALT1' -KeySize 16
        $key2 = Get-PBKDF2 -PasswordString 'password' -SALT 'SALT2' -KeySize 16

        $hex1 = Get-HexStringFromByteArray -Data $key1
        $hex2 = Get-HexStringFromByteArray -Data $key2

        $hex1 | Should -Not -Be $hex2
    }

    It 'produces different keys for different passwords' {
        $key1 = Get-PBKDF2 -PasswordString 'password1' -SALT 'EXAMPLE.COMuser' -KeySize 16
        $key2 = Get-PBKDF2 -PasswordString 'password2' -SALT 'EXAMPLE.COMuser' -KeySize 16

        $hex1 = Get-HexStringFromByteArray -Data $key1
        $hex2 = Get-HexStringFromByteArray -Data $key2

        $hex1 | Should -Not -Be $hex2
    }
}

Describe 'Protect-Aes' {
    It 'encrypts data using AES-128' {
        $key = New-Object byte[] 16
        $iv = New-Object byte[] 16
        $data = New-Object byte[] 16

        $result = Protect-Aes -KeyData $key -IVData $iv -Data $data
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 16
    }

    It 'encrypts data using AES-256' {
        $key = New-Object byte[] 32
        $iv = New-Object byte[] 16
        $data = New-Object byte[] 16

        $result = Protect-Aes -KeyData $key -IVData $iv -Data $data
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 16
    }

    It 'produces consistent output for same inputs' {
        $key = New-Object byte[] 16
        $iv = New-Object byte[] 16
        $data = @(1..16)

        $result1 = Protect-Aes -KeyData $key -IVData $iv -Data $data
        $result2 = Protect-Aes -KeyData $key -IVData $iv -Data $data

        $hex1 = Get-HexStringFromByteArray -Data $result1
        $hex2 = Get-HexStringFromByteArray -Data $result2

        $hex1 | Should -Be $hex2
    }
}

Describe 'Get-AES128Key' {
    It 'generates AES-128 key' {
        $result = Get-AES128Key -PasswordString 'password' -SALT 'EXAMPLE.COMuser'
        $result | Should -Not -BeNullOrEmpty
        # Should be 32 hex characters (16 bytes * 2)
        $result.Length | Should -Be 32
    }

    It 'generates different keys for different passwords' {
        $key1 = Get-AES128Key -PasswordString 'password1' -SALT 'EXAMPLE.COMuser'
        $key2 = Get-AES128Key -PasswordString 'password2' -SALT 'EXAMPLE.COMuser'
        $key1 | Should -Not -Be $key2
    }

    It 'generates different keys for different salts' {
        $key1 = Get-AES128Key -PasswordString 'password' -SALT 'SALT1'
        $key2 = Get-AES128Key -PasswordString 'password' -SALT 'SALT2'
        $key1 | Should -Not -Be $key2
    }
}

Describe 'Get-AES256Key' {
    It 'generates AES-256 key' {
        $result = Get-AES256Key -PasswordString 'password' -SALT 'EXAMPLE.COMuser'
        $result | Should -Not -BeNullOrEmpty
        # Should be 64 hex characters (32 bytes * 2)
        $result.Length | Should -Be 64
    }

    It 'generates different keys for different passwords' {
        $key1 = Get-AES256Key -PasswordString 'password1' -SALT 'EXAMPLE.COMuser'
        $key2 = Get-AES256Key -PasswordString 'password2' -SALT 'EXAMPLE.COMuser'
        $key1 | Should -Not -Be $key2
    }

    It 'generates different keys for different salts' {
        $key1 = Get-AES256Key -PasswordString 'password' -SALT 'SALT1'
        $key2 = Get-AES256Key -PasswordString 'password' -SALT 'SALT2'
        $key1 | Should -Not -Be $key2
    }
}

Describe 'New-KeyTabEntry' {
    It 'creates RC4 keytab entry' {
        $result = New-KeyTabEntry `
            -PasswordString 'password' `
            -RealmString 'EXAMPLE.COM' `
            -Components @('user') `
            -SALT 'EXAMPLE.COMuser' `
            -KVNO 1 `
            -PrincipalType 'KRB5_NT_PRINCIPAL' `
            -EncryptionKeyType 'RC4'

        $result | Should -Not -BeNullOrEmpty
        $result.KeyBlock | Should -Not -BeNullOrEmpty
        $result.KeytabEntry | Should -Not -BeNullOrEmpty
        $result.KeyType[1] | Should -Be 23  # RC4 = 0x17 = 23
    }

    It 'creates AES128 keytab entry' {
        $result = New-KeyTabEntry `
            -PasswordString 'password' `
            -RealmString 'EXAMPLE.COM' `
            -Components @('user') `
            -SALT 'EXAMPLE.COMuser' `
            -KVNO 1 `
            -PrincipalType 'KRB5_NT_PRINCIPAL' `
            -EncryptionKeyType 'AES128'

        $result | Should -Not -BeNullOrEmpty
        $result.KeyType[1] | Should -Be 17  # AES128 = 0x11 = 17
    }

    It 'creates AES256 keytab entry' {
        $result = New-KeyTabEntry `
            -PasswordString 'password' `
            -RealmString 'EXAMPLE.COM' `
            -Components @('user') `
            -SALT 'EXAMPLE.COMuser' `
            -KVNO 1 `
            -PrincipalType 'KRB5_NT_PRINCIPAL' `
            -EncryptionKeyType 'AES256'

        $result | Should -Not -BeNullOrEmpty
        $result.KeyType[1] | Should -Be 18  # AES256 = 0x12 = 18
    }

    It 'handles multi-component principals' {
        $result = New-KeyTabEntry `
            -PasswordString 'password' `
            -RealmString 'EXAMPLE.COM' `
            -Components @('http', 'server.example.com') `
            -SALT 'EXAMPLE.COMhttpserver.example.com' `
            -KVNO 1 `
            -PrincipalType 'KRB5_NT_SRV_HST' `
            -EncryptionKeyType 'AES256'

        $result | Should -Not -BeNullOrEmpty
        $result.Components.Count | Should -Be 2
    }
}

Describe 'Invoke-KeyTabTools Integration Tests' {
    BeforeAll {
        $testFile = Join-Path $TestDrive 'test.keytab'
    }

    AfterEach {
        if (Test-Path $testFile) {
            Remove-Item $testFile -Force
        }
    }

    It 'creates keytab file with default AES256' {
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -NoPrompt `
            -Quiet

        Test-Path $testFile | Should -Be $true
        $fileBytes = [System.IO.File]::ReadAllBytes($testFile)
        # Check keytab version header (0x05 0x02)
        $fileBytes[0] | Should -Be 0x05
        $fileBytes[1] | Should -Be 0x02
    }

    It 'creates keytab file with multiple encryption types' {
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -RC4 `
            -AES128 `
            -AES256 `
            -NoPrompt `
            -Quiet

        Test-Path $testFile | Should -Be $true
        $fileBytes = [System.IO.File]::ReadAllBytes($testFile)
        $fileBytes.Length | Should -BeGreaterThan 100  # Should have 3 entries
    }

    It 'appends to existing keytab file' {
        # Create initial file
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -NoPrompt `
            -Quiet

        $initialSize = (Get-Item $testFile).Length

        # Append to file
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser2' `
            -Password 'TestPassword456' `
            -File $testFile `
            -Append `
            -NoPrompt `
            -Quiet

        $finalSize = (Get-Item $testFile).Length
        $finalSize | Should -BeGreaterThan $initialSize
    }

    It 'handles service principal format' {
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'http/server.example.com' `
            -Password 'ServicePassword' `
            -File $testFile `
            -PType 'KRB5_NT_SRV_HST' `
            -NoPrompt `
            -Quiet

        Test-Path $testFile | Should -Be $true
    }

    It 'supports custom SALT' {
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -SALT 'CUSTOMSALT' `
            -File $testFile `
            -NoPrompt `
            -Quiet

        Test-Path $testFile | Should -Be $true
    }

    It 'supports custom KVNO' {
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -KVNO 5 `
            -NoPrompt `
            -Quiet

        Test-Path $testFile | Should -Be $true
    }
}

Describe 'Get-KeyTabEntries' {
    BeforeAll {
        $testFile = Join-Path $TestDrive 'test.keytab'
    }

    AfterEach {
        if (Test-Path $testFile) {
            Remove-Item $testFile -Force
        }
    }

    It 'fails gracefully when file does not exist' {
        $result = Get-KeyTabEntries -FilePath 'nonexistent.keytab' -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
    }

    It 'parses keytab file with single AES256 entry' {
        # Create a keytab file
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -AES256 `
            -NoPrompt `
            -Quiet

        # Parse it
        $entries = Get-KeyTabEntries -FilePath $testFile
        $entries | Should -Not -BeNullOrEmpty
        $entries.Count | Should -Be 1
        $entries[0].Principal | Should -Be 'testuser@EXAMPLE.COM'
        $entries[0].Realm | Should -Be 'EXAMPLE.COM'
        $entries[0].EncryptionType | Should -Be 'AES256-CTS-HMAC-SHA1-96'
        $entries[0].KVNO | Should -Be 1
    }

    It 'parses keytab file with multiple encryption types' {
        # Create a keytab file with RC4, AES128, and AES256
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -RC4 `
            -AES128 `
            -AES256 `
            -NoPrompt `
            -Quiet

        # Parse it
        $entries = Get-KeyTabEntries -FilePath $testFile
        $entries | Should -Not -BeNullOrEmpty
        $entries.Count | Should -Be 3

        # Verify all three encryption types are present
        $encTypes = $entries | Select-Object -ExpandProperty EncryptionType
        $encTypes | Should -Contain 'RC4-HMAC'
        $encTypes | Should -Contain 'AES128-CTS-HMAC-SHA1-96'
        $encTypes | Should -Contain 'AES256-CTS-HMAC-SHA1-96'
    }

    It 'parses keytab file with multiple principals' {
        # Create first entry
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'user1' `
            -Password 'Password1' `
            -File $testFile `
            -NoPrompt `
            -Quiet

        # Append second entry
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'user2' `
            -Password 'Password2' `
            -File $testFile `
            -Append `
            -NoPrompt `
            -Quiet

        # Parse it
        $entries = Get-KeyTabEntries -FilePath $testFile
        $entries | Should -Not -BeNullOrEmpty
        $entries.Count | Should -Be 2

        # Verify principals
        $principals = $entries | Select-Object -ExpandProperty Principal
        $principals | Should -Contain 'user1@EXAMPLE.COM'
        $principals | Should -Contain 'user2@EXAMPLE.COM'
    }

    It 'parses service principal format correctly' {
        # Create service principal entry
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'http/server.example.com' `
            -Password 'ServicePassword' `
            -File $testFile `
            -PType 'KRB5_NT_SRV_HST' `
            -NoPrompt `
            -Quiet

        # Parse it
        $entries = Get-KeyTabEntries -FilePath $testFile
        $entries | Should -Not -BeNullOrEmpty
        $entries.Count | Should -Be 1
        $entries[0].Principal | Should -Be 'http/server.example.com@EXAMPLE.COM'
        $entries[0].Components.Count | Should -Be 2
        $entries[0].Components[0] | Should -Be 'http'
        $entries[0].Components[1] | Should -Be 'server.example.com'
        $entries[0].PrincipalType | Should -Be 'KRB5_NT_SRV_HST'
    }

    It 'preserves custom KVNO values' {
        # Create entry with custom KVNO
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -KVNO 42 `
            -NoPrompt `
            -Quiet

        # Parse it
        $entries = Get-KeyTabEntries -FilePath $testFile
        $entries | Should -Not -BeNullOrEmpty
        $entries[0].KVNO | Should -Be 42
    }

    It 'returns key hash for each entry' {
        # Create entry
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -AES256 `
            -NoPrompt `
            -Quiet

        # Parse it
        $entries = Get-KeyTabEntries -FilePath $testFile
        $entries | Should -Not -BeNullOrEmpty
        $entries[0].KeyHash | Should -Not -BeNullOrEmpty
        # AES256 key should be 64 hex characters (32 bytes)
        $entries[0].KeyHash.Length | Should -Be 64
        $entries[0].KeyLength | Should -Be 32
    }

    It 'handles RC4 key length correctly' {
        # Create RC4 entry
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -RC4 `
            -NoPrompt `
            -Quiet

        # Parse it
        $entries = Get-KeyTabEntries -FilePath $testFile
        $entries | Should -Not -BeNullOrEmpty
        # RC4 key should be 32 hex characters (16 bytes)
        $entries[0].KeyHash.Length | Should -Be 32
        $entries[0].KeyLength | Should -Be 16
    }

    It 'parses timestamp correctly' {
        # Create entry
        Invoke-KeyTabTools `
            -Realm 'EXAMPLE.COM' `
            -Principal 'testuser' `
            -Password 'TestPassword123' `
            -File $testFile `
            -NoPrompt `
            -Quiet

        # Parse it
        $entries = Get-KeyTabEntries -FilePath $testFile
        $entries | Should -Not -BeNullOrEmpty
        $entries[0].Timestamp | Should -Not -BeNullOrEmpty
        $entries[0].Timestamp | Should -BeOfType [DateTime]
        # Timestamp should be recent (within last hour)
        $timeDiff = (Get-Date).ToUniversalTime() - $entries[0].Timestamp
        $timeDiff.TotalHours | Should -BeLessThan 1
    }
}
