# Arch Linux Auto-Rotate Script

A Bash script for 2-in-1 laptops running **Hyprland** on Arch Linux that automatically rotates the display and touchscreen based on the physical orientation of the device, but **only when in tablet mode**.

Tested on a Lenovo IdeaPad Flex 5.

---

## How It Works

The script runs two concurrent processes:

1. **Tablet mode monitor** – watches `/dev/input/event5` via `libinput debug-events` for hardware switch events. When the laptop is folded into tablet mode, rotation is enabled. When it is folded back into laptop mode, the display resets to normal orientation (transform 0) and rotation is disabled.

2. **Orientation monitor** – reads sensor data from `monitor-sensor` and applies the matching Hyprland display transform whenever a rotation event is received *and* tablet mode is active. Supported orientations: `normal`, `left-up`, `right-up`, and `bottom-up`.

After every rotation, the wallpaper is re-applied using `swww` (the daemon is restarted to ensure correct scaling for the new orientation).

All events are appended to a log file (`~/rotate-debug.log` by default) for debugging.

---

## Prerequisites

- **Hyprland** window manager
- **swww** – wallpaper daemon (`swww` and `swww-daemon`)
- **libinput** – for tablet mode detection (`libinput debug-events`)
- **iio-sensor-proxy** – provides the `monitor-sensor` command for reading orientation data

---

## Configuration

At the top of `auto-rotate.sh`, adjust the following variables to match your system:

| Variable | Default | Description |
|---|---|---|
| `monitor` | `eDP-1` | The Hyprland monitor name (run `hyprctl monitors` to find yours) |
| `scale` | `1.5` | Display scale factor applied on every rotation |
| `touchscreen` | `wacom-hid-52c6-finger` | Touchscreen device name (run `hyprctl devices` to find yours) |
| `wallpaper` | `~/Downloads/sunweall.png` | Path to the wallpaper image |
| `log_file` | `~/rotate-debug.log` | Path to the debug log file |

You may also need to change the input device path (`/dev/input/event5`) in `monitor_tablet_mode` to match the correct event node for your laptop's lid/tablet switch (check with `libinput list-devices`).

---

## Usage

Make the script executable and run it (ideally as a background process started with your Hyprland session):

```bash
chmod +x auto-rotate.sh
./auto-rotate.sh &
```

To start it automatically with Hyprland, add the following to your `hyprland.conf`:

```
exec-once = /path/to/auto-rotate.sh
```

---

## Notes

- Rotation is intentionally **ignored in laptop mode** to prevent accidental screen flips when the device is used as a regular laptop.
- The script resets the display to normal orientation whenever tablet mode is turned off.
- This script is tailored for the Lenovo IdeaPad Flex 5 and **may require adjustments** on other hardware (device names, event node, scale factor, etc.).
