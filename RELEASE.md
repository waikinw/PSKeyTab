# Release Process

This document describes how to create a new release of KeyTabTools.

## Prerequisites

Before creating a release, ensure:

1. All tests pass (`Invoke-Pester`)
2. Code quality checks pass (`./Invoke-ScriptAnalyzer.ps1`)
3. CHANGELOG.md is updated with the new version
4. Module version in `KeyTabTools.psd1` is updated
5. All changes are committed and pushed

## Publishing to PowerShell Gallery

### One-Time Setup

1. Create a PowerShell Gallery API key:
   - Go to https://www.powershellgallery.com/
   - Sign in with your Microsoft account
   - Go to "API Keys" in your account
   - Create a new API key with "Push" permission
   - Set expiration (recommended: 365 days)

2. Add the API key to GitHub Secrets:
   - Go to your repository settings
   - Navigate to "Secrets and variables" → "Actions"
   - Create a new secret named `PSGALLERY_API_KEY`
   - Paste your PowerShell Gallery API key

### Automatic Publishing (Recommended)

**Method 1: Create a GitHub Release**

1. Create and push a version tag:
   ```bash
   git tag v1.3.0
   git push origin v1.3.0
   ```

2. The `release.yml` workflow will automatically:
   - Run all tests
   - Create a GitHub release with artifacts
   - The release package will be available for download

3. To publish to PowerShell Gallery:
   - Go to Actions → "Publish to PowerShell Gallery"
   - Click "Run workflow"
   - The module will be published automatically

**Method 2: Manual Workflow Trigger**

1. Go to "Actions" → "Publish to PowerShell Gallery"
2. Click "Run workflow"
3. Select the branch (usually `main`)
4. Click "Run workflow"

### Manual Publishing (Alternative)

If you prefer to publish manually:

```powershell
# Test the module manifest
Test-ModuleManifest -Path ./KeyTabTools.psd1

# Publish to PowerShell Gallery
Publish-Module -Path . -NuGetApiKey "YOUR_API_KEY" -Verbose

# Or publish to a test repository first
Publish-Module -Path . -NuGetApiKey "YOUR_API_KEY" -Repository PSGalleryTest -Verbose
```

## Creating a GitHub Release

### Automatic (Recommended)

Create and push a version tag:

```bash
# Create a tag matching the module version
git tag v1.3.0 -m "Release version 1.3.0"

# Push the tag to GitHub
git push origin v1.3.0
```

The `release.yml` workflow will automatically:
- Run all tests
- Build the release package
- Create a GitHub release
- Attach the module ZIP file
- Extract release notes from CHANGELOG.md

### Manual

1. Go to GitHub repository → "Releases"
2. Click "Draft a new release"
3. Create a new tag (e.g., `v1.3.0`)
4. Set release title: `Release v1.3.0`
5. Copy release notes from CHANGELOG.md
6. Attach the module ZIP file (optional)
7. Click "Publish release"

## Release Checklist

Use this checklist for each release:

- [ ] Update version in `KeyTabTools.psd1`
- [ ] Update `CHANGELOG.md` with new version and changes
- [ ] Run `Invoke-Pester` - all tests pass
- [ ] Run `./Invoke-ScriptAnalyzer.ps1` - no critical issues
- [ ] Run `./Test-Module.ps1` - verification passes
- [ ] Commit all changes
- [ ] Push to GitHub
- [ ] Create and push version tag (`git tag v1.3.0 && git push origin v1.3.0`)
- [ ] Verify GitHub release was created automatically
- [ ] Verify CI/CD pipeline passes
- [ ] Publish to PowerShell Gallery (manually or via workflow)
- [ ] Verify module appears on PowerShell Gallery
- [ ] Test installation: `Install-Module KeyTabTools -Force`
- [ ] Update main branch if released from feature branch

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., 1.3.0)
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

Examples:
- `1.3.0` → `1.3.1` - Bug fix
- `1.3.1` → `1.4.0` - New feature
- `1.4.0` → `2.0.0` - Breaking change

## Troubleshooting

### "Module already exists" error

If you get an error that the module version already exists:

1. Update the version number in `KeyTabTools.psd1`
2. You cannot republish the same version to PowerShell Gallery
3. You must increment the version

### "API key is invalid" error

1. Check that the `PSGALLERY_API_KEY` secret is set correctly
2. Verify the API key hasn't expired
3. Regenerate the API key if needed

### Tests fail during release

1. Run `Invoke-Pester` locally to identify failures
2. Fix the issues
3. Commit and push
4. Retry the release

### GitHub release not created

1. Check that you pushed the tag: `git push origin v1.3.0`
2. Verify the tag name starts with `v` (e.g., `v1.3.0`, not `1.3.0`)
3. Check the Actions tab for workflow errors

## Post-Release

After publishing a release:

1. Announce the release (if applicable)
2. Monitor for issues
3. Update documentation if needed
4. Plan next release

## Resources

- [PowerShell Gallery Publishing Guide](https://docs.microsoft.com/en-us/powershell/scripting/gallery/how-to/publishing-packages/publishing-a-package)
- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [Semantic Versioning](https://semver.org/)
