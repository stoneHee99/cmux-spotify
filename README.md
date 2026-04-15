# cmux-spotify

Show your currently playing Spotify track in [cmux](https://cmux.dev)'s sidebar — right next to your Claude Code session.

![Spotify Green](https://img.shields.io/badge/Spotify-1DB954?style=flat&logo=spotify&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white)

## What it does

A background script that polls Spotify and updates the cmux sidebar in real time.

- `♫ Track - Artist` in Spotify green (`#1DB954`) when playing
- `⏸ Track - Artist` in gray when paused
- Automatically clears when Spotify is closed
- Configurable poll interval (default: 3 seconds)

## Installation

### 1. Download

```bash
curl -o ~/.cmux-spotify.sh \
  https://raw.githubusercontent.com/stoneHee99/cmux-spotify/main/cmux-spotify.sh
chmod +x ~/.cmux-spotify.sh
```

### 2. Run

```bash
# Start in background
nohup ~/.cmux-spotify.sh &

# Or with a custom interval (seconds)
nohup ~/.cmux-spotify.sh --interval 2 &
```

### 3. Auto-start (optional)

To start automatically when you open cmux, add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
# Start cmux-spotify if inside cmux and not already running
if [ -n "$CMUX_WORKSPACE_ID" ] && ! pgrep -f cmux-spotify.sh >/dev/null; then
  nohup ~/.cmux-spotify.sh >/dev/null 2>&1 &
fi
```

### Stop

```bash
pkill -f cmux-spotify.sh
```

## Platform support

| OS | Method | Requirements |
|---|---|---|
| macOS | AppleScript (`osascript`) | Spotify desktop app |
| Linux | [playerctl](https://github.com/altdesktop/playerctl) (MPRIS/D-Bus) | `playerctl`, Spotify desktop app |
| Windows | Window title reading (via PowerShell) | Spotify desktop app, Git Bash or WSL |

### Linux: Install playerctl

```bash
# Ubuntu / Debian
sudo apt install playerctl

# Arch
sudo pacman -S playerctl

# Fedora
sudo dnf install playerctl
```

### Windows note

When Spotify is paused on Windows, the window title changes to just "Spotify", so the track name is not available in paused state.

## How it works

The script runs a simple loop:

1. Check if Spotify is running
2. Read the current track, artist, and playback state using OS-native methods
3. Call `cmux set-status spotify "..."` to update the sidebar
4. Sleep for the configured interval
5. On exit (`Ctrl+C` / `kill`), automatically clears the status via `cmux clear-status`

Only updates the sidebar when the track actually changes, so it's lightweight.

## cmux commands used

```bash
cmux set-status spotify "♫ Track - Artist" --color "#1DB954"  # set
cmux clear-status spotify                                      # clear
cmux list-status                                               # check
```

## License

MIT
