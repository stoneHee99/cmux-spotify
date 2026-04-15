#!/bin/sh
# launch.sh
# Creates a Spotify workspace in cmux at the bottom of the sidebar.
# Safe to call multiple times — skips if already running.

if pgrep -f spotify-tui.sh >/dev/null 2>&1; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create workspace running the TUI
ws=$(cmux new-workspace --command "sh $SCRIPT_DIR/spotify-tui.sh" 2>/dev/null | awk '{print $2}')

if [ -z "$ws" ]; then
  echo "Failed to create workspace. Is cmux running?"
  exit 1
fi

# Rename to Spotify
cmux rename-workspace --workspace "$ws" "Spotify" 2>/dev/null

# Move to the very bottom
cmux reorder-workspace --workspace "$ws" --index 9999 2>/dev/null

echo "Spotify workspace created: $ws"
