#!/usr/bin/env bash
# Update tmux window options with Claude Code status for display in status bar

# Status icons
ICON_THINKING=""
ICON_BACKGROUND=""
ICON_IDLE=""

# Detect Claude Code status from pane content
detect_status() {
    local pane_id="$1"

    # Capture last few lines of the pane
    local content
    content=$(tmux capture-pane -p -t "$pane_id" -S -2 -E - 2>/dev/null)

    # Check for thinking (spinners that Claude Code uses)
    if echo "$content" | grep -qE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⠐⠒⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟●◐◓◑○]'; then
        echo "thinking"
        return
    fi

    # Check for background task indicators
    if echo "$content" | grep -qiE 'running.*background|task.*running|background.*shell|background.*agent'; then
        echo "background"
        return
    fi

    # Check for "Working on it" type messages
    if echo "$content" | grep -qiE 'working|processing|generating'; then
        echo "thinking"
        return
    fi

    echo "idle"
}

# Main: iterate all panes and update their window's status option
main() {
    tmux list-panes -a -F '#{pane_id} #{window_id}' 2>/dev/null | while read -r pane_id window_id; do
        # Skip non-shell panes (vim, etc.)
        local cmd
        cmd=$(tmux display-message -t "$pane_id" -p '#{pane_current_command}' 2>/dev/null)
        case "$cmd" in
            *sh|zsh|fish|bash) ;;
            *) continue ;;
        esac

        local status
        status=$(detect_status "$pane_id")

        # Store status in window option for use in status bar
        tmux set-window-option -t "$window_id" "@claude-status" "$status" 2>/dev/null
    done
}

main "$@"
