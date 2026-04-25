# MCP Plugin Installation Workflow

## ⚠️ The Danger Zone: Installing via MCP Slash Commands

When you install a new MCP plugin using slash commands, it will likely:

1. **Install the plugin globally** (✅ Good)
2. **Enable it in `~/.claude/settings.json`** (❌ Bad for MCP plugins!)
3. **Load its MCP servers in ALL projects** (❌ Token waste!)

## 🎯 Safe Installation Workflow

### **Option 1: Manual Installation (Recommended)**

**Step 1: Install the plugin without enabling**
```bash
# Plugin gets installed but stays disabled
npm install -g @some/mcp-plugin
```

**Step 2: Test in a specific project first**
```json
// test-project/.claude/settings.json
{
  "enabledPlugins": {
    "@some/mcp-plugin": true  // Only enable here first
  }
}
```

**Step 3: If it has MCP servers, use .mcp.json instead**
```json
// test-project/.mcp.json
{
  "mcpServers": {
    "some-server": {
      "command": "npx",
      "args": ["-y", "@some/mcp-plugin"]
    }
  }
}
```

**Step 4: Only enable globally if it has NO MCP servers**
```json
// ~/.claude/settings.json
{
  "enabledPlugins": {
    "@some/non-mcp-plugin": true  // Safe - no MCP server
  }
}
```

### **Option 2: Install via Slash Command, Then Fix**

**Step 1: Install via slash command**
```bash
/install-mcp @some/new-mcp-plugin
```

**Step 2: Check what got enabled**
```bash
cat ~/.claude/settings.json | grep -A 5 "enabledPlugins"
```

**Step 3: If it has MCP servers, disable globally**
```json
// ~/.claude/settings.json
{
  "enabledPlugins": {
    "@some/new-mcp-plugin": false  // Disable global loading
  }
}
```

**Step 4: Add to projects that actually need it**
```json
// project-that-needs-it/.mcp.json
{
  "mcpServers": {
    "new-server": {
      "command": "npx",
      "args": ["-y", "@some/new-mcp-plugin"]
    }
  }
}
```

## 🔍 How to Check if a Plugin Has MCP Servers

**Before installing:**
```bash
# Check the plugin's metadata
npm view @some/mcp-plugin
# Or look for .mcp.json in the plugin repository
```

**After installing:**
```bash
# Check if the plugin contains MCP configuration
find ~/.claude/plugins/cache/*mcp-plugin*/.mcp.json
# If this returns files, the plugin has MCP servers!
```

## ⚡ Quick Decision Tree

```
Installing new MCP plugin?
│
├─→ Does it have MCP servers?
│   │
│   ├─→ YES → Install globally + DISABLE globally → Use .mcp.json per project
│   │
│   └─→ NO  → Install globally + ENABLE globally (safe)
│
└─→ Test in one project first before using everywhere
```

## 🎯 Best Practices

1. **Always test new MCP plugins in a single project first**
2. **Check if plugins include MCP servers before enabling globally**
3. **Prefer .mcp.json configuration over plugin-based loading**
4. **Keep global plugins to a minimum** (only non-MCP plugins)
5. **Document which projects need which MCP servers**

## 📋 Checklist Before Installing New MCP Plugin

- [ ] Does this plugin have MCP servers?
- [ ] Do I need this in ALL projects or just some?
- [ ] Can I configure it via .mcp.json instead?
- [ ] Have I tested it in one project first?
- [ ] Is the token cost worth the functionality?

## 🚨 Recovery: What If I Already Installed It Globally?

**Don't panic! Just follow the recovery steps:**

1. **Find the plugin name:**
   ```bash
   cat ~/.claude/settings.json | grep "enabledPlugins"
   ```

2. **Disable it globally:**
   ```json
   {
     "enabledPlugins": {
       "@problematic/mcp-plugin": false
     }
   }
   ```

3. **Add to specific projects that need it:**
   ```json
   // specific-project/.mcp.json
   {
     "mcpServers": {
       "problematic-server": { /* config */ }
     }
   }
   ```

## 💡 Pro Tip: Plugin vs MCP Server

Remember: **Plugins are packages, MCP servers are tools**

- **Plugin**: The installation package (may include MCP server)
- **MCP Server**: The actual tool that can be loaded multiple ways
- **Goal**: Install plugins once, configure MCP servers per project

This way you get:
- ✅ Clean installation (plugins installed once)
- ✅ Token optimization (MCP servers only load where needed)
- ✅ Project control (each project chooses its tools)
