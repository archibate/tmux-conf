#!/usr/bin/env bash
#
# Blinking Claude indicator - alternates between window number and ✻
# Usage: claude_blink.sh window_id is_current
#

window_id="$1"
is_current="$2"  # "1" if current window, empty otherwise

# Get the window's claude status
claude_status=$(tmux show-window-options -t "$window_id" -v "@claude-status" 2>/dev/null || echo "idle")

# Get the actual window index (not the internal ID)
window_index=$(tmux display -p -t "$window_id" -F '#I')

# Determine what to show (number or ✻)
show_content="$window_index"
if [[ "$claude_status" == "thinking" ]]; then
  now=$(date +%s)
  if (( now % 2 == 0 )); then
    show_content="✻"
  fi
fi

# Determine color based on status and whether current
if [[ "$claude_status" == "thinking" ]]; then
  # Claude orange - bold if current
  # Don't use #[default] to preserve background color
  if [[ -n "$is_current" ]]; then
    echo "#[fg=#fe8019,bold,nodim]${show_content}"
  else
    echo "#[fg=#fe8019,nodim]${show_content}"
  fi
else
  # Normal - gray (inactive) or bright gray (current)
  # The calling format handles the base colors, we just return content
  echo "${show_content}"
fi
