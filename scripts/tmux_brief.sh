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
prompt="⚠️ READ-ONLY MODE - OBSERVE ONLY ⚠️

You are analyzing tmux pane content for a STATUS REPORT. You MUST:
✓ ONLY use tmux read-only commands (see reference below)
✓ ONLY output observations and status summaries
✗ NEVER use other tools (Edit, Write, Web, etc.)
✗ NEVER modify files, processes, or tmux state
✗ NEVER run commands that change system state
✗ NEVER try to fix anything

If you see an error, REPORT IT. Do NOT fix it.
If you see a failed process, REPORT IT. Do NOT restart it.

---

## Tmux Commands Reference (READ-ONLY)

You MAY use these tmux commands to gather more information:

\`\`\`bash
# List all sessions
tmux list-sessions

# List windows in a session
tmux list-windows -t session_name

# List panes in a window
tmux list-panes -t session_name:window_index

# Capture more lines from a pane (if you need more context)
tmux capture-pane -t session_name:window_index.pane_index -p -S -100

# Get pane current command (if available)
tmux display-message -t session_name:window_index.pane_index -p '#{pane_current_command}'
\`\`\`

---

## Output Format

You MUST use this exact structure:

🔴 session:window - brief issue/action
🟡 session:window - brief issue/action
🟢 session:window - brief issue/action

Emoji guide:

🔴 HIGH: Errors, crashes, stuck processes, failures
🟡 MEDIUM: Waiting for input, pending requests, questions
🟢 LOW: Running tasks (progress%), nice-to-have items

If NOTHING needs attention, output: ✅ All clear - no immediate action needed

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

prompt+="--- END ---

Generate the status report following the exact format specified above without additional text. Remember: BE CONCISE, visit all important panes, follow the format, no additional text."

# Invoke Claude with haiku for speed, print mode for single output
# Filter to only show lines with relevant emojis
echo "$prompt" | claude --settings ~/.config/tmux/claude-settings.json -p --model haiku --max-turns 30 --permission-mode plan 2>/dev/null | grep -E '🔴|🟡|🟢|✅'
