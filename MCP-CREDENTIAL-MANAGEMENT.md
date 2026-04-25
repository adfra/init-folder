# MCP Server Credential Management Guide

## 🔐 The Security Problem

You're absolutely right to be concerned! **`.mcp.json` files are committed to git**, so they should **NEVER contain credentials**.

## ✅ The Solution: Split Configuration Pattern

### **Pattern: `.mcp.json` + `.mcp.local.json`**

**Public Configuration** (committed to git):
```json
// .mcp.json
{
  "mcpServers": {
    "firefly-iii": {
      "command": "node",
      "args": ["~/.claude/mcp/firefly-iii/index.js"],
      "env": {
        "FIREFLY_URL": "${FIREFLY_URL}",
        "FIREFLY_TOKEN": "${FIREFLY_TOKEN}"
      }
    },
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp"
    }
  }
}
```

**Private Credentials** (NOT committed to git):
```json
// .mcp.local.json
{
  "mcpServers": {
    "firefly-iii": {
      "command": "node",
      "args": ["~/.claude/mcp/firefly-iii/index.js"],
      "env": {
        "FIREFLY_URL": "https://your-firefly-instance.com",
        "FIREFLY_TOKEN": "your-secret-token-here"
      }
    },
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp",
      "headers": {
        "Authorization": "Bearer your-supabase-token"
      }
    }
  }
}
```

## 🛡️ How It Works

### **1. .gitignore Protection**
```gitignore
# ... existing rules ...

# Local MCP configurations with credentials
.mcp.local.json
*.local.json
```

### **2. File Priority**
- **Claude Code reads BOTH files** and merges them
- **`.mcp.local.json` overrides** values in `.mcp.json`
- **`.mcp.json`** provides the structure and default values
- **`.mcp.local.json`** provides the actual credentials

### **3. Environment Variable Reference Pattern**
```json
// .mcp.json (public, committed)
{
  "mcpServers": {
    "my-server": {
      "env": {
        "API_KEY": "${API_KEY}",      // Reference environment variable
        "SECRET_TOKEN": "${SECRET_TOKEN}"
      }
    }
  }
}
```

```bash
# .env (gitignored)
API_KEY=your-actual-api-key-here
SECRET_TOKEN=your-actual-secret-here
```

## 🎯 Best Practices

### **Rule #1: Never Commit Credentials**
- ❌ **DON'T**: Put real tokens/keys in `.mcp.json`
- ✅ **DO**: Use environment variable references (`${VAR_NAME}`)
- ✅ **DO**: Put credentials in `.mcp.local.json` (gitignored)

### **Rule #2: Environment Variables First (Recommended)**
```json
// .mcp.json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

```bash
# .env (gitignored)
GITHUB_TOKEN=ghp_your-github-token
```

**Benefits**:
- ✅ More secure (credentials in separate file)
- ✅ Easier to rotate credentials
- ✅ Works across multiple tools
- ✅ Standard practice (12-factor app style)

### **Rule #3: .mcp.local.json for Complex Credentials**
Use when you need more than simple environment variables:

```json
// .mcp.local.json
{
  "mcpServers": {
    "complex-server": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer token-here",
        "X-Custom-Header": "custom-value",
        "X-API-Key": "api-key-here"
      }
    }
  }
}
```

## 📁 File Structure Example

```
my-project/
├── .git/
├── .gitignore              # Contains: *.local.json
├── .env                    # Gitignored, contains actual credentials
├── .mcp.json               # ✅ Committed (no credentials)
├── .mcp.local.json        # ❌ Gitignored (contains credentials)
├── src/
└── README.md
```

## 🔍 How to Check If Your Repo Is Safe

**Run these checks:**

```bash
# 1. Make sure .local.json files are gitignored
grep "*.local.json" .gitignore

# 2. Check if any credentials accidentally committed
git grep -r "token\|key\|secret\|password" .mcp.json

# 3. Verify .mcp.local.json exists but isn't tracked
ls -la .mcp.local.json
git status .mcp.local.json  # Should show "untracked"
```

## 🚨 Recovery: What If I Accidentally Committed Credentials?

### **Immediate Actions:**

1. **Remove credentials from the file**
2. **Use git filter-repo to remove from history**
   ```bash
   git filter-repo --force --index-filter \
     "git rm --cached --ignore-unmatch .mcp.local.json"
   ```
3. **Create proper .mcp.local.json**
4. **Force push** (if the repo is already shared)

### **Better Approach for Existing Repos:**

```bash
# 1. Remove sensitive data
sed -i 's/"token": ".*"/"token": "REDACTED"/' .mcp.json

# 2. Add to .gitignore
echo "*.local.json" >> .gitignore

# 3. Commit the cleanup
git add .gitignore .mcp.json
git commit -m "security: remove credentials and add .gitignore"

# 4. Create .mcp.local.json with real credentials
cat > .mcp.local.json << 'EOF'
{
  "mcpServers": {
    "my-server": {
      "env": {
        "API_TOKEN": "real-token-here"
      }
    }
  }
}
EOF
```

## 🎯 Quick Reference

| File | Purpose | Committed? | Contains |
|------|---------|------------|----------|
| `.mcp.json` | Server structure | ✅ Yes | Non-sensitive config only |
| `.mcp.local.json` | Credentials | ❌ No | Real tokens/keys/passwords |
| `.env` | Environment variables | ❌ No | Real credential values |

## 💡 Pro Tips

1. **Always use environment variables** when possible
2. **Document required variables** in `.mcp.json` (show what's needed)
3. **Use `.env.example` files** to show structure without real values
4. **Test with `.mcp.local.json`** before committing `.mcp.json`
5. **Never ignore `.mcp.json`** - the structure should be version controlled

## 🔐 Security Checklist

Before committing, verify:
- [ ] `.mcp.json` contains NO real credentials
- [ ] `.mcp.json` only has environment variable references
- [ ] `.mcp.local.json` exists with real credentials
- [ ] `.gitignore` includes `*.local.json`
- [ ] `.mcp.local.json` shows as untracked in `git status`
- [ ] No sensitive data in `.env` files that are committed

**Remember**: `.mcp.json` is for **structure** (public), `.mcp.local.json` is for **secrets** (private)! 🔒
