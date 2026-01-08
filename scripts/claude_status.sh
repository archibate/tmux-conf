#!/usr/bin/env bash
# Update tmux window options with Claude Code status for display in status bar
# Does NOT modify window names - uses window options instead
# Usage: claude_status.sh [--monitor|--once]

# Config
PID_FILE="/tmp/tmux_claude_status_monitor.pid"
CHECK_INTERVAL=1  # seconds between checks

# Detect Claude Code status from pane content
detect_status() {
    local pane_id="$1"

    # Capture last few lines of the pane
    local content
    content=$(tmux capture-pane -p -t "$pane_id" -S -5 -E - 2>/dev/null)

    # Check for Claude spinner with status text
    # Claude shows "✻ Contemplating…", "✻ Working…", etc.
    if echo "$content" | grep -qE '✻.*(Contemplating|Working|Thinking|Processing|Generating|…|\.\.\.)'; then
        echo "thinking"
        return
    fi

    echo "idle"
}

# Main: iterate all windows and update status in window options
update_all_windows() {
    # Iterate all panes and update their window status option
    while IFS=' ' read -r pane_id window_id _ cmd; do
        # Only check shell/claude panes (skip vim, etc.)
        case "$cmd" in
            *sh|zsh|fish|bash|claude) ;;
            *) continue ;;
        esac

        # Detect status
        local status
        status=$(detect_status "$pane_id")

        # Store status in window option for use in status bar
        tmux set-window-option -t "$window_id" '@claude-status' "$status"
    done < <(tmux list-panes -a -F '#{pane_id} #{window_id} #{window_name} #{pane_current_command}' 2>/dev/null)
}

# Monitor mode: run continuously
monitor_mode() {
    # Check if already running
    if [[ -f "$PID_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            # Already running, exit silently
            exit 0
        fi
    fi

    # Write our PID
    echo $$ > "$PID_FILE"

    # Trap to clean up PID file on exit
    trap 'rm -f "$PID_FILE"' EXIT

    # Run in a loop
    while tmux has-session 2>/dev/null; do
        update_all_windows
        sleep "$CHECK_INTERVAL"
    done

    # Clean up PID file when tmux exits
    rm -f "$PID_FILE"
}

# Main entry point
main() {
    case "${1:-}" in
        --monitor|-m)
            monitor_mode
            ;;
        --once|-o|"")
            update_all_windows
            ;;
        *)
            echo "Usage: $0 [--monitor|--once]" >&2
            echo "  --monitor  Run continuously in background" >&2
            echo "  --once     Run once and exit (default)" >&2
            exit 1
            ;;
    esac
}

main "$@"
