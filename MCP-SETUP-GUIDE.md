# MCP Server Configuration Guide

## Token Optimization Strategy

### **Global Configuration** (`~/.claude/settings.json`)
✅ **Enabled globally** (available in all projects):
- `typescript-lsp@claude-plugins-official` - LSP support (minimal token impact)
- `taches-cc-resources@taches-cc-resources` - GSD workflow tools
- `vapi-voice-ai@vapi-skills` - VAPI voice skills

❌ **Disabled globally** (enable per-project when needed):
- `supabase@claude-plugins-official` - Supabase MCP server (~2-5K tokens/session)
- `vercel@claude-plugins-official` - Vercel MCP server (~1-3K tokens/session)
- `oh-my-claudecode@omc` - OMC wiki/memory tools (~500-1K tokens/session)

## Per-Project Configuration

### **Supabase Projects Only**
Create `.claude/settings.json` in your Supabase project:
```json
{
  "enabledPlugins": {
    "supabase@claude-plugins-official": true
  }
}
```

### **Vercel Projects Only**
Create `.claude/settings.json` in your Vercel project:
```json
{
  "enabledPlugins": {
    "vercel@claude-plugins-official": true
  }
}
```

### **Projects Using OMC Features**
Create `.claude/settings.json` in projects needing wiki/memory:
```json
{
  "enabledPlugins": {
    "oh-my-claudecode@omc": true
  }
}
```

### **Combined Configuration**
For projects that need multiple MCP servers:
```json
{
  "enabledPlugins": {
    "supabase@claude-plugins-official": true,
    "vercel@claude-plugins-official": true,
    "oh-my-claudecode@omc": true
  }
}
```

## Token Savings Estimation

**Before optimization**: 6-9K tokens per project session
**After optimization**: 0-2K tokens per project session (only when needed)

**Annual savings** (assuming 100 projects × 10 sessions/year): 
- **Supabase alone**: 2-5M tokens saved
- **Vercel alone**: 1-3M tokens saved  
- **Total potential**: 4-9M tokens saved annually

## Quick Reference

**Need Supabase tools?** Add to project `.claude/settings.json`:
```json
{"enabledPlugins": {"supabase@claude-plugins-official": true}}
```

**Need Vercel deployment tools?** Add to project `.claude/settings.json`:
```json
{"enabledPlugins": {"vercel@claude-plugins-official": true}}
```

**Need wiki/memory management?** Add to project `.claude/settings.json`:
```json
{"enabledPlugins": {"oh-my-claudecode@omc": true}}
```
