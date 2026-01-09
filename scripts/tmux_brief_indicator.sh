#!/usr/bin/env bash
# Status bar indicator for tmux_brief monitoring
# Shows alert when new issues are detected
# Usage: tmux_brief_indicator.sh

OPTION_STATUS="@brief-status"
OPTION_COUNT_HIGH="@brief-count-high"
OPTION_COUNT_MEDIUM="@brief-count-medium"

# Gruvbox colors
RED="#cc241d"
YELLOW="#d79921"
GRAY="#928374"
BRIGHT_RED="#fb4934"
BRIGHT_YELLOW="#fabd2f"

# Read tmux options
status=$(tmux show-option -gv "$OPTION_STATUS" 2>/dev/null || echo "idle")
high_count=$(tmux show-option -gv "$OPTION_COUNT_HIGH" 2>/dev/null || echo "0")
medium_count=$(tmux show-option -gv "$OPTION_COUNT_MEDIUM" 2>/dev/null || echo "0")

# Determine what to display
if [[ "$status" == "alert" ]]; then
    # Build the indicator
    local parts=()

    # Add high priority count (red)
    if [[ "$high_count" -gt 0 ]]; then
        parts+=("#[fg=${RED},bold]⚠${high_count}")
    fi

    # Add medium priority count (yellow)
    if [[ "$medium_count" -gt 0 ]]; then
        parts+=("#[fg=${YELLOW}]${medium_count}")
    fi

    # If no counts but status is alert, show generic warning
    if [[ ${#parts[@]} -eq 0 ]]; then
        echo "#[fg=${RED},bold]⚠"
        return
    fi

    # Join parts with space
    local IFS=" "
    echo "${parts[*]}"
else
    # Idle state - show subtle dot
    echo "#[fg=${GRAY}]·"
fi
