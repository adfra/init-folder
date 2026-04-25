# MCP Server Credential Management Guide

## 🔐 The Security Problem

**`.mcp.json` files are committed to git**, so they should **NEVER contain credentials**.

## ✅ The Solution: Environment Variable Pattern (Recommended)

### **Pattern: `.mcp.json` + `.env`**

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
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
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
```bash
# .env
FIREFLY_URL=https://your-firefly-instance.com
FIREFLY_TOKEN=your-secret-token-here
GITHUB_TOKEN=ghp_your-github-token
```

## 🛡️ How It Works

### **1. .gitignore Protection**
```gitignore
# Environment variables with credentials
.env
.env.local
.env.*.local

# Local configurations
*.local
```

### **2. Environment Variable Resolution**
- **Claude Code reads** `.mcp.json` (committed)
- **Claude Code resolves** `${VARIABLE}` from `.env` file
- **`.env` file** is gitignored and stays local

### **3. No Duplication, No Confusion**
- ✅ Single source of truth: `.mcp.json`
- ✅ Single credentials file: `.env`
- ✅ No duplicate configuration
- ✅ Standard 12-factor app pattern

## 📁 File Structure Example

```
my-project/
├── .git/
├── .gitignore              # Contains: .env, *.local
├── .env                    # ❌ Gitignored (contains real credentials)
├── .env.example           # ✅ Committed (shows structure)
├── .mcp.json               # ✅ Committed (env var references only)
├── src/
└── README.md
```

## 🎯 Best Practices

### **Rule #1: Use Environment Variables in .mcp.json**
```json
// ✅ CORRECT
{
  "mcpServers": {
    "my-server": {
      "env": {
        "API_KEY": "${API_KEY}",
        "SECRET_TOKEN": "${SECRET_TOKEN}"
      }
    }
  }
}
```

```json
// ❌ WRONG - Never do this!
{
  "mcpServers": {
    "my-server": {
      "env": {
        "API_KEY": "sk-live-abc123",
        "SECRET_TOKEN": "secret-value"
      }
    }
  }
}
```

### **Rule #2: Create .env.example for Documentation**
```bash
# .env.example (committed)
# Firefly III Configuration
FIREFLY_URL=https://your-firefly-instance.com
FIREFLY_TOKEN=your-firefly-token-here

# GitHub Configuration  
GITHUB_TOKEN=ghp_your-github-token-here
```

**Benefits**:
- ✅ Shows required variables
- ✅ Provides example format
- ✅ No real credentials exposed
- ✅ Easy for team members to get started

### **Rule #3: Never Commit .env Files**
- ✅ `.env` is in `.gitignore`
- ✅ `.env.example` is committed instead
- ✅ Each developer has their own `.env`

## 🔍 How to Check If Your Repo Is Safe

**Run these security checks:**

```bash
# 1. Make sure .env is gitignored
grep "\.env" .gitignore

# 2. Check if any real credentials in .mcp.json
git grep -r "sk-\|ghp_\|live_\|token.*[a-zA-Z0-9]" .mcp.json

# 3. Verify .env exists but isn't tracked
ls -la .env
git status .env  # Should show "untracked"

# 4. Confirm .env.example exists and is tracked
ls -la .env.example
git status .env.example  # Should show "tracked"
```

## 🚨 Recovery: What If I Accidentally Committed Credentials?

### **Scenario 1: Committed .env file**
```bash
# 1. Remove .env from git tracking
git rm --cached .env

# 2. Add to .gitignore (if not already there)
echo ".env" >> .gitignore

# 3. Commit the cleanup
git add .gitignore
git commit -m "security: remove .env from version control"

# 4. The .env file still exists locally (good!)
```

### **Scenario 2: Committed credentials in .mcp.json**
```bash
# 1. Replace credentials with environment variables
# Edit .mcp.json to use ${VARIABLE_NAME} format

# 2. Create .env file with real values
cat > .env << 'EOF'
API_KEY=your-real-key-here
SECRET_TOKEN=your-real-token
EOF

# 3. Add .env to .gitignore
echo ".env" >> .gitignore

# 4. Commit the changes
git add .mcp.json .gitignore .env.example
git commit -m "security: use environment variables for credentials"
```

### **Scenario 3: Remove from git history**
```bash
# Use git-filter-repo to remove sensitive data from history
git filter-repo --force --index-filter \
  'git rm --cached --ignore-unmatch .env'

# Force push (use caution!)
git push origin --force
```

## 🎯 Quick Reference

| File | Purpose | Committed? | Contains |
|------|---------|------------|----------|
| `.mcp.json` | Server structure + env var references | ✅ Yes | `${VARIABLE_NAME}` only |
| `.env` | Real credential values | ❌ No | Actual tokens/keys |
| `.env.example` | Documentation template | ✅ Yes | Example format only |

## 💡 Pro Tips

1. **Use .env.example** to document required variables
2. **Never commit real credentials** - always use env vars
3. **Keep .mcp.json simple** - just structure and references
4. **Test locally with .env** before committing
5. **Use different .env files** for development/production
6. **Rotate credentials by updating .env** (no code changes needed)

## 🔐 Security Checklist

Before committing, verify:
- [ ] `.mcp.json` contains ONLY `${VARIABLE}` references
- [ ] `.mcp.json` has NO real credentials (tokens, keys, secrets)
- [ ] `.env` exists locally with real values
- [ ] `.env` is gitignored (shows as untracked)
- [ ] `.env.example` exists with example format
- [ ] `.gitignore` includes `.env`
- [ ] No sensitive data in git history

**Remember**: `.mcp.json` = **Structure** (public), `.env` = **Secrets** (private)! 🔒

## 🚀 Getting Started Template

**New project setup:**
```bash
# 1. Create .env.example template
cat > .env.example << 'EOF'
# MCP Server Credentials
FIREFLY_URL=https://your-instance.com
FIREFLY_TOKEN=your-token-here
GITHUB_TOKEN=ghp_your-token-here
EOF

# 2. Create your local .env
cp .env.example .env
# Edit .env with your real credentials

# 3. Create .mcp.json with env var references
cat > .mcp.json << 'EOF'
{
  "mcpServers": {
    "firefly-iii": {
      "command": "node",
      "args": ["~/.claude/mcp/firefly-iii/index.js"],
      "env": {
        "FIREFLY_URL": "${FIREFLY_URL}",
        "FIREFLY_TOKEN": "${FIREFLY_TOKEN}"
      }
    }
  }
}
EOF

# 4. Update .gitignore
echo ".env" >> .gitignore

# 5. Commit the structure (NOT the secrets)
git add .env.example .mcp.json .gitignore
git commit -m "Add MCP server configuration"
```

**Team member onboarding:**
```bash
# 1. Clone the repo
git clone your-repo

# 2. Copy the example env file
cp .env.example .env

# 3. Add their own credentials
# Edit .env with their real tokens/keys

# 4. Start working!
```

Simple, secure, no duplication! 🎉
