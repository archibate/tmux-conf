#!/usr/bin/env bash
# CPU usage for tmux status line (Linux)

get_cpu() {
    # Simple one-shot CPU reading using /proc/stat
    cpu_line=$(grep '^cpu ' /proc/stat 2>/dev/null)

    if [[ -n "$cpu_line" ]]; then
        read -r _ user nice system idle iowait irq softproc _ <<< "$cpu_line"
        idle=$((idle + iowait))
        non_idle=$((user + nice + system + irq + softproc))
        total=$((idle + non_idle))
        if [[ $total -gt 0 ]]; then
            printf "%d%%" "$((100 * non_idle / total))"
            return 0
        fi
    fi

    # Fallback to top
    local cpu=$(top -bn1 2>/dev/null | grep -E "Cpu\(s\)" | awk '{print $2}' | cut -d'%' -f1)
    if [[ -n "$cpu" ]]; then
        printf "%d%%" "$cpu"
        return 0
    fi

    printf "%s" "--"
}

get_cpu
