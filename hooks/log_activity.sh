#!/bin/bash

##############################################################################
# Claude Code Activity Logging Hook
#
# This script runs when a Claude Code session ends (Stop event).
# It logs session activity for auditing and analytics.
#
# Exit Codes:
#   0 - Always succeeds (logging should never block)
##############################################################################

# Configuration
LOG_FILE="$HOME/.claude/logs/activity.log"
STATS_FILE="$HOME/.claude/logs/session_stats.log"

# Logging function
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Parse input from Claude Code (if available)
parse_input() {
    # Read from stdin if available
    if [ -t 0 ]; then
        echo "{}"
    else
        cat
    fi
}

##############################################################################
# MAIN EXECUTION
##############################################################################

# Get input data
INPUT=$(parse_input)

# Log session end
log_message "=== Session ended ==="
log_message "Working directory: $(pwd)"
log_message "User: $(whoami)"

# Extract stats from environment if available
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
log_message "Session ID: $SESSION_ID"

# Log to stats file for analytics
{
    echo "---"
    echo "timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "session_id: $SESSION_ID"
    echo "working_directory: $(pwd)"
    echo "user: $(whoami)"
    echo "hostname: $(hostname)"

    # Check if we're in a git repo and log info
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "git_branch: $(git branch --show-current 2>/dev/null)"
        echo "git_repo: $(basename "$(git rev-parse --show-toplevel 2>/dev/null)")"

        # Count recent commits in session (last hour)
        RECENT_COMMITS=$(git log --oneline --since="1 hour ago" 2>/dev/null | wc -l | tr -d ' ')
        echo "recent_commits: $RECENT_COMMITS"
    fi

    echo ""
} >> "$STATS_FILE"

log_message "Activity logged successfully"

# Always exit successfully - logging should never block
exit 0
