#!/usr/bin/env bash
# State management for tmux_brief monitoring
# Tracks issue history and detects NEW issues
# Usage: tmux_brief_state.sh [--store|--get-new|--cleanup]

STATE_DIR="${TMPDIR:-/tmp}/tmux_brief"
STATE_FILE="$STATE_DIR/state"
CURRENT_REPORT="$STATE_DIR/current_report"
MAX_AGE=$((4 * 60 * 60))  # 4 hours

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Parse brief report and extract issues
# Output: priority|session:window|description
parse_report() {
    local report="$1"

    # Filter only 🔴 and 🟡 lines, extract components
    echo "$report" | grep -E '^(🔴|🟡)' | while IFS=' ' read -r emoji session_window desc; do
        # Map emoji to priority name
        local priority
        case "$emoji" in
            🔴) priority="high" ;;
            🟡) priority="medium" ;;
            *) continue ;;
        esac

        # Clean up session:window (remove colon if present in different format)
        session_window=$(echo "$session_window" | sed 's/:$//')

        echo "${priority}|${session_window}|${desc}"
    done
}

# Store current report with timestamp
store_state() {
    local report="$1"
    local timestamp=$(date +%s)

    # Store full report for popup
    echo "$report" > "$CURRENT_REPORT"

    # Parse and append to state file
    parse_report "$report" | while IFS='|' read -r priority session_window description; do
        # Create unique key: priority:session:window
        local key="${priority}:${session_window}"
        # Hash description for change detection
        local desc_hash=$(echo "$description" | md5sum | cut -c1-8)

        echo "${timestamp}|${key}|${desc_hash}|${description}" >> "$STATE_FILE"
    done

    # Cleanup old entries
    cleanup_old_state "$MAX_AGE"
}

# Get NEW issues (not in previous state)
get_new_issues() {
    local report="$1"
    local timestamp=$(date +%s)

    # Parse current issues into temp file
    local current_state="$STATE_DIR/current_tmp"
    parse_report "$report" | while IFS='|' read -r priority session_window description; do
        local key="${priority}:${session_window}"
        local desc_hash=$(echo "$description" | md5sum | cut -c1-8)
        echo "${timestamp}|${key}|${desc_hash}|${description}"
    done > "$current_state"

    # Read existing state and build lookup
    declare -A existing_issues
    if [[ -f "$STATE_FILE" ]]; then
        while IFS='|' read -r ts key hash desc; do
            # Only keep the most recent entry for each key
            existing_issues["$key"]="${hash}"
        done < "$STATE_FILE"
    fi

    # Find new issues
    while IFS='|' read -r ts key hash desc; do
        local is_new=0

        # Check if key exists in existing state
        if [[ -z "${existing_issues[$key]}" ]]; then
            # Completely new issue
            is_new=1
        elif [[ "${existing_issues[$key]}" != "$hash" ]]; then
            # Issue exists but description changed
            is_new=1
        fi

        if [[ $is_new -eq 1 ]]; then
            # Output with emoji
            local priority="${key%%:*}"
            local session_window="${key#*:}"
            local emoji
            case "$priority" in
                high) emoji="🔴" ;;
                medium) emoji="🟡" ;;
            esac
            echo "${emoji} ${session_window} - ${desc}"
        fi
    done < "$current_state"

    rm -f "$current_state"
}

# Cleanup old state entries
cleanup_old_state() {
    local max_age="${1:-$MAX_AGE}"
    local now=$(date +%s)
    local cutoff=$((now - max_age))

    # Filter state file to only keep recent entries
    if [[ -f "$STATE_FILE" ]]; then
        local temp="$STATE_FILE.tmp"
        while IFS='|' read -r ts key hash desc; do
            if [[ $ts -ge $cutoff ]]; then
                echo "${ts}|${key}|${hash}|${desc}"
            fi
        done < "$STATE_FILE" > "$temp"
        mv "$temp" "$STATE_FILE"
    fi
}

# Get current report (for popup)
get_current_report() {
    if [[ -f "$CURRENT_REPORT" ]]; then
        cat "$CURRENT_REPORT"
    fi
}

# Get all current issues as structured data
get_all_issues() {
    local report="$1"

    parse_report "$report" | while IFS='|' read -r priority session_window description; do
        local emoji
        case "$priority" in
            high) emoji="🔴" ;;
            medium) emoji="🟡" ;;
        esac
        echo "${emoji}|${session_window}|${description}"
    done
}

# Main entry point
main() {
    case "${1:-}" in
        --store|-s)
            store_state "$2"
            ;;
        --get-new|-n)
            get_new_issues "$2"
            ;;
        --cleanup|-c)
            cleanup_old_state "${2:-$MAX_AGE}"
            ;;
        --current|-C)
            get_current_report
            ;;
        --all|-a)
            get_all_issues "$2"
            ;;
        *)
            echo "Usage: $0 [--store report|--get-new report|--cleanup [age]|--current|--all report]" >&2
            exit 1
            ;;
    esac
}

main "$@"
