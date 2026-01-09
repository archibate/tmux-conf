#!/usr/bin/env bash
# tmux_session_picker.sh - Fuzzy session picker with preview, similar to tmux_catalog

# Get preview content for a session (first window's pane)
get_session_preview() {
    local session="$1"
    local first_window

    first_window=$(tmux list-windows -t "$session" -F '#{window_index}' 2>/dev/null | head -1)

    if [[ -n "$first_window" ]]; then
        local pane_id="${session}:${first_window}"
        tmux capture-pane -t "$pane_id" -p -S -30 2>/dev/null | head -40
    else
        echo "Empty session"
    fi
}

# Get session info (window count, attached status, etc.)
get_session_info() {
    local session="$1"

    local windows=$(tmux list-windows -t "$session" 2>/dev/null | wc -l)
    local attached=$(tmux display-message -t "$session" -p '#{?session_attached,attached,detached}' 2>/dev/null)

    local created=$(tmux display-message -t "$session" -p '#{session_created_string}' 2>/dev/null)
    local last_activity=$(tmux display-message -t "$session" -p '#{session_activity_string}' 2>/dev/null)

    printf "#[bold]%s#[nobold] " "$session"
    printf "(%d windows" "$windows"

    if [[ "$attached" == "attached" ]]; then
        printf ", #[green]attached#[default]"
    fi

    printf ")"

    if [[ -n "$last_activity" && "$last_activity" != "0" ]]; then
        printf " - last: %s" "$last_activity"
    fi
}

# Generate session list for fzf
generate_session_list() {
    tmux list-sessions -F '#{session_name} #{session_activity} #{?session_attached,1,0}' 2>/dev/null | \
        sort -rnk2 | \
        while read -r session activity attached; do
            # Get session info
            local windows=$(tmux list-windows -t "$session" 2>/dev/null | wc -l)
            local attached_mark=""
            [[ "$attached" == "1" ]] && attached_mark="*"

            # Get first window name for context
            local first_window_name=$(tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null | head -1)

            # Format: session_name* (windows) first_window
            # * indicates attached session
            printf "%-25s (%d)    %s\t%s\n" \
                "${session}${attached_mark}" \
                "$windows" \
                "$first_window_name" \
                "$session"
        done
}

# Main picker function
session_picker() {
    local temp_file
    temp_file=$(mktemp)
    trap "rm -f $temp_file" EXIT

    # Generate and show picker
    (
        generate_session_list | \
        fzf --prompt='Session> ' \
            --header='ENTER to attach | Ctrl-N to create new session | ESC to close' \
            --delimiter='\t' \
            --with-nth=1 \
            --preview="$HOME/.config/tmux/scripts/session_preview.sh {+}" \
            --preview-window='right:50%:border-left' \
            --height=100% \
            --border=rounded \
            --info=inline \
            --print-query \
            --expect=ctrl-n
    ) > "$temp_file"

    local query=$(head -1 "$temp_file")
    local key=$(head -2 "$temp_file" | tail -1)
    local selected=$(tail -1 "$temp_file")

    # Ctrl-N was pressed - create new session
    if [[ "$key" == "ctrl-n" ]]; then
        if [[ -n "$query" ]]; then
            tmux new-session -d -s "$query" 2>/dev/null
            if [[ -n "$TMUX" ]]; then
                tmux switch-client -t "$query"
            else
                tmux attach-session -t "$query"
            fi
        fi
        return
    fi

    # ESC pressed with no selection
    if [[ -z "$selected" || "$selected" == *"Session>"* ]]; then
        return
    fi

    # Extract session name and switch
    local session=$(echo "$selected" | cut -f2)
    if [[ -n "$session" ]]; then
        # Remove the * suffix if present
        session="${session%\*}"

        # Use attach-session if outside tmux, switch-client if inside
        if [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$session"
        else
            tmux attach-session -t "$session"
        fi
    fi
}

# Run the picker
session_picker
