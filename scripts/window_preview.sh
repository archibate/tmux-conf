#!/usr/bin/env bash
# window_preview.sh - Preview window content for fzf

selected="$1"
target=$(echo "$selected" | cut -f2)

if [[ -n "$target" ]]; then
    tmux capture-pane -t "$target" -p -S -30 2>/dev/null | head -40
else
    echo "No window selected"
fi
