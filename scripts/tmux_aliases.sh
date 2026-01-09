tu() {
    # If argument is ".", use current directory basename
    if [[ "$1" == "." ]]; then
        local session_name=$(basename "$PWD")
    elif [[ -n "$1" ]]; then
        local session_name="$1"
    fi

    # If we have a session name, create or attach
    if [[ -n "$session_name" ]]; then
        if tmux has-session -t "$session_name" 2>/dev/null; then
            if [[ -n "$TMUX" ]]; then
                tmux switch-client -t "$session_name"
            else
                tmux attach-session -t "$session_name"
            fi
        else
            tmux new-session -s "$session_name"
        fi
        return
    fi

    # Check if any sessions exist
    if ! tmux has-session 2>/dev/null; then
        # No sessions exist, create a new one using dir basename
        local new_session=$(basename "$PWD")
        tmux new-session -s "$new_session"
        return
    fi

    # Show enhanced picker with preview
    ~/.config/tmux/scripts/tmux_session_picker.sh
}

alias tl='tmux ls'
alias ta='tmux attach'

# Tmux catalog - interactive window/session picker with preview
tc() {
    ~/.config/tmux/scripts/tmux_catalog.sh
}
