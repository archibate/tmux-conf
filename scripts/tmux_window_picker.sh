#!/usr/bin/env bash
# tmux_window_picker.sh - Pick windows from current session with preview

# Get preview content for a window (first pane)
get_window_preview() {
    local target="$1"
    tmux capture-pane -t "$target" -p -S -30 2>/dev/null | head -40
}

# Get window description from pane content
get_window_description() {
    local pane_id="$1"
    local content

    content=$(tmux capture-pane -t "$pane_id" -p -S -50 2>/dev/null | head -50)
    local description=$(echo "$content" | grep -v '^[[:space:]]*$' | head -1 | sed 's/^[[:space:]]*//')

    if [[ ${#description} -gt 80 ]]; then
        description="${description:0:77}..."
    fi

    if [[ -z "$description" ]]; then
        description=$(tmux display-message -t "$pane_id" -p '#{pane_current_command}')
    fi

    echo "$description"
}

# Generate window list for current session only
generate_window_list() {
    local current_session
    current_session=$(tmux display-message -p '#{session_name}')

    tmux list-windows -t "$current_session" -F '#{window_index} #{window_name} #{window_panes}' | \
        while read -r win_index win_name win_panes; do
            local pane_id="${current_session}:${win_index}.0"
            local description
            description=$(get_window_description "$pane_id")
            local path
            path=$(tmux display-message -t "$pane_id" -p '#{pane_current_path}')
            path="${path/#$HOME/\~}"

            local pane_text="${win_panes} pane"
            [[ $win_panes -ne 1 ]] && pane_text="${win_panes} panes"

            # Format: "window_index: window_name | description | path"
            printf "%-25s %-50s %s\t%s:%s\n" \
                "${win_index}: ${win_name}" \
                "$description" \
                "$path" \
                "$current_session" \
                "$win_index"
        done
}

# Main picker function
window_picker() {
    local temp_file
    temp_file=$(mktemp)
    trap "rm -f $temp_file" EXIT

    # Generate and show picker
    (
        generate_window_list | \
        fzf --prompt='Window> ' \
            --header='ENTER to select | ESC to close' \
            --delimiter='\t' \
            --with-nth=1 \
            --preview="$HOME/.config/tmux/scripts/window_preview.sh {+}" \
            --preview-window='right:50%:border-left' \
            --height=100% \
            --border=rounded \
            --info=inline \
            --print-query
    ) > "$temp_file"

    local query=$(head -1 "$temp_file")
    local selected=$(tail -1 "$temp_file")

    # ESC pressed with no selection
    if [[ -z "$selected" || "$selected" == *"Window>"* ]]; then
        return
    fi

    # Extract session:window and select
    local target=$(echo "$selected" | cut -f2)
    if [[ -n "$target" ]]; then
        tmux select-window -t "$target"
    fi
}

# Check if inside tmux
if ! tmux list-sessions &>/dev/null; then
    echo "Error: Not inside tmux session"
    exit 1
fi

# Run the picker
window_picker
