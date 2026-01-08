#!/usr/bin/env bash
# Memory usage for tmux status line (Linux)

# Read from /proc/meminfo for reliability
if [[ -f /proc/meminfo ]]; then
    mem_total=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
    mem_avail=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)

    if [[ -n "$mem_total" && -n "$mem_avail" && "$mem_total" -gt 0 ]]; then
        used=$((mem_total - mem_avail))
        printf "%.0f%%" "$((100 * used / mem_total))"
    else
        printf "%s" "--"
    fi
else
    printf "%s" "--"
fi
