#!/bin/bash

##############################################################################
# Claude Code Auto-Format Hook
#
# This script runs after Write/Edit operations to auto-format code.
# It detects file type and applies the appropriate formatter.
#
# Exit Codes:
#   0 - Formatting successful or not needed
#   (Non-zero exits are non-blocking for formatting hooks)
##############################################################################

# Configuration
LOG_FILE="$HOME/.claude/logs/format.log"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Check if formatter exists
has_formatter() {
    command -v "$1" >/dev/null 2>&1
}

# Format based on file extension
format_file() {
    local file="$1"
    local ext="${file##*.}"

    case "$ext" in
        ts|tsx|js|jsx|json|css|scss|md|html|yaml|yml)
            if has_formatter prettier; then
                prettier --write "$file" 2>/dev/null
                log_message "INFO" "Formatted with prettier: $file"
            fi
            ;;
        py)
            if has_formatter black; then
                black "$file" 2>/dev/null
                log_message "INFO" "Formatted with black: $file"
            elif has_formatter autopep8; then
                autopep8 --in-place "$file" 2>/dev/null
                log_message "INFO" "Formatted with autopep8: $file"
            fi
            # Also sort imports if isort available
            if has_formatter isort; then
                isort "$file" 2>/dev/null
            fi
            ;;
        go)
            if has_formatter gofmt; then
                gofmt -w "$file" 2>/dev/null
                log_message "INFO" "Formatted with gofmt: $file"
            fi
            ;;
        rs)
            if has_formatter rustfmt; then
                rustfmt "$file" 2>/dev/null
                log_message "INFO" "Formatted with rustfmt: $file"
            fi
            ;;
        rb)
            if has_formatter rubocop; then
                rubocop -a "$file" 2>/dev/null
                log_message "INFO" "Formatted with rubocop: $file"
            fi
            ;;
        php)
            if has_formatter php-cs-fixer; then
                php-cs-fixer fix "$file" 2>/dev/null
                log_message "INFO" "Formatted with php-cs-fixer: $file"
            fi
            ;;
        swift)
            if has_formatter swiftformat; then
                swiftformat "$file" 2>/dev/null
                log_message "INFO" "Formatted with swiftformat: $file"
            fi
            ;;
        *)
            log_message "DEBUG" "No formatter for extension: $ext"
            ;;
    esac
}

##############################################################################
# MAIN EXECUTION
##############################################################################

# Parse input from Claude Code
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
    # Try alternate path for different tool formats
    FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // empty' 2>/dev/null)
fi

if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    log_message "INFO" "Auto-format triggered for: $FILE_PATH"
    format_file "$FILE_PATH"
else
    log_message "DEBUG" "No file path found or file doesn't exist"
fi

# Always exit successfully - formatting should never block
exit 0
