---
name: init-folder
description: Initialize a blank folder on Windows for agentic development. Creates git repo, generates smart .gitignore with interactive project type selection, sets up GitHub remote, creates .planning/ folder, and makes initial baseline commit.
---

<objective>
Transform a blank folder into a ready-to-code workspace for agentic development in one command. This skill eliminates repetitive setup friction by automating git initialization, .gitignore configuration, GitHub remote creation, and GSD workflow preparation.
</objective>

<prerequisites>
- **Windows**: PowerShell required
- **git**: Must be installed and available in PATH
- **gh CLI**: Recommended for GitHub remote creation (fallback guidance provided if missing)
- **GitHub auth**: gh CLI must be authenticated (`gh auth login`) for remote creation
</prerequisites>

<quick_start>
Run this skill in any empty folder where you want to start a new project. The skill will:
1. Validate prerequisites (git, PowerShell on Windows)
2. Ask for project type to configure .gitignore appropriately
3. Execute PowerShell script to perform setup
4. Report results with clear next steps
</quick_start>

<process>

## 1. Validate Environment

Check that required tools are available:

```powershell
# Check if running on Windows
$windowsCheck = [System.Environment]::OSVersion.Platform -eq "Win32NT"

# Check if git is available
$gitCheck = Get-Command git -ErrorAction SilentlyContinue

# Check if gh CLI is available (optional but recommended)
$ghCheck = Get-Command gh -ErrorAction SilentlyContinue
```

**If not on Windows:**
- Error with guidance: "This skill requires Windows. PowerShell script is Windows-specific."

**If git not found:**
- Error with guidance: "git not found. Install git from https://git-scm.com/download/win"

**If gh CLI not found:**
- Warning but continue: "gh CLI not found. GitHub remote will be skipped. Install gh from https://cli.github.com/ and run `gh auth login` to enable remote creation."

## 2. Gather Project Type

Use AskUserQuestion to determine .gitignore configuration:

```xml
<AskUserQuestion>
  <question>What type of project is this?</question>
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

## 3. Execute PowerShell Script

Run the initialization script with collected parameters:

```powershell
pwsh -ExecutionPolicy Bypass -File .claude/skills/init-folder/scripts/initialize.ps1 `
  -ProjectTypes "Node.js,Python" `
  -GitHubUsername "adfra"
```

Parameters:
- **ProjectTypes**: Comma-separated list of selected project types
- **GitHubUsername**: Hardcoded to "adfra" per requirements
- **CurrentDirectory**: Optionally specify target folder (defaults to current)

## 4. Handle Script Output

The script will return:

**Success:**
```
✓ Repository initialized
✓ .gitignore created (Node.js, Python)
✓ .planning/ folder created
✓ GitHub remote created: https://github.com/adfra/[folder-name]
✓ Initial commit made
```

**Partial Success (gh CLI missing):**
```
✓ Repository initialized
✓ .gitignore created (Node.js, Python)
✓ .planning/ folder created
⚠ GitHub remote skipped (gh CLI not found)
  To add remote manually: git remote add origin https://github.com/adfra/[repo-name].git
✓ Initial commit made
```

**Failure:**
```
✗ git init failed: [error message]
  Fix: [actionable guidance]
```

## 5. Report Results

Present the output to the user with clear next steps:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 INIT-FOLDER COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your project is ready! Next steps:

1. Start coding: .
2. Plan your work: /gsd-discuss-phase 1
3. View status: git status

Remote: https://github.com/adfra/[repo-name]
```

</process>

<error_handling>

## Common Errors and Guidance

| Error | Cause | Guidance |
|-------|-------|----------|
| "PowerShell not found" | Not on Windows or PS not in PATH | This skill requires Windows. Verify OS and install PowerShell Core if needed |
| "git: command not found" | git not installed or not in PATH | Install git from https://git-scm.com/download/win |
| "gh: command not found" | gh CLI not installed | Install from https://cli.github.com/; skill will continue without remote creation |
| "gh not authenticated" | User hasn't run `gh auth login` | Run `gh auth login` to authenticate, then re-run skill |
| "Permission denied" | Can't write to .git/ or .gitignore | Check folder permissions, run as administrator if needed |
| "Repository already exists" | Folder already has a .git/ directory | This folder is already initialized. Use a different folder or `rm -rf .git` first |

All errors include:
- What went wrong (specific error message)
- Why it failed (root cause)
- How to fix it (actionable next step)

</error_handling>

<artifacts>

The skill creates these artifacts in the target folder:

```
project-folder/
├── .git/                    # Git repository (created by git init)
├── .gitignore               # Smart ignore file with project-specific rules
├── .planning/               # Empty folder for GSD workflow
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

# OS files
.DS_Store
Thumbs.db

# GSD workflow
.planning/
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

[Claude validates Windows, git, gh]
[Claude asks project type]
User: [selects Node.js, TypeScript]

[Claude executes PowerShell script]

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

</examples>

<success_criteria>
Skill is successful when:
- [ ] Git repository created (.git/ folder exists)
- [ ] .gitignore created with minimal base + selected project types
- [ ] .planning/ folder created (empty)
- [ ] Initial commit made (.gitignore committed)
- [ ] GitHub remote created (if gh CLI available and authenticated)
- [ ] Clear error messages with actionable guidance (if any step fails)
- [ ] User knows next steps (start coding or run GSD planning)
</success_criteria>
