#!/bin/bash
# init-folder Script
# Preconfigures a blank folder for agentic development
# Cross-platform: Works on Linux, macOS, and Windows (via Git Bash/WSL)

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DARK_GRAY='\033[0;90m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Default parameters
PROJECT_TYPES=""
GITHUB_USERNAME="adfra"
CURRENT_DIRECTORY="$(pwd)"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-types)
            PROJECT_TYPES="$2"
            shift 2
            ;;
        --github-username)
            GITHUB_USERNAME="$2"
            shift 2
            ;;
        --current-directory)
            CURRENT_DIRECTORY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Helper functions
write_status() {
    local symbol="$1"
    local message="$2"
    local color="${3:-$WHITE}"
    echo -e "${color}${symbol} ${message}${NC}"
}

write_error_guidance() {
    local error="$1"
    local guidance="$2"
    write_status "✗" "$error" "$RED"
    echo -e "${YELLOW}  Fix: $guidance${NC}"
}

# Change to target directory
cd "$CURRENT_DIRECTORY" 2>/dev/null || { write_error_guidance "Cannot access directory" "$CURRENT_DIRECTORY"; exit 1; }

# Get folder name for repo name
FOLDER_NAME=$(basename "$CURRENT_DIRECTORY")
if [[ -z "$FOLDER_NAME" ]] || [[ "$FOLDER_NAME" == "." ]]; then
    FOLDER_NAME="new-project"
fi

# Arrays for warnings
WARNINGS=()

# 1. Initialize git repository
echo ""
write_status "" "Initializing git repository..." "$CYAN"
if git init 2>&1 | grep -v "^Initialized"; then
    write_status "✓" "Repository initialized" "$GREEN"
else
    write_error_guidance "git init failed" "Check if git is installed and folder is writable"
    exit 1
fi

# 2. Create .gitignore
echo ""
write_status "" "Creating .gitignore..." "$CYAN"

# Start with minimal base .gitignore
GITIGNORE_CONTENT="# Environment variables
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
"

# Add project-specific rules based on selection
SELECTED_TYPES=()
IFS=',' read -ra TYPES <<< "$PROJECT_TYPES"
for type in "${TYPES[@]}"; do
    type=$(echo "$type" | xargs) # trim whitespace

    case "$type" in
        *Node*)
            GITIGNORE_CONTENT+="
# Node.js
node_modules/
package-lock.json
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*
.npm/
.eslintcache
"
            SELECTED_TYPES+=("Node.js")
            ;;
        *Python*)
            GITIGNORE_CONTENT+="
# Python
__pycache__/
*.py[cod]
*\$py.class
*.so
.Python
venv/
env/
.venv/
ENV/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
.pytest_cache/
.coverage
htmlcov/
.tox/
.hypothesis/
.mypy_cache/
"
            SELECTED_TYPES+=("Python")
            ;;
        *Rust*)
            GITIGNORE_CONTENT+="
# Rust
target/
**/*.rs.bk
Cargo.lock
"
            SELECTED_TYPES+=("Rust")
            ;;
        *Go*)
            GITIGNORE_CONTENT+="
# Go
bin/
pkg/
*.exe
*.test
*.out
go.work
"
            SELECTED_TYPES+=("Go")
            ;;
        *TypeScript*)
            GITIGNORE_CONTENT+="
# TypeScript
*.tsbuildinfo
dist/
build/
"
            SELECTED_TYPES+=("TypeScript")
            ;;
        *Java*)
            GITIGNORE_CONTENT+="
# Java
*.class
*.jar
*.war
*.nar
target/
.mvn/
mvnw
mvnw.cmd
"
            SELECTED_TYPES+=("Java")
            ;;
        *Web*)
            GITIGNORE_CONTENT+="
# Web/HTML/CSS
.vscode/
.idea/
dist/
build/
.cache/
"
            SELECTED_TYPES+=("Web")
            ;;
    esac
done

# Write .gitignore
echo "$GITIGNORE_CONTENT" > .gitignore

# Format selected types string
if [[ ${#SELECTED_TYPES[@]} -gt 0 ]]; then
    TYPES_STR=$(IFS=', '; echo "${SELECTED_TYPES[*]}")
else
    TYPES_STR="minimal base"
fi
write_status "✓" ".gitignore created ($TYPES_STR)" "$GREEN"

# 3. Create .planning/ folder
echo ""
write_status "" "Creating .planning/ folder..." "$CYAN"
mkdir -p .planning
write_status "✓" ".planning/ folder created" "$GREEN"

# 4. Check for gh CLI and create GitHub remote
echo ""
write_status "" "Checking for gh CLI..." "$CYAN"
GH_AVAILABLE=false
if command -v gh &>/dev/null; then
    # Check if authenticated (suppress error output)
    if gh auth status &>/dev/null 2>&1; then
        GH_AVAILABLE=true

        # Create repository (suppress verbose output, capture errors only)
        if gh repo create "$FOLDER_NAME" --public --source="$CURRENT_DIRECTORY" --remote=origin --push 2>&1 | grep -v "^Created"; then
            write_status "✓" "GitHub remote created: https://github.com/$GITHUB_USERNAME/$FOLDER_NAME" "$GREEN"
        else
            WARNINGS+=("GitHub remote creation failed")
            write_status "⚠" "GitHub remote creation failed" "$YELLOW"
            echo -e "${YELLOW}  To add manually:${NC}"
            echo -e "${YELLOW}    git remote add origin https://github.com/$GITHUB_USERNAME/$FOLDER_NAME.git${NC}"
        fi
    else
        WARNINGS+=("gh CLI not authenticated")
        echo ""
        echo -e "${YELLOW}⚠ gh CLI not authenticated${NC}"
        echo -e "${YELLOW}  Run 'gh auth login' to authenticate, then:${NC}"
        echo -e "${YELLOW}    git remote add origin https://github.com/$GITHUB_USERNAME/$FOLDER_NAME.git${NC}"
        echo -e "${YELLOW}    git push -u origin main${NC}"
    fi
else
    WARNINGS+=("gh CLI not found")
    echo ""
    echo -e "${YELLOW}⚠ gh CLI not found. GitHub remote will be skipped.${NC}"
    echo -e "${YELLOW}  Install gh from https://cli.github.com/ to enable remote creation.${NC}"
    echo -e "${YELLOW}  To add remote manually:${NC}"
    echo -e "${YELLOW}    git remote add origin https://github.com/$GITHUB_USERNAME/$FOLDER_NAME.git${NC}"
fi

# 5. Make initial commit
echo ""
write_status "" "Making initial commit..." "$CYAN"
if git add .gitignore 2>&1 >/dev/null && git commit -m "chore: initialize project with .gitignore" 2>&1 >/dev/null; then
    write_status "✓" "Initial commit made" "$GREEN"
else
    write_error_guidance "git commit failed" "Check git configuration (user.name, user.email)"
    exit 1
fi

# Summary
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN} INIT-FOLDER COMPLETE${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Your project is ready! Next steps:${NC}"
echo -e "${WHITE}1. Start coding${NC}"
echo -e "${WHITE}2. Plan your work: /gsd-discuss-phase 1${NC}"
echo -e "${WHITE}3. View status: git status${NC}"

if [[ "$GH_AVAILABLE" == true ]]; then
    echo ""
    echo -e "${CYAN}Remote: https://github.com/$GITHUB_USERNAME/$FOLDER_NAME${NC}"
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Warnings:${NC}"
    for warning in "${WARNINGS[@]}"; do
        echo -e "${YELLOW}  ⚠ $warning${NC}"
    done
fi

echo ""
