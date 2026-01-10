#!/usr/bin/env bash
#
# Multi-metric sparkline for tmux status bar
# Usage: sparkline_stats.sh [POINTS] [DYNAMIC]
#   POINTS: number of history points to show (default: 1)
#   DYNAMIC: "dynamic" for dynamic scaling, anything else for fixed 0-100 scale
#   Cache always stores 20 points for history
#
# Examples:
#   sparkline_stats.sh         # Status bar: 1 point, fixed scale
#   sparkline_stats.sh 20      # Popup: 20 points, fixed scale
#   sparkline_stats.sh 20 dynamic  # Popup: 20 points, dynamic scaling
#

CACHE_FILE="${TMPDIR:-/tmp}/tmux_sparkline_cache"
CACHE_POINTS=20  # Always store 20 points in cache
SHOW_POINTS=${1:-1}  # How many points to display
DYNAMIC_MODE=${2:-"fixed"}  # "dynamic" or "fixed"
UPDATE_INTERVAL=5

# Get current metrics
cpu_percent=$(~/.config/tmux/scripts/cpu_usage.sh)
mem_percent=$(~/.config/tmux/scripts/mem_usage.sh)
glm_percent=$(~/.config/tmux/scripts/glm_usage_simple.py)

# Current values as numbers (strip % if present)
cpu_val=${cpu_percent//%/}
mem_val=${mem_percent//%/}
glm_val=${glm_percent//%/}

# Check if we need to update (throttle)
now=$(date +%s)
last_update=0
if [[ -f "$CACHE_FILE" ]]; then
  last_update=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
fi

if (( now - last_update >= UPDATE_INTERVAL )); then
  # Need to update cache
  if [[ -f "$CACHE_FILE" ]]; then
    # Read existing history
    declare -a cpu_history mem_history glm_history
    i=0
    while IFS=$'\t' read -r cpu mem glm; do
      cpu_history[$i]=$cpu
      mem_history[$i]=$mem
      glm_history[$i]=$glm
      ((i++))
    done < "$CACHE_FILE"

    # Remove oldest, add new at end
    cpu_history=("${cpu_history[@]:1}")
    mem_history=("${mem_history[@]:1}")
    glm_history=("${glm_history[@]:1}")
    cpu_history+=("$cpu_val")
    mem_history+=("$mem_val")
    glm_history+=("$glm_val")
  else
    # First run - initialize with zeros (zero padding), then add current value
    declare -a cpu_history mem_history glm_history
    for ((i=0; i<CACHE_POINTS-1; i++)); do
      cpu_history+=("0")
      mem_history+=("0")
      glm_history+=("0")
    done
    cpu_history+=("$cpu_val")
    mem_history+=("$mem_val")
    glm_history+=("$glm_val")
  fi

  # Write back to cache (tab-separated)
  for ((i=0; i<CACHE_POINTS; i++)); do
    echo "${cpu_history[$i]}	${mem_history[$i]}	${glm_history[$i]}"
  done > "$CACHE_FILE"
else
  # Read from cache
  declare -a cpu_history mem_history glm_history
  i=0
  while IFS=$'\t' read -r cpu mem glm; do
    cpu_history[$i]=$cpu
    mem_history[$i]=$mem
    glm_history[$i]=$glm
    ((i++))
  done < "$CACHE_FILE"
fi

# Sparkline characters (8 levels) - use array for reliable indexing
declare -a SPARK_CHARS=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')

# Function to generate sparkline from history array
# Args: hist_array_ref, num_points_to_show, dynamic_mode
# dynamic_mode: "dynamic" for auto-scaling, "fixed" or "glm" for 0-100 scale
generate_sparkline() {
  local -n hist=$1
  local num_points=$2
  local dynamic_mode=$3

  local max_val=100  # Default fixed scale (0-100 for percentages)

  if [[ "$dynamic_mode" == "dynamic" ]]; then
    # Find max value in history for dynamic scaling
    local peak=0
    for val in "${hist[@]}"; do
      (( val > peak )) && peak=$val
    done
    # Use peak*1.5 for headroom, minimum scale of 10 for low-usage systems
    max_val=$(( peak * 3 / 2 ))  # peak * 1.5 using integer math
    (( max_val < 10 )) && max_val=10
  fi

  # Take only the last N points
  local start_idx=$(( CACHE_POINTS - num_points ))
  local end_idx=$(( CACHE_POINTS - 1 ))

  declare -a spark_arr
  for ((i=start_idx; i<=end_idx; i++)); do
    local val=${hist[$i]}
    # Scale to 0-7 range (8 levels)
    local idx=$(( (val * 7) / max_val ))
    (( idx < 0 )) && idx=0
    (( idx > 7 )) && idx=7
    spark_arr+=("${SPARK_CHARS[$idx]}")
  done

  # Join array into string
  local IFS=
  echo "${spark_arr[*]}"
}

# Generate sparklines
# Status bar: fixed scale (consistent across time)
# Popup: dynamic scale (except GLM which is always fixed)
if [[ "$DYNAMIC_MODE" == "dynamic" ]]; then
  cpu_spark=$(generate_sparkline cpu_history $SHOW_POINTS "dynamic")
  mem_spark=$(generate_sparkline mem_history $SHOW_POINTS "dynamic")
  glm_spark=$(generate_sparkline glm_history $SHOW_POINTS "glm")  # GLM always fixed
else
  cpu_spark=$(generate_sparkline cpu_history $SHOW_POINTS "fixed")
  mem_spark=$(generate_sparkline mem_history $SHOW_POINTS "fixed")
  glm_spark=$(generate_sparkline glm_history $SHOW_POINTS "glm")  # GLM always fixed
fi

# Output with color codes for tmux
# Colors: CPU=green, MEM=blue, GLM=purple
printf '#[fg=#b8bb26]%s#[default] #[fg=#83a598]%s#[default] #[fg=#d3869b]%s' \
  "$cpu_spark" "$mem_spark" "$glm_spark"
