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

# Helper function to determine MCP server installation type
function Get-McpInstallType {
    param(
        [object]$ServerConfig
    )

    $command = $ServerConfig.command
    $args = $ServerConfig.args

    # npx-based servers
    if ($command -eq "npx" -or $args -match "npx") {
        return "npx"
    }

    # Check if it's in ~/.claude/mcp/ (source installation)
    if ($args -match "\.claude[/\\]mcp[/\\]") {
        return "source"
    }

    # Global npm packages
    if ($command -eq "node" -or $command -eq "npm") {
        return "global"
    }

    return "unknown"
}

# Helper function to suggest installation command
function Get-InstallSuggestion {
    param(
        [string]$ServerName,
        [string]$InstallType
    )

    switch ($InstallType) {
        "npx" {
            return "No installation needed - runs via npx"
        }
        "source" {
            return "Already installed in ~/.claude/mcp/$ServerName/"
        }
        "global" {
            return "Install with: npm install -g $ServerName"
        }
        default {
            return "Manual installation required"
        }
    }
}

try {
    Set-Location $CurrentDirectory

    # Initialize empty config structures
    $mcpConfig = @{ mcpServers = @{} }
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

        # Look for .mcp.json or .mcp.local.json
        $configFiles = @(
            (Join-Path $path ".mcp.json"),
            (Join-Path $path ".mcp.local.json"),
            (Join-Path $path ".claude" "claude.json"),
            (Join-Path $path ".claude" "claude.local.json")
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
                                # Determine installation type
                                $installType = Get-McpInstallType -ServerConfig $serverConfig

                                # Determine if it has sensitive data (environment variables, secrets)
                                $hasSensitiveData = $serverConfig.PSObject.Properties.Name -match "env|password|secret|token|key|credential" -or $configFile -like "*.local.json"

                                if ($hasSensitiveData) {
                                    $localConfig.mcpServers.$serverName = $serverConfig
                                    Write-Status "  →" "$serverName ($installType → .mcp.local.json)" "DarkCyan"
                                } else {
                                    $mcpConfig.mcpServers.$serverName = $serverConfig
                                    Write-Status "  →" "$serverName ($installType → .mcp.json)" "DarkGreen"
                                }

                                # Show installation suggestion if needed
                                $suggestion = Get-InstallSuggestion -ServerName $serverName -InstallType $installType
                                Write-Host "     $suggestion" -ForegroundColor DarkGray
                            }
                        }
                    }
                } catch {
                    Write-Status "⚠" "Failed to parse $configFile" "Yellow"
                }
            }
        }
    }

    # Write .mcp.json
    if ($mcpConfig.mcpServers.PSObject.Properties.Count -gt 0) {
        $mcpJson = $mcpConfig | ConvertTo-Json -Depth 10
        $mcpJson | Out-File -FilePath ".mcp.json" -Encoding utf8
        Write-Status "✓" "Created .mcp.json with $($mcpConfig.mcpServers.PSObject.Properties.Count) server(s)" "Green"
    } else {
        Write-Host "  No non-sensitive MCP configurations to write" -ForegroundColor DarkGray
    }

    # Write .mcp.local.json
    if ($localConfig.mcpServers.PSObject.Properties.Count -gt 0) {
        $localJson = $localConfig | ConvertTo-Json -Depth 10
        $localJson | Out-File -FilePath ".mcp.local.json" -Encoding utf8
        Write-Status "✓" "Created .mcp.local.json with $($localConfig.mcpServers.PSObject.Properties.Count) server(s)" "Green"

        # Ensure *.local.json is in .gitignore
        $gitignorePath = ".gitignore"
        if (Test-Path $gitignorePath) {
            $gitignoreContent = Get-Content $gitignorePath -Raw
            if ($gitignoreContent -notmatch "\*\.local\.json") {
                $gitignoreContent += "`n# Local MCP configurations`n*.local.json`n"
                $gitignoreContent | Out-File -FilePath $gitignorePath -Encoding utf8
                Write-Status "✓" "Updated .gitignore with *.local.json pattern" "Green"
            }
        }
    } else {
        Write-Host "  No sensitive MCP configurations to write" -ForegroundColor DarkGray
    }

    # Summary
    $totalInstalled = $mcpConfig.mcpServers.PSObject.Properties.Count + $localConfig.mcpServers.PSObject.Properties.Count

    Write-Host "`n" -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host " MCP INSTALLATION COMPLETE" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "`nInstalled $totalInstalled MCP server(s)" -ForegroundColor Green

    if ($localConfig.mcpServers.PSObject.Properties.Count -gt 0) {
        Write-Host "`n⚠ Credentials are in .mcp.local.json (not in git)" -ForegroundColor Yellow
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
