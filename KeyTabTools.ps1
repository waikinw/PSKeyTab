<#PSScriptInfo
.VERSION 1.3.0
.GUID 325f7f9a-87be-42ec-ba96-c5e423718284
.AUTHOR waikinw
.COMPANYNAME
.COPYRIGHT (c) 2020 Adam Burford, (c) 2024 waikinw
.TAGS KeyTab Ktpass Key Tab Kerberos ActiveDirectory AES RC4 Cross-Platform
.LICENSEURI https://github.com/waikinw/PSKeyTab/blob/main/LICENSE
.PROJECTURI https://github.com/waikinw/PSKeyTab
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES https://github.com/waikinw/PSKeyTab/blob/main/CHANGELOG.md
.PRIVATEDATA
#>

<#
.DESCRIPTION
 This script will generate off-line keytab files for use with Active Directory (AD). While the script is designed to work independently of AD, this script can be used with a wrapper script that uses Get-ADUser or Get-ADObject to retrieve the UPN of a samaccountname or a list of samaccountnames for use in batch processing of KeyTab creation.

 Original work by Adam Burford (TRAB): https://github.com/TheRealAdamBurford/Create-KeyTab
 Current repository: https://github.com/waikinw/PSKeyTab
#>
##########################################################
###
###      KeyTabTools.ps1
###
###      Originally Created: 2019-10-26 by Adam Burford
###      Enhanced: 2024-11-14 by waikinw
###
###      Original Author: Adam Burford (TRAB)
###      Current Maintainer: waikinw
###
###
### Notes: Create RC4-HMAC, AES128. AES256 KeyTab file. Does not use AD. 
### Password, ServicePRincipal/UPN must be set on AD account.
### Future add may include option AD lookup for Kvno, SPN and UPN.
###
### 2019-11-11 - Added custom SALT option
### 2019-11-11 - Added current Epoch Time Stamp.
### 2019-11-12 - Added -Append option
### 2019-11-12 - Added -Quiet and -NoPrompt switches for use in batch mode
### 2019-11-14 - Added support for UPN format primary/principal (e.g. host/www.domain.com). The principal is split into an array. 
###              The slash is removed from the SALT calculation.
###
### 2019-11-18 - Changed output text. RC4,AES128,AES256
### 2019-11-18 - Created static nFold output.
### 2019-11-26 - Added a Get-Password function to mask password prompt input
### 2020-01-30 - Add Info for posting to https://www.powershellgallery.com
### 2020-09-15 - Added suggested use of [decimal]::Parse from "https://github.com/matherm-aboehm" to fix timestamp error on localized versions of Windows. Line 535.
### 2020-10-26 - Add KRB5_NT_SRV_HST to possible PType values
###
##########################################################
### Attribution:
### https://tools.ietf.org/html/rfc3961
### https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-kile/936a4878-9462-4753-aac8-087cd3ca4625?redirectedfrom=MSDN
### https://github.com/dfinke/powershell-algorithms/blob/master/src/algorithms/math/euclidean-algorithm/euclideanAlgorithm.ps1
### https://afana.me/archive/2016/12/29/how-mit-keytab-files-store-passwords.aspx/
### http://www.ioplex.com/utilities/keytab.txt

<#
.SYNOPSIS
This script will generate and append version 502 KeyTab files

.DESCRIPTION
Required Parameters

-Realm     : The Realm for the KeyTab
-Principal : The Principal for the KeyTab. Case sensative for AES SALT. Default REALM+Principal
-Password  : 

Optional Parameters

-SALT      : Use a custom SALT
-File      : KeyTab File Path. Default = CurrentDirectory\login.keytab
-KVNO      : Default = 1. Exceeding 255 will wrap the KVNO. THe 32bit KVNO field is not implimented.
-PType     : Default = KRB5_NT_PRINCIPAL
-RC4       : Generate RC4 Key
-AES128    : Generate AES128 Key
-AES256    : Generate AES256 Key - This is default if no Etype switch is set.
-Append    : Append Key Data to an existing KeyTab file.
-Quiet     : Suppress Text Output
-NoPrompt  : Suppress Write KeyTab File Prompt

.EXAMPLE
.\KeyTabTools.ps1
.EXAMPLE
.\KeyTabTools.ps1 -AES256 -AES128 -RC4
.EXAMPLE
.\KeyTabTools.ps1 -AES256 -AES128 -Append
.EXAMPLE
.\KeyTabTools.ps1 -AES256 -AES128 -SALT "MY.REALM.COMprincipalname"
.EXAMPLE
.\KeyTabTools.ps1 -Realm "MY.REALM.COM" -Principal "principalname" -Password "Secret" -File "c:\temp\login.keytab"

.NOTES
Use -QUIET and -NOPROMPT for batch mode processing.

.LINK
https://www.linkedin.com/in/adamburford
#>
param (
    [string]$Realm,
    [string]$Principal,
    [string]$Password,
    [string]$SALT,
    [string]$File,
    [int]$KVNO,
    [ValidateSet("KRB5_NT_PRINCIPAL", "KRB5_NT_SRV_INST", "KRB5_NT_SRV_HST", "KRB5_NT_UID")][String[]]$PType="KRB5_NT_PRINCIPAL",
    [switch]$RC4,
    [switch]$AES128,
    [switch]$AES256,
    [switch]$Append,
    [switch]$Quiet,
    [switch]$NoPrompt
)

function Get-MD4 {
    <#
    .SYNOPSIS
        Calculates an MD4 hash.

    .DESCRIPTION
        Returns the MD4 hash of a string or byte array.  Optionally the
        result can be returned in upper case.
    #>

    param(
        [string]$String,
        [byte[]]$ByteArray,
        [switch]$UpperCase
    )
    
    # Author: Larry.Song@outlook.com
    # https://github.com/LarrysGIT/MD4-powershell
    # Reference: https://tools.ietf.org/html/rfc1320
    # MD4('abc'): a448017aaf21d8525fc10ae87aa6729d
    $Array = [byte[]]@()
    if($String)
    {
        $Array = [byte[]]@($String.ToCharArray() | %{[int]$_})
    }
    if($ByteArray)
    {
        $Array = $ByteArray
    }
    # padding 100000*** to length 448, last (64 bits / 8) 8 bytes fill with original length
    # at least one (512 bits / 8) 64 bytes array
    $M = New-Object Byte[] (([math]::Floor($Array.Count/64) + 1) * 64)
    # copy original byte array, start from index 0
    $Array.CopyTo($M, 0)
    # padding bits 1000 0000
    $M[$Array.Count] = 0x80
    # padding bits 0000 0000 to fill length (448 bits /8) 56 bytes
    # Default value is 0 when creating a new byte array, so, no action
    # padding message length to the last 64 bits
    @([BitConverter]::GetBytes($Array.Count * 8)).CopyTo($M, $M.Count - 8)

    # message digest buffer (A,B,C,D)
    $A = [Convert]::ToUInt32('0x67452301', 16)
    $B = [Convert]::ToUInt32('0xefcdab89', 16)
    $C = [Convert]::ToUInt32('0x98badcfe', 16)
    $D = [Convert]::ToUInt32('0x10325476', 16)
    
    # There is no unsigned number shift in C#, have to define one.
    Add-Type -TypeDefinition @'
public class Shift
{
  public static uint Left(uint a, int b)
    {
        return ((a << b) | (((a >> 1) & 0x7fffffff) >> (32 - b - 1)));
    }
}
'@

    # define 3 auxiliary functions
    function FF([uint32]$X, [uint32]$Y, [uint32]$Z)
    {
        (($X -band $Y) -bor ((-bnot $X) -band $Z))
    }
    function GG([uint32]$X, [uint32]$Y, [uint32]$Z)
    {
        (($X -band $Y) -bor ($X -band $Z) -bor ($Y -band $Z))
    }
    function HH([uint32]$X, [uint32]$Y, [uint32]$Z){
        ($X -bxor $Y -bxor $Z)
    }
    # processing message in one-word blocks
    for($i = 0; $i -lt $M.Count; $i += 64)
    {
        # Save a copy of A/B/C/D
        $AA = $A
        $BB = $B
        $CC = $C
        $DD = $D

        # Round 1 start
        $A = [Shift]::Left(($A + (FF -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 0)..($i + 3)], 0)) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (FF -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 4)..($i + 7)], 0)) -band [uint32]::MaxValue, 7)
        $C = [Shift]::Left(($C + (FF -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 8)..($i + 11)], 0)) -band [uint32]::MaxValue, 11)
        $B = [Shift]::Left(($B + (FF -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 12)..($i + 15)], 0)) -band [uint32]::MaxValue, 19)

        $A = [Shift]::Left(($A + (FF -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 16)..($i + 19)], 0)) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (FF -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 20)..($i + 23)], 0)) -band [uint32]::MaxValue, 7)
        $C = [Shift]::Left(($C + (FF -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 24)..($i + 27)], 0)) -band [uint32]::MaxValue, 11)
        $B = [Shift]::Left(($B + (FF -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 28)..($i + 31)], 0)) -band [uint32]::MaxValue, 19)

        $A = [Shift]::Left(($A + (FF -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 32)..($i + 35)], 0)) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (FF -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 36)..($i + 39)], 0)) -band [uint32]::MaxValue, 7)
        $C = [Shift]::Left(($C + (FF -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 40)..($i + 43)], 0)) -band [uint32]::MaxValue, 11)
        $B = [Shift]::Left(($B + (FF -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 44)..($i + 47)], 0)) -band [uint32]::MaxValue, 19)

        $A = [Shift]::Left(($A + (FF -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 48)..($i + 51)], 0)) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (FF -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 52)..($i + 55)], 0)) -band [uint32]::MaxValue, 7)
        $C = [Shift]::Left(($C + (FF -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 56)..($i + 59)], 0)) -band [uint32]::MaxValue, 11)
        $B = [Shift]::Left(($B + (FF -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 60)..($i + 63)], 0)) -band [uint32]::MaxValue, 19)
        # Round 1 end
        # Round 2 start
        $A = [Shift]::Left(($A + (GG -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 0)..($i + 3)], 0) + 0x5A827999) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (GG -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 16)..($i + 19)], 0) + 0x5A827999) -band [uint32]::MaxValue, 5)
        $C = [Shift]::Left(($C + (GG -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 32)..($i + 35)], 0) + 0x5A827999) -band [uint32]::MaxValue, 9)
        $B = [Shift]::Left(($B + (GG -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 48)..($i + 51)], 0) + 0x5A827999) -band [uint32]::MaxValue, 13)

        $A = [Shift]::Left(($A + (GG -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 4)..($i + 7)], 0) + 0x5A827999) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (GG -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 20)..($i + 23)], 0) + 0x5A827999) -band [uint32]::MaxValue, 5)
        $C = [Shift]::Left(($C + (GG -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 36)..($i + 39)], 0) + 0x5A827999) -band [uint32]::MaxValue, 9)
        $B = [Shift]::Left(($B + (GG -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 52)..($i + 55)], 0) + 0x5A827999) -band [uint32]::MaxValue, 13)

        $A = [Shift]::Left(($A + (GG -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 8)..($i + 11)], 0) + 0x5A827999) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (GG -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 24)..($i + 27)], 0) + 0x5A827999) -band [uint32]::MaxValue, 5)
        $C = [Shift]::Left(($C + (GG -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 40)..($i + 43)], 0) + 0x5A827999) -band [uint32]::MaxValue, 9)
        $B = [Shift]::Left(($B + (GG -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 56)..($i + 59)], 0) + 0x5A827999) -band [uint32]::MaxValue, 13)

        $A = [Shift]::Left(($A + (GG -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 12)..($i + 15)], 0) + 0x5A827999) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (GG -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 28)..($i + 31)], 0) + 0x5A827999) -band [uint32]::MaxValue, 5)
        $C = [Shift]::Left(($C + (GG -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 44)..($i + 47)], 0) + 0x5A827999) -band [uint32]::MaxValue, 9)
        $B = [Shift]::Left(($B + (GG -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 60)..($i + 63)], 0) + 0x5A827999) -band [uint32]::MaxValue, 13)
        # Round 2 end
        # Round 3 start
        $A = [Shift]::Left(($A + (HH -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 0)..($i + 3)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (HH -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 32)..($i + 35)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 9)
        $C = [Shift]::Left(($C + (HH -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 16)..($i + 19)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 11)
        $B = [Shift]::Left(($B + (HH -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 48)..($i + 51)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 15)

        $A = [Shift]::Left(($A + (HH -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 8)..($i + 11)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (HH -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 40)..($i + 43)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 9)
        $C = [Shift]::Left(($C + (HH -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 24)..($i + 27)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 11)
        $B = [Shift]::Left(($B + (HH -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 56)..($i + 59)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 15)

        $A = [Shift]::Left(($A + (HH -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 4)..($i + 7)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (HH -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 36)..($i + 39)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 9)
        $C = [Shift]::Left(($C + (HH -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 20)..($i + 23)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 11)
        $B = [Shift]::Left(($B + (HH -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 52)..($i + 55)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 15)

        $A = [Shift]::Left(($A + (HH -X $B -Y $C -Z $D) + [BitConverter]::ToUInt32($M[($i + 12)..($i + 15)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 3)
        $D = [Shift]::Left(($D + (HH -X $A -Y $B -Z $C) + [BitConverter]::ToUInt32($M[($i + 44)..($i + 47)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 9)
        $C = [Shift]::Left(($C + (HH -X $D -Y $A -Z $B) + [BitConverter]::ToUInt32($M[($i + 28)..($i + 31)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 11)
        $B = [Shift]::Left(($B + (HH -X $C -Y $D -Z $A) + [BitConverter]::ToUInt32($M[($i + 60)..($i + 63)], 0) + 0x6ED9EBA1) -band [uint32]::MaxValue, 15)
        # Round 3 end
        # Increment start
        $A = ($A + $AA) -band [uint32]::MaxValue
        $B = ($B + $BB) -band [uint32]::MaxValue
        $C = ($C + $CC) -band [uint32]::MaxValue
        $D = ($D + $DD) -band [uint32]::MaxValue
        # Increment end
    }
    # Output start
    $A = ('{0:x8}' -f $A) -ireplace '^(\w{2})(\w{2})(\w{2})(\w{2})$', '$4$3$2$1'
    $B = ('{0:x8}' -f $B) -ireplace '^(\w{2})(\w{2})(\w{2})(\w{2})$', '$4$3$2$1'
    $C = ('{0:x8}' -f $C) -ireplace '^(\w{2})(\w{2})(\w{2})(\w{2})$', '$4$3$2$1'
    $D = ('{0:x8}' -f $D) -ireplace '^(\w{2})(\w{2})(\w{2})(\w{2})$', '$4$3$2$1'
    # Output end

    if($UpperCase)
    {
        return "$A$B$C$D".ToUpper()
    }
    else
    {
        return "$A$B$C$D"
    }
}

function Get-PBKDF2 {
    <#
    .SYNOPSIS
        Derives bytes using PBKDF2.

    .PARAMETER PasswordString
        The source password.

    .PARAMETER SALT
        The salt value for the key derivation.

    .PARAMETER KeySize
        Size of the key in bytes (16 or 32).
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$PasswordString,
        [Parameter(Mandatory=$true)]
        [string]$SALT,
        [Parameter(Mandatory=$true)]
        [ValidateSet('16','32')][string]$KeySize
    )

### Set Key Size
switch($KeySize){
"16"{
    [int] $size = 16
    break;
    }
"32"{
    [int] $size = 32
    break;
     }
default{}
}

[byte[]] $password = [Text.Encoding]::UTF8.GetBytes($PasswordString)
[byte[]] $saltBytes = [Text.Encoding]::UTF8.GetBytes($SALT)

#PBKDF2 IterationCount=4096
$deriveBytes = new-Object Security.Cryptography.Rfc2898DeriveBytes($password, $saltBytes, 4096)

<#
$hexStringSALT = Get-HexStringFromByteArray -Data $deriveBytes.Salt    
Write-Host "SALT (HEX):"$hexStringSALT -ForegroundColor Yellow
#>

return $deriveBytes.GetBytes($size)
}

function Protect-Aes {
    <#
    .SYNOPSIS
        Encrypts data using AES CBC mode with no padding.

    .DESCRIPTION
        Helper used to create keys for AES based encryption types. All
        parameters should be supplied as byte arrays.

    .PARAMETER KeyData
        The AES key material.

    .PARAMETER IVData
        Initialization vector for the encryption.

    .PARAMETER Data
        Data to encrypt.
    #>

    param(
        [Parameter(Mandatory=$true)]
        [byte[]]$KeyData,
        [Parameter(Mandatory=$true)]
        [byte[]]$IVData,
        [Parameter(Mandatory=$true)]
        [byte[]]$Data
    )

### All arguments should be supplied as byte arrays

### AES 128-CTS
# KeySize = 16
# AESKey = Protect-Aes -KeyData PBKdf2 -IVData IV -Data NFoldText

### AES 256-CTS
# KeySize = 32
# K1 = Protect-Aes -KeyData PBKdf2 -IVData IV -Data NFoldText
# K2 = Protect-Aes -KeyData PBKdf2 -IVData IV -Data K1
# AESKey = K1 + K2

# Create AES Object
    $Aes = $null
    $encryptor = $null
    $memStream = $null
    $cryptoStream = $null
    $AESKey = $null
    
    $Aes = New-Object System.Security.Cryptography.AesManaged
    $Aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $Aes.Padding = [System.Security.Cryptography.PaddingMode]::None
    $Aes.BlockSize = 128

    $encryptor = $Aes.CreateEncryptor($KeyData,$IVData)
    $memStream = new-Object IO.MemoryStream

    [byte[]] $AESKey = @()
    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $cryptoStream.Write($Data, 0, $Data.Length)
    $CryptoStream.FlushFinalBlock()
    $cryptoStream.Close()

    $AESKey = $memStream.ToArray()
    $memStream.Close()
    $Aes.Dispose()

    return $AESKey
}

function Get-AES128Key {
    <#
    .SYNOPSIS
        Generates an AES-128 key.

    .PARAMETER PasswordString
        Source password used for key derivation.

    .PARAMETER SALT
        Kerberos salt value.
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$PasswordString,
        [Parameter(Mandatory=$true)]
        [string]$SALT = ""
    )

[byte[]] $PBKDF2 = Get-PBKDF2 -PasswordString $passwordString -SALT $SALT -KeySize 16
#[byte[]] $nFolded = (Get-NFold-Bytes -Data ([Text.Encoding]::ASCII.GetBytes("kerberos")) -KeySize 16)
[byte[]] $nFolded = @(107,101,114,98,101,114,111,115,123,155,91,43,147,19,43,147)
[byte[]] $Key = $PBKDF2
[byte[]] $IV =  @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

$AES128Key = Protect-Aes -KeyData $key -IVData $IV -Data $nFolded
return $(Get-HexStringFromByteArray -Data $AES128Key)
}

function Get-AES256Key {
    <#
    .SYNOPSIS
        Generates an AES-256 key.

    .PARAMETER PasswordString
        Source password used for key derivation.

    .PARAMETER SALT
        Kerberos salt value.
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$PasswordString,
        [Parameter(Mandatory=$true)]
        [string]$SALT = ""
    )

[byte[]] $PBKDF2 = Get-PBKDF2 -PasswordString $passwordString -SALT $SALT -KeySize 32
#[byte[]] $nFolded = (Get-NFold-Bytes -Data ([Text.Encoding]::ASCII.GetBytes("kerberos")) -KeySize 16)
[byte[]] $nFolded = @(107,101,114,98,101,114,111,115,123,155,91,43,147,19,43,147)
[byte[]] $Key = $PBKDF2
[byte[]] $IV =  @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

$k1 = Protect-Aes -KeyData $key -IVData $IV -Data $nFolded
$k2 = Protect-Aes -KeyData $key -IVData $IV -Data $k1

$AES256Key = $k1 + $k2
return $(Get-HexStringFromByteArray -Data $AES256Key)
}

function Get-HexStringFromByteArray {
    <#
    .SYNOPSIS
        Converts a byte array into an uppercase hexadecimal string.

    .PARAMETER Data
        Byte array to convert.
    #>

    param(
        [Parameter(Mandatory=$true, Position=0)]
        [AllowEmptyCollection()]
        [byte[]]$Data
    )
$hexString = $null

        $sb = New-Object System.Text.StringBuilder ($Data.Length * 2)
        foreach($b in $Data)
        {
            $sb.AppendFormat("{0:x2}", $b) |Out-Null
        }
        $hexString = $sb.ToString().ToUpper([CultureInfo]::InvariantCulture)

return $hexString
}

function Get-ByteArrayFromHexString {
    <#
    .SYNOPSIS
        Converts a hexadecimal string into a byte array.

    .PARAMETER HexString
        String containing hexadecimal characters.
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$HexString
    )
        $i = 0;
        $bytes = @()
        while($i -lt $HexString.Length)
        {
            $chars = $HexString.SubString($i, 2)
            $b = [Convert]::ToByte($chars, 16)
            $bytes += $b
            $i = $i+2
        }
return $bytes
}

function Get-BytesBigEndian {
    <#
    .SYNOPSIS
        Returns a big endian byte representation of an integer.

    .PARAMETER Value
        Integer value to convert.

    .PARAMETER BitSize
        Length of the resulting byte array in bits (16 or 32).
    #>

    param(
        [Parameter(Mandatory=$true)]
        [int]$Value,
        [Parameter(Mandatory=$true)]
        [ValidateSet('16','32')][string]$BitSize
    )

### Set Key Type
[byte[]] $bytes = @()
switch($BitSize){
"16"{
    $bytes = [BitCOnverter]::GetBytes([int16]$Value)
    if([BitCOnverter]::IsLittleEndian){
    [Array]::Reverse($bytes)
    }
    break;
    }
"32"{
    $bytes = [BitCOnverter]::GetBytes([int32]$Value)
    if([BitCOnverter]::IsLittleEndian){
    [Array]::Reverse($bytes)
    }
    break;
     }
default{}
}

return $bytes
}

function Get-PrincipalType {
    <#
    .SYNOPSIS
        Returns the numerical value for a Kerberos principal type.

    .PARAMETER PrincipalType
        String representation of the principal type.
    #>

    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('KRB5_NT_PRINCIPAL','KRB5_NT_SRV_INST','KRB5_NT_SRV_HST','KRB5_NT_UID')]
        [string[]]$PrincipalType
    )

[byte[]] $nameType = @()

switch($PrincipalType){
"KRB5_NT_PRINCIPAL"{$nameType = @(00,00,00,01);break}
"KRB5_NT_SRV_INST"{$nameType = @(00,00,00,02);break}
"KRB5_NT_SRV_HST"{$nameType = @(00,00,00,03);break}
"KRB5_NT_UID"{$nameType = @(00,00,00,05);break}
default{$nameType = @(00,00,00,01);break}
}

return $nameType
}

function New-KeyTabEntry {
    <#
    .SYNOPSIS
        Creates a keytab entry object.

    .DESCRIPTION
        Builds the byte sequence for a single keytab entry using the
        supplied credentials and encryption type.

    .PARAMETER PasswordString
        Account password.

    .PARAMETER RealmString
        Kerberos realm for the entry.

    .PARAMETER Components
        Array of principal components.

    .PARAMETER SALT
        Optional Kerberos salt to use.

    .PARAMETER KVNO
        Key version number.

    .PARAMETER PrincipalType
        Kerberos principal type for the entry.

    .PARAMETER EncryptionKeyType
        Desired encryption type (RC4, AES128 or AES256).
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]$PasswordString,
        [Parameter(Mandatory=$true)]
        [string]$RealmString,
        [Parameter(Mandatory=$true)]
        $Components,
        [Parameter(Mandatory=$false)]
        [string]$SALT = "",
        [Parameter(Mandatory=$false)]
        [int]$KVNO = 1,
        [Parameter(Mandatory=$true)]
        [ValidateSet('KRB5_NT_PRINCIPAL','KRB5_NT_SRV_INST','KRB5_NT_SRV_HST','KRB5_NT_UID')]
        [string[]]$PrincipalType,
        [Parameter(Mandatory=$true)]
        [ValidateSet('RC4','AES128','AES256')]
        [string[]]$EncryptionKeyType
    )

### Key Types: RC4 0x17 (23), AES128  0x11 (17), AES256  0x12 (18)

### Set Key Type
[byte[]] $keyType = @()
[byte[]] $sizeKeyBlock = @()

switch($EncryptionKeyType){
"RC4"{
       $keyType = @(00,23)
       $sizeKey = 16
       $sizeKeyBlock = @(00,16)
       ### Create RC4-HMAC Key. Unicode is required for MD4 hash input.
       [byte[]]$password = [Text.Encoding]::Unicode.GetBytes($passwordString)
       $keyBlock = Get-MD4 -ByteArray $password -UpperCase
       break
       }
"AES128"{
        $keyType = @(00,17)
        $sizeKey = 16
        $sizeKeyBlock = @(00,16)
        #$keyBlock = Get-AES128Key -PasswordString $passwordString -Realm $RealmString -Principal $PrincipalString -SALT $SALT
        $keyBlock = Get-AES128Key -PasswordString $passwordString -SALT $SALT
        break
        }
"AES256"{
        $keyType = @(00,18)
        $sizeKey = 32
        $sizeKeyBlock = @(00,32)
        #$keyBlock = Get-AES256Key -PasswordString $passwordString -Realm $RealmString -Principal $PrincipalString -SALT $SALT
        $keyBlock = Get-AES256Key -PasswordString $passwordString -SALT $SALT
        break
        }
default{}
}

### Set Principal Type
[byte[]] $nameType = @()
switch($PrincipalType){
"KRB5_NT_PRINCIPAL"{$nameType = @(00,00,00,01);break}
"KRB5_NT_SRV_INST"{$nameType = @(00,00,00,02);break}
"KRB5_NT_SRV_HST"{$nameType = @(00,00,00,03);break}
"KRB5_NT_UID"{$nameType = @(00,00,00,05);break}
default{$nameType = @(00,00,00,01);break}
}

### KVNO larger than 255 requires 32bit KVNO field at the end of the record
$vno = @()

if($kvno -le 255){
$vno = @([byte]$kvno)
} else {
$vno = @(00)
}

[byte[]]$numComponents = Get-BytesBigEndian -BitSize 16 -Value $components.Count

### To Set TimeStamp To Jan 1, 1970 - [byte[]]$timeStamp = @(0,0,0,0)
### [byte[]]$timeStamp = Get-BytesBigEndian -BitSize 32 -Value ([int]([Math]::Truncate((Get-Date(Get-Date).ToUniversalTime() -UFormat %s))))
### 15 September 2020 Updated
### https://github.com/matherm-aboehm suggested use of [decimal]::Parse to fix timestamp error on localized versions of Windows.
[byte[]]$timeStamp = Get-BytesBigEndian -BitSize 32 -Value ([int]([Math]::Truncate([decimal]::Parse((Get-Date(Get-Date).ToUniversalTime() -UFormat %s)))))

### Data size information for KeyEntry
# num_components bytes   = 2
# realm bytes            = variable (2 bytes) + length
# components array bytes = varable (2 bytes) + length for each component. Component count should be typically 1 or 2.
# name type bytes        = 4
# timestamp bytes        = 4
# kvno bytes             = 1 or 4
# Key Type bytes         = 2
# Key bytes              = 2 + 16 or 32 "RC4 and AES128 are 16 Byte Keys. AES 256 is 32"

$sizeRealm  = Get-BytesBigEndian -Value ([Text.Encoding]::UTF8.GetByteCount($realmString)) -BitSize 16
[Int32]$sizeKeyTabEntry = 2 #NumComponentsSize
$sizeKeyTabEntry += 2 #RealmLength Byte Count 
$sizeKeyTabEntry += ([Text.Encoding]::UTF8.GetByteCount($realmString))
    foreach($principal in $Components){
    $sizePrincipal = ([Text.Encoding]::UTF8.GetByteCount($principal))
    $sizeKeyTabEntry += $sizePrincipal + 2
    }
$sizeKeyTabEntry += 4 #NameType
$sizeKeyTabEntry += 4 #TimeStamp
$sizeKeyTabEntry += 1 #KVNO 8bit
$sizeKeyTabEntry += 2 #KeyType
$sizeKeyTabEntry += 2 #Key Length Count
$sizeKeyTabEntry += $sizeKey

$sizeTotal = Get-BytesBigEndian -Value $sizeKeyTabEntry -BitSize 32

[byte[]] $keytabEntry = @()
$keytabEntry += $sizeTotal
$keytabEntry += $numComponents
$keytabEntry += $sizeRealm
$keytabEntry += [byte[]][Text.Encoding]::UTF8.GetBytes($realmString)
    foreach($principal in $Components){
    $sizePrincipal = Get-BytesBigEndian -Value ([Text.Encoding]::UTF8.GetByteCount($principal)) -BitSize 16
    $keytabEntry += $sizePrincipal
    $keytabEntry += [byte[]][Text.Encoding]::UTF8.GetBytes($principal)
    }
$keytabEntry += $nameType
$keytabEntry += $timeStamp
$keytabEntry += $vno
$keytabEntry += $keyType
$keytabEntry += $sizeKeyBlock
$keytabEntry += Get-ByteArrayFromHexString -HexString $keyBlock

$keytabEntryObject = [PsCustomObject]@{
        Size           = $sizeKeyTabEntry
        NumComponents  = $numComponents
        Realm          = [byte[]][Text.Encoding]::UTF8.GetBytes($realmString)
        Components     = $components
        NameType       = $nameType
        TimeStamp      = $timeStamp
        KeyType        = $keyType
        KeyBlock       = $keyBlock
        KeytabEntry    = $keytabEntry
    }
return $keytabEntryObject
}

Function Get-Password {
    <#
    .SYNOPSIS
        Prompts for a password without echoing input.
    #>

    $passwordSecure = Read-Host -Prompt "Enter Password" -AsSecureString
    $passwordBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($passwordBSTR)

    return $password
}

function Get-KeyTabEntries {
    <#
    .SYNOPSIS
        Parses and lists entries from a keytab file.

    .DESCRIPTION
        Reads a keytab file and displays its contents, including principals,
        encryption types, KVNOs, and timestamps for each entry.

    .PARAMETER FilePath
        Path to the keytab file to read.

    .EXAMPLE
        Get-KeyTabEntries -FilePath "login.keytab"

    .EXAMPLE
        Get-KeyTabEntries -FilePath "C:\temp\service.keytab" | Format-Table

    .NOTES
        Returns an array of custom objects with the following properties:
        - Principal: Full principal name (components@realm)
        - Realm: Kerberos realm
        - Components: Array of principal components
        - PrincipalType: Name type (KRB5_NT_PRINCIPAL, etc.)
        - EncryptionType: Encryption type (RC4-HMAC, AES128-CTS, AES256-CTS)
        - KVNO: Key version number
        - Timestamp: Entry timestamp
        - KeyLength: Length of the key in bytes
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$FilePath
    )

    # Verify file exists
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Keytab file not found: $FilePath"
        return
    }

    # Read the entire file as bytes
    try {
        [byte[]]$fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
    }
    catch {
        Write-Error "Failed to read keytab file: $_"
        return
    }

    # Verify minimum file size (header is 2 bytes)
    if ($fileBytes.Length -lt 2) {
        Write-Error "Invalid keytab file: file too small"
        return
    }

    # Parse and verify header (should be 0x05 0x02 for version 502)
    if ($fileBytes[0] -ne 5 -or $fileBytes[1] -ne 2) {
        Write-Warning "Unexpected keytab version: $($fileBytes[0]).$($fileBytes[1]) (expected 5.2)"
    }

    # Helper function to read big-endian integers
    function Read-BigEndianInt16 {
        param([byte[]]$bytes, [int]$offset)
        return ([int16]$bytes[$offset] -shl 8) -bor $bytes[$offset + 1]
    }

    function Read-BigEndianInt32 {
        param([byte[]]$bytes, [int]$offset)
        return ([int32]$bytes[$offset] -shl 24) -bor
               ([int32]$bytes[$offset + 1] -shl 16) -bor
               ([int32]$bytes[$offset + 2] -shl 8) -bor
               $bytes[$offset + 3]
    }

    # Helper function to convert principal type number to name
    function Get-PrincipalTypeName {
        param([int32]$typeValue)
        switch ($typeValue) {
            1 { return "KRB5_NT_PRINCIPAL" }
            2 { return "KRB5_NT_SRV_INST" }
            3 { return "KRB5_NT_SRV_HST" }
            5 { return "KRB5_NT_UID" }
            default { return "UNKNOWN ($typeValue)" }
        }
    }

    # Helper function to convert encryption type to name
    function Get-EncryptionTypeName {
        param([int16]$keyType)
        switch ($keyType) {
            23 { return "RC4-HMAC" }
            17 { return "AES128-CTS-HMAC-SHA1-96" }
            18 { return "AES256-CTS-HMAC-SHA1-96" }
            default { return "UNKNOWN ($keyType)" }
        }
    }

    # Parse entries
    $entries = @()
    $offset = 2  # Skip header

    while ($offset -lt $fileBytes.Length) {
        # Check if we have enough bytes for entry size field
        if ($offset + 4 -gt $fileBytes.Length) {
            Write-Warning "Incomplete entry at offset $offset (not enough bytes for size field)"
            break
        }

        # Read entry size (4 bytes, big-endian)
        $entrySize = Read-BigEndianInt32 -bytes $fileBytes -offset $offset
        $offset += 4

        # Verify we have enough bytes for the entire entry
        if ($offset + $entrySize -gt $fileBytes.Length) {
            Write-Warning "Incomplete entry at offset $($offset - 4) (size: $entrySize, available: $($fileBytes.Length - $offset))"
            break
        }

        $entryStart = $offset

        try {
            # Read number of components (2 bytes, big-endian)
            $numComponents = Read-BigEndianInt16 -bytes $fileBytes -offset $offset
            $offset += 2

            # Read realm length and realm string
            $realmLength = Read-BigEndianInt16 -bytes $fileBytes -offset $offset
            $offset += 2
            $realm = [Text.Encoding]::UTF8.GetString($fileBytes, $offset, $realmLength)
            $offset += $realmLength

            # Read components
            $components = @()
            for ($i = 0; $i -lt $numComponents; $i++) {
                $componentLength = Read-BigEndianInt16 -bytes $fileBytes -offset $offset
                $offset += 2
                $component = [Text.Encoding]::UTF8.GetString($fileBytes, $offset, $componentLength)
                $components += $component
                $offset += $componentLength
            }

            # Read name type (4 bytes, big-endian)
            $nameTypeValue = Read-BigEndianInt32 -bytes $fileBytes -offset $offset
            $offset += 4
            $principalType = Get-PrincipalTypeName -typeValue $nameTypeValue

            # Read timestamp (4 bytes, big-endian)
            $timestampValue = Read-BigEndianInt32 -bytes $fileBytes -offset $offset
            $offset += 4

            # Convert Unix timestamp to DateTime (handle epoch time 0 specially)
            if ($timestampValue -eq 0) {
                $timestamp = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
            }
            else {
                $timestamp = ([DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).AddSeconds($timestampValue)
            }

            # Read KVNO (1 byte)
            $kvno = $fileBytes[$offset]
            $offset += 1

            # Read key type (2 bytes, big-endian)
            $keyTypeValue = Read-BigEndianInt16 -bytes $fileBytes -offset $offset
            $offset += 2
            $encryptionType = Get-EncryptionTypeName -keyType $keyTypeValue

            # Read key length (2 bytes, big-endian)
            $keyLength = Read-BigEndianInt16 -bytes $fileBytes -offset $offset
            $offset += 2

            # Read key data
            $keyData = $fileBytes[$offset..($offset + $keyLength - 1)]
            $keyHex = Get-HexStringFromByteArray -Data $keyData
            $offset += $keyLength

            # Construct principal name
            $principalName = if ($components.Count -gt 0) {
                ($components -join '/') + '@' + $realm
            }
            else {
                '@' + $realm
            }

            # Create entry object
            $entry = [PSCustomObject]@{
                Principal      = $principalName
                Realm          = $realm
                Components     = $components
                PrincipalType  = $principalType
                EncryptionType = $encryptionType
                KVNO           = $kvno
                Timestamp      = $timestamp
                KeyLength      = $keyLength
                KeyHash        = $keyHex
            }

            $entries += $entry
        }
        catch {
            Write-Warning "Error parsing entry at offset $entryStart`: $_"
            # Skip to next potential entry
            $offset = $entryStart + $entrySize
            continue
        }

        # Verify we consumed exactly the expected number of bytes
        $actualSize = $offset - $entryStart
        if ($actualSize -ne $entrySize) {
            Write-Warning "Entry size mismatch at offset $entryStart (expected: $entrySize, actual: $actualSize)"
        }
    }

    return $entries
}


function Invoke-KeyTabTools {
    <#
    .SYNOPSIS
        Generates one or more keytab entries and writes them to disk.

    .DESCRIPTION
        Wrapper function that accepts parameters typically used with ktpass
        to create offline keytab files. When called as a script, the
        parameters are passed directly from the command line.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,HelpMessage="REALM name will be forced to Upper Case")]$Realm,
        [Parameter(Mandatory=$true,HelpMessage="Principal is case sensative. It must match the principal portion of the UPN",ValueFromPipelineByPropertyName=$true)]$Principal,
        [Parameter(Mandatory=$false)]$Password,
        [Parameter(Mandatory=$false)]$SALT,
        [Parameter(Mandatory=$false)]$File,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)][int]$KVNO,
        [Parameter(Mandatory=$false)][ValidateSet("KRB5_NT_PRINCIPAL", "KRB5_NT_SRV_INST", "KRB5_NT_SRV_HST", "KRB5_NT_UID")][String[]]$PType="KRB5_NT_PRINCIPAL",
        [Parameter(Mandatory=$false)][Switch]$RC4,
        [Parameter(Mandatory=$false)][Switch]$AES128,
        [Parameter(Mandatory=$false)][Switch]$AES256,
        [Parameter(Mandatory=$false)][Switch]$Append,
        [Parameter(Mandatory=$false)][Switch]$Quiet,
    [Parameter(Mandatory=$false)][Switch]$NoPrompt
    )


    if ([string]::IsNullOrEmpty($Password)) { $Password = Get-Password }

    if ([string]::IsNullOrEmpty($File)) { $File = Join-Path -Path (Get-Location) -ChildPath "login.keytab" }

if($Quiet) {
$Script:Silent = $true
} else {
$Script:Silent = $false
}

### Force Realm to UPPERCASE
$Realm = $Realm.ToUpper()

### The Components array splits the primary/principal.
$PrincipalArray = @()
$PrincipalArray = $Principal.Split(',')
### Check For Custom SALT
if([string]::IsNullOrEmpty($SALT) -eq $true) {
$SALT = $Realm
for($i=0;$i -lt $PrincipalArray.Count;$i++){
$SALT += $($PrincipalArray[$i].Replace('/',""))
}

}
### Finish splitting principal into component parts. PrincipalArray should have at most 2 elements. Testing with Java-based tools,
### the keytab entry can only support one UPN. The components portion of the keytab entry appears to only be for splitting
### a UPN in an SPN format. e.g. HOST/user@dev.home
$PrincipalText = $Principal
$Principal = $Principal.Replace('/',",")
$PrincipalArray = @()
$PrincipalArray = $Principal.Split(',')

[byte[]] $keyTabVersion = @(05,02)
[byte[]] $keyTabEntries = @()

### Set Default Encryption to AES256 if none of the E-Type switches are set
if(!$RC4 -and !$AES128 -and !$AES256){
$AES256 = $true
}

### Truncate KVNO
[Byte[]] $KVNO = [Byte[]](Get-BytesBigEndian -BitSize 32 -Value $KVNO)
[int16] $KVNO = [int]$KVNO[3]

### Create KeyTab Entries for selected E-Types RC4/AES128/AES256 supported
$keytabEntry = $null
if($RC4 -eq $true){
$keytabEntry = New-KeyTabEntry `
-realmString $Realm -Components $PrincipalArray -passwordString $Password `
-PrincipalType $PType -EncryptionKeyType RC4 -KVNO $KVNO
$keyTabEntries += $keytabEntry.KeytabEntry
if($Script:Silent -eq $false){ Write-Host "RC4:"$keytabEntry.KeyBlock -ForegroundColor Cyan}
}
$keytabEntry = $null
if($AES128 -eq $true){
$keytabEntry = New-KeyTabEntry `
-realmString $Realm -Components $PrincipalArray -passwordString $Password `
-PrincipalType $PType -EncryptionKeyType AES128 -KVNO $KVNO -SALT $SALT
$keyTabEntries += $keytabEntry.KeytabEntry
if($Script:Silent -eq $false){ Write-Host "AES128:"$keytabEntry.KeyBlock -ForegroundColor Cyan}
}
$keytabEntry = $null
if($AES256 -eq $true){
$keytabEntry = New-KeyTabEntry `
-realmString $Realm -Components $PrincipalArray -passwordString $Password `
-PrincipalType $PType -EncryptionKeyType AES256 -KVNO $KVNO -SALT $SALT
$keyTabEntries += $keytabEntry.KeytabEntry
if($Script:Silent -eq $false){ Write-Host "AES256:"$keytabEntry.KeyBlock -ForegroundColor Cyan}
}

if($Script:Silent -eq $false){
Write-Host $("Principal Type:").PadLeft(15)$PType -ForegroundColor Green
Write-Host $("Realm:").PadLeft(15)$Realm -ForegroundColor Green
Write-Host $("User Name:").PadLeft(15)$PrincipalText -ForegroundColor Green
Write-Host $("SALT:").PadLeft(15)$SALT -ForegroundColor Green
Write-Host $("Keytab File:").PadLeft(15)$File -ForegroundColor Green
Write-Host $("Append File:").PadLeft(15)$Append -ForegroundColor Green
Write-Host ""
}

if(!$NoPrompt){
Write-Host "Press Enter to Write KeyTab File /Ctrl+C to quit..." -ForegroundColor Yellow -NoNewline
[void](Read-Host)
Write-Host ""
}

if($Append -eq $true){
$fileBytes = @()
    if([System.IO.File]::Exists($File)){
    $fileBytes += [System.IO.File]::ReadAllBytes($File) + $keyTabEntries
    [System.IO.File]::WriteAllBytes($File,$fileBytes)
    } else {
    $fileBytes = @()
    $fileBytes += $keyTabVersion
    $fileBytes += $keyTabEntries
    [System.IO.File]::WriteAllBytes($File,$fileBytes)
    }
} else {
$fileBytes = @()
$fileBytes += $keyTabVersion
$fileBytes += $keyTabEntries
[System.IO.File]::WriteAllBytes($File,$fileBytes)
}
}

if ($MyInvocation.InvocationName -ne ".") {
    Invoke-KeyTabTools @PSBoundParameters
}
