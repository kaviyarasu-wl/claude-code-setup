#!/bin/bash

##############################################################################
# Claude Code Session Start Hook
#
# This script runs when a Claude Code session starts.
# It verifies the development environment and sets up prerequisites.
#
# Exit Codes:
#   0 - Environment ready, allow session
#   2 - Critical issue, block session (with error message)
##############################################################################

# Configuration
LOG_FILE="$HOME/.claude/logs/session_start.log"
REQUIRED_TOOLS=("git" "curl")
RECOMMENDED_TOOLS=("node" "npm" "python3" "docker" "gh")

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get tool version safely
get_version() {
    local tool="$1"
    case "$tool" in
        git) git --version 2>/dev/null | head -1 ;;
        node) node --version 2>/dev/null ;;
        npm) npm --version 2>/dev/null ;;
        python3) python3 --version 2>/dev/null ;;
        docker) docker --version 2>/dev/null | head -1 ;;
        gh) gh --version 2>/dev/null | head -1 ;;
        curl) curl --version 2>/dev/null | head -1 ;;
        *) echo "unknown" ;;
    esac
}

##############################################################################
# MAIN EXECUTION
##############################################################################

log_message "INFO" "=== Session starting ==="
log_message "INFO" "User: $(whoami)"
log_message "INFO" "Working directory: $(pwd)"
log_message "INFO" "Shell: $SHELL"

# Check required tools
missing_required=()
for tool in "${REQUIRED_TOOLS[@]}"; do
    if command_exists "$tool"; then
        log_message "INFO" "Required tool found: $tool ($(get_version "$tool"))"
    else
        missing_required+=("$tool")
        log_message "ERROR" "Required tool missing: $tool"
    fi
done

# If required tools are missing, block session
if [ ${#missing_required[@]} -gt 0 ]; then
    cat >&2 <<EOF
Warning: Missing required tools: ${missing_required[*]}

Some Claude Code features may not work properly.
Please install the missing tools.
EOF
    # Don't block, just warn
fi

# Check recommended tools (informational only)
for tool in "${RECOMMENDED_TOOLS[@]}"; do
    if command_exists "$tool"; then
        log_message "INFO" "Recommended tool found: $tool ($(get_version "$tool"))"
    else
        log_message "WARN" "Recommended tool not installed: $tool"
    fi
done

# Check git configuration
if command_exists git; then
    GIT_USER=$(git config --global user.name 2>/dev/null)
    GIT_EMAIL=$(git config --global user.email 2>/dev/null)
    if [ -n "$GIT_USER" ] && [ -n "$GIT_EMAIL" ]; then
        log_message "INFO" "Git configured: $GIT_USER <$GIT_EMAIL>"
    else
        log_message "WARN" "Git user not fully configured"
    fi
fi

# Check if in a git repository
if git rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    log_message "INFO" "Git repository detected, branch: $BRANCH"
fi

# Log environment info
log_message "INFO" "PATH: $PATH"
log_message "INFO" "=== Session start complete ==="

# Always allow session to proceed
exit 0
