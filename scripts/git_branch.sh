#!/usr/bin/env bash
#
# Show git branch of current pane's working directory
# Usage: git_branch.sh

# Get current pane path
pane_path="$(tmux display -p '#{pane_current_path}')"

# Check if we're in a git repo
if cd "$pane_path" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  # Get branch name
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  # Check for dirty working directory
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo " $branch*"
  else
    echo " $branch"
  fi
else
  echo ""
fi
