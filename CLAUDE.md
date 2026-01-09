# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a vim-user-friendly tmux configuration using TPM (Tmux Plugin Manager). The config is located at `~/.config/tmux/tmux.conf` and is symlinked to `~/.tmux.conf`.

## Key Architecture

### Plugin Management (TPM)
- Plugins are defined in `tmux.conf` with `set -g @plugin '<repo>'`
- TPM is initialized at the bottom with `run '~/.tmux/plugins/tpm/tpm'`
- Install plugins: `prefix + I` (via tmux) or `~/.tmux/plugins/tpm/bin/install_plugins`
- Update all plugins: `prefix + U` or `~/.tmux/plugins/tpm/bin/update_plugins`
- Clean unused plugins: `~/.tmux/plugins/tpm/bin/clean_plugins`

### Status Bar Scripts
Custom scripts in `scripts/` are called from the status bar:
- `cpu_usage.sh` - CPU percentage via `/proc/stat`
- `mem_usage.sh` - Memory percentage via `/proc/meminfo`
- `glm_usage_simple.py` - GLM API usage (reads from `~/.claude/settings.json`, caches for 60s)
- `claude_status.sh` - Claude Code activity monitor (background process, shows ✻ in window list when Claude is active)

The status bar updates every 1 second (`set -g status-interval 1`), so scripts must be fast and have caching.

**CRITICAL**: Status bar scripts are called on every refresh. Always implement caching for expensive operations (API calls, file I/O).

### Fuzzy Pickers (fzf-based)
All pickers use fzf with live preview and tab-delimited hidden data:

1. **Window Picker** (`prefix + w`): `tmux_window_picker.sh`
   - Shows windows in current session with preview
   - Preview: `window_preview.sh` (captures 30 lines of pane content)
   - Hidden data: `session:window` (after tab)

2. **Session Picker** (`prefix + f`): `tmux_session_picker.sh`
   - Shows all sessions sorted by last activity
   - `Ctrl-N` creates new session from query
   - Preview: `session_preview.sh` (shows windows + content preview)
   - Hidden data: `session_name` (after tab)

3. **Catalog Picker** (`prefix + F` or `tc` command): `tmux_catalog.sh`
   - Shows ALL windows across ALL sessions
   - Preview: `fzf_preview.sh` (captures 30 lines of pane content)
   - Hidden data: `session:window` (after tab)

**Pattern**: All pickers follow the same structure:
- Generate list with visible format + hidden target (tab-separated)
- fzf `--with-nth=1` shows only visible part
- fzf `--preview` script extracts target via `cut -f2`
- Selection parsed with `cut -f2` to get the target

### Session Management (`scripts/tmux_aliases.sh`)
The `tu()` function provides fuzzy session management:
- `tu` - Show fzf menu of existing sessions (sorted by last activity)
- `tu <name>` - Attach to or create session named `<name>`
- `tu .` - Create/use session named after current directory

Aliases:
- `tl` - List sessions (`tmux ls`)
- `ta` - Attach to session (`tmux attach`)
- `tc` - Show catalog picker (`tmux_catalog.sh`)
- `ts` - Full analysis: Claude Code panes, Other panes, Attention table (`tmux_summarize.sh`)
- `tb` - Quick attention-only: 🔴🟡🟢 emoji priorities for issues/stuck/waiting/progress (`tmux_brief.sh`)

Both use `claude-settings.json` to restrict to **tmux commands only** (safe, no file edits)

### Vim-style Keybindings
This config is designed for vim users:
- Prefix: `Ctrl-a` (not `Ctrl-b`)
- Pane nav: `h`/`j`/`k`/`l` (vim-style)
- Pane resize: `H`/`J`/`K`/`L` (shift = resize)
- Splits: `s` (horizontal), `v` (vertical)
- Copy mode: vi-style with `v` for visual selection, `y` to yank
- Windows: `1`-`9` to select, `n`/`p` for next/prev, `,` to rename
- Pickers: `w` (window), `f` (session), `F` (catalog)

### Session Persistence (tmux-resurrect + tmux-continuum)
- **tmux-resurrect**: Manual save/restore of sessions (including pane content, running processes)
- **tmux-continuum**: Automatic save every 5 minutes, auto-restore on tmux start
- All plugins are managed through TPM

### Claude Code Status Indicator
The `@claude-status` window option is set by `claude_status.sh`:
- `thinking` - Claude is working (shows ✻ in window list)
- `idle` - Claude is idle
- The monitor runs as background process via `run-shell -b` in tmux.conf
- Checks pane content for spinner patterns: `✻.*(Contemplating|Working|Thinking|…|\.\.\.)`

## Color Scheme

Uses Gruvbox colors consistently:
- Background: `#1d2021` (bg0), `#32302f` (bg1)
- Foreground: `#ebdbb2` (fg), `#b8bb26` (green), `#83a598` (blue), `#d79921` (yellow), `#fe8019` (orange), `#d3869b` (purple)
- Muted: `#3c3836` (bg2), `#928374` (gray)

## Common Commands

```bash
# Reload config after editing
tmux source-file ~/.tmux.conf

# List sessions
tmux ls  # or: tl (alias)

# Attach to session
tmux attach -t <name>  # or: ta <name> (alias)

# Session save/restore (tmux-resurrect)
prefix + Ctrl-s  # Save session manually
prefix + Ctrl-r  # Restore saved session
# Note: tmux-continuum auto-saves every 5 minutes and auto-restores on start
```

## File Structure

```
~/.config/tmux/
├── tmux.conf              # Main config file
├── claude-settings.json   # Settings for `ts` - restricts Claude to tmux commands only
├── scripts/
│   ├── cpu_usage.sh       # CPU percentage for status bar
│   ├── mem_usage.sh       # Memory percentage for status bar
│   ├── glm_usage_simple.py  # GLM API usage (cached 60s)
│   ├── claude_status.sh   # Claude Code activity monitor (background process)
│   ├── tmux_install.sh    # Installation helper
│   ├── tmux_aliases.sh    # tu() function, tl/ta/tc/ts aliases
│   ├── tmux_window_picker.sh   # Window picker (prefix + w)
│   ├── window_preview.sh       # Window preview content
│   ├── tmux_session_picker.sh  # Session picker (prefix + f)
│   ├── session_preview.sh      # Session preview content
│   ├── tmux_catalog.sh         # Catalog picker (prefix + F or tc)
│   ├── fzf_preview.sh          # Catalog preview content
│   ├── tmux_summarize.sh       # Full Claude analysis (ts) - all panes with attention table
│   └── tmux_brief.sh           # Quick attention-only (tb) - 🔴🟡🟢 emoji priorities
└── plugins/
    └── tpm/                # Tmux Plugin Manager (git submodule)
```
