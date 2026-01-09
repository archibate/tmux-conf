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

# Run fresh brief to get current state
current_report=$($BRIEF_SCRIPT 2>/dev/null)

# Parse and group by priority
declare -a high_issues medium_issues
high_count=0
medium_count=0

while IFS= read -r line; do
    if [[ "$line" =~ ^(🔴|🟡)\ ([^:]+:[0-9]+)\ -\ (.*)$ ]]; then
        emoji="${BASH_REMATCH[1]}"
        session_window="${BASH_REMATCH[2]}"
        description="${BASH_REMATCH[3]}"

        # Check if this is a new issue
        local new_marker=""
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
cat << 'EOF'
╔═══════════════════════════════════════════╗
║           TMUX BRIEF REPORT              ║
╠═══════════════════════════════════════════╣
║                                           ║
EOF

# Helper to print a row
print_row() {
    local text="$1"
    # Pad to 41 chars (inner width)
    local padded=$(printf "%-41s" "$text")
    echo "║ ${padded} ║"
}

# Print high priority section
if [[ $high_count -gt 0 ]]; then
    print_row "${C_RED}🔴 HIGH PRIORITY${C_RESET} ${C_GRAY}(${high_count})${C_RESET}"
    echo "║                                           ║"
    for issue in "${high_issues[@]}"; do
        # Truncate if too long (max 39 chars to fit in box)
        local truncated="${issue:0:39}"
        print_row "$truncated"
    done
    echo "║                                           ║"
fi

# Print medium priority section
if [[ $medium_count -gt 0 ]]; then
    print_row "${C_YELLOW}🟡 MEDIUM PRIORITY${C_RESET} ${C_GRAY}(${medium_count})${C_RESET}"
    echo "║                                           ║"
    for issue in "${medium_issues[@]}"; do
        local truncated="${issue:0:39}"
        print_row "$truncated"
    done
    echo "║                                           ║"
fi

# All clear message
if [[ $high_count -eq 0 && $medium_count -eq 0 ]]; then
    print_row "${C_GREEN}✅ All clear - no issues detected${C_RESET}"
    echo "║                                           ║"
fi

# Footer with last check time
if [[ -n "$last_check_time" ]]; then
    print_row "${C_GRAY}Last check: ${last_check_time}${C_RESET}"
else
    print_row "${C_GRAY}Press any key to close...${C_RESET}"
fi

cat << 'EOF'
╚═══════════════════════════════════════════╝
EOF

# Wait for any key press (timeout after 5 minutes if no input)
read -n1 -s -t 300
