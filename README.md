# Tmux Config - Vim User Edition

A vim-user-friendly tmux configuration with TPM (Tmux Plugin Manager), featuring fuzzy pickers, beautiful Gruvbox status bar, and smart session management.

![Screenshot](screenshot.png)

```bash
git clone git@github.com:archibate/tmux-conf ~/.config/tmux
~/.config/tmux/tmux_install.sh
```

## Features

- **Vim-style keybindings** - Navigate panes with `h`/`j`/`k`/`l`, resize with `H`/`J`/`K`/`L`
- **Fuzzy pickers** - fzf-powered session, window, and catalog browsers with live preview
- **Beautiful status bar** - Gruvbox color scheme with CPU, memory, and API usage indicators
- **Session persistence** - Auto-save every 5 minutes with tmux-continuum
- **Smart clipboard** - tmux-yank for seamless system clipboard integration
- **Claude Code aware** - Shows `✻` indicator when Claude is thinking

## Installation

### Prerequisites

```bash
# Install tmux (3.0+ required)
sudo apt install tmux  # Debian/Ubuntu
brew install tmux      # macOS

# Install dependencies
sudo apt install fzf xsel tree python3  # Debian/Ubuntu
brew install fzf tree python3           # macOS
```

### Quick Install

```bash
# Clone this repository
git clone https://github.com/yourusername/tmux-config.git ~/.config/tmux

# Create symlink
ln -s ~/.config/tmux/tmux.conf ~/.tmux.conf

# Install TPM plugins
~/.tmux/plugins/tpm/bin/install_plugins

# Source the config
tmux source-file ~/.tmux.conf
```

### Manual Install

1. Copy `tmux.conf` to `~/.tmux.conf` or `~/.config/tmux/tmux.conf`
2. Add the following to your shell config (`~/.bashrc`, `~/.zshrc`):

```bash
# Tmux aliases
source ~/.config/tmux/scripts/tmux_aliases.sh
```

3. Install TPM:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

4. Install plugins: Press `prefix + I` (default prefix: `Ctrl-a`)

## Key Bindings

### Prefix

The prefix key is `Ctrl-a` (instead of the default `Ctrl-b` for better ergonomics).

### Pane Navigation (Vim-style)

| Key | Action |
|-----|--------|
| `h` | Move to left pane |
| `j` | Move to pane below |
| `k` | Move to pane above |
| `l` | Move to right pane |
| `H` | Resize pane left 5 cells |
| `J` | Resize pane down 5 cells |
| `K` | Resize pane up 5 cells |
| `L` | Resize pane right 5 cells |
| `x` | Kill current pane |
| `b` | Break pane to new window |
| `prefix + m` | Move pane to another window |

### Pane Splits

| Key | Action |
|-----|--------|
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
| `prefix + a` | Last window (quick toggle) |
| `prefix + ,` | Rename window |
| `prefix + X` | Kill window |
| `prefix + w` | Window picker (fzf) |
| `prefix + C-h` | Move window left |
| `prefix + C-l` | Move window right |

### Session Management

| Key | Action |
|-----|--------|
| `prefix + f` | Session picker (fzf) |
| `prefix + F` | Catalog picker (all sessions/windows) |
| `prefix + A` | Last session (quick toggle) |
| `prefix + .` | Rename session |

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

### Misc

| Key | Action |
|-----|--------|
| `prefix + ?` | List all key bindings |
| `prefix + Ctrl-w` | Save pane to file (`~/tmux-capture-*.txt`) |
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

**Note**: tmux-continuum auto-saves every 5 minutes and auto-restores on tmux start.

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
| `tc` | Show catalog picker |

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

## Configuration

### TPM (Plugin Manager)

```bash
# Install plugins
prefix + I

# Update plugins
prefix + U

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
# Change prefix (default: Ctrl-a)
unbind C-b
set -g prefix C-a

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
# Install TPM manually
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install plugins
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

## License

MIT

## Credits

- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- [Greg Hurrell](https://github.com/wincent) for original vim-style config inspiration
- [Gruvbox](https://github.com/morhetz/gruvbox) for color scheme
