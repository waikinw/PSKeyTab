# CLAUDE.md - AI Assistant Guide for KeyTabTools

This document provides comprehensive guidance for AI assistants (like Claude) working with the KeyTabTools PowerShell module codebase.

## Table of Contents

- [Project Overview](#project-overview)
- [Codebase Structure](#codebase-structure)
- [Development Environment](#development-environment)
- [Testing Strategy](#testing-strategy)
- [Development Workflows](#development-workflows)
- [Coding Conventions](#coding-conventions)
- [Common Tasks](#common-tasks)
- [Release Process](#release-process)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

---

## Project Overview

**KeyTabTools** is a cross-platform PowerShell module for generating offline Kerberos keytab files as an alternative to Microsoft's `ktpass` tool.

### Key Facts

- **Language**: PowerShell 5.1+
- **Platform**: Cross-platform (Windows, Linux, macOS)
- **Module Version**: 1.3.0
- **License**: MIT
- **Original Author**: Adam Burford (TRAB)
- **Current Maintainer**: waikinw
- **Repository**: https://github.com/waikinw/PSKeyTab
- **PowerShell Gallery**: https://www.powershellgallery.com/packages/KeyTabTools

### Core Functionality

The module generates Kerberos keytab files supporting:
- **RC4-HMAC** encryption
- **AES-128** encryption
- **AES-256** encryption (default)
- Offline generation (no Active Directory connection required)
- Multiple principal types (user accounts, service principals)

### Project History

This is a derivative work based on Adam Burford's [Create-KeyTab](https://github.com/TheRealAdamBurford/Create-KeyTab) project, developed as an independent repository with significant enhancements:
- Comprehensive test coverage (60+ tests)
- PowerShell Gallery publication support
- CI/CD automation with GitHub Actions
- Enhanced documentation and module structure
- Cross-platform verification

---

## Codebase Structure

### Repository Layout

```
PSKeyTab/
├── .github/
│   └── workflows/          # GitHub Actions CI/CD workflows
│       ├── pester.yml      # Test automation (push/PR)
│       ├── release.yml     # GitHub release creation
│       └── publish.yml     # PowerShell Gallery publishing
├── docs/                   # GitHub Pages documentation
├── tests/
│   └── KeyTabTools.Tests.ps1  # Pester test suite (60+ tests)
├── KeyTabTools.ps1         # Main script (906 lines)
├── KeyTabTools.psm1        # Module wrapper (loads .ps1)
├── KeyTabTools.psd1        # Module manifest
├── Test-Module.ps1         # Quick verification script
├── Invoke-ScriptAnalyzer.ps1  # Code quality checker
├── README.md               # User documentation
├── CONTRIBUTING.md         # Contribution guidelines
├── CHANGELOG.md            # Version history
├── RELEASE.md              # Release process documentation
├── PSGALLERY_SETUP.md      # PowerShell Gallery setup guide
└── LICENSE                 # MIT license
```

### Key Files Explained

#### Core Module Files

1. **KeyTabTools.ps1** (906 lines)
   - Main implementation file
   - Contains all function definitions
   - Can be run as standalone script OR imported as module
   - Includes cryptographic functions (MD4, PBKDF2, AES)
   - Main entry point: `Invoke-KeyTabTools`

2. **KeyTabTools.psm1** (3 lines)
   - Module wrapper that dot-sources KeyTabTools.ps1
   - Simple: `. $PSScriptRoot\KeyTabTools.ps1`

3. **KeyTabTools.psd1**
   - Module manifest with metadata
   - Defines exported functions (11 functions)
   - PowerShell Gallery tags and URLs
   - Current version: 1.3.0

#### Testing & Quality

1. **tests/KeyTabTools.Tests.ps1**
   - Pester test suite
   - 60+ comprehensive tests
   - Covers all major functions
   - Integration and unit tests

2. **Test-Module.ps1**
   - Quick smoke test (5 tests)
   - Verifies module can be imported
   - Tests basic functionality
   - Used for rapid validation

3. **Invoke-ScriptAnalyzer.ps1**
   - Code quality analysis
   - Runs PSScriptAnalyzer
   - Reports errors, warnings, info
   - Optional `-Fix` parameter for auto-fixes

#### CI/CD Workflows

1. **.github/workflows/pester.yml**
   - Runs on: push, pull_request
   - Jobs: test, analyze, verify
   - Platform: Windows latest
   - Uploads test results as artifacts

2. **.github/workflows/release.yml**
   - Runs on: version tags (v*)
   - Creates GitHub release
   - Builds release package (ZIP)
   - Extracts release notes from CHANGELOG.md
   - Requires all tests to pass

3. **.github/workflows/publish.yml**
   - Runs on: release published OR manual trigger
   - Publishes to PowerShell Gallery
   - Requires `PSGALLERY_API_KEY` secret
   - Validates manifest before publishing
   - Runs tests before publishing

### Exported Functions

The module exports 11 functions (defined in KeyTabTools.psd1):

**Main Function:**
- `Invoke-KeyTabTools` - Generate keytab files

**Cryptographic Functions:**
- `Get-MD4` - Calculate MD4 hash (for RC4)
- `Get-PBKDF2` - Derive keys using PBKDF2
- `Protect-Aes` - AES encryption helper
- `Get-AES128Key` - Generate AES-128 key
- `Get-AES256Key` - Generate AES-256 key

**Utility Functions:**
- `Get-HexStringFromByteArray` - Convert bytes to hex string
- `Get-ByteArrayFromHexString` - Convert hex string to bytes
- `Get-BytesBigEndian` - Convert integers to big-endian bytes
- `Get-PrincipalType` - Get principal type numeric value
- `New-KeyTabEntry` - Create a single keytab entry

---

## Development Environment

### Prerequisites

- **PowerShell**: 5.1 or later
- **Pester**: Testing framework (auto-installed in CI)
- **PSScriptAnalyzer**: Code quality tool (auto-installed in CI)
- **Git**: Version control

### Initial Setup

```powershell
# Clone the repository
git clone https://github.com/waikinw/PSKeyTab.git
cd PSKeyTab

# Import the module for development
Import-Module ./KeyTabTools.psd1 -Force

# Verify installation
Get-Command -Module KeyTabTools
```

### Development Tools

**Quick Verification:**
```powershell
./Test-Module.ps1
```

**Run All Tests:**
```powershell
Invoke-Pester
```

**Code Quality Check:**
```powershell
./Invoke-ScriptAnalyzer.ps1

# Auto-fix issues (use with caution)
./Invoke-ScriptAnalyzer.ps1 -Fix
```

---

## Testing Strategy

### Test Structure

The project uses **Pester** for testing with two levels:

#### 1. Quick Smoke Tests (Test-Module.ps1)
- 5 quick verification tests
- Module import validation
- Function export checks
- Basic cryptographic function tests
- Keytab entry generation test
- File creation test
- Runs in ~2-5 seconds

#### 2. Comprehensive Test Suite (tests/KeyTabTools.Tests.ps1)
- 60+ detailed tests
- Module import tests
- Utility function tests (hex conversion, byte arrays, etc.)
- Cryptographic function tests (MD4, PBKDF2, AES)
- Keytab entry generation tests
- Integration tests for full keytab creation
- Edge case handling
- Runs in ~10-30 seconds

### Running Tests

```powershell
# Quick smoke test
./Test-Module.ps1

# Full Pester suite
Invoke-Pester

# With detailed output
Invoke-Pester -Output Detailed

# CI mode (generates XML)
Invoke-Pester -Output Detailed -CI

# Specific tests by tag (if implemented)
Invoke-Pester -TagFilter 'Integration'
```

### Test Coverage

The test suite covers:
- ✅ Module import and export validation
- ✅ Hex string conversions
- ✅ Byte array operations
- ✅ Big-endian conversions
- ✅ MD4 hash calculations
- ✅ PBKDF2 key derivation
- ✅ AES encryption (128 & 256)
- ✅ Principal type mapping
- ✅ Keytab entry generation (all encryption types)
- ✅ Full keytab file creation
- ✅ File append functionality
- ✅ Custom SALT handling
- ✅ Custom KVNO values
- ✅ Different principal types

### CI/CD Testing

**On every push/PR:**
1. Pester tests run on Windows latest
2. PSScriptAnalyzer code quality checks
3. Quick verification with Test-Module.ps1
4. Test results uploaded as artifacts

**Before releases:**
1. All tests must pass
2. No critical PSScriptAnalyzer errors
3. Module manifest validation

---

## Development Workflows

### Making Changes

```powershell
# 1. Create a feature branch
git checkout -b feature/your-feature-name

# 2. Make your changes to KeyTabTools.ps1

# 3. Test your changes
./Test-Module.ps1
Invoke-Pester

# 4. Check code quality
./Invoke-ScriptAnalyzer.ps1

# 5. Commit and push
git add .
git commit -m "Description of changes"
git push origin feature/your-feature-name

# 6. Create PR on GitHub
```

### Git Branch Strategy

- **main**: Stable, production-ready code
- **feature/***: New features
- **bugfix/***: Bug fixes
- **release/***: Release preparation

### CI/CD Pipeline

**On Push/PR:**
```
push → pester.yml → [test, analyze, verify] → ✅/❌
```

**On Version Tag:**
```
git tag v1.3.0 → release.yml → [tests, build, release] → GitHub Release
```

**Publishing:**
```
Release published → publish.yml → [tests, validate, publish] → PowerShell Gallery
```

---

## Coding Conventions

### PowerShell Best Practices

1. **Function Naming**
   - Use approved verbs: `Get-`, `New-`, `Invoke-`, `Protect-`
   - Pascal case: `Get-AES256Key`, not `get-aes256key`

2. **Parameter Naming**
   - Pascal case: `-PasswordString`, `-RealmString`
   - Use descriptive names
   - Mark mandatory parameters appropriately

3. **Comments & Documentation**
   - Use `<#.SYNOPSIS#>` blocks for all functions
   - Include `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
   - Inline comments for complex logic

4. **Error Handling**
   - Use `try/catch` blocks
   - Provide meaningful error messages
   - Use `-ErrorAction` appropriately

5. **Code Style**
   - 4-space indentation
   - Opening braces on same line
   - Use explicit parameter names in function calls

### Module-Specific Conventions

1. **Encryption Functions**
   - Always validate input lengths
   - Use byte arrays for cryptographic operations
   - Convert strings to bytes explicitly (UTF-8)

2. **Keytab Generation**
   - SALT calculation is critical for AES
   - Realm is always uppercase
   - Principal case sensitivity matters for AES
   - Default encryption: AES256 if none specified

3. **File Operations**
   - Use `[System.IO.File]::WriteAllBytes()` for keytabs
   - Support `-Append` mode properly
   - Prompt before overwriting (unless `-NoPrompt`)

4. **Testing Conventions**
   - Test descriptions use single quotes
   - Use `Should -Be`, `Should -Not -BeNullOrEmpty`
   - Test both success and error cases
   - Clean up temporary files in tests

---

## Common Tasks

### Adding a New Function

1. **Add to KeyTabTools.ps1:**
```powershell
function Get-NewFunction {
    <#
    .SYNOPSIS
        Brief description
    .DESCRIPTION
        Detailed description
    .PARAMETER ParameterName
        Parameter description
    .EXAMPLE
        Get-NewFunction -ParameterName "value"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ParameterName
    )

    # Implementation
}
```

2. **Export in KeyTabTools.psd1:**
```powershell
FunctionsToExport = @(
    'Get-MD4',
    # ... existing functions ...
    'Get-NewFunction'  # Add here
)
```

3. **Add Tests:**
```powershell
Describe 'Get-NewFunction' {
    It 'does something correctly' {
        $result = Get-NewFunction -ParameterName "test"
        $result | Should -Be "expected"
    }
}
```

4. **Update Documentation:**
- Add to README.md in "Exported Functions" section
- Add usage examples if public-facing
- Update CHANGELOG.md

### Fixing a Bug

1. **Write a failing test first** (TDD approach)
2. Fix the bug in KeyTabTools.ps1
3. Verify test now passes
4. Run full test suite
5. Check code quality
6. Update CHANGELOG.md

### Updating Documentation

**User-Facing:**
- README.md - Primary user documentation
- CONTRIBUTING.md - Contribution guidelines

**Developer-Facing:**
- CLAUDE.md (this file) - AI assistant guide
- RELEASE.md - Release process
- PSGALLERY_SETUP.md - Gallery setup

**Code Documentation:**
- Inline comments in KeyTabTools.ps1
- Function synopsis blocks

---

## Release Process

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., 1.3.0)
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Creating a Release

**Pre-Release Checklist:**
- [ ] All tests pass: `Invoke-Pester`
- [ ] Code quality check: `./Invoke-ScriptAnalyzer.ps1`
- [ ] Update version in `KeyTabTools.psd1`
- [ ] Update `CHANGELOG.md` with changes
- [ ] Commit all changes

**Release Steps:**

```bash
# 1. Update version
# Edit KeyTabTools.psd1: ModuleVersion = '1.4.0'

# 2. Update changelog
# Edit CHANGELOG.md with new version section

# 3. Commit changes
git add KeyTabTools.psd1 CHANGELOG.md
git commit -m "Bump version to 1.4.0"
git push

# 4. Create and push tag
git tag v1.4.0
git push origin v1.4.0

# 5. GitHub Actions automatically:
#    - Runs all tests
#    - Creates GitHub release
#    - Builds release package
```

**Publishing to PowerShell Gallery:**

Option 1: Automatic (after GitHub release)
- Workflow triggers on release published
- Tests run automatically
- Published if tests pass

Option 2: Manual trigger
- Go to Actions → "Publish to PowerShell Gallery"
- Click "Run workflow"
- Select branch
- Click "Run workflow"

### Release Artifacts

Each release includes:
- GitHub release with tag
- ZIP file with module files
- Release notes from CHANGELOG.md
- PowerShell Gallery package (after manual publish)

---

## AI Assistant Guidelines

### Context for AI Assistants

When working with this codebase, AI assistants should:

#### 1. Understand the Domain

**Kerberos Concepts:**
- **Keytab files**: Binary files containing principal/key pairs
- **Realm**: Kerberos domain (always uppercase, e.g., EXAMPLE.COM)
- **Principal**: User or service identity (case-sensitive for AES)
- **SALT**: Used in key derivation (critical for AES)
- **KVNO**: Key version number (1-255)
- **Principal Types**: KRB5_NT_PRINCIPAL, KRB5_NT_SRV_HST, etc.

**Encryption Types:**
- **RC4-HMAC**: Uses MD4 hash, less secure but compatible
- **AES-128**: 128-bit AES with PBKDF2 key derivation
- **AES-256**: 256-bit AES (default), most secure

#### 2. Code Modification Guidelines

**DO:**
- ✅ Run tests before AND after changes
- ✅ Update tests when adding features
- ✅ Follow existing code style
- ✅ Add appropriate error handling
- ✅ Update CHANGELOG.md for user-facing changes
- ✅ Validate cryptographic operations carefully
- ✅ Test with multiple encryption types

**DON'T:**
- ❌ Modify cryptographic algorithms without testing
- ❌ Change function signatures without updating tests
- ❌ Skip code quality checks
- ❌ Modify exported functions without updating manifest
- ❌ Break backward compatibility without version bump
- ❌ Commit without running `./Test-Module.ps1`

#### 3. Testing Requirements

**Always run:**
```powershell
# Quick check
./Test-Module.ps1

# Full validation
Invoke-Pester
./Invoke-ScriptAnalyzer.ps1
```

**Before suggesting code:**
- Consider impact on existing functionality
- Think about test coverage
- Verify PowerShell version compatibility (5.1+)
- Consider cross-platform implications

#### 4. Security Considerations

**CRITICAL SECURITY AREAS:**
- Password handling (use SecureString where appropriate)
- Cryptographic implementations (MD4, PBKDF2, AES)
- File permissions on keytab files
- SALT calculation (affects key derivation)
- Byte array operations (endianness matters)

**When modifying crypto code:**
1. Understand the RFC/spec (RFC 3961 for Kerberos)
2. Test against known good values
3. Verify with multiple encryption types
4. Check for side-channel vulnerabilities

#### 5. Common Pitfalls to Avoid

**Keytab Format:**
- Keytab files are binary, not text
- Header must be `0x05 0x02` (version 502)
- All multi-byte integers are big-endian
- Entry format is strictly defined

**SALT Calculation:**
- User accounts: `REALM + principal`
- Computer accounts: `REALM + "host" + hostname.lowercaserealm`
- Minimum 8 bytes for AES
- Case sensitivity matters

**Principal Parsing:**
- Service principals may contain `/` (e.g., `http/server.example.com`)
- Slash is NOT included in SALT
- Components are split into array for keytab entry

**PowerShell Quirks:**
- Byte arrays need explicit casting
- String encoding matters (UTF-8 for Kerberos)
- `+=` on arrays is inefficient (creates new array)
- Use `[System.IO.File]::` for binary operations

#### 6. Documentation Standards

**When adding features:**
1. Add function synopsis/description
2. Update README.md with examples
3. Add entry to CHANGELOG.md
4. Update this CLAUDE.md if workflow changes
5. Add Pester tests
6. Consider adding to Test-Module.ps1 if critical

**Documentation locations:**
- User guide: README.md
- API reference: Function synopsis blocks
- Developer guide: CLAUDE.md (this file)
- Release notes: CHANGELOG.md
- Process docs: RELEASE.md, CONTRIBUTING.md

#### 7. Debugging Tips

**Common issues:**

1. **"Module not found"**
   - Use full path: `Import-Module ./KeyTabTools.psd1`
   - Check manifest exports

2. **Authentication fails with keytab**
   - Verify principal case matches AD
   - Check SALT calculation
   - Try RC4 instead of AES (less strict)
   - Verify KVNO matches AD

3. **Tests fail after changes**
   - Run `./Test-Module.ps1` first
   - Check if function signature changed
   - Verify exported functions in .psd1
   - Look for byte array issues

4. **PSScriptAnalyzer errors**
   - Use `-Fix` flag cautiously
   - Some warnings may be acceptable
   - Zero errors required for CI

#### 8. File Modification Priority

**Frequently modified:**
- KeyTabTools.ps1 (main implementation)
- tests/KeyTabTools.Tests.ps1 (test suite)
- CHANGELOG.md (version history)
- README.md (user documentation)

**Occasionally modified:**
- KeyTabTools.psd1 (version, exports)
- Test-Module.ps1 (add critical tests)
- CLAUDE.md (workflow changes)

**Rarely modified:**
- KeyTabTools.psm1 (simple wrapper)
- .github/workflows/*.yml (CI/CD)
- RELEASE.md, CONTRIBUTING.md (process docs)

---

## Additional Resources

### Official Documentation

- [PowerShell Gallery - KeyTabTools](https://www.powershellgallery.com/packages/KeyTabTools)
- [GitHub Repository](https://github.com/waikinw/PSKeyTab)
- [Original Create-KeyTab by Adam Burford](https://github.com/TheRealAdamBurford/Create-KeyTab)

### Kerberos References

- [RFC 3961 - Kerberos Encryption Types](https://tools.ietf.org/html/rfc3961)
- [MS-KILE - Kerberos Protocol Extensions](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-kile/)
- [MIT Kerberos Documentation](https://web.mit.edu/kerberos/krb5-latest/doc/)
- [Keytab File Format](http://www.ioplex.com/utilities/keytab.txt)

### PowerShell References

- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
- [Pester Documentation](https://pester.dev/)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)

---

## Changelog for CLAUDE.md

**v1.0.0 - 2024-11-14**
- Initial creation of comprehensive AI assistant guide
- Documented codebase structure and development workflows
- Added testing strategy and coding conventions
- Included release process and common tasks
- Provided security considerations and debugging tips

---

*This document should be updated whenever significant changes are made to the project structure, workflows, or conventions.*
