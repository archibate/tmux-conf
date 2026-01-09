#!/usr/bin/env bash
# session_preview.sh - Preview session content for fzf

selected="$1"
session=$(echo "$selected" | cut -f2)
# Remove * suffix if present
session="${session%\*}"

if [[ -n "$session" ]]; then
    # Get session info header
    windows=$(tmux list-windows -t "$session" 2>/dev/null | wc -l)
    attached=$(tmux display-message -t "$session" -p '#{?session_attached,attached,detached}' 2>/dev/null)

    printf "#[bold]%s#[nobold] (%d windows, %s)\n\n" "$session" "$windows" "$attached"

    # List windows in this session
    tmux list-windows -t "$session" -F '#{window_index}: #{window_name} (#{window_panes} panes)' 2>/dev/null | \
        while read -r window_info; do
            printf "  %s\n" "$window_info"
        done

    printf "\n"

    # Get first window for content preview
    first_window=$(tmux list-windows -t "$session" -F '#{window_index}' 2>/dev/null | head -1)
    if [[ -n "$first_window" ]]; then
        tmux capture-pane -t "${session}:${first_window}" -p -S -25 2>/dev/null | head -30
    fi
else
    echo "No session selected"
fi
