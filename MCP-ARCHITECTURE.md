# MCP Server Configuration Strategy

## The Problem: Multiple Overlapping Systems

Currently, MCP servers can be configured in **3 different ways**, causing confusion:

### 1. **Plugin-Based MCP Servers** (Global)
```json
// ~/.claude/settings.json
"enabledPlugins": {
  "supabase@claude-plugins-official": true  // Loads MCP server in ALL projects
}
```
- **Scope**: Global (all projects)
- **Control**: `~/.claude/settings.json`
- **Examples**: Supabase, Vercel, OMC plugins

### 2. **Project-Level MCP Servers** (.mcp.json)
```json
// project-folder/.mcp.json
{
  "mcpServers": {
    "firefly-iii": {
      "command": "node",
      "args": ["~/.claude/mcp/firefly-iii/index.js"]
    }
  }
}
```
- **Scope**: Project-specific
- **Control**: `project-folder/.mcp.json`
- **Examples**: firefly-iii, custom servers

### 3. **Global MCP Configuration** (if it exists)
```json
// ~/.claude/claude.json (if it existed)
{
  "mcpServers": {
    "some-server": { ... }
  }
}
```
- **Scope**: Global (all projects)
- **Control**: `~/.claude/claude.json`
- **Current status**: You don't have this file

## **🎯 Recommended Consistent Strategy:**

### **Rule #1: Use .mcp.json for ALL MCP Servers**

**Prefer project-level MCP configuration** (.mcp.json) over plugin-based:

```json
// project-folder/.mcp.json
{
  "mcpServers": {
    // NPX-based servers (recommended)
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    },
    
    // Source-based servers (like firefly-iii)
    "firefly-iii": {
      "command": "node",
      "args": ["~/.claude/mcp/firefly-iii/index.js"],
      "env": {
        "FIREFLY_URL": "${FIREFLY_URL}",
        "FIREFLY_TOKEN": "${FIREFLY_TOKEN}"
      }
    },
    
    // Remote HTTP servers (if needed)
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp"
    }
  }
}
```

### **Rule #2: Disable Plugin-Based MCP Servers Globally**

```json
// ~/.claude/settings.json
"enabledPlugins": {
  "supabase@claude-plugins-official": false,   // ❌ Disable global MCP
  "vercel@claude-plugins-official": false,     // ❌ Disable global MCP
  "oh-my-claudecode@omc": false                // ❌ Disable global MCP
}
```

**Then add them via .mcp.json when needed:**

```json
// supabase-project/.mcp.json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp"
    }
  }
}
```

### **Rule #3: Keep Non-MCP Plugins Global**

Only keep plugins global if they don't include MCP servers:

```json
// ~/.claude/settings.json
"enabledPlugins": {
  "typescript-lsp@claude-plugins-official": true,  // ✅ No MCP server
  "taches-cc-resources@taches-cc-resources": true   // ✅ No MCP server
}
```

## **🔄 Migration Path:**

### **Current State → Recommended State**

**Before:**
- ❌ Supabase MCP loads in ALL projects (via plugin)
- ❌ Vercel MCP loads in ALL projects (via plugin)
- ❌ OMC MCP loads in ALL projects (via plugin)
- ✅ firefly-iii only loads in ing-to-firefly-sync (via .mcp.json)

**After:**
- ✅ NO MCP servers load globally
- ✅ Each project defines its own .mcp.json
- ✅ Token optimization achieved

### **How to Convert Plugin MCP to .mcp.json:**

**1. Find the plugin's MCP configuration:**
```bash
cat ~/.claude/plugins/cache/claude-plugins-official/supabase/0.1.5/.mcp.json
```

**2. Copy to your project's .mcp.json:**
```json
// your-project/.mcp.json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp",
      "headers": {
        "X-Source-Name": "claude-code-plugin"
      }
    }
  }
}
```

**3. Disable the plugin globally:**
```json
// ~/.claude/settings.json
"enabledPlugins": {
  "supabase@claude-plugins-official": false
}
```

## **📊 Benefits of Consistent Strategy:**

1. **Token Optimization**: Only load what you need
2. **Clear Ownership**: One configuration method (.mcp.json)
3. **Project Portability**: .mcp.json files are part of your project
4. **Better Debugging**: Easier to see what MCPs are loaded per project
5. **Consistent Pattern**: All MCPs work the same way

## **🎯 Quick Reference:**

**Want to add an MCP server?** → Use `.mcp.json`  
**Using init-folder skill?** → It will help you create .mcp.json  
**Need Supabase tools?** → Add Supabase to your project's .mcp.json  
 **Need Vercel deployment?** → Add Vercel to your project's .mcp.json

**Result**: Clean, consistent, token-optimized MCP configuration! 🎉
