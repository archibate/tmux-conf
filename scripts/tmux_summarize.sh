#!/bin/bash
# Analyze all tmux panes using Claude - detect errors, issues, progress, and need for intervention
# SAFETY: Uses claude-settings.json to restrict Claude to tmux commands ONLY
# - Bash: only "tmux *" allowed
# - Edit, Write, WebFetch, WebSearch, Skill: all denied

# Get all sessions
sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)

if [ -z "$sessions" ]; then
    echo "No tmux sessions found."
    exit 0
fi

# Build prompt with all window content
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

\`\`\`
## 📊 Tmux Pane Status Report

### Summary
- **Total Sessions**: N
- **Active Session**: <name> (attached)
- **Claude Code Sessions**: N sessions with active Claude instances

---

### 📍 Claude Code Panes

#### \`session:window.pane\` (name) - **[Status]** - Brief single-line description
- **Status**: Working / Error / Stuck / Waiting for input / Idle
- **Context**: What it's doing (1 line max)
- **Action Needed**: ⚠️ What human needs to do (if anything)

(Only expand details for non-idle panes. Group similar idle panes.)

### 📍 Other Panes

(Same format as above. Group idle shells together.)

---

### ⚠️ Items Requiring Attention

| Priority | Session/Window | Issue |
|----------|----------------|-------|
| **High** | ... | Critical errors/interrupts |
| **Medium** | ... | Pending user requests |
| **Low** | ... | Running in progress |
\`\`\`

## Guidelines

1. **BE CONCISE** - Most panes get 1 line. Only expand if:
   - Error/failure/crash
   - Actively running (progress bar, processing)
   - Waiting for user input
   - Claude with pending task

2. **GROUP IDLE PANES** - Don't list each idle shell separately:
   - \`session:2.1 - 5.1\` - **[Idle Shells]** - Zsh sessions

3. **PRIORITIZE** - Put important stuff first. Group Claude Code vs Other panes.

4. **ATTENTION TABLE** - Only list items needing human action.

"

# Iterate through each session and window
while IFS= read -r session; do
    windows=$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}:#{window_active}' 2>/dev/null)

    while IFS=: read -r win_idx win_name win_active; do
        # Get all panes in this window
        panes=$(tmux list-panes -t "${session}:${win_idx}" -F '#{pane_index}' 2>/dev/null)

        while IFS= read -r pane_idx; do
            # Get pane content (last 50 lines to catch progress bars near bottom)
            content=$(tmux capture-pane -t "${session}:${win_idx}.${pane_idx}" -p -S -50 2>/dev/null)

            # Skip empty panes
            if [ -z "$content" ]; then
                continue
            fi

            # Add to prompt (include pane index in format)
            prompt+="📍 session:$session window:$win_idx.$pane_idx name:$win_name
$content

"
        done <<< "$panes"
    done <<< "$windows"
done <<< "$sessions"

prompt+="--- END ---

Generate the status report following the exact format specified above. Remember: BE CONCISE, group idle panes, prioritize important items."

# Invoke Claude with the prompt and restricted settings (tmux commands only)
echo "$prompt" | claude --settings ~/.config/tmux/claude-settings.json -p --model sonnet --max-turns 100 --permission-mode plan
