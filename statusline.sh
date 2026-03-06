#!/usr/bin/env bash
# Claude Code status line: context usage progress bar

INPUT=$(cat)

USED_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "unknown"')
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0')

# Round percentage to integer
PCT=$(printf '%.0f' "$USED_PCT")

# Progress bar (10 chars wide)
BAR_WIDTH=10
FILLED=$(( PCT * BAR_WIDTH / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))

# Color thresholds
if [ "$PCT" -ge 90 ]; then
  COLOR="\033[31m"  # red
elif [ "$PCT" -ge 70 ]; then
  COLOR="\033[33m"  # yellow
else
  COLOR="\033[32m"  # green
fi
RESET="\033[0m"

# Build bar
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

# Format cost
COST_FMT=$(printf '$%.2f' "$COST")

printf "[%s] ${COLOR}%s${RESET} %d%% ctx | %s" "$MODEL" "$BAR" "$PCT" "$COST_FMT"
