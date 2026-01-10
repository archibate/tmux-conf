#!/usr/bin/env bash
#
# Load average sparkline for tmux status bar
# Tracks 20 data points of recent load history
# Updates every 5 seconds (cached between calls)
#

CACHE_FILE="${TMPDIR:-/tmp}/tmux_load_sparkline_cache"
POINTS=20
UPDATE_INTERVAL=5

# Get current load (1-minute average)
current_load=$(awk '{print $1}' /proc/loadavg)

# Check if we need to update (throttle: don't update every second)
now=$(date +%s)
last_update=0
if [[ -f "$CACHE_FILE" ]]; then
  last_update=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
fi

if (( now - last_update >= UPDATE_INTERVAL )); then
  # Need to update cache
  if [[ -f "$CACHE_FILE" ]]; then
    # Read existing history, drop oldest, add new
    readarray -t history < "$CACHE_FILE"
    # Remove oldest, add new at end
    history=("${history[@]:1}")
    history+=("$current_load")
  else
    # First run - initialize with zeros (zero padding), then add current load
    history=()
    for ((i=0; i<POINTS-1; i++)); do
      history+=("0")
    done
    history+=("$current_load")
  fi

  # Write back to cache
  printf '%s\n' "${history[@]}" > "$CACHE_FILE"
else
  # Read from cache
  readarray -t history < "$CACHE_FILE"
fi

# Calculate average load
sum=0
for val in "${history[@]}"; do
  sum=$(echo "$sum + $val" | bc -l)
done
avg_load=$(echo "$sum / ${#history[@]}" | bc -l)

# Fixed scaling: use CPU count-based scale for consistent status bar display
cpu_count=$(nproc)
if (( cpu_count > 16 )); then
  scale_max=8
else
  scale_max=$cpu_count
fi

# Sparkline characters (8 levels) - use array for reliable indexing
declare -a SPARK_CHARS=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')

declare -a sparkline_arr
for val in "${history[@]}"; do
  # Scale to 0-7 range (8 levels) using fixed scale
  normalized=$(echo "$val / $scale_max" | bc -l)
  idx=$(echo "$normalized * 7" | bc -l)
  idx=${idx/.*}  # Truncate to integer
  # Clamp to 0-7
  (( idx < 0 )) && idx=0
  (( idx > 7 )) && idx=7

  sparkline_arr+=("${SPARK_CHARS[$idx]}")
done

# Join array into string
sparkline=$(
  IFS=
  echo "${sparkline_arr[*]}"
)

# Output: sparkline + current load + trend indicator
# Trend: compare current (1m) vs 5m ago (5th element from end in our 20-point history)
trend="→"
if [[ ${#history[@]} -ge 5 ]]; then
  older="${history[-5]}"
  if (( $(echo "$current_load > $older + 0.2" | bc -l) )); then
    trend="↑"
  elif (( $(echo "$current_load < $older - 0.2" | bc -l) )); then
    trend="↓"
  fi
fi

# Format: sparkline [current avg trend]
printf "%s [%.2f %s]" "$sparkline" "$avg_load" "$trend"
