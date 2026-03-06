#!/bin/bash
# Agent Indicator Hook - Shows which agent is currently working

# Read JSON input from stdin
INPUT=$(cat)

# Extract the subagent_type from the tool input
AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

if [ -n "$AGENT_TYPE" ]; then
    # Create a visual banner for the agent
    BANNER="════════════════════════════════════════════════════"

    # Map agent types to emoji indicators for better visibility
    case "$AGENT_TYPE" in
        "elite-performance-optimizer")
            ICON="⚡"
            ;;
        "elite-project-architect")
            ICON="🏗️"
            ;;
        "elite-devops-automation")
            ICON="🚀"
            ;;
        "elite-database-specialist")
            ICON="🗄️"
            ;;
        "elite-project-orchestrator")
            ICON="🎯"
            ;;
        "elite-project-manager")
            ICON="📋"
            ;;
        "elite-fullstack-developer")
            ICON="💻"
            ;;
        "Explore")
            ICON="🔍"
            ;;
        "Plan")
            ICON="📝"
            ;;
        "Bash")
            ICON="🖥️"
            ;;
        *)
            ICON="🤖"
            ;;
    esac

    # Output to stderr so it appears in the UI
    echo "" >&2
    echo "$BANNER" >&2
    echo "$ICON  AGENT: $AGENT_TYPE" >&2
    echo "$BANNER" >&2
    echo "" >&2
fi

# Always exit 0 to allow the tool to proceed
exit 0
