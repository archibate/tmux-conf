#!/usr/bin/env bash
# fzf_preview.sh - Preview tmux pane content for fzf

# fzf passes the entire selected line as $1
selected="$1"

# Extract target from second tab-delimited field
target=$(echo "$selected" | cut -f2)

if [[ -n "$target" ]]; then
    tmux capture-pane -t "$target" -p -S -30 2>/dev/null | head -40
else
    echo "No target"
fi
