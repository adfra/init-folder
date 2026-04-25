#!/bin/bash
# install-mcps.sh - Install MCP servers from existing configurations
# Usage: ./install-mcps.sh --selected-mcps "mcp-server-1,mcp-server-2" --source-paths "path1,path2"

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DARK_GRAY='\033[0;90m'
DARK_CYAN='\033[0;36m'
DARK_GREEN='\033[0;32m'
WHITE='\033[0;37m'
NC='\033[0m'

# Default parameters
SELECTED_MCPS=""
SOURCE_PATHS=""
CURRENT_DIRECTORY="$(pwd)"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --selected-mcps)
            SELECTED_MCPS="$2"
            shift 2
            ;;
        --source-paths)
            SOURCE_PATHS="$2"
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

# Helper function
write_status() {
    local symbol="$1"
    local message="$2"
    local color="${3:-$WHITE}"
    echo -e "${color}${symbol} ${message}${NC}"
}

# Function to determine MCP server installation type
get_mcp_install_type() {
    local command="$1"
    local args="$2"

    # npx-based servers
    if [[ "$command" == "npx" ]] || echo "$args" | grep -q "npx"; then
        echo "npx"
    # Check if it's in ~/.claude/mcp/ (source installation)
    elif echo "$args" | grep -q "\.claude/mcp/"; then
        echo "source"
    # Global npm packages
    elif [[ "$command" == "node" ]] || [[ "$command" == "npm" ]]; then
        echo "global"
    else
        echo "unknown"
    fi
}

# Function to suggest installation command
get_install_suggestion() {
    local server_name="$1"
    local install_type="$2"

    case "$install_type" in
        npx)
            echo "No installation needed - runs via npx"
            ;;
        source)
            echo "Already installed in ~/.claude/mcp/$server_name/"
            ;;
        global)
            echo "Install with: npm install -g $server_name"
            ;;
        *)
            echo "Manual installation required"
            ;;
    esac
}

# Function to sanitize server config by removing problematic env vars
sanitize_server_config() {
    local server_config="$1"

    # Remove environment variables that may cause issues
    # These patterns match problematic variable names that shouldn't be copied
    local problematic_patterns=(
        "VAPI_URL"
        "VAPI_KEY"
        "VAPI_TOKEN"
        "WEBHOOK_URL"
        "WEBHOOK_KEY"
        "CALL_WEBHOOK"
        "PHONE_NUMBER"
        "ASSISTANT_ID"
    )

    # Build a jq filter to remove these env keys
    local jq_filter="."
    for pattern in "${problematic_patterns[@]}"; do
        jq_filter="$jq_filter | del(.env[\"$pattern\"]?)"
    done

    # Apply the filter if env exists
    if echo "$server_config" | jq -e '.env' >/dev/null 2>&1; then
        echo "$server_config" | jq "$jq_filter" 2>/dev/null || echo "$server_config"
    else
        echo "$server_config"
    fi
}

# Change to target directory
cd "$CURRENT_DIRECTORY" 2>/dev/null || { write_status "✗" "Cannot access directory: $CURRENT_DIRECTORY" "$RED"; exit 1; }

# Initialize empty JSON structures
MCP_CONFIG='{"mcpServers": {}}'
LOCAL_CONFIG='{"mcpServers": {}}'

# Parse source paths and selected MCPs
IFS=',' read -ra PATHS_TO_SEARCH <<< "$SOURCE_PATHS"
IFS=',' read -ra MCP_LIST <<< "$SELECTED_MCPS"

echo ""
write_status "" "Scanning for MCP configurations..." "$CYAN"

# Scan each source path for MCP configurations
for path in "${PATHS_TO_SEARCH[@]}"; do
    path=$(echo "$path" | xargs) # trim whitespace
    if [[ ! -d "$path" ]]; then
        write_status "⚠" "Path not found: $path" "$YELLOW"
        continue
    fi

    # Look for .mcp.json, .mcp.local.json, or .claude/claude.json, .claude/claude.local.json
    config_files=(
        "$path/.mcp.json"
        "$path/.mcp.local.json"
        "$path/.claude/claude.json"
        "$path/.claude/claude.local.json"
    )

    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            echo -e "${DARK_GRAY}  Found: $config_file${NC}"

            # Try to parse the JSON file
            if server_names=$(jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null); then
                while IFS= read -r server_name; do
                    # Check if this MCP was selected
                    if echo " ${MCP_LIST[*]} " | grep -q " $server_name "; then
                        # Get server config
                        server_config=$(jq -r ".mcpServers.\"$server_name\"" "$config_file")

                        # Determine installation type
                        command=$(echo "$server_config" | jq -r '.command // ""' 2>/dev/null || echo "")
                        args=$(echo "$server_config" | jq -r '.args // [] | join(" ")' 2>/dev/null || echo "")
                        install_type=$(get_mcp_install_type "$command" "$args")

                        # Sanitize config to remove problematic env vars (like VAPI_URL)
                        sanitized_config=$(sanitize_server_config "$server_config")

                        # Determine if it has sensitive data
                        has_sensitive_data=false
                        # Check for sensitive keys in the server config (after sanitization)
                        if echo "$sanitized_config" | jq -e '.env' >/dev/null 2>&1; then
                            has_sensitive_data=true
                        elif echo "$sanitized_config" | jq -e 'keys[]' | grep -qE '(password|secret|token|key|credential)'; then
                            has_sensitive_data=true
                        elif [[ "$config_file" == *.local.json ]]; then
                            has_sensitive_data=true
                        fi

                        if [[ "$has_sensitive_data" == true ]]; then
                            # Add to local config
                            LOCAL_CONFIG=$(echo "$LOCAL_CONFIG" | jq --arg name "$server_name" --argjson config "$sanitized_config" '.mcpServers[$name] = $config')
                            write_status "  →" "$server_name ($install_type → .mcp.local.json)" "$DARK_CYAN"
                        else
                            # Add to non-sensitive config
                            MCP_CONFIG=$(echo "$MCP_CONFIG" --arg name "$server_name" --argjson config "$sanitized_config" '.mcpServers[$name] = $config')
                            write_status "  →" "$server_name ($install_type → .mcp.json)" "$DARK_GREEN"
                        fi

                        # Show installation suggestion
                        suggestion=$(get_install_suggestion "$server_name" "$install_type")
                        echo -e "${DARK_GRAY}     $suggestion${NC}"
                    fi
                done <<< "$server_names"
            else
                write_status "⚠" "Failed to parse $config_file (invalid JSON)" "$YELLOW"
            fi
        fi
    done
done

# Count installed servers
mcp_count=$(echo "$MCP_CONFIG" | jq -r '.mcpServers | length' 2>/dev/null || echo "0")
local_count=$(echo "$LOCAL_CONFIG" | jq -r '.mcpServers | length' 2>/dev/null || echo "0")
total_installed=$((mcp_count + local_count))

# Write .mcp.json
if [[ "$mcp_count" -gt 0 ]]; then
    echo "$MCP_CONFIG" | jq '.' > .mcp.json
    write_status "✓" "Created .mcp.json with $mcp_count server(s)" "$GREEN"
else
    echo -e "${DARK_GRAY}  No non-sensitive MCP configurations to write${NC}"
fi

# Write .mcp.local.json
if [[ "$local_count" -gt 0 ]]; then
    echo "$LOCAL_CONFIG" | jq '.' > .mcp.local.json
    write_status "✓" "Created .mcp.local.json with $local_count server(s)" "$GREEN"

    # Ensure *.local.json is in .gitignore
    if [[ -f .gitignore ]]; then
        if ! grep -q "\*\.local\.json" .gitignore; then
            echo "" >> .gitignore
            echo "# Local MCP configurations" >> .gitignore
            echo "*.local.json" >> .gitignore
            write_status "✓" "Updated .gitignore with *.local.json pattern" "$GREEN"
        fi
    fi
else
    echo -e "${DARK_GRAY}  No sensitive MCP configurations to write${NC}"
fi

# Summary
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN} MCP INSTALLATION COMPLETE${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Installed $total_installed MCP server(s)${NC}"

if [[ "$local_count" -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠ Credentials are in .mcp.local.json (not in git)${NC}"
fi

echo ""
