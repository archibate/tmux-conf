#!/usr/bin/env bash
#
# Show git branch of current pane's working directory
# Usage: git_branch.sh

CACHE_FILE="${TMPDIR:-/tmp}/tmux_git_branch_$(tmux display -p '#{session_id}_#{window_id}_#{pane_id}')"
CACHE_TTL=2  # Cache for 2 seconds (feels immediate, reduces cursor flicker)

# Get current pane path
pane_path="$(tmux display -p '#{pane_current_path}')"

# Check if cache is valid
if [[ -f "$CACHE_FILE" ]]; then
  last_update=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
  now=$(date +%s)
  if (( now - last_update < CACHE_TTL )); then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# Check if we're in a git repo
if cd "$pane_path" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  # Get branch name
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  # Check for dirty working directory
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "$branch*" > "$CACHE_FILE"
  else
    echo "$branch" > "$CACHE_FILE"
  fi
else
  echo "" > "$CACHE_FILE"
fi

cat "$CACHE_FILE"
