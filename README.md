# claude-code-spotify

Show your currently playing Spotify track in [Claude Code](https://docs.anthropic.com/en/docs/claude-code)'s status line.

```
bagseoghui@host  ~/project  ⎇ main  Opus 4.6  ctx:25%  ♫ Dynamite - BTS  14:30:00
                                                        ^^^^^^^^^^^^^^^^^^^^^^^^
```

## Features

- Displays the current track and artist in Claude Code's bottom status bar
- Shows `♫` when playing, `⏸` when paused
- Disappears when Spotify is not running
- Cross-platform: **macOS**, **Linux**, and **Windows**

## Installation

### 1. Download the script

```bash
# macOS / Linux
curl -o ~/.claude/spotify-now-playing.sh \
  https://raw.githubusercontent.com/stoneHee99/claude-code-spotify/main/spotify-now-playing.sh
chmod +x ~/.claude/spotify-now-playing.sh
```

```powershell
# Windows (PowerShell)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/stoneHee99/claude-code-spotify/main/spotify-now-playing.ps1" `
  -OutFile "$env:USERPROFILE\.claude\spotify-now-playing.ps1"
```

### 2. Configure Claude Code

Add the following to your Claude Code `settings.json`:

**macOS / Linux** (`~/.claude/settings.json`)

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh ~/.claude/spotify-now-playing.sh"
  }
}
```

**Windows** (`%USERPROFILE%\.claude\settings.json`)

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -File %USERPROFILE%\\.claude\\spotify-now-playing.ps1"
  }
}
```

### 3. Restart Claude Code

Restart Claude Code and play something on Spotify. You should see the track info in the status bar.

## Integrating with an existing status line

If you already have a custom `statusline-command.sh`, add this snippet:

```bash
# Spotify now playing
spotify=$(sh ~/.claude/spotify-now-playing.sh 2>/dev/null)
if [ -n "$spotify" ]; then
  out="${out}  $(printf '\033[36m%s\033[0m' "$spotify")"
fi
```

## Platform details

| OS | Method | Requirements |
|---|---|---|
| macOS | AppleScript (`osascript`) | Spotify desktop app |
| Linux | [playerctl](https://github.com/altdesktop/playerctl) (MPRIS/D-Bus) | `playerctl` installed, Spotify desktop app |
| Windows | Window title reading | Spotify desktop app |

### Linux: Install playerctl

```bash
# Ubuntu / Debian
sudo apt install playerctl

# Arch
sudo pacman -S playerctl

# Fedora
sudo dnf install playerctl
```

### Windows limitation

When Spotify is paused, the window title changes to just "Spotify", so the track name is not available in paused state. Only `⏸ Spotify` is shown.

## How it works

The script checks if Spotify is running, reads the current playback state and track info using OS-native methods, and outputs a single line of text. Claude Code's status line picks up this output and displays it at the bottom of the terminal.

## License

MIT
