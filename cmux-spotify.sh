#!/bin/sh
# cmux-spotify.sh
# Polls Spotify and updates the cmux sidebar with the current track.
# Supports macOS (osascript), Linux (playerctl), and Windows (PowerShell).
#
# Usage:
#   cmux-spotify.sh [--interval <seconds>]
#
# Default interval: 3 seconds

INTERVAL=3

while [ $# -gt 0 ]; do
  case "$1" in
    --interval) INTERVAL="$2"; shift 2 ;;
    *) shift ;;
  esac
done

OS="$(uname -s)"
PREV=""

get_spotify_info() {
  case "$OS" in
    Darwin)
      if ! pgrep -x "Spotify" >/dev/null 2>&1; then
        echo ""
        return
      fi
      state=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
      if [ "$state" = "playing" ]; then
        track=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
        artist=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
        echo "playing|$track|$artist"
      elif [ "$state" = "paused" ]; then
        track=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
        artist=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
        echo "paused|$track|$artist"
      else
        echo ""
      fi
      ;;
    Linux)
      if ! command -v playerctl >/dev/null 2>&1; then
        echo ""
        return
      fi
      state=$(playerctl -p spotify status 2>/dev/null)
      if [ "$state" = "Playing" ]; then
        track=$(playerctl -p spotify metadata title 2>/dev/null)
        artist=$(playerctl -p spotify metadata artist 2>/dev/null)
        echo "playing|$track|$artist"
      elif [ "$state" = "Paused" ]; then
        track=$(playerctl -p spotify metadata title 2>/dev/null)
        artist=$(playerctl -p spotify metadata artist 2>/dev/null)
        echo "paused|$track|$artist"
      else
        echo ""
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      info=$(powershell.exe -NoProfile -Command '
        $p = Get-Process -Name Spotify -EA 0 | ? { $_.MainWindowTitle -and $_.MainWindowTitle -ne "Spotify" -and $_.MainWindowTitle -ne "" }
        if ($p) { "playing|" + $p.MainWindowTitle }
        elseif (Get-Process -Name Spotify -EA 0 | ? { $_.MainWindowTitle -eq "Spotify" }) { "paused|Spotify" }
      ' 2>/dev/null | tr -d '\r')
      echo "$info"
      ;;
    *)
      echo ""
      ;;
  esac
}

cleanup() {
  cmux clear-status spotify 2>/dev/null
  exit 0
}

trap cleanup INT TERM

while true; do
  info=$(get_spotify_info)

  if [ "$info" != "$PREV" ]; then
    if [ -z "$info" ]; then
      cmux clear-status spotify 2>/dev/null
    else
      state=$(echo "$info" | cut -d'|' -f1)
      track=$(echo "$info" | cut -d'|' -f2)
      artist=$(echo "$info" | cut -d'|' -f3)

      if [ "$state" = "playing" ]; then
        cmux set-status spotify "♫ $track - $artist" --color "#1DB954"
      else
        cmux set-status spotify "⏸ $track - $artist" --color "#535353"
      fi
    fi
    PREV="$info"
  fi

  sleep "$INTERVAL"
done
