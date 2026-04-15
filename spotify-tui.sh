#!/bin/sh
# spotify-tui.sh
# Minimal Spotify mini-player TUI for cmux workspace.
# Updates the cmux sidebar status + progress AND renders an interactive TUI.
# macOS (osascript) / Linux (playerctl)

OS="$(uname -s)"
INTERVAL=1
WS_ID="$CMUX_WORKSPACE_ID"
SEP=$(printf '\036')  # ASCII Record Separator — safe delimiter

# ── Spotify helpers ──────────────────────────────────────────

get_all_info() {
  case "$OS" in
    Darwin)
      if ! pgrep -x "Spotify" >/dev/null 2>&1; then
        printf 'stopped\036\036\0360\0361'
        return
      fi
      osascript -e '
        tell application "Spotify"
          set sep to ASCII character 30
          set s to player state as string
          if s is "stopped" then
            return s & sep & sep & sep & "0" & sep & "1"
          end if
          set t to name of current track
          set a to artist of current track
          set al to album of current track
          set p to player position
          set d to duration of current track
          return s & sep & t & sep & a & sep & al & sep & (round p) & sep & (round (d / 1000))
        end tell
      ' 2>/dev/null
      ;;
    Linux)
      if ! command -v playerctl >/dev/null 2>&1; then
        printf 'stopped\036\036\0360\0361'
        return
      fi
      state=$(playerctl -p spotify status 2>/dev/null | tr '[:upper:]' '[:lower:]')
      if [ "$state" != "playing" ] && [ "$state" != "paused" ]; then
        printf 'stopped\036\036\0360\0361'
        return
      fi
      track=$(playerctl -p spotify metadata title 2>/dev/null)
      artist=$(playerctl -p spotify metadata artist 2>/dev/null)
      album=$(playerctl -p spotify metadata album 2>/dev/null)
      pos=$(playerctl -p spotify position 2>/dev/null | cut -d. -f1)
      dur=$(playerctl -p spotify metadata mpris:length 2>/dev/null | awk '{printf "%.0f", $1/1000000}')
      printf '%s\036%s\036%s\036%s\036%s\036%s' "$state" "$track" "$artist" "$album" "${pos:-0}" "${dur:-1}"
      ;;
    *)
      printf 'stopped\036\036\0360\0361'
      ;;
  esac
}

spotify_cmd() {
  case "$OS" in
    Darwin) osascript -e "tell application \"Spotify\" to $1" 2>/dev/null ;;
    Linux)  playerctl -p spotify "$1" 2>/dev/null ;;
  esac
}

format_time() {
  m=$(( $1 / 60 ))
  s=$(( $1 % 60 ))
  printf '%d:%02d' "$m" "$s"
}

# ── Colors ───────────────────────────────────────────────────

GREEN='\033[1;32m'
DIM='\033[2m'
BOLD='\033[1m'
CYAN='\033[36m'
RESET='\033[0m'
WHITE='\033[1;37m'
GRAY='\033[90m'
CLR='\033[K'

# ── Marquee ──────────────────────────────────────────────────

MARQUEE_OFFSET=0
MARQUEE_MAX=25
MARQUEE_LEN=0
PREV_TRACK=""
SCROLLED=""

update_marquee() {
  text="$1"
  MARQUEE_LEN=$(printf '%s' "$text" | python3 -c "import sys; print(len(sys.stdin.read()))")
  if [ "$MARQUEE_LEN" -le "$MARQUEE_MAX" ]; then
    SCROLLED="$text"
    return
  fi
  padded="${text}   ·   ${text}"
  SCROLLED=$(printf '%s' "$padded" | python3 -c "import sys; t=sys.stdin.read(); print(t[$MARQUEE_OFFSET:$MARQUEE_OFFSET+$MARQUEE_MAX], end='')")
  total=$((MARQUEE_LEN + 7))
  MARQUEE_OFFSET=$(( (MARQUEE_OFFSET + 1) % total ))
}

# ── Sidebar update ───────────────────────────────────────────

update_sidebar() {
  state="$1" track="$2" artist="$3" pos="$4" dur="$5"

  [ -z "$WS_ID" ] && return

  if [ "$state" != "playing" ] && [ "$state" != "paused" ]; then
    cmux clear-status spotify --workspace "$WS_ID" 2>/dev/null
    cmux clear-progress --workspace "$WS_ID" 2>/dev/null
    PREV_TRACK=""
    return
  fi

  # Reset marquee on track change
  if [ "$track" != "$PREV_TRACK" ]; then
    MARQUEE_OFFSET=0
    PREV_TRACK="$track"
  fi

  pos_fmt=$(format_time "$pos")
  dur_fmt=$(format_time "$dur")
  song_text="$track - $artist"
  update_marquee "$song_text"

  if [ "$state" = "playing" ]; then
    cmux set-status spotify "♫ $SCROLLED" --color "#1DB954" --workspace "$WS_ID" 2>/dev/null
  else
    cmux set-status spotify "⏸ $SCROLLED" --color "#535353" --workspace "$WS_ID" 2>/dev/null
  fi

  if [ "$dur" -gt 0 ]; then
    progress=$(awk "BEGIN {printf \"%.2f\", $pos / $dur}")
    cmux set-progress "$progress" --label "$pos_fmt / $dur_fmt" --workspace "$WS_ID" 2>/dev/null
  fi
}

# ── Render TUI (flicker-free) ────────────────────────────────

render() {
  # Move cursor to top-left instead of clearing
  printf '\033[H'

  info=$(get_all_info)

  state=$(printf '%s' "$info" | awk -F"$SEP" '{print $1}')
  track=$(printf '%s' "$info" | awk -F"$SEP" '{print $2}')
  artist=$(printf '%s' "$info" | awk -F"$SEP" '{print $3}')
  album=$(printf '%s' "$info" | awk -F"$SEP" '{print $4}')
  pos=$(printf '%s' "$info" | awk -F"$SEP" '{print $5}')
  dur=$(printf '%s' "$info" | awk -F"$SEP" '{print $6}')

  pos=${pos:-0}
  dur=${dur:-1}

  if [ "$state" != "playing" ] && [ "$state" != "paused" ]; then
    update_sidebar "" "" "" "" ""
    printf '\n%b' "$CLR"
    printf '  %bSpotify is not running%b%b\n' "$DIM" "$RESET" "$CLR"
    printf '%b\n%b\n%b\n%b\n%b\n' "$CLR" "$CLR" "$CLR" "$CLR" "$CLR"
    return
  fi

  update_sidebar "$state" "$track" "$artist" "$pos" "$dur"

  pos_fmt=$(format_time "$pos")
  dur_fmt=$(format_time "$dur")

  # Progress bar
  cols=$(tput cols 2>/dev/null || echo 40)
  bar_width=$(( cols - 16 ))
  [ "$bar_width" -lt 10 ] && bar_width=10

  if [ "$dur" -gt 0 ]; then
    filled=$(( pos * bar_width / dur ))
  else
    filled=0
  fi
  empty=$(( bar_width - filled ))

  bar=""
  i=0; while [ $i -lt $filled ]; do bar="${bar}━"; i=$((i+1)); done
  bar="${bar}●"
  i=0; while [ $i -lt $empty ]; do bar="${bar}─"; i=$((i+1)); done

  if [ "$state" = "playing" ]; then
    icon="▶"
    icon_color="$GREEN"
  else
    icon="⏸"
    icon_color="$DIM"
  fi

  printf '\n%b' "$CLR"
  printf '  %b%s%b  %b%s%b%b\n' "$icon_color" "$icon" "$RESET" "$BOLD" "$track" "$RESET" "$CLR"
  printf '     %b%s%b%b\n' "$CYAN" "$artist" "$RESET" "$CLR"
  printf '     %b%s%b%b\n' "$DIM" "$album" "$RESET" "$CLR"
  printf '\n%b' "$CLR"
  printf '  %b%s%b %b%s%b %b%s%b%b\n' "$GRAY" "$pos_fmt" "$RESET" "$GREEN" "$bar" "$RESET" "$GRAY" "$dur_fmt" "$RESET" "$CLR"
  printf '\n%b' "$CLR"
  printf '  %b⏮  ⏯  ⏭%b   %bp%b prev  %bspace%b play/pause  %bn%b next  %bq%b quit%b\n' "$WHITE" "$RESET" "$DIM" "$RESET" "$DIM" "$RESET" "$DIM" "$RESET" "$DIM" "$RESET" "$CLR"
}

# ── Cleanup ──────────────────────────────────────────────────

cleanup() {
  tput cnorm 2>/dev/null
  stty echo icanon 2>/dev/null
  if [ -n "$WS_ID" ]; then
    cmux clear-status spotify --workspace "$WS_ID" 2>/dev/null
    cmux clear-progress --workspace "$WS_ID" 2>/dev/null
  fi
  exit 0
}

# ── Main loop ────────────────────────────────────────────────

clear
tput civis 2>/dev/null
trap cleanup INT TERM

stty -echo -icanon min 0 time 0 2>/dev/null

while true; do
  render
  i=0
  while [ $i -lt $((INTERVAL * 10)) ]; do
    key=$(dd bs=1 count=1 2>/dev/null)
    if [ -n "$key" ]; then
      case "$key" in
        q|Q) cleanup ;;
        ' ')
          case "$OS" in
            Darwin) spotify_cmd "playpause" ;;
            Linux)  spotify_cmd "play-pause" ;;
          esac
          break ;;
        n|N)
          case "$OS" in
            Darwin) spotify_cmd "next track" ;;
            Linux)  spotify_cmd "next" ;;
          esac
          break ;;
        p|P)
          case "$OS" in
            Darwin) spotify_cmd "previous track" ;;
            Linux)  spotify_cmd "previous" ;;
          esac
          break ;;
      esac
    fi
    sleep 0.1
    i=$((i+1))
  done
done
