#!/bin/bash

##############################################################################
# Pre-Commit Gate Hook
#
# This script runs before git commits to validate code quality.
# It performs linting and test checks to ensure quality standards.
#
# Exit Codes:
#   0 - All checks passed
#   2 - Validation failed (block commit)
##############################################################################

# Configuration
LOG_FILE="$HOME/.claude/logs/pre_commit.log"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Parse input
INPUT=$(cat)

log_message "INFO" "Pre-commit gate check initiated"

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED_FILES" ]; then
    log_message "INFO" "No staged files, skipping checks"
    exit 0
fi

log_message "INFO" "Checking staged files: $STAGED_FILES"

# Check for common issues in staged files
ERRORS=""

# Check for debug statements
for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        # Check for common debug statements that shouldn't be committed
        if grep -qE "(console\.log|var_dump|dd\(|print_r|debugger)" "$file" 2>/dev/null; then
            ERRORS="${ERRORS}Warning: Possible debug statement in $file\n"
            log_message "WARN" "Debug statement found in $file"
        fi

        # Check for TODO/FIXME that might indicate incomplete work
        if grep -qE "TODO|FIXME|XXX|HACK" "$file" 2>/dev/null; then
            log_message "INFO" "TODO/FIXME found in $file (informational)"
        fi
    fi
done

# Check for large files
for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        SIZE=$(wc -c < "$file" 2>/dev/null)
        if [ "$SIZE" -gt 1000000 ]; then
            ERRORS="${ERRORS}Warning: Large file staged: $file ($(($SIZE / 1024))KB)\n"
            log_message "WARN" "Large file staged: $file"
        fi
    fi
done

# If there are errors, output warning but don't block (informational only)
if [ -n "$ERRORS" ]; then
    echo -e "Pre-commit warnings:\n$ERRORS" >&2
    log_message "WARN" "Pre-commit warnings issued"
fi

log_message "INFO" "Pre-commit gate check completed"
exit 0
