---
name: init-folder
description: Initialize a blank folder for agentic development. Creates git repo, generates smart .gitignore with interactive project type selection, sets up GitHub remote, creates .planning/ folder, installs selected MCP servers, and makes initial baseline commit.
---

<objective>
Transform a blank folder into a ready-to-code workspace for agentic development in one command. This skill eliminates repetitive setup friction by automating git initialization, .gitignore configuration, GitHub remote creation, and GSD workflow preparation.
</objective>

<prerequisites>
- **bash**: Required (Works on Linux, macOS, Windows via Git Bash/WSL)
- **git**: Must be installed and available in PATH
- **gh CLI**: Recommended for GitHub remote creation (fallback guidance provided if missing)
- **GitHub auth**: gh CLI must be authenticated (`gh auth login`) for remote creation
- **jq**: Required for MCP installation (JSON parser for MCP configs)
</prerequisites>

<quick_start>
Run this skill in any empty folder where you want to start a new project. The skill will:
1. Validate prerequisites (git, bash, jq)
2. Ask for project type to configure .gitignore appropriately
3. Scan for existing MCP configurations across projects (including global)
4. Offer to install selected MCP servers
5. Execute bash scripts to perform setup
6. Report results with clear next steps
</quick_start>

<process>

## 1. Validate Environment

Check that required tools are available:

```bash
# Check if git is available
if ! command -v git &>/dev/null; then
    echo "Error: git not found"
fi

# Check if bash is available
if ! command -v bash &>/dev/null; then
    echo "Error: bash not found"
fi

# Check if jq is available (for MCP installation)
if ! command -v jq &>/dev/null; then
    echo "Warning: jq not found - MCP installation will be skipped"
fi

# Check if gh CLI is available (optional but recommended)
if ! command -v gh &>/dev/null; then
    echo "Warning: gh CLI not found - GitHub remote will be skipped"
fi
```

**If git not found:**
- Error with guidance: "git not found. Install from https://git-scm.com/"

**If bash not found:**
- Error with guidance: "bash not found. This skill requires a bash-compatible shell"

**If jq not found:**
- Warning but continue: "jq not found. MCP installation will be skipped. Install from https://stedolan.github.io/jq/"

**If gh CLI not found:**
- Warning but continue: "gh CLI not found. GitHub remote will be skipped. Install from https://cli.github.com/"

## 2. Gather Project Type

Use AskUserQuestion to determine .gitignore configuration. **Note: This selection configures your .gitignore file with appropriate patterns for the selected project type(s).**

```xml
<AskUserQuestion>
  <question>Select project type(s) for .gitignore configuration:</question>
  <header>Project Type</header>
  <multiSelect>true</multiSelect>
  <options>
    <option>
      <label>Node.js</label>
      <description>node_modules, package-lock.json, npm debug logs</description>
    </option>
    <option>
      <label>Python</label>
      <description>__pycache__, *.pyc, venv, .venv, *.egg-info</description>
    </option>
    <option>
      <label>Rust</label>
      <description>target/, Cargo.lock (if lib), *.rlib</description>
    </option>
    <option>
      <label>Go</label>
      <description>vendor/, *.exe, *.test, *.out</description>
    </option>
    <option>
      <label>TypeScript</label>
      <description>*.tsbuildinfo, dist/, build/</description>
    </option>
    <option>
      <label>Java</label>
      <description>*.class, target/, *.jar, *.war</description>
    </option>
    <option>
      <label>Web/HTML/CSS</label>
      <description>.vscode/, .idea/, build/, dist/</description>
    </option>
    <option>
      <label>None/Other</label>
      <description>Just minimal defaults (.env, credentials)</description>
    </option>
  </options>
</AskUserQuestion>
```

Collect selected project types into a comma-separated string for the script.

## 3. Scan for Existing MCP Configurations

Search for existing MCP server configurations across projects to present installation options:

```bash
# Get user's home directory
HOME_DIR="${HOME:-~}"

# Define search paths
declare -a search_paths=(
    "$HOME_DIR/.claude"                      # Global Claude config
    "$HOME_DIR/source/repos/*/.claude"       # Project configs (recursive)
)

# Discover available MCP servers
declare -A available_mcps

for path in "${search_paths[@]}"; do
    # Handle glob expansion
    for expanded_path in $path; do
        [[ ! -d "$expanded_path" ]] && continue

        # Check for config files
        for config_file in "$expanded_path"/claude.json "$expanded_path"/claude.local.json \
                          "$expanded_path"/.mcp.json "$expanded_path"/.mcp.local.json; do
            [[ ! -f "$config_file" ]] && continue

            # Extract MCP server names using jq (suppress errors)
            while IFS= read -r server_name; do
                [[ -z "$server_name" ]] && continue
                [[ ! "${available_mcps[$server_name]+isset}" ]] || continue  # Skip duplicates

                # Get server config to determine type
                server_config=$(jq -r ".mcpServers[\"$server_name\"]" "$config_file" 2>/dev/null)
                command=$(echo "$server_config" | jq -r '.command // ""' 2>/dev/null)

                # Determine installation type
                if [[ "$command" == "npx" ]]; then
                    install_type="npx"
                elif echo "$server_config" | jq -e '.env' >/dev/null 2>&1; then
                    install_type="configured"
                else
                    install_type="global"
                fi

                available_mcps["$server_name"]="$config_file|$install_type"
            done < <(jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null)
        done
    done
done
```

## 4. Offer MCP Installation

If MCP servers were discovered, present them to the user with their installation type:

```xml
<AskUserQuestion>
  <question>Which MCP servers should be installed in this project?</question>
  <header>MCP Servers</header>
  <multiSelect>true</multiSelect>
  <options>
    <!-- Dynamically populate discovered MCPs -->
    <option>
      <label>mcp-server-name</label>
      <description>Type: [npx/global/configured] • From: [source path]</description>
    </option>
  </options>
</AskUserQuestion>
```

**Installation Types:**
- **npx**: Runs directly from npm registry (e.g., `npx @modelcontextprotocol/server-example`)
- **global**: Installed globally via npm or other package manager
- **configured**: Has environment variables/credentials (requires .local.json)

If no MCPs discovered or user declines, skip installation step.

## 5. Execute Bash Script

Run the initialization script with collected parameters:

```bash
bash .claude/skills/init-folder/scripts/initialize.sh \
  --project-types "Node.js,Python" \
  --github-username "adfra"
```

Parameters:
- **--project-types**: Comma-separated list of selected project types
- **--github-username**: Hardcoded to "adfra" per requirements

## 6. Install MCP Servers (If Selected)

If user selected MCP servers in step 4, install them:

```bash
selected_mcps="server1,server2"  # From AskUserQuestion results
source_paths="path1,path2,path3"  # Discovered configs

bash .claude/skills/init-folder/scripts/install-mcps.sh \
  --selected-mcps "$selected_mcps" \
  --source-paths "$source_paths"
```

Parameters:
- **--selected-mcps**: Comma-separated list of MCP server names selected by user
- **--source-paths**: Comma-separated list of paths containing MCP configurations

The script will:
- Create `.mcp.json` with non-sensitive MCP configs
- Create `.mcp.local.json` with credentials
- Update `.gitignore` to include `*.local.json` pattern

## 7. Handle Script Output

The script returns structured output:

**Success:**
```
✓ Repository initialized
✓ .gitignore created (Node.js, Python)
✓ .planning/ folder created
✓ GitHub remote created: https://github.com/adfra/[folder-name]
✓ Initial commit made
✓ MCP servers installed: server1, server2
  → .mcp.json created with non-sensitive configs
  → .mcp.local.json created with credentials (gitignored)
```

**Partial Success (gh CLI missing):**
```
✓ Repository initialized
✓ .gitignore created (Node.js, Python)
✓ .planning/ folder created
⚠ GitHub remote skipped (gh CLI not found)
  To add remote manually: git remote add origin https://github.com/adfra/[repo-name].git
✓ Initial commit made
✓ MCP servers installed: server1, server2
  → .mcp.json created with non-sensitive configs
  → .mcp.local.json created with credentials (gitignored)
```

## 8. Report Results

Present the output to the user with clear next steps:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 INIT-FOLDER COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your project is ready! Next steps:

1. Start coding
2. Plan your work: /gsd-discuss-phase 1
3. View status: git status

Remote: https://github.com/adfra/[repo-name]

MCP servers installed: server1, server2
⚠ Credentials are in .mcp.local.json (not in git)
```

</process>

<error_handling>

## Common Errors and Guidance

| Error | Cause | Guidance |
|-------|-------|----------|
| "git: command not found" | git not installed or not in PATH | Install from https://git-scm.com/ |
| "bash: command not found" | bash not available | This skill requires bash. On Windows, use Git Bash or WSL |
| "jq: command not found" | jq not installed | Install from https://stedolan.github.io/jq/; MCP installation will be skipped |
| "gh: command not found" | gh CLI not installed | Install from https://cli.github.com/; skill will continue without remote creation |
| "gh not authenticated" | User hasn't run `gh auth login` | Run `gh auth login` to authenticate, then re-run skill |
| "Permission denied" | Can't write to .git/ or .gitignore | Check folder permissions |
| "Repository already exists" | Folder already has a .git/ directory | Use a different folder or `rm -rf .git` first |
| "Invalid JSON in MCP config" | Corrupted or malformed MCP configuration file | Check the source MCP configuration file for valid JSON syntax |

All errors include:
- What went wrong (specific error message)
- Why it failed (root cause)
- How to fix it (actionable next step)

**Script Error Handling:**
- Scripts use `set -euo pipefail` for strict error handling
- Command output is suppressed where appropriate to avoid cluttering the chat
- Errors are captured and reported with actionable guidance
- Long command errors are structured and don't overflow into the chat

</error_handling>

<artifacts>

The skill creates these artifacts in the target folder:

```
project-folder/
├── .git/                    # Git repository (created by git init)
├── .gitignore               # Smart ignore file with project-specific rules
├── .planning/               # Empty folder for GSD workflow
├── .mcp.json                # MCP server configurations (if MCPs installed, no credentials)
├── .mcp.local.json          # MCP credentials (gitignored, if MCPs installed)
└── .git/                    # Initial commit with .gitignore
```

The .gitignore includes:

**Always included (minimal base):**
```
# Environment variables
.env
.env.local
.env.*.local

# Credentials
*.pem
*.key
credentials.json
auth.json
.secrets
*.creds

# OS files
.DS_Store
Thumbs.db
Desktop.ini

# IDE/Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# GSD workflow
.planning/

# OMC (Oh My Claude Code) session data
.omc/

# Build artifacts (general)
dist/
build/
out/
*.log
```

**Project-specific extensions** (based on user selection):
- Node.js: node_modules/, package-lock.json, *.log
- Python: __pycache__/, *.pyc, venv/, .venv/
- TypeScript: *.tsbuildinfo, dist/, build/
- Rust: target/, Cargo.lock
- etc.

</artifacts>

<examples>

## Basic Usage

```
User: /init-folder

[Claude validates git, bash, jq]
[Claude asks project type for .gitignore]
User: [selects Node.js, TypeScript]

[Claude executes bash script]

✓ Repository initialized
✓ .gitignore created (Node.js, TypeScript)
✓ .planning/ folder created
✓ GitHub remote created: https://github.com/adfra/my-new-project
✓ Initial commit made
```

## With Missing gh CLI

```
User: /init-folder

⚠ gh CLI not found. GitHub remote will be skipped.
  Install gh from https://cli.github.com/ to enable remote creation.

[Claude continues setup without remote]

✓ Repository initialized
✓ .gitignore created
✓ .planning/ folder created
⚠ GitHub remote skipped
  To add manually: git remote add origin https://github.com/adfra/[repo].git
✓ Initial commit made
```

## With MCP Server Installation

```
User: /init-folder

[Claude validates git, bash, jq]
[Claude asks project type for .gitignore]
User: [selects Node.js, TypeScript]

[Claude scans for MCP configurations]
Found 2 MCP servers available:
1. @modelcontextprotocol/server-github (npx)
   No installation needed - runs via npx
2. firefly-iii (configured)
   Has credentials in source config

[Claude asks which MCP servers to install]
User: [selects @modelcontextprotocol/server-github, firefly-iii]

✓ Repository initialized
✓ .gitignore created (Node.js, TypeScript)
✓ .planning/ folder created
✓ GitHub remote created: https://github.com/adfra/my-new-project
✓ Initial commit made
✓ MCP servers installed: @modelcontextprotocol/server-github, firefly-iii
  → .mcp.json created with 1 server(s)
  → .mcp.local.json created with 1 server(s)
```

</examples>

<success_criteria>
Skill is successful when:
- [ ] Git repository created (.git/ folder exists)
- [ ] .gitignore created with minimal base + selected project types
- [ ] .planning/ folder created (empty)
- [ ] Initial commit made (.gitignore committed)
- [ ] GitHub remote created (if gh CLI available and authenticated)
- [ ] MCP servers installed (if selected by user)
  - [ ] .mcp.json created with non-sensitive configs
  - [ ] .mcp.local.json created with credentials
  - [ ] *.local.json pattern added to .gitignore
- [ ] Clear error messages with actionable guidance (if any step fails)
- [ ] User knows next steps (start coding or run GSD planning)
- [ ] Project type selection clearly indicates it's for .gitignore configuration
- [ ] MCP scan picks up global and installed but inactive servers
- [ ] Scripts work on Linux, macOS, and Windows (via Git Bash/WSL)
- [ ] Long command errors don't overflow into the chat
</success_criteria>
