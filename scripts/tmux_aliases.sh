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
            tmux attach-session -t "$session_name"
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

    # Show fzf menu, sorted by last activity
    local sessions=$(tmux list-sessions -F "#{session_activity} #{session_name}" 2>/dev/null | \
        sort -rn | \
        awk '{print $2}')

    local selected=$(printf "%s\n" "$sessions" | fzf --prompt="Select tmux session> " --print-query)

    local query=$(head -1 <<< "$selected")
    local session=$(tail -1 <<< "$selected")

    [[ -z "$session" && -z "$query" ]] && return 0

    if [[ -n "$session" ]]; then
        tmux attach-session -t "$session"
    elif [[ -n "$query" ]]; then
        tmux new-session -s "$query"
    fi
}

alias tl='tmux ls'
alias ta='tmux attach'
