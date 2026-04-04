#!/bin/bash
monitor="eDP-1"
scale="1.5"
touchscreen="wacom-hid-52c6-finger" #your touchscreen device
wallpaper="$HOME/Downloads/sunweall.png"
log_file="$HOME/rotate-debug.log"

# State files for communication between processes
tablet_state_file="/tmp/tablet_mode_state"
rotation_state_file="/tmp/rotation_state"

# Initialize tablet mode as off
echo "false" >"$tablet_state_file"

echo "$(date): Starting rotation monitor script with tablet mode detection" >>"$log_file"

# Function to apply wallpaper with refresh
apply_wallpaper() {

  #needed for wallpaper scaling
  echo "$(date): Refreshing swww daemon for orientation: $1" >>"$log_file"

  pkill swww-daemon 2>/dev/null #very
  swww init &
  swww img "$wallpaper" --transition-type none --resize fit --fill-color 000000

  echo "$(date): Wallpaper applied for orientation: $1" >>"$log_file"
}

# Function to set orientation (only if in tablet mode)
set_orientation() {
  local transform=$1
  local orientation_name=$2

  # Read current tablet mode state
  local tablet_mode=$(cat "$tablet_state_file" 2>/dev/null || echo "false")

  if [ "$tablet_mode" = "true" ]; then
    echo "$(date): Setting orientation to $orientation_name (transform: $transform)" >>"$log_file"

    hyprctl keyword monitor "$monitor,preferred,auto,$scale,transform,$transform"
    hyprctl keyword input:touchdevice:transform $transform
    apply_wallpaper "$orientation_name"
  else
    echo "$(date): Rotation ignored - not in tablet mode (orientation would be: $orientation_name)" >>"$log_file"
  fi
}

# Background process to monitor tablet mode
monitor_tablet_mode() {
  echo "$(date): Starting tablet mode monitor" >>"$log_file"
  libinput debug-events --device /dev/input/event5 2>/dev/null | while read -r line; do
    if echo "$line" | grep -q "SWITCH_TOGGLE.*tablet-mode.*state 1"; then
      echo "true" >"$tablet_state_file"
      echo "$(date): Tablet mode: ON" >>"$log_file"
    elif echo "$line" | grep -q "SWITCH_TOGGLE.*tablet-mode.*state 0"; then
      echo "false" >"$tablet_state_file"
      echo "$(date): Tablet mode: OFF - resetting to normal orientation" >>"$log_file"
      # Reset to normal orientation when exiting tablet mode
      hyprctl keyword monitor "$monitor,preferred,auto,$scale,transform,0"
      hyprctl keyword input:touchdevice:transform 0
      apply_wallpaper "normal (laptop mode)"
    fi
  done
}

# Start tablet mode monitoring in background
monitor_tablet_mode &
tablet_monitor_pid=$!

# Monitor orientation changes in main process
monitor-sensor | while read -r line; do
  echo "$(date): $line" >>"$log_file"

  case "$line" in
  *"orientation changed: normal"*)
    set_orientation 0 "normal"
    ;;
  *"orientation changed: left-up"*)
    set_orientation 1 "left-up"
    ;;
  *"orientation changed: right-up"*)
    set_orientation 3 "right-up"
    ;;
  *"orientation changed: bottom-up"*)
    set_orientation 2 "bottom-up"
    ;;
  esac
done

# Cleanup on exit
cleanup() {
  echo "$(date): Cleaning up..." >>"$log_file"
  kill $tablet_monitor_pid 2>/dev/null
  rm -f "$tablet_state_file" "$rotation_state_file"
  exit 0
}

trap cleanup EXIT INT TERM
