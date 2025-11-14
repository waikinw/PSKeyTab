# PowerShell Gallery API Key Setup Guide

This guide will walk you through setting up your PowerShell Gallery API key for automated publishing.

## What is a GitHub Secret?

GitHub Secrets are encrypted environment variables that are stored in your repository settings. They're perfect for storing sensitive data like API keys because:
- ✅ They're encrypted and hidden from public view
- ✅ They're only available to GitHub Actions workflows
- ✅ They never appear in logs
- ✅ They can't be read by pull requests from forks (security!)

## Step-by-Step Setup

### Step 1: Get Your PowerShell Gallery API Key

1. **Go to PowerShell Gallery**
   - Visit: https://www.powershellgallery.com/

2. **Sign In**
   - Click "Sign in" in the top right
   - Use your Microsoft account (same one you use for Azure, Office 365, etc.)
   - If you don't have one, create a Microsoft account first

3. **Navigate to API Keys**
   - After signing in, click your username in the top right
   - Select "API Keys" from the dropdown menu
   - Or go directly to: https://www.powershellgallery.com/account/apikeys

4. **Create a New API Key**
   - Click "Create" or "+ Create"
   - Fill in the form:
     ```
     Key Name:           PSKeyTab Publishing Key
     Select Scopes:      ☑ Push new packages and package versions
                         ☐ Push only new package versions of existing packages
                         ☐ Unlist packages

     Glob Pattern:       KeyTabTools (or * for all packages)

     Expiration:         365 days (recommended)
                         Note: You'll need to regenerate yearly
     ```

5. **Copy the API Key**
   - **IMPORTANT**: Copy the key immediately!
   - It looks like: `oy2abc...xyz123` (long random string)
   - You'll only see it once - if you lose it, you'll need to create a new one
   - Keep it somewhere safe temporarily (like a password manager)

### Step 2: Add the Secret to GitHub

1. **Go to Your GitHub Repository**
   - Navigate to: https://github.com/waikinw/PSKeyTab

2. **Open Settings**
   - Click the "Settings" tab (⚙️ icon at the top)
   - Note: You need admin/write access to the repo

3. **Navigate to Secrets and Variables**
   - In the left sidebar, find "Security" section
   - Click "Secrets and variables"
   - Click "Actions" (this expands to show the submenu)

   The full path is: `Settings` → `Secrets and variables` → `Actions`

4. **Add New Repository Secret**
   - Click the green "New repository secret" button
   - Fill in:
     ```
     Name:  PSGALLERY_API_KEY
            ^^^^^^^^^^^^^^^^^^^^
            Must be EXACTLY this (case-sensitive)

     Secret: oy2abc...xyz123
             (paste the API key you copied from PowerShell Gallery)
     ```

5. **Save the Secret**
   - Click "Add secret"
   - You should see it listed as `PSGALLERY_API_KEY` with a green checkmark

### Step 3: Verify It's Set Up

After adding the secret:

1. Go to your repository secrets page again
   - You should see: `PSGALLERY_API_KEY` with "Updated X seconds ago"

2. You **cannot** view the value again (for security)
   - You'll only see: `PSGALLERY_API_KEY • Updated 1 minute ago`
   - If you need to change it, click "Update" to replace it

3. The secret is now available to your GitHub Actions workflows!

## How It's Used in Your Workflow

In `.github/workflows/publish.yml`, the secret is used like this:

```yaml
- name: Publish to PowerShell Gallery
  shell: pwsh
  env:
    PSGALLERY_API_KEY: ${{ secrets.PSGALLERY_API_KEY }}
    # ^^^^^^^^^^^^^^^^     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    # Environment variable  References your GitHub Secret
  run: |
    Publish-Module -Path . -NuGetApiKey $env:PSGALLERY_API_KEY
```

**What happens:**
1. GitHub Actions reads the secret `PSGALLERY_API_KEY` from your repository
2. It's made available as an environment variable `$env:PSGALLERY_API_KEY`
3. PowerShell uses it to authenticate with PowerShell Gallery
4. Your module gets published!

## Types of Secrets in GitHub

For your reference, here are the different types:

### 1. **Repository Secrets** ✅ (What you're using)
- **Location**: Settings → Secrets and variables → Actions
- **Scope**: Only this repository
- **Best for**: Project-specific keys like your PSGallery API key

### 2. **Environment Secrets**
- **Location**: Settings → Environments → (environment name) → Secrets
- **Scope**: Specific deployment environments (production, staging, etc.)
- **Best for**: Different keys for different environments
- **Example**: Different API keys for test vs production deployments

### 3. **Organization Secrets**
- **Location**: Organization Settings → Secrets and variables → Actions
- **Scope**: All repositories in the organization
- **Best for**: Shared credentials across multiple repos
- **Note**: You need organization admin rights

For this project, **Repository Secrets** is what you need!

## Troubleshooting

### "Secret not found" Error

If the workflow says it can't find the secret:
1. Check the name is EXACTLY: `PSGALLERY_API_KEY` (case-sensitive)
2. Make sure you added it to the correct repository
3. Try updating the secret to refresh it

### "Invalid API Key" Error

If publishing fails with authentication error:
1. The API key may have expired
2. The key might not have "Push" permissions
3. Generate a new key and update the secret

### Can't See Settings Tab

If you don't see the Settings tab:
1. You need write/admin access to the repository
2. Ask the repository owner to add the secret for you
3. Or ask them to grant you admin access

### Testing the Secret

To test if the secret is working, you can:

1. Go to "Actions" tab in your repo
2. Select "Publish to PowerShell Gallery" workflow
3. Click "Run workflow"
4. Select your branch
5. Click "Run workflow"
6. Watch the logs - if the secret is missing, it will fail early

## Security Best Practices

✅ **DO:**
- Use repository secrets for sensitive data
- Set expiration dates on API keys
- Regenerate keys periodically (annually)
- Use minimal permissions (only "Push" for publishing)

❌ **DON'T:**
- Never commit API keys to your repository
- Don't share secrets in issues or pull requests
- Don't use the same API key for multiple purposes
- Don't give your API key to others

## Rotating Your API Key

When your key expires (or if compromised):

1. **Create a new API key** on PowerShell Gallery (same steps as above)
2. **Update the GitHub secret**:
   - Go to Settings → Secrets and variables → Actions
   - Click "Update" next to `PSGALLERY_API_KEY`
   - Paste the new key
   - Click "Update secret"
3. **Delete the old key** from PowerShell Gallery

## Summary Checklist

- [ ] Created Microsoft account (if needed)
- [ ] Signed into PowerShell Gallery
- [ ] Created API key with "Push" permission
- [ ] Copied the API key
- [ ] Added secret to GitHub: `PSGALLERY_API_KEY`
- [ ] Verified secret shows in repository settings
- [ ] Ready to publish! 🚀

## Need Help?

If you get stuck:
1. Check the [RELEASE.md](RELEASE.md) file for more publishing details
2. See [PowerShell Gallery Publishing Docs](https://docs.microsoft.com/en-us/powershell/scripting/gallery/how-to/publishing-packages/publishing-a-package)
3. Open an issue in the repository

---

**You're now ready to publish to PowerShell Gallery!** 🎉
