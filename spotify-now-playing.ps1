# spotify-now-playing.ps1
# Outputs the currently playing Spotify track for use in status lines.
# Windows only - reads the Spotify window title.

$proc = Get-Process -Name Spotify -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -ne "Spotify" -and $_.MainWindowTitle -ne "" }

if ($proc) {
    # Playing: window title = "Artist - Track"
    $title = $proc.MainWindowTitle
    $parts = $title -split " - ", 2
    $artist = $parts[0]
    $track = $parts[1]
    Write-Host -NoNewline "♫ $track - $artist"
} else {
    # Check if Spotify is running but paused
    $paused = Get-Process -Name Spotify -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -eq "Spotify" }
    if ($paused) {
        Write-Host -NoNewline "⏸ Spotify"
    }
}
