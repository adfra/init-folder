# init-folder PowerShell Script
# Preconfigures a blank folder on Windows for agentic development

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectTypes = "",

    [Parameter(Mandatory=$false)]
    [string]$GitHubUsername = "adfra",

    [Parameter(Mandatory=$false)]
    [string]$CurrentDirectory = (Get-Location).Path
)

# Error handling preference
$ErrorActionPreference = "Stop"

# Helper function for colored output
function Write-Status {
    param(
        [string]$Symbol,
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host "$Symbol $Message" -ForegroundColor $Color
}

# Helper function for error output
function Write-Error-Guidance {
    param(
        [string]$Error,
        [string]$Guidance
    )
    Write-Status "✗" $Error "Red"
    Write-Host "  Fix: $Guidance" -ForegroundColor Yellow
}

try {
    $errors = @()
    $warnings = @()

    # Change to target directory
    Set-Location $CurrentDirectory

    # Get folder name for repo name
    $folderName = Split-Path -Leaf $CurrentDirectory
    if ([string]::IsNullOrWhiteSpace($folderName)) {
        $folderName = "new-project"
    }

    # 1. Initialize git repository
    Write-Host "`nInitializing git repository..." -ForegroundColor Cyan
    $gitInit = git init 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✓" "Repository initialized" "Green"
    } else {
        throw "git init failed: $gitInit"
    }

    # 2. Create .gitignore
    Write-Host "`nCreating .gitignore..." -ForegroundColor Cyan

    # Minimal base .gitignore
    $gitignoreContent = @"
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

# Build artifacts (general)
dist/
build/
out/
*.log

"@

    # Add project-specific rules based on selection
    $projectTypesList = $ProjectTypes -split ','
    $selectedTypes = @()

    foreach ($type in $projectTypesList) {
        $type = $type.Trim()

        switch -Wildcard ($type) {
            "*Node*" {
                $gitignoreContent += @"

# Node.js
node_modules/
package-lock.json
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*
.npm/
.eslintcache
"@
                $selectedTypes += "Node.js"
            }
            "*Python*" {
                $gitignoreContent += @"

# Python
__pycache__/
*.py[cod]
*$py.class
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
"@
                $selectedTypes += "Python"
            }
            "*Rust*" {
                $gitignoreContent += @"

# Rust
target/
**/*.rs.bk
Cargo.lock
"@
                $selectedTypes += "Rust"
            }
            "*Go*" {
                $gitignoreContent += @"

# Go
bin/
pkg/
*.exe
*.test
*.out
go.work
"@
                $selectedTypes += "Go"
            }
            "*TypeScript*" {
                $gitignoreContent += @"

# TypeScript
*.tsbuildinfo
dist/
build/
"@
                $selectedTypes += "TypeScript"
            }
            "*Java*" {
                $gitignoreContent += @"

# Java
*.class
*.jar
*.war
*.nar
target/
.mvn/
mvnw
mvnw.cmd
"@
                $selectedTypes += "Java"
            }
            "*Web*" {
                $gitignoreContent += @"

# Web/HTML/CSS
.vscode/
.idea/
dist/
build/
.cache/
"@
                $selectedTypes += "Web"
            }
        }
    }

    # Write .gitignore
    $gitignoreContent | Out-File -FilePath ".gitignore" -Encoding utf8
    $selectedTypesStr = if ($selectedTypes.Count -gt 0) { $selectedTypes -join ", " } else { "minimal base" }
    Write-Status "✓" ".gitignore created ($selectedTypesStr)" "Green"

    # 3. Create .planning/ folder
    Write-Host "`nCreating .planning/ folder..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path ".planning" -Force | Out-Null
    Write-Status "✓" ".planning/ folder created" "Green"

    # 4. Check for gh CLI and create GitHub remote
    Write-Host "`nChecking for gh CLI..." -ForegroundColor Cyan
    $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue

    if ($ghAvailable) {
        # Check if authenticated
        $authCheck = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Create repository
            Write-Host "Creating GitHub repository..." -ForegroundColor Cyan
            $createRepo = gh repo create "$folderName" --public --source="$CurrentDirectory" --remote=origin --push 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Status "✓" "GitHub remote created: https://github.com/$GitHubUsername/$folderName" "Green"
            } else {
                $warnings += "GitHub remote creation failed: $createRepo"
                Write-Status "⚠" "GitHub remote creation failed" "Yellow"
                Write-Host "  To add manually:" -ForegroundColor Yellow
                Write-Host "    git remote add origin https://github.com/$GitHubUsername/$folderName.git" -ForegroundColor Yellow
            }
        } else {
            $warnings += "gh CLI not authenticated"
            Write-Host "`n⚠ gh CLI not authenticated" -ForegroundColor Yellow
            Write-Host "  Run 'gh auth login' to authenticate, then:" -ForegroundColor Yellow
            Write-Host "    git remote add origin https://github.com/$GitHubUsername/$folderName.git" -ForegroundColor Yellow
            Write-Host "    git push -u origin main" -ForegroundColor Yellow
        }
    } else {
        $warnings += "gh CLI not found"
        Write-Host "`n⚠ gh CLI not found. GitHub remote will be skipped." -ForegroundColor Yellow
        Write-Host "  Install gh from https://cli.github.com/ to enable remote creation." -ForegroundColor Yellow
        Write-Host "  To add remote manually:" -ForegroundColor Yellow
        Write-Host "    git remote add origin https://github.com/$GitHubUsername/$folderName.git" -ForegroundColor Yellow
    }

    # 5. Make initial commit
    Write-Host "`nMaking initial commit..." -ForegroundColor Cyan
    git add .gitignore 2>&1 | Out-Null
    git commit -m "chore: initialize project with .gitignore" 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Status "✓" "Initial commit made" "Green"
    } else {
        $errors += "git commit failed"
        Write-Error-Guidance "git commit failed" "Check git configuration (user.name, user.email)"
    }

    # Summary
    Write-Host "`n" -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host " INIT-FOLDER COMPLETE" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "`nYour project is ready! Next steps:" -ForegroundColor Green
    Write-Host "1. Start coding" -ForegroundColor White
    Write-Host "2. Plan your work: /gsd-discuss-phase 1" -ForegroundColor White
    Write-Host "3. View status: git status" -ForegroundColor White

    if ($ghAvailable -and $authCheck -and $LASTEXITCODE -eq 0) {
        Write-Host "`nRemote: https://github.com/$GitHubUsername/$folderName" -ForegroundColor Cyan
    }

    if ($warnings.Count -gt 0) {
        Write-Host "`nWarnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  ⚠ $warning" -ForegroundColor Yellow
        }
    }

    Write-Host ""

} catch {
    Write-Host "`n" -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host " INIT-FOLDER FAILED" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "`n$($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nTo fix:" -ForegroundColor Yellow
    Write-Host "1. Check if git is installed: git --version" -ForegroundColor White
    Write-Host "2. Check folder permissions" -ForegroundColor White
    Write-Host "3. Ensure folder is empty or doesn't already have a .git/ directory" -ForegroundColor White
    Write-Host ""
    exit 1
}
