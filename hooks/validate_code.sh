#!/bin/bash

##############################################################################
# Claude Code Validation Hook
#
# This script runs before Write/Edit operations to validate code.
# It performs basic syntax checking and linting.
#
# Exit Codes:
#   0 - Validation passed
#   2 - Validation failed (blocks the operation)
##############################################################################

# Configuration
LOG_FILE="$HOME/.claude/logs/validate.log"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Check if tool exists
has_tool() {
    command -v "$1" >/dev/null 2>&1
}

# Validate syntax based on file extension
validate_syntax() {
    local file="$1"
    local content="$2"
    local ext="${file##*.}"
    local temp_file

    # Create temp file for validation
    temp_file=$(mktemp "/tmp/validate.XXXXXX.$ext")
    echo "$content" > "$temp_file"

    local result=0

    case "$ext" in
        py)
            if has_tool python3; then
                python3 -m py_compile "$temp_file" 2>/dev/null
                result=$?
            fi
            ;;
        js|jsx)
            if has_tool node; then
                node --check "$temp_file" 2>/dev/null
                result=$?
            fi
            ;;
        ts|tsx)
            # TypeScript syntax check is complex, skip for now
            result=0
            ;;
        json)
            if has_tool jq; then
                jq empty "$temp_file" 2>/dev/null
                result=$?
            elif has_tool python3; then
                python3 -c "import json; json.load(open('$temp_file'))" 2>/dev/null
                result=$?
            fi
            ;;
        yaml|yml)
            if has_tool python3; then
                python3 -c "import yaml; yaml.safe_load(open('$temp_file'))" 2>/dev/null
                result=$?
            fi
            ;;
        sh|bash)
            if has_tool bash; then
                bash -n "$temp_file" 2>/dev/null
                result=$?
            fi
            ;;
        rb)
            if has_tool ruby; then
                ruby -c "$temp_file" 2>/dev/null
                result=$?
            fi
            ;;
        go)
            # Go syntax requires full package, skip
            result=0
            ;;
        *)
            # Unknown extension, skip validation
            result=0
            ;;
    esac

    rm -f "$temp_file"
    return $result
}

# Check for common dangerous patterns
check_dangerous_patterns() {
    local content="$1"
    local file="$2"
    local warnings=""

    # Check for hardcoded secrets (simplified)
    if echo "$content" | grep -qiE '(password|secret|api_key|apikey|token)\s*=\s*["\x27][^"\x27]{8,}["\x27]'; then
        warnings="$warnings\n- Potential hardcoded secret detected"
    fi

    # Check for eval usage
    if echo "$content" | grep -qE '\beval\s*\('; then
        warnings="$warnings\n- eval() usage detected - potential security risk"
    fi

    # Check for SQL concatenation (basic)
    if echo "$content" | grep -qE 'SELECT.*\+.*FROM|INSERT.*\+.*INTO|WHERE.*\+'; then
        warnings="$warnings\n- Potential SQL injection: string concatenation in query"
    fi

    if [ -n "$warnings" ]; then
        echo -e "Warnings:$warnings"
        return 1
    fi
    return 0
}

##############################################################################
# MAIN EXECUTION
##############################################################################

# Parse input from Claude Code
INPUT=$(cat)

# Extract file path and content
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null)
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .content // empty' 2>/dev/null)

# If no content in input, this might be an Edit operation
if [ -z "$CONTENT" ]; then
    NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null)
    if [ -n "$NEW_STRING" ]; then
        CONTENT="$NEW_STRING"
    fi
fi

if [ -z "$FILE_PATH" ]; then
    log_message "DEBUG" "No file path found, skipping validation"
    exit 0
fi

log_message "INFO" "Validating: $FILE_PATH"

# Run syntax validation
if [ -n "$CONTENT" ]; then
    if ! validate_syntax "$FILE_PATH" "$CONTENT"; then
        log_message "ERROR" "Syntax validation failed: $FILE_PATH"
        echo "Syntax error detected in $FILE_PATH" >&2
        # Don't block, just warn
        # exit 2
    fi

    # Check for dangerous patterns (warning only)
    check_dangerous_patterns "$CONTENT" "$FILE_PATH" >/dev/null 2>&1
fi

log_message "INFO" "Validation passed: $FILE_PATH"
exit 0
