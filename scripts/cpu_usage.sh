#!/usr/bin/env bash
# CPU usage for tmux status line (Linux)
# Uses delta calculation: two samples with interval for accurate current usage

get_cpu() {
    # Read /proc/stat and return total and idle
    get_cpu_stats() {
        read -r _ user nice system idle iowait irq softproc _ <<< "$(grep '^cpu ' /proc/stat 2>/dev/null)"
        local idle_total=$((idle + iowait))
        local non_idle=$((user + nice + system + irq + softproc))
        local total=$((idle_total + non_idle))
        echo "$total $idle_total"
    }

    # First sample
    read -r total1 idle1 <<< "$(get_cpu_stats)"
    [[ -z "$total1" || $total1 -eq 0 ]] && { printf "%s" "--"; return 1; }

    # Wait 100ms for accurate delta
    sleep 0.1

    # Second sample
    read -r total2 idle2 <<< "$(get_cpu_stats)"
    [[ -z "$total2" || $total2 -eq 0 ]] && { printf "%s" "--"; return 1; }

    # Calculate deltas
    local total_diff=$((total2 - total1))
    local idle_diff=$((idle2 - idle1))

    if [[ $total_diff -gt 0 ]]; then
        local usage=$((100 * (total_diff - idle_diff) / total_diff))
        printf "%d%%" "$usage"
        return 0
    fi

    printf "%s" "--"
}

get_cpu
