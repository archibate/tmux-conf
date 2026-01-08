# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a vim-user-friendly tmux configuration using TPM (Tmux Plugin Manager). The config is located at `~/.config/tmux/tmux.conf` and is symlinked to `~/.tmux.conf`.

## Key Architecture

### Plugin Management (TPM)
- Plugins are defined in `tmux.conf` with `set -g @plugin '<repo>'`
- TPM is initialized at the bottom with `run '~/.tmux/plugins/tpm/tpm'`
- Plugin installation: `~/.tmux/plugins/tpm/bin/install_plugins`
- Update all plugins: `~/.tmux/plugins/tpm/bin/update_plugins`
- Clean unused plugins: `~/.tmux/plugins/tpm/bin/clean_plugins`

### Status Bar Scripts
Custom scripts in `scripts/` are called from the status bar:
- `cpu_usage.sh` - CPU percentage via `/proc/stat`
- `mem_usage.sh` - Memory percentage via `/proc/meminfo`
- `glm_usage_simple.py` - GLM API usage (reads from `~/.claude/settings.json`, caches for 60s)
- `claude_status.sh` - Claude Code activity monitor (background process, shows ✻ in window list when Claude is active)

The status bar updates every 1 second (`set -g status-interval 1`), so scripts must be fast and have caching.

### Session Management (`scripts/tmux_aliases.sh`)
The `tu()` function provides fuzzy session management:
- `tu` - Show fzf menu of existing sessions (sorted by last activity)
- `tu <name>` - Attach to or create session named `<name>`
- `tu .` - Create/use session named after current directory

### Vim-style Keybindings
This config is designed for vim users:
- Prefix: `Ctrl-a` (not `Ctrl-b`)
- Pane nav: `h`/`j`/`k`/`l` (vim-style)
- Pane resize: `H`/`J`/`K`/`L` (shift = resize)
- Splits: `s` (horizontal), `v` (vertical)
- Copy mode: vi-style with `v` for visual selection, `y` to yank
- Windows: `1`-`9` to select, `n`/`p` for next/prev, `,` to rename

### Session Persistence (tmux-resurrect + tmux-continuum)
- **tmux-resurrect**: Manual save/restore of sessions (including pane content, running processes)
- **tmux-continuum**: Automatic save every 5 minutes, auto-restore on tmux start
- All plugins are managed through TPM

## Color Scheme

Uses Gruvbox colors consistently:
- Background: `#1d2021` (bg0), `#32302f` (bg1)
- Foreground: `#ebdbb2` (fg), `#b8bb26` (green), `#83a598` (blue), `#d79921` (yellow), `#fe8019` (orange), `#d3869b` (purple)
- Muted: `#3c3836` (bg2), `#928374` (gray)

## Common Commands

```bash
# Install/update plugins
~/.tmux/plugins/tpm/bin/install_plugins
~/.tmux/plugins/tpm/bin/update_plugins

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
├── tmux.conf          # Main config file
├── scripts/
│   ├── cpu_usage.sh   # CPU percentage for status bar
│   ├── mem_usage.sh   # Memory percentage for status bar
│   ├── glm_usage_simple.py  # GLM API usage
│   ├── claude_status.sh  # Claude Code activity monitor
│   ├── tmux_install.sh  # Installation helper
│   └── tmux_aliases.sh  # tu() function, tl/ta aliases
└── plugins/
    └── tpm/           # Tmux Plugin Manager (git submodule)
```
