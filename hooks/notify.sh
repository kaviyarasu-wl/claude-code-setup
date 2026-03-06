#!/bin/bash
# Desktop notification hook for Claude Code
# Sends macOS notifications for important events

# Read JSON input from stdin
input=$(cat)

# Parse event type
event=$(echo "$input" | jq -r '.event_type // empty')

case "$event" in
  "Notification")
    message=$(echo "$input" | jq -r '.message // "Claude Code notification"')
    title=$(echo "$input" | jq -r '.title // "Claude Code"')

    # macOS notification
    if command -v osascript &> /dev/null; then
      osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\""
    fi
    ;;

  "Stop")
    # Optional: notify when Claude finishes a response
    if command -v osascript &> /dev/null; then
      osascript -e 'display notification "Task completed" with title "Claude Code" sound name "Pop"'
    fi
    ;;
esac

exit 0
