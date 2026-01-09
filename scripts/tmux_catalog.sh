#!/usr/bin/env bash
# tmux_catalog.sh - Interactive tmux window/session picker with fzf

# Colors for output
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_SESSION='\033[38;5;208m'   # Orange
readonly COLOR_WINDOW='\033[38;5;151m'    # Green
readonly COLOR_PANE='\033[38;5;109m'      # Blue
readonly COLOR_DESC='\033[38;5;245m'      # Gray

# Get one-sentence description of a pane by capturing its content
get_pane_description() {
    local pane_id="$1"
    local content

    # Capture pane content (last 50 lines should be enough)
    content=$(tmux capture-pane -t "$pane_id" -p -S -50 2>/dev/null | head -50)

    # Skip empty lines and get first meaningful line
    local description=$(echo "$content" | grep -v '^[[:space:]]*$' | head -1 | sed 's/^[[:space:]]*//')

    # If too long, truncate
    if [[ ${#description} -gt 80 ]]; then
        description="${description:0:77}..."
    fi

    # If still empty, use current command
    if [[ -z "$description" ]]; then
        description=$(tmux display-message -t "$pane_id" -p '#{pane_current_command}')
    fi

    echo "$description"
}

# Generate catalog entries
generate_catalog() {
    local current_session
    current_session=$(tmux display-message -p '#{session_name}')

    # Get all sessions, sorted by last activity (most recent first)
    tmux list-sessions -F '#{session_name} #{session_activity} #{?session_attached,(attached),(detached)}' | \
        sort -rnk2 | \
        while read -r session activity attached; do
            local is_attached=""
            [[ "$attached" == "(attached)" ]] && is_attached="*"

            # Print session header
            printf "${COLOR_BOLD}${COLOR_SESSION}Session: %s${COLOR_RESET} ${COLOR_DIM}%s${COLOR_RESET}\n" \
                "$session" "$is_attached"

            # List windows in this session
            tmux list-windows -t "$session" -F '#{window_index} #{window_name} #{window_panes} #{pane_current_command}' | \
                while read -r win_index win_name win_panes pane_cmd; do
                    local pane_id="${session}:${win_index}.0"
                    local description
                    description=$(get_pane_description "$pane_id")
                    local path
                    path=$(tmux display-message -t "$pane_id" -p '#{pane_current_path}')

                    # Shorten home directory
                    path="${path/#$HOME/\~}"

                    printf "  ${COLOR_WINDOW}%s:%s${COLOR_RESET} (${COLOR_DIM}%s pane%s${COLOR_RESET}) ${COLOR_DESC}%s${COLOR_RESET}\n" \
                        "$win_index" "$win_name" "$win_panes" "$([[ $win_panes -gt 1 ]] && echo s)" "$description"
                    printf "    ${COLOR_DIM}↳ %s${COLOR_RESET}\n" "$path"
                done
            printf "\n"
        done
}

# Generate compact format for fzf (with hidden data for switching)
generate_fzf_list() {
    tmux list-sessions -F '#{session_name} #{session_activity} #{?session_attached,(attached),(detached)}' | \
        sort -rnk2 | \
        while read -r session activity attached; do
            local is_attached=""
            [[ "$attached" == "(attached)" ]] && is_attached="*"

            tmux list-windows -t "$session" -F '#{window_index} #{window_name} #{window_panes}' | \
                while read -r win_index win_name win_panes; do
                    local pane_id="${session}:${win_index}.0"
                    local description
                    description=$(get_pane_description "$pane_id")
                    local path
                    path=$(tmux display-message -t "$pane_id" -p '#{pane_current_path}')
                    path="${path/#$HOME/\~}"

                    # Format: "Session:Window | Name | Description" with target at end for parsing
                    printf "%s:%s | %s | %s | %s\t%s\n" \
                        "$session" "$win_index" "$win_name" "$description" "$path" "$session:$win_index"
                done
        done
}

# Main picker function using fzf (without --tmux option for compatibility)
tmux_picker() {
    local temp_file
    local target

    # Create temp file for the selection result
    temp_file=$(mktemp)
    trap "rm -f $temp_file" EXIT

    # Generate fzf list and pipe to fzf, capture selection to temp file
    (
        generate_fzf_list | column -t -s '|' | \
        fzf --prompt='Tmux> ' \
            --header='ENTER to switch | ESC to close' \
            --delimiter='\t' \
            --with-nth=1 \
            --preview="echo {} | cut -f2 | sed 's|~|$HOME|g' | xargs tmux capture-pane -t -p -S -20 2>/dev/null" \
            --preview-window='right:50%:border-left' \
            --height=100% \
            --border=rounded \
            --info=inline \
            --print-query
    ) > "$temp_file"

    # Read the selection (last line is the selected item)
    local selection
    selection=$(tail -1 "$temp_file" 2>/dev/null)

    if [[ -n "$selection" && "$selection" != *"Tmux>"* ]]; then
        target=$(echo "$selection" | cut -f2)
        tmux switch-client -t "$target"
    fi
}

# Check dependencies
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is required but not installed"
    echo "Install with: apt install fzf  # or brew install fzf"
    exit 1
fi

if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is required but not installed"
    exit 1
fi

# Check if inside tmux
if [[ -z "$TMUX" ]]; then
    echo "Error: Not inside tmux session"
    exit 1
fi

# Run the picker
tmux_picker
