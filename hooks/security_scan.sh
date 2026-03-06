#!/bin/bash

##############################################################################
# Claude Code Security Scan Hook
#
# This script runs before Bash operations to check for dangerous commands.
# It blocks potentially destructive or malicious operations.
#
# Exit Codes:
#   0 - Command is safe
#   2 - Command is blocked (dangerous)
##############################################################################

# Configuration
LOG_FILE="$HOME/.claude/logs/security.log"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Check if command is dangerous
is_dangerous_command() {
    local cmd="$1"

    # Dangerous patterns
    local dangerous_patterns=(
        # Destructive file operations
        "rm -rf /"
        "rm -rf /*"
        "rm -rf ~"
        ": > /dev/sd"
        "mkfs"
        "dd if=.*/dev/"

        # Fork bombs
        ":(){ :|:& };:"
        "fork while"

        # System modification
        "chmod -R 777 /"
        "chown -R.*/"

        # Network attacks
        "nc -e"
        "bash -i.*>&.*/dev/tcp"
        "curl.*|.*bash"
        "wget.*|.*bash"
        "curl.*|.*sh"
        "wget.*|.*sh"

        # Credential theft
        "cat.*/etc/shadow"
        "cat.*/etc/passwd"
        "cat.*\.ssh/id_"

        # History manipulation
        "history -c"
        "shred.*history"

        # Crypto mining indicators
        "xmrig"
        "minerd"
        "cpuminer"
    )

    # Check each pattern
    for pattern in "${dangerous_patterns[@]}"; do
        if echo "$cmd" | grep -qiE "$pattern"; then
            return 0  # Dangerous
        fi
    done

    return 1  # Safe
}

# Check for suspicious patterns that warrant warning
has_suspicious_pattern() {
    local cmd="$1"

    local suspicious_patterns=(
        # Mass file operations
        "rm -rf"
        "find.*-delete"
        "find.*-exec.*rm"

        # Permission changes
        "chmod -R"
        "chown -R"

        # Git force operations
        "git push.*--force"
        "git push.*-f"
        "git reset --hard"

        # Database operations
        "DROP DATABASE"
        "DROP TABLE"
        "TRUNCATE"
        "DELETE FROM.*WHERE 1"

        # Environment modification
        "export PATH="
        "unset PATH"
    )

    for pattern in "${suspicious_patterns[@]}"; do
        if echo "$cmd" | grep -qiE "$pattern"; then
            return 0  # Suspicious
        fi
    done

    return 1  # Clean
}

##############################################################################
# MAIN EXECUTION
##############################################################################

# Parse input from Claude Code
INPUT=$(cat)

# Extract command from tool input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
    log_message "DEBUG" "No command found in input"
    exit 0
fi

log_message "INFO" "Security scan for command: $COMMAND"

# Check for dangerous commands
if is_dangerous_command "$COMMAND"; then
    log_message "BLOCKED" "Dangerous command blocked: $COMMAND"
    cat >&2 <<EOF
Security Alert: Dangerous command blocked

The following command has been blocked for security reasons:
$COMMAND

This command matches patterns known to be destructive or malicious.
If you believe this is a false positive, please review the command
and try a safer alternative.
EOF
    exit 2
fi

# Check for suspicious patterns (warning only)
if has_suspicious_pattern "$COMMAND"; then
    log_message "WARN" "Suspicious pattern detected: $COMMAND"
    # Don't block, just log the warning
fi

log_message "INFO" "Command approved: $COMMAND"
exit 0
