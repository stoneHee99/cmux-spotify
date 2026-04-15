#!/bin/sh
# spotify-now-playing.sh
# Outputs the currently playing Spotify track for use in status lines.
# Supports macOS (osascript) and Linux (playerctl).

OS="$(uname -s)"

case "$OS" in
  Darwin)
    if ! pgrep -x "Spotify" >/dev/null 2>&1; then
      exit 0
    fi

    state=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)

    if [ "$state" = "playing" ]; then
      track=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
      artist=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
      printf '♫ %s - %s' "$track" "$artist"
    elif [ "$state" = "paused" ]; then
      track=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
      artist=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
      printf '⏸ %s - %s' "$track" "$artist"
    fi
    ;;

  Linux)
    if ! command -v playerctl >/dev/null 2>&1; then
      exit 0
    fi

    state=$(playerctl -p spotify status 2>/dev/null)

    if [ "$state" = "Playing" ]; then
      track=$(playerctl -p spotify metadata title 2>/dev/null)
      artist=$(playerctl -p spotify metadata artist 2>/dev/null)
      printf '♫ %s - %s' "$track" "$artist"
    elif [ "$state" = "Paused" ]; then
      track=$(playerctl -p spotify metadata title 2>/dev/null)
      artist=$(playerctl -p spotify metadata artist 2>/dev/null)
      printf '⏸ %s - %s' "$track" "$artist"
    fi
    ;;
esac
