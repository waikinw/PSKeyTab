# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2024-11-14

### Added
- **NEW FEATURE**: `Get-KeyTabEntries` function to parse and list entries from existing keytab files
  - Read and analyze keytab file contents
  - Display principal names, encryption types, KVNOs, and timestamps
  - Support for all encryption types (RC4-HMAC, AES128, AES256)
  - Export capabilities for analysis (CSV, filtering, etc.)
  - Comprehensive error handling for corrupt or invalid files
- Added 9 new comprehensive tests for `Get-KeyTabEntries` function
- Added example usage in README.md (Example 8: Listing Keytab Entries)

### Documentation
- Updated README.md with `Get-KeyTabEntries` usage examples
- Added detailed documentation for parsing keytab files
- Updated exported functions list in module documentation

### Fixed
- Test reliability: Explicitly set KVNO values in tests to ensure consistent behavior

## [1.3.0] - 2024-11-14

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

### Infrastructure
- PowerShell Gallery publishing workflow
- GitHub release automation with artifacts
- Enhanced module manifest with PSGallery metadata
- Comprehensive release documentation

## [1.2.0] - 2024-11-13
- Added PowerShell module wrapper `KeyTabTools.psm1`.
- Introduced Pester test framework with a basic unit test.
- Added GitHub Actions workflow for running tests.
- Created contributing guidelines and changelog.
