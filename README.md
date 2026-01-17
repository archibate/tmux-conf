# Tmux Config - Vim User Edition

A vim-user-friendly tmux configuration with TPM (Tmux Plugin Manager), featuring fuzzy pickers, beautiful Gruvbox status bar, and smart session management.

![Screenshot](cover.png)

```bash
git clone https://github.com/archibate/tmux-conf ~/.config/tmux --depth=1
~/.config/tmux/tmux_install.sh
```

## Features

- **Vim-style keybindings** - Navigate panes with `C-h`/`C-j`/`C-k`/`C-l`, resize with `M-h`/`M-j`/`M-k`/`M-l`
- **Fuzzy pickers** - fzf-powered session, window, and catalog browsers with live preview
- **Beautiful status bar** - Gruvbox color scheme with CPU, memory, and API usage indicators
- **Session persistence** - Auto-save every 15 minutes with tmux-continuum
- **Smart clipboard** - tmux-yank for seamless system clipboard integration
<!-- - **Claude Code aware** - Shows `✻` indicator when Claude is thinking -->
- **Stats popup** - Real-time system metrics with sparkline history (prefix + i)
- **Issue monitoring** - Background detection of new issues across panes (optional)

## Installation

```bash
# 1. Install dependencies
sudo apt install tmux fzf xsel tree python3   # Debian/Ubuntu
brew install tmux fzf tree python3             # macOS

# 2. Clone this repository
git clone <your-repo-url> ~/.config/tmux

# 3. Run the installer (sets up config + aliases + TPM + plugins)
bash ~/.config/tmux/scripts/tmux_install.sh

# 4. Start tmux
tmux start-server
```

That's it! The installer sets up:
- `~/.tmux.conf` symlink to the config
- Shell aliases (`tu`, `tl`, `ta`, `tc`, `ts`, `tb`)
- TPM (Tmux Plugin Manager) and all plugins

## Key Bindings

### Prefix

The prefix key is `Ctrl-z` (instead of the tmux built-in default `Ctrl-b` for better ergonomics).

You can customize prefix key in [tmux.conf](tmux.conf):

```tmux
unbind C-b
set -g prefix C-z
bind C-z send-prefix
```

### Pane Navigation

| Key | Action |
|-----|--------|
| `prefix + h` | Move to left pane |
| `prefix + j` | Move to pane below |
| `prefix + k` | Move to pane above |
| `prefix + l` | Move to right pane |
| `prefix + x` | Kill current pane |
| `prefix + b` | Break pane to new window |
| `prefix + m` | Move pane to another window |

### Pane Management

| Key | Action |
|-----|--------|
| `prefix + H` | Move pane to left |
| `prefix + J` | Move pane below |
| `prefix + K` | Move pane above |
| `prefix + L` | Move pane to right |
| `prefix + s` | Horizontal split (like vim `:split`) |
| `prefix + v` | Vertical split (like vim `:vsplit`) |
| `prefix + r` | Rotate panes |

### Window Management

| Key | Action |
|-----|--------|
| `prefix + c` or `t` | Create new window |
| `prefix + 1-9` | Select window 1-9 |
| `prefix + n` | Next window |
| `prefix + p` | Previous window |
| `prefix + z` | Last window (quick toggle) |
| `prefix + ,` | Rename window |
| `prefix + X` | Kill window |
| `prefix + w` | Window picker (fzf) |

### Session Management

| Key | Action |
|-----|--------|
| `prefix + f` | Session picker (fzf) |
| `prefix + F` | Catalog picker (all sessions/windows) |
| `prefix + a` | Last session (quick toggle) |
| `prefix + .` | Rename session |
| `prefix + d` | Detach session |

### Copy Mode (Vi-style)

| Key | Action |
|-----|--------|
| `prefix + Esc` | Enter copy mode |
| `v` | Start visual selection |
| `V` | Select line |
| `Ctrl-v` | Rectangle toggle |
| `y` | Copy selection |
| `Y` | Copy to system clipboard (via xclip) |
| `p` | Paste from tmux buffer |
| `i`/`a`/`q`/`Esc` | Exit copy mode |

### Plugin Management

| Key | Action |
|-----|--------|
| `prefix + I` | Install plugins |
| `prefix + U` | Update plugins |
| `prefix + R` | Reload `~/.tmux.conf` |

### Misc

| Key | Action |
|-----|--------|
| `prefix + ?` | List all key bindings |
| `prefix + Ctrl-w` | Save pane to file (`/tmp/tmux-capture-YYYYMMDD-HHMMSS.txt`) |
| `prefix + P` | Paste buffer |

## Plugin Key Bindings

### tmux-yank (Clipboard)

| Key | Action |
|-----|--------|
| `prefix + y` | Copy command line to clipboard |
| `prefix + Y` | Copy current directory to clipboard |
| `y` (in copy mode) | Copy selection to system clipboard |
| `Y` (in copy mode) | Copy and paste to command line |

**Mouse**: Select text with mouse to copy directly to clipboard.

### tmux-sidebar (Directory Tree)

| Key | Action |
|-----|--------|
| `prefix + Tab` | Toggle sidebar (tree view) |
| `prefix + Backspace` | Toggle sidebar and focus it |

### tmux-copycat (Search)

| Key | Action |
|-----|--------|
| `prefix + /` | Regex search |
| `prefix + Ctrl-f` | Search files |
| `prefix + Ctrl-g` | Search git hashes (after `git log`) |
| `prefix + Ctrl-u` | Search URLs |
| `prefix + Ctrl-d` | Search numbers |
| `prefix + Alt-h` | Search SHA hashes |
| `prefix + Alt-i` | Search IP addresses |

In copycat mode:
- `n` - Next match
- `N` - Previous match
- `Enter` - Copy match (vi mode)

### tmux-open (Open Files/URLs)

In copy mode:
| Key | Action |
|-----|--------|
| `o` | Open with system default |
| `Ctrl-o` | Open with `$EDITOR` |
| `Shift-s` | Search in web browser |

### tmux-which-key (Action Menu)

| Key | Action |
|-----|--------|
| `prefix + Space` | Show action menu |
| `Ctrl-Space` | Show action menu (root table) |

### tmux-resurrect (Session Persistence)

| Key | Action |
|-----|--------|
| `prefix + Ctrl-s` | Save session manually |
| `prefix + Ctrl-r` | Restore saved session |

**Note**: tmux-continuum auto-saves every 15 minutes and auto-restores on tmux start.

## Useful Default Tmux Bindings (Not Overridden)

| Key | Action |
|-----|--------|
| `prefix + :` | Command prompt |
| `prefix + [` | Enter scroll mode (alternative to Esc) |
| `prefix + ]` | Paste from buffer |
| `prefix + space` | Next layout |
| `prefix + z` | Zoom/unzoom pane |
| `prefix + {` | Swap pane left |
| `prefix + }` | Swap pane right |
| `prefix + o` | Rotate panes forward |
| `prefix + ~` | Show messages |

## Shell Aliases

After sourcing `tmux_aliases.sh`:

| Command | Action |
|---------|--------|
| `tu` | Show fzf session picker |
| `tu <name>` | Attach to or create session `<name>` |
| `tu .` | Create/use session named after current directory |
| `tl` | List sessions (`tmux ls`) |
| `ta` | Attach to session (`tmux attach`) |
| `tc` | Show catalog picker (all sessions/windows) |
| `ts` | Full Claude analysis with attention table |
| `tb` | Quick attention-only view (🔴🟡🟢) |

## Status Bar

The status bar shows (left to right):
- Session name (in blue)
- Hostname
- Current path
- CPU usage (green)
- Memory usage (green)
- GLM API usage (purple)
- Current time
- Tmux mode indicator

### Claude Code Status Indicator

When using Claude Code, a `✻` appears in the window list when Claude is thinking. This is handled by the `claude_status.sh` background monitor.

### Stats Popup (`prefix + i`)

Shows real-time system metrics with 20-point sparkline history:

| Metric | Description |
|--------|-------------|
| **LOAD** | 1/5/15-minute load averages (scaled by CPU cores) |
| **CPU** | Current usage percentage with average |
| **MEM** | Memory usage percentage with average |
| **GLM** | Claude API token usage (fixed 0-100 scale) |

Color-coded with Gruvbox: 🔴 high > 🟡 medium > 🟢 low.

### Sparkline Cache System

Status bar scripts use caching to ensure 1-second refresh rate doesn't impact performance:

| Cache File | Metric | Update Interval | Data Points |
|------------|--------|-----------------|-------------|
| `/tmp/tmux_sparkline_cache` | CPU/MEM/GLM | 5 seconds | 20 points |
| `/tmp/tmux_load_sparkline_cache` | LOAD | 5 seconds | 20 points |
| `/tmp/.glm_usage_cache` | GLM API usage | 60 seconds | 1 point |

The cache ensures smooth status bar updates while keeping resource usage low.

### Claude Analysis Commands

| Command | Action |
|---------|--------|
| `ts` | Full analysis with attention table and pane content |
| `tb` | Quick attention-only view with emoji priorities (🔴🟡🟢) |

Both commands operate in read-only mode and only invoke tmux commands (no file edits).

<!-- ### Issue Monitoring System (Optional) -->
<!--  -->
<!-- **Note:** This feature is currently disabled in `tmux.conf`. To enable, uncomment the `run-shell -b` line. -->
<!--  -->
<!-- Automatically monitors all tmux panes for issues and notifies when new problems appear: -->
<!--  -->
<!-- **Keybinding:** -->
<!-- - `prefix + B` - Show brief popup with all current issues -->
<!--  -->
<!-- **Status bar indicators:** -->
<!-- - `·` (gray dot) - No new issues -->
<!-- - `⚠1` (red) - New 🔴 high-priority issues -->
<!-- - `⚠1` (yellow) - New 🟡 medium-priority issues -->
<!--  -->
<!-- **Manual control:** -->
<!-- ```bash -->
<!-- # Check monitor status -->
<!-- ~/.config/tmux/scripts/tmux_brief_monitor.sh --status -->
<!--  -->
<!-- # Stop monitor -->
<!-- ~/.config/tmux/scripts/tmux_brief_monitor.sh --stop -->
<!--  -->
<!-- # Run single check -->
<!-- ~/.config/tmux/scripts/tmux_brief_monitor.sh --once -->
<!-- ``` -->

## Configuration

### TPM (Plugin Manager)

**Note**: TPM and all plugins are installed automatically by the installer script. Use these commands to manually manage plugins.

```bash
# Install plugins (if not already installed)
~/.tmux/plugins/tpm/bin/install_plugins # equivalent to: prefix + I

# Update plugins
~/.tmux/plugins/tpm/bin/update_plugins # equivalent to: prefix + U

# Clean unused plugins
~/.tmux/plugins/tpm/bin/clean_plugins
```

### Reload Config

```bash
# Inside tmux
tmux source-file ~/.tmux.conf

# Or from shell
tmux reload
```

### Customization

Edit `tmux.conf` to customize:

```tmux
# Change prefix key to Ctrl-z
unbind C-b
set -g prefix C-z

# Add more plugins
set -g @plugin 'githubusername/reponame'

# Change colors
set -g status-bg '#1d2021'
set -g status-fg '#ebdbb2'
```

## Color Scheme

Uses [Gruvbox](https://github.com/morhetz/gruvbox) colors:

| Usage | Color |
|-------|-------|
| Background | `#1d2021` (bg0) |
| Background (lighter) | `#32302f` (bg1) |
| Foreground | `#ebdbb2` (fg) |
| Green | `#b8bb26` |
| Blue | `#83a598` |
| Yellow | `#d79921` |
| Orange | `#fe8019` |
| Purple | `#d3869b` |
| Gray | `#928374` |

## Plugins Used

- [tpm](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager
- [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) - Sensible defaults
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) - Save/restore sessions
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) - Auto-save sessions
- [tmux-yank](https://github.com/tmux-plugins/tmux-yank) - Clipboard integration
- [tmux-open](https://github.com/tmux-plugins/tmux-open) - Open files/URLs
- [tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) - Regex search
- [tmux-sidebar](https://github.com/tmux-plugins/tmux-sidebar) - Directory tree
- [tmux-which-key](https://github.com/alexwforsythe/tmux-which-key) - Action menu
- [tmux-mode-indicator](https://github.com/MunifTanjim/tmux-mode-indicator) - Mode indicator

## Troubleshooting

### Plugins not loading

```bash
# Re-run the installer (handles TPM + plugins)
bash ~/.config/tmux/scripts/tmux_install.sh

# Or install TPM manually
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Then install plugins
~/.tmux/plugins/tpm/bin/install_plugins
```

### Mouse selection not copying to clipboard

Install clipboard tool:
```bash
sudo apt install xsel  # Linux
brew install reattach-to-user-namespace  # macOS
```

### Status bar scripts not working

Ensure scripts are executable:
```bash
chmod +x ~/.config/tmux/scripts/*.sh
chmod +x ~/.config/tmux/scripts/*.py
```

## Credits

- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- [Gruvbox](https://github.com/morhetz/gruvbox) for color scheme inspiration
