# Contributing

Thank you for considering contributing to KeyTabTools!

## Development setup
1. Ensure PowerShell 5.1 or newer is installed.
2. Clone the repository and import the module manifest:
   ```powershell
   Import-Module ./KeyTabTools.psd1
   ```
3. Run tests with Pester:
   ```powershell
   Invoke-Pester
   ```

## Pull requests
- Create a feature branch based on `main`.
- Include tests for new functionality.
- Ensure `Invoke-Pester` succeeds before submitting.
