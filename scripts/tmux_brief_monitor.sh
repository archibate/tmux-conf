#!/usr/bin/env bash
# Background monitor for tmux_brief - runs periodic checks and updates tmux options
# Usage: tmux_brief_monitor.sh [--monitor|--stop|--status|--once]

# Config
PID_FILE="${TMPDIR:-/tmp}/tmux_brief_monitor.pid"
CHECK_INTERVAL=120  # 2 minutes
STATE_SCRIPT="$HOME/.config/tmux/scripts/tmux_brief_state.sh"
BRIEF_SCRIPT="$HOME/.config/tmux/scripts/tmux_brief.sh"

# Tmux options we set
OPTION_STATUS="@brief-status"         # "idle" | "alert"
OPTION_COUNT_HIGH="@brief-count-high" # number of 🔴 issues
OPTION_COUNT_MEDIUM="@brief-count-medium" # number of 🟡 issues
OPTION_LAST_UPDATE="@brief-last-update" # timestamp of last check
OPTION_NEW_ISSUES="@brief-new-issues"  # JSON-like list of new issues (for popup)

# Run brief check and update tmux options
run_check() {
    # Ensure tmux is running
    if ! tmux has-session 2>/dev/null; then
        return
    fi

    # Run brief and capture output
    local brief_output
    brief_output=$($BRIEF_SCRIPT 2>/dev/null)

    # Handle empty or all-clear output
    if [[ -z "$brief_output" ]] || echo "$brief_output" | grep -q "✅ All clear"; then
        set_tmux_options "idle" "0" "0" ""
        $STATE_SCRIPT --store "$brief_output" 2>/dev/null
        return
    fi

    # Get counts by priority
    local high_count medium_count
    high_count=$(echo "$brief_output" | grep -c "^🔴" || echo "0")
    medium_count=$(echo "$brief_output" | grep -c "^🟡" || echo "0")

    # Get new issues (this also stores state)
    local new_issues
    new_issues=$($STATE_SCRIPT --get-new "$brief_output" 2>/dev/null)

    # Store current state
    $STATE_SCRIPT --store "$brief_output" 2>/dev/null

    # Determine status based on new issues
    local status="idle"
    if [[ -n "$new_issues" ]]; then
        status="alert"
    fi

    # Format new issues for storage (newline-separated, pipe escaped)
    local new_issues_escaped
    new_issues_escaped=$(echo "$new_issues" | sed 's/|/\\|/g' | tr '\n' '|')

    # Update tmux options
    set_tmux_options "$status" "$high_count" "$medium_count" "$new_issues_escaped"
}

# Set all tmux options
set_tmux_options() {
    local status="$1"
    local high="$2"
    local medium="$3"
    local new_issues="$4"
    local timestamp=$(date +%s)

    tmux set-option -g "$OPTION_STATUS" "$status" 2>/dev/null
    tmux set-option -g "$OPTION_COUNT_HIGH" "$high" 2>/dev/null
    tmux set-option -g "$OPTION_COUNT_MEDIUM" "$medium" 2>/dev/null
    tmux set-option -g "$OPTION_LAST_UPDATE" "$timestamp" 2>/dev/null
    tmux set-option -g "$OPTION_NEW_ISSUES" "$new_issues" 2>/dev/null
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
        # Stale PID file, remove it
        rm -f "$PID_FILE"
    fi

    # Write our PID
    echo $$ > "$PID_FILE"

    # Trap to clean up PID file on exit
    trap 'rm -f "$PID_FILE"' EXIT INT TERM

    # Initial check
    run_check

    # Run in a loop
    while tmux has-session 2>/dev/null; do
        sleep "$CHECK_INTERVAL"
        run_check
    done

    # Clean up PID file when tmux exits
    rm -f "$PID_FILE"
}

# Stop the monitor
stop_monitor() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            rm -f "$PID_FILE"
            echo "Stopped tmux_brief monitor (PID: $pid)"
            return 0
        fi
        rm -f "$PID_FILE"
    fi
    echo "No running monitor found"
    return 1
}

# Show monitor status
show_status() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            echo "✓ Monitor running (PID: $pid)"
            echo ""
            echo "Current state:"
            echo "  Status: $(tmux show-option -gv "$OPTION_STATUS" 2>/dev/null || echo "unknown")"
            echo "  🔴 High: $(tmux show-option -gv "$OPTION_COUNT_HIGH" 2>/dev/null || echo "0")"
            echo "  🟡 Medium: $(tmux show-option -gv "$OPTION_COUNT_MEDIUM" 2>/dev/null || echo "0")"
            local last_update
            last_update=$(tmux show-option -gv "$OPTION_LAST_UPDATE" 2>/dev/null)
            if [[ -n "$last_update" && "$last_update" != "0" ]]; then
                local last_time
                last_time=$(date -d "@$last_update" "+%H:%M:%S" 2>/dev/null || date -r "$last_update" "+%H:%M:%S" 2>/dev/null)
                echo "  Last check: $last_time"
            fi
            return 0
        fi
    fi
    echo "✗ Monitor not running"
    return 1
}

# Run once and exit
run_once() {
    run_check
}

# Main entry point
main() {
    case "${1:-}" in
        --monitor|-m|"")
            monitor_mode
            ;;
        --stop|--kill|-k)
            stop_monitor
            ;;
        --status|-s)
            show_status
            ;;
        --once|-o)
            run_once
            ;;
        *)
            echo "Usage: $0 [--monitor|--stop|--status|--once]" >&2
            echo "  --monitor  Run continuously in background (default)" >&2
            echo "  --stop     Stop running monitor" >&2
            echo "  --status   Show monitor status" >&2
            echo "  --once     Run once and exit" >&2
            exit 1
            ;;
    esac
}

main "$@"
