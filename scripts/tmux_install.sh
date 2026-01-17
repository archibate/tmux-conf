#!/usr/bin/env bash

if [ -f ~/.$(basename $SHELL)rc ] && ! grep tmux_aliases.sh ~/.$(basename $SHELL)rc; then
    echo "-- installing tmux aliases into ~/.$(basename $SHELL)rc"
    echo "[ ! -f ~/.config/tmux/scripts/tmux_aliases.sh ] || source ~/.config/tmux/scripts/tmux_aliases.sh" >> ~/.$(basename $SHELL)rc
fi

if [ ! -f ~/.tmux.conf ]; then
    echo "-- installing ~/.tmux.conf"
    ln -sf ~/.config/tmux/tmux.conf ~/.tmux.conf
fi
