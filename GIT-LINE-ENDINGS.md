# Git Line Ending Configuration for Windows

## The Problem
```
warning: in the working copy of '.mcp.json', LF will be replaced by CRLF the next time Git touches it
```

## The Solution

### **Option 1: Disable Auto-CRLF (Recommended)**
```bash
# Disable automatic LF ↔ CRLF conversion
git config --global core.autocrlf false

# Force LF line endings
git config --global core.eol lf
```

### **Option 2: Use Auto-CRLF Properly**
```bash
# Keep autocrlf but set it to handle the conversion correctly
git config --global core.autocrlf true

# Set checkout behavior
git config --global core.autocrlf input
```

## Apply to Existing Repositories

After configuring git settings, refresh your repositories:

```bash
# Go to your repo
cd /path/to/your/repo

# Refresh all files with correct line endings
git add --renormalize .

# Commit the normalization
git commit -m "Normalize line endings"
```

## Verify Configuration

```bash
# Check current settings
git config --global --get core.autocrlf
git config --global --get core.eol
git config --global --list
```

## Recommended Configuration

For Windows development with cross-platform projects:

```bash
# .gitconfig global settings
git config --global core.autocrlf false
git config --global core.eol lf
git config --global core.safecrlf false
```

This means:
- **autocrlf false**: Don't do any line ending conversion
- **eol lf**: Use LF line endings
- **safecrlf false**: Don't refuse to convert mixed line endings
