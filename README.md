# KeyTabTools

KeyTabTools is a PowerShell utility for generating offline keytab files for Active Directory accounts. It can be used on any system with PowerShell and does not require direct domain access.

## Requirements

- PowerShell 5.1 or later
- Knowledge of the account password and UPN or service principal name

## Installation

Clone this repository and import the module:

```powershell
Import-Module ./KeyTabTools.psd1
```

Alternatively, you can run the script directly:

```powershell
./KeyTabTools.ps1 -Realm DEV.HOME -Principal http/AppService -AES256
```

## Usage

When imported as a module, the helper functions become available. To generate a keytab via the script, run it with the desired parameters. Default encryption is AES256.

```powershell
./KeyTabTools.ps1 -Realm DEV.HOME -Principal user@dev.home -File .\login.keytab
```

See the [documentation site](https://therealadamburford.github.io/Create-KeyTab/) for detailed examples and parameter explanations.

