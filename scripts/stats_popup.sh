#!/usr/bin/env bash
#
# Detailed system stats popup
# Shows LOAD/CPU/MEM/GLM with 20-point sparklines and current values
#

# Colors (Gruvbox)
C_GREEN=$'\033[38;2;184;187;38m'   # #b8bb26
C_BLUE=$'\033[38;2;131;165;152m'    # #83a598
C_PURPLE=$'\033[38;2;211;134;155m'  # #d3869b
C_YELLOW=$'\033[38;2;215;153;33m'   # #d79921
C_GRAY=$'\033[38;2;146;131;116m'    # #928374
C_RESET=$'\033[0m'

# Get current values
cpu_curr=$(~/.config/tmux/scripts/cpu_usage.sh)
mem_curr=$(~/.config/tmux/scripts/mem_usage.sh)
glm_curr=$(~/.config/tmux/scripts/glm_usage_simple.py)
load_curr=$(awk '{print $1, $2, $3}' /proc/loadavg)

# Read cache directly to generate sparklines
CACHE_FILE="${TMPDIR:-/tmp}/tmux_sparkline_cache"
declare -a SPARK_CHARS=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')

# Function to generate sparkline from cache
# Args: col (1=CPU, 2=MEM, 3=GLM), use_dynamic (true/false)
# GLM always uses fixed 0-100 scale, CPU/MEM use dynamic scaling when requested
generate_from_cache() {
  local col=$1
  local use_dynamic=$2
  local points=20

  if [[ ! -f "$CACHE_FILE" ]]; then
    echo "▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"
    return
  fi

  # GLM always uses fixed 0-100 scale
  if [[ $col -eq 3 ]]; then
    use_dynamic=false
  fi

  local max_val=100  # Default fixed scale
  if [[ "$use_dynamic" == "true" ]]; then
    # Find peak value for dynamic scaling
    local peak=0
    while IFS=$'\t' read -r cpu mem glm; do
      local val=$(echo "$cpu $mem $glm" | awk -v c=$col '{print $c}')
      (( val > peak )) && peak=$val
    done < "$CACHE_FILE"
    # Use peak*1.5 for headroom, minimum scale of 10 for low-usage systems
    max_val=$(( peak * 3 / 2 ))  # peak * 1.5 using integer math
    (( max_val < 10 )) && max_val=10
  fi

  # Generate sparkline
  declare -a spark_arr
  while IFS=$'\t' read -r cpu mem glm; do
    local val=$(echo "$cpu $mem $glm" | awk -v c=$col '{print $c}')
    local idx=$(( (val * 7) / max_val ))
    (( idx < 0 )) && idx=0
    (( idx > 7 )) && idx=7
    spark_arr+=("${SPARK_CHARS[$idx]}")
  done < "$CACHE_FILE"

  local IFS=
  echo "${spark_arr[*]}"
}

# Generate sparklines: CPU/MEM use dynamic scaling, GLM uses fixed 0-100 scale
cpu_spark=$(generate_from_cache 1 true)
mem_spark=$(generate_from_cache 2 true)
glm_spark=$(generate_from_cache 3 false)

# Calculate historical stats (current/avg) from cache
# Returns: current_value average_value (separate lines)
calc_stats() {
  local col=$1
  if [[ ! -f "$CACHE_FILE" ]]; then
    echo "?"
    echo "?"
    return
  fi

  local sum=0 count=0 last_val=0
  while IFS=$'\t' read -r cpu mem glm; do
    local val=$(echo "$cpu $mem $glm" | awk -v c=$col '{print $c}')
    last_val=$val
    sum=$((sum + val))
    ((count++))
  done < "$CACHE_FILE"

  local avg=$((sum / count))
  echo "$last_val"
  echo "$avg"
}

# Get CPU stats
cpu_curr=$(calc_stats 1 | head -1)
cpu_avg=$(calc_stats 1 | tail -1)

# Get MEM stats
mem_curr=$(calc_stats 2 | head -1)
mem_avg=$(calc_stats 2 | tail -1)

# Load sparkline (from separate cache) - load uses floats, need awk for math
# Uses dynamic max scaling: peak*1.5 for headroom, minimum 1.0
load_cache="${TMPDIR:-/tmp}/tmux_load_sparkline_cache"
if [[ -f "$load_cache" ]]; then
  # Find peak and calculate max = peak*1.5 with minimum of 1.0
  max_load=$(awk '{if ($1 > max) max = $1} END {
    max_scaled = max * 1.5
    if (max_scaled < 1.0) max_scaled = 1.0
    print max_scaled
  }' "$load_cache")

  # Generate sparkline with dynamic scaling using awk
  load_spark=$(awk -v max="$max_load" '{
    idx = int(($1 * 7) / max)
    if (idx < 0) idx = 0
    if (idx > 7) idx = 7
    chars[idx]
  } BEGIN {
    split("▁▂▃▄▅▆▇█", chars, "")
  } {
    printf "%s", chars[idx + 1]
  }' "$load_cache")
else
  load_spark="▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"
fi

# Clear screen and show stats
clear
cat << 'EOF'
╔═══════════════════════════════════════════╗
║          SYSTEM RESOURCE MONITOR          ║
╠═══════════════════════════════════════════╣
║                                           ║
EOF

# Function to format a row with right border
# Usage: format_row label_color label sparkline value
format_row() {
  local color=$1
  local label=$2
  local spark=$3
  local value=$4
  local box_width=41  # Inner width (between borders)

  # Calculate content length
  # Label (4) + 2 spaces + sparkline (20) + 1 space = 27 chars before value
  local prefix_len=27
  local value_max_len=$((box_width - prefix_len))

  # Right-align value in remaining space
  printf "║ ${color}%s  %s %*s${C_RESET} ║\n" "$label" "$spark" "$value_max_len" "$value"
}

# Function to format a row with split current/avg
# Usage: format_row_split label_color label sparkline current avg
format_row_split() {
  local color=$1
  local label=$2
  local spark=$3
  local current=$4
  local avg=$5
  local box_width=41  # Inner width (between borders)

  # Label (4) + 2 spaces + sparkline (20) + 1 space = 27 chars before value area
  local prefix_len=27
  local value_area_len=$((box_width - prefix_len))

  local current_str="${current}%"

  # If avg is empty, left-align current% and pad to fill box
  if [[ -z "$avg" ]]; then
    # Pad current% to fill the value area
    printf "║ ${color}%s  %s %s%*s${C_RESET} ║\n" \
      "$label" "$spark" "$current_str" \
      $((value_area_len - ${#current_str})) ""
    return
  fi

  # Format: "current%        (avg avg%)"
  # Calculate padding: remaining space after "current%" and "(avg X%)"
  local avg_str="(avg ${avg}%)"
  local padding_len=$((value_area_len - ${#current_str} - ${#avg_str}))

  # Build the padding string
  local padding=""
  for ((i=0; i<padding_len; i++)); do
    padding+=" "
  done

  printf "║ ${color}%s  %s %s${C_RESET}%s${C_GRAY}%s${C_RESET} ║\n" \
    "$label" "$spark" "$current_str" "$padding" "$avg_str"
}

# LOAD
format_row "$C_YELLOW" "LOAD" "$load_spark" "$load_curr"

# CPU
format_row_split "$C_GREEN" "CPU " "$cpu_spark" "$cpu_curr" "$cpu_avg"

# MEM
format_row_split "$C_BLUE" "MEM " "$mem_spark" "$mem_curr" "$mem_avg"

# GLM (no avg since it doesn't change much, left-aligned)
format_row_split "$C_PURPLE" "GLM " "$glm_spark" "${glm_curr//%/}" ""

cat << 'EOF'
║                                           ║
╚═══════════════════════════════════════════╝
EOF

# Wait for any key press
read -n1 -s
