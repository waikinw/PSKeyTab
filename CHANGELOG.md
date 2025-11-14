# Changelog

## 1.3.0 (Unreleased)

### Fixed
- **CRITICAL**: Added `Invoke-KeyTabTools` to module exports - module can now be properly imported and used
- Module now works correctly when imported via `Import-Module`

### Added
- Comprehensive Pester test suite with 60+ tests covering all functions
- `Test-Module.ps1` - Quick verification script to check if module is working
- `Invoke-ScriptAnalyzer.ps1` - Code quality analysis tool
- Extensive README documentation with:
  - 7 detailed usage examples
  - Troubleshooting guide
  - Parameter reference tables
  - Advanced usage scenarios
  - Integration examples
- Enhanced GitHub Actions CI pipeline with:
  - Pester test execution
  - PSScriptAnalyzer code quality checks
  - Module verification tests

### Improved
- All major functions now have comprehensive test coverage
- Better module structure and organization
- Clearer usage documentation and examples

### Testing
- Integration tests for keytab file generation
- Unit tests for all cryptographic functions
- Helper function tests
- Module import and export validation

## 1.2.0
- Added PowerShell module wrapper `KeyTabTools.psm1`.
- Introduced Pester test framework with a basic unit test.
- Added GitHub Actions workflow for running tests.
- Created contributing guidelines and changelog.
