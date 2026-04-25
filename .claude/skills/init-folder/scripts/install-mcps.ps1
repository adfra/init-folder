# install-mcps.ps1 - Install MCP servers from existing configurations
# Usage: ./install-mcps.ps1 -SelectedMCPs "mcp-server-1,mcp-server-2" -SourcePaths "path1,path2"

param(
    [Parameter(Mandatory=$false)]
    [string]$SelectedMCPs = "",

    [Parameter(Mandatory=$false)]
    [string]$SourcePaths = "",

    [Parameter(Mandatory=$false)]
    [string]$CurrentDirectory = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param(
        [string]$Symbol,
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host "$Symbol $Message" -ForegroundColor $Color
}

try {
    Set-Location $CurrentDirectory

    # Create .claude directory if it doesn't exist
    $claudeDir = ".claude"
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    # Initialize empty config structures
    $claudeConfig = @{ mcpServers = @{} }
    $localConfig = @{ mcpServers = @{} }

    # Parse source paths and selected MCPs
    $pathsToSearch = if ($SourcePaths) { $SourcePaths -split ',' } else @()
    $mcpList = if ($SelectedMCPs) { $SelectedMCPs -split ',' } else @()

    Write-Host "`nScanning for MCP configurations..." -ForegroundColor Cyan

    # Scan each source path for MCP configurations
    foreach ($path in $pathsToSearch) {
        $path = $path.Trim()
        if (-not (Test-Path $path)) {
            Write-Status "⚠" "Path not found: $path" "Yellow"
            continue
        }

        # Look for claude.json or claude.local.json
        $configFiles = @(
            (Join-Path $path ".claude" "claude.json"),
            (Join-Path $path ".claude" "claude.local.json"),
            (Join-Path $path "claude.json"),
            (Join-Path $path "claude.local.json")
        )

        foreach ($configFile in $configFiles) {
            if (Test-Path $configFile) {
                Write-Host "  Found: $configFile" -ForegroundColor DarkGray

                try {
                    $config = Get-Content $configFile -Raw | ConvertFrom-Json

                    if ($config.mcpServers) {
                        foreach ($serverName in $config.mcpServers.PSObject.Properties.Name) {
                            $serverConfig = $config.mcpServers.$serverName

                            # Check if this MCP was selected
                            if ($mcpList -contains $serverName) {
                                # Determine if it has sensitive data (environment variables, secrets)
                                $hasSensitiveData = $serverConfig.PSObject.Properties.Name -match "env|password|secret|token|key|credential" -or $configFile -like "*.local.json"

                                if ($hasSensitiveData) {
                                    $localConfig.mcpServers.$serverName = $serverConfig
                                    Write-Status "  →" "$serverName (credentials → claude.local.json)" "DarkCyan"
                                } else {
                                    $claudeConfig.mcpServers.$serverName = $serverConfig
                                    Write-Status "  →" "$serverName (config → claude.json)" "DarkGreen"
                                }
                            }
                        }
                    }
                } catch {
                    Write-Status "⚠" "Failed to parse $configFile" "Yellow"
                }
            }
        }
    }

    # Write claude.json
    if ($claudeConfig.mcpServers.PSObject.Properties.Count -gt 0) {
        $claudeJson = $claudeConfig | ConvertTo-Json -Depth 10
        $claudeJson | Out-File -FilePath (Join-Path $claudeDir "claude.json") -Encoding utf8
        Write-Status "✓" "Created .claude/claude.json with $($claudeConfig.mcpServers.PSObject.Properties.Count) server(s)" "Green"
    } else {
        Write-Host "  No non-sensitive MCP configurations to write" -ForegroundColor DarkGray
    }

    # Write claude.local.json
    if ($localConfig.mcpServers.PSObject.Properties.Count -gt 0) {
        $localJson = $localConfig | ConvertTo-Json -Depth 10
        $localJson | Out-File -FilePath (Join-Path $claudeDir "claude.local.json") -Encoding utf8
        Write-Status "✓" "Created .claude/claude.local.json with $($localConfig.mcpServers.PSObject.Properties.Count) server(s)" "Green"

        # Ensure *.local is in .gitignore
        $gitignorePath = ".gitignore"
        if (Test-Path $gitignorePath) {
            $gitignoreContent = Get-Content $gitignorePath -Raw
            if ($gitignoreContent -notmatch "\*\.local") {
                $gitignoreContent += "`n# Local Claude configurations`n*.local`n*.local.json`n"
                $gitignoreContent | Out-File -FilePath $gitignorePath -Encoding utf8
                Write-Status "✓" "Updated .gitignore with *.local pattern" "Green"
            }
        }
    } else {
        Write-Host "  No sensitive MCP configurations to write" -ForegroundColor DarkGray
    }

    # Summary
    $totalInstalled = $claudeConfig.mcpServers.PSObject.Properties.Count + $localConfig.mcpServers.PSObject.Properties.Count

    Write-Host "`n" -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host " MCP INSTALLATION COMPLETE" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "`nInstalled $totalInstalled MCP server(s)" -ForegroundColor Green

    if ($localConfig.mcpServers.PSObject.Properties.Count -gt 0) {
        Write-Host "`n⚠ Credentials are in .claude/claude.local.json (not in git)" -ForegroundColor Yellow
    }

    Write-Host ""

} catch {
    Write-Host "`n" -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host " MCP INSTALLATION FAILED" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "`n$($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
