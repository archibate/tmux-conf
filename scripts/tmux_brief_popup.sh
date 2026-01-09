#!/usr/bin/env bash
# Popup viewer for tmux_brief report
# Shows current issues with NEW markers
# Usage: tmux_brief_popup.sh

STATE_SCRIPT="$HOME/.config/tmux/scripts/tmux_brief_state.sh"
BRIEF_SCRIPT="$HOME/.config/tmux/scripts/tmux_brief.sh"

# Tmux options
OPTION_NEW_ISSUES="@brief-new-issues"
OPTION_LAST_UPDATE="@brief-last-update"
OPTION_COUNT_HIGH="@brief-count-high"
OPTION_COUNT_MEDIUM="@brief-count-medium"

# Gruvbox colors
C_RED=$'\033[38;2;204;36;29m'       # #cc241d
C_YELLOW=$'\033[38;2;215;153;33m'    # #d79921
C_GREEN=$'\033[38;2;184;187;38m'     # #b8bb26
C_GRAY=$'\033[38;2;146;131;116m'     # #928374
C_BRIGHT=$'\033[38;2;220;224;232m'    # #d5c4a1
C_RESET=$'\033[0m'

# Get new issues from tmux option (pipe-separated, with \| escapes)
new_issues_raw=$(tmux show-option -gv "$OPTION_NEW_ISSUES" 2>/dev/null || echo "")

# Convert back to newline-separated and unescape pipes
new_issues=$(echo "$new_issues_raw" | sed 's/|/\n/g' | sed 's/\\|/|/g')

# Create a lookup for new issues
declare -A is_new
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Extract session:window for lookup
        key=$(echo "$line" | sed 's/🔴 \|🟡 //' | sed 's/ - .*//')
        is_new["$key"]=1
    fi
done <<< "$new_issues"

# Try to get stored report first (faster, more reliable)
STATE_DIR="${TMPDIR:-/tmp}/tmux_brief"
CURRENT_REPORT="$STATE_DIR/current_report"

current_report=""
if [[ -f "$CURRENT_REPORT" ]]; then
    current_report=$(cat "$CURRENT_REPORT" 2>/dev/null)
fi

# If stored report is empty or only whitespace, run fresh brief
if [[ -z "$current_report" ]] || [[ $(echo "$current_report" | wc -l) -lt 2 ]]; then
    current_report=$($BRIEF_SCRIPT 2>/dev/null)
fi

# If still empty, show message and exit
if [[ -z "$current_report" ]]; then
    clear
    echo "No report available. Brief may be running or no issues detected."
    echo ""
    echo "Press any key to close..."
    read -n1 -s -t 300
    exit 0
fi

# Parse and group by priority
declare -a high_issues medium_issues
high_count=0
medium_count=0

while IFS= read -r line; do
    # Parse using simple string operations (more reliable than regex for emojis)
    # Extract emoji
    if [[ "$line" == 🔴* ]]; then
        emoji="🔴"
    elif [[ "$line" == 🟡* ]]; then
        emoji="🟡"
    else
        continue
    fi

    # Extract rest after emoji
    rest="${line#* }"

    # Split by " - " to get key and description
    key="${rest%% -*}"
    desc="${rest#* - }"

    # Only process high/medium priority (ignore green/low)
    session_window="$key"
    description="$desc"

    # Check if this is a new issue
    new_marker=""
    if [[ -n "${is_new[$session_window]}" ]]; then
        new_marker="${C_YELLOW}⚡${C_RESET} "
    fi

    if [[ "$emoji" == "🔴" ]]; then
        high_issues+=("${C_RED}${emoji}${C_RESET} ${new_marker}${C_BRIGHT}${session_window}${C_RESET} - ${description}")
        ((high_count++))
    else
        medium_issues+=("${C_YELLOW}${emoji}${C_RESET} ${new_marker}${C_BRIGHT}${session_window}${C_RESET} - ${description}")
        ((medium_count++))
    fi
done <<< "$current_report"

# Get last check time
last_update_ts=$(tmux show-option -gv "$OPTION_LAST_UPDATE" 2>/dev/null || echo "0")
last_check_time=""
if [[ -n "$last_update_ts" && "$last_update_ts" != "0" ]]; then
    last_check_time=$(date -d "@$last_update_ts" "+%H:%M" 2>/dev/null || date -r "$last_update_ts" "+%H:%M" 2>/dev/null)
fi

# Clear screen and show popup
clear
echo ""

# Print high priority section
if [[ $high_count -gt 0 ]]; then
    echo "${C_RED}🔴 HIGH PRIORITY${C_RESET} ${C_GRAY}(${high_count})${C_RESET}"
    echo ""
    for issue in "${high_issues[@]}"; do
        echo "  $issue"
    done
    echo ""
fi

# Print medium priority section
if [[ $medium_count -gt 0 ]]; then
    echo "${C_YELLOW}🟡 MEDIUM PRIORITY${C_RESET} ${C_GRAY}(${medium_count})${C_RESET}"
    echo ""
    for issue in "${medium_issues[@]}"; do
        echo "  $issue"
    done
    echo ""
fi

# All clear message
if [[ $high_count -eq 0 && $medium_count -eq 0 ]]; then
    echo "${C_GREEN}✅ All clear - no issues detected${C_RESET}"
    echo ""
fi

# Footer with last check time
if [[ -n "$last_check_time" ]]; then
    echo "${C_GRAY}Last check: ${last_check_time}${C_RESET}"
else
    echo "${C_GRAY}Press any key to close...${C_RESET}"
fi

echo ""

# Wait for any key press (timeout after 5 minutes if no input)
read -n1 -s -t 300
