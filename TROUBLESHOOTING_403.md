# Troubleshooting PowerShell Gallery 403 Error

You're getting: `403 - The specified API key is invalid, has expired, or does not have permission to access the specified package`

The good news: Your module builds successfully! ✅
The issue: API key authentication is failing.

## Possible Causes & Solutions

### 1. API Key Has Wrong Permissions ⚠️ (Most Common)

When you created the API key, you need to select the right scope:

**Go back to PowerShell Gallery and check:**
1. Visit: https://www.powershellgallery.com/account/apikeys
2. Find your API key for KeyTabTools
3. Check the **Scopes** - it should have:
   - ☑ **Push new packages and package versions** ← MUST be checked!
   - NOT just "Push only new package versions of existing packages"

**If wrong:**
- Delete the old key
- Create a new one with the correct scope
- Update the GitHub secret

### 2. Glob Pattern Restriction 🎯

Your API key might have a glob pattern that doesn't match "KeyTabTools"

**Check in PowerShell Gallery:**
1. Go to: https://www.powershellgallery.com/account/apikeys
2. Look at the **Glob Pattern** for your key
3. It should be either:
   - `KeyTabTools` (exact match)
   - `*` (all packages)

**If it's something else** (like a different package name):
- Update the glob pattern, or
- Create a new key with the correct pattern

### 3. API Key Expired ⏰

Check the expiration date of your API key:
1. Go to: https://www.powershellgallery.com/account/apikeys
2. Look at the **Expires** column
3. If expired or close to expiring, create a new one

### 4. GitHub Secret Not Set Correctly 🔐

Verify the secret is set in GitHub:
1. Go to: https://github.com/waikinw/PSKeyTab/settings/secrets/actions
2. You should see: `PSGALLERY_API_KEY`
3. If not there or wrong, add/update it

### 5. First-Time Publishing Requires "Push New Packages" Permission 🆕

Since "KeyTabTools" doesn't exist on PowerShell Gallery yet, you need the permission to create new packages.

**Make sure your API key has:**
```
Scope: Push new packages and package versions
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
       This is required for first-time publish!
```

NOT just:
```
Scope: Push only new package versions of existing packages
       (This won't work for first-time publish)
```

## Step-by-Step Fix

### Option 1: Create a New API Key (Recommended)

1. **Go to PowerShell Gallery**
   - https://www.powershellgallery.com/account/apikeys

2. **Delete the old key** (if it exists)
   - Click the trash icon next to your old key

3. **Create a new key:**
   ```
   Key Name:        KeyTabTools Publisher

   Select Scopes:   ☑ Push new packages and package versions
                    ☐ Push only new package versions...
                    ☐ Unlist packages

   Glob Pattern:    KeyTabTools
                    (or * for all packages)

   Expiration:      365 days
   ```

4. **Copy the new API key**
   - It looks like: `oy2abc...xyz123`
   - Copy it immediately (you won't see it again!)

5. **Update GitHub Secret:**
   - Go to: https://github.com/waikinw/PSKeyTab/settings/secrets/actions
   - Click `PSGALLERY_API_KEY`
   - Click "Update"
   - Paste the new key
   - Click "Update secret"

6. **Retry the workflow:**
   - Go to Actions → "Publish to PowerShell Gallery"
   - Click "Run workflow"

### Option 2: Verify Existing Key

1. **Check your key on PowerShell Gallery:**
   - Go to: https://www.powershellgallery.com/account/apikeys
   - Verify:
     - ✅ Scope: "Push new packages and package versions"
     - ✅ Glob Pattern: `KeyTabTools` or `*`
     - ✅ Not expired

2. **If everything looks good, try regenerating:**
   - Click "Regenerate" on the key
   - Copy the new key value
   - Update GitHub secret
   - Retry

## Quick Verification Checklist

- [ ] API key has "Push new packages and package versions" scope
- [ ] Glob pattern is `KeyTabTools` or `*`
- [ ] API key is not expired
- [ ] GitHub secret `PSGALLERY_API_KEY` is set correctly
- [ ] You've copied the ENTIRE key (they're long!)

## Common Mistakes to Avoid

❌ **Wrong Scope**
- Using "Push only new package versions..." won't work for first publish

❌ **Wrong Pattern**
- Having a pattern for a different package name

❌ **Partial Key**
- Not copying the entire API key (they're very long)

❌ **Old Key**
- Using an expired key

## Testing

After updating the API key:

1. Go to: https://github.com/waikinw/PSKeyTab/actions
2. Select "Publish to PowerShell Gallery"
3. Click "Run workflow"
4. Watch the logs

If it still fails with 403, the issue is definitely with the API key permissions.

## Need More Help?

If you're still stuck, share:
1. Screenshot of your API key settings (hide the actual key!)
2. The scope and glob pattern you used
3. Whether the key is expired

---

**Most likely fix:** Create a new API key with "Push new packages and package versions" scope! 🔑
