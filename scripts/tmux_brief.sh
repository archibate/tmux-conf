#!/bin/bash
# Quick attention-only report - shows only items needing human intervention
# SAFETY: Uses claude-settings.json to restrict Claude to tmux commands ONLY

# Get all sessions
sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

if [ -z "$sessions" ]; then
    echo "No tmux sessions found."
    exit 0
fi

# Build prompt - much simpler, focused on attention items
prompt="⚠️ TMUX ATTENTION CHECK ⚠️

Scan these tmux panes and list ONLY items that need human attention.

Use this format:
🔴 session:window - brief issue/action
🟡 session:window - brief issue/action
🟢 session:window - brief issue/action

Emoji guide:
🔴 HIGH: Errors, crashes, stuck processes, failures
🟡 MEDIUM: Waiting for input, pending requests, questions
🟢 LOW: Running tasks (progress%), nice-to-have items

If NOTHING needs attention, output: ✅ All clear - no immediate action needed

Here are the panes:

"

# Iterate through each session and window
while IFS= read -r session; do
    windows=$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}:#{window_active}' 2>/dev/null)

    while IFS=: read -r win_idx win_name win_active; do
        # Get pane content (last 30 lines for speed)
        content=$(tmux capture-pane -t "${session}:${win_idx}.0" -p -S -30 2>/dev/null)

        # Skip empty windows
        if [ -z "$content" ]; then
            continue
        fi

        # Add to prompt (more compact format)
        prompt+="[$session:$win_idx|$win_name]
$content
"
    done <<< "$windows"
done <<< "$sessions"

prompt+="---

List attention items only. Use the emoji format above. If all clear, say so."

# Invoke Claude with haiku for speed, print mode for single output
echo "$prompt" | claude --settings ~/.config/tmux/claude-settings.json -p --model haiku --max-turns 30 --permission-mode plan 2>/dev/null
