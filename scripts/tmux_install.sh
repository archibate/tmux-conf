#!/usr/bin/env bash

if [ -f ~/.${SHELL}rc ]; then
    echo "[ ! -f ~/.config/tmux/tmux_aliases.sh ] || source ~/.config/tmux/tmux_aliases.sh" >> ~/.${SHELL}rc
fi

if [ -f ~/.tmux.conf ]; then
    ln -sf ~/.config/tmux/tmux.conf ~/.tmux.conf
fi
