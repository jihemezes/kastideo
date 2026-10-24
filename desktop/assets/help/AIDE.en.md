# Kastideo for Windows and Linux

> Preview 1 (mock-up) — version 1.1.7-desktop1. This pre-release brings the home screen, live TV in the Classic interface and the player from the Mac version. Other features will follow in steps.

## What this preview includes

- **Home**: global search (channels, movies, series), three big Live, Movies and Series tiles with their counts, Favorites and Recents shortcuts.
- **Live (Classic interface)**: sidebar with All channels, Favorites, Recents and the provider's categories; channel list with search; player on the right.
- **Player** (mpv engine): compact auto-hiding control bar, stream health pill (colour, SD/HD/FHD/4K, stalls), volume, theater mode, full screen, “Ready in x s” badge.
- **Stream relay**: as on Mac, Kastideo opens a single connection to the provider itself and passes it to the player; the previous channel is closed before the next one opens.
- **Refused channels**: when the provider refuses a channel (HTTP 403/404), Kastideo does not insist and explains why.

## Adding a source

**Sources** button (antenna, top right of the home screen) > **Add a source**:

- **Xtream Codes**: server address, username and password. The password is stored in the system vault (Credential Manager on Windows, GNOME keyring on Linux).
- **M3U playlist**: playlist address or file path. A “get.php?username=…&password=…” address is recognised and turned into a much faster Xtream source.

Sources are refreshed at launch when their last update is more than 6 hours old.

## Keyboard shortcuts

- **Ctrl+0**: home — **Ctrl+1**: live
- **Space**: play / pause — **M**: mute — **F**: favorite
- **Ctrl+Enter** or double-click the picture: theater mode — **Esc**: exit theater mode
- **F11**: full screen
- **Ctrl+Alt+L**: playback log

## Right-click on a channel

Watch, add to or remove from favorites, copy the channel name.

## Installation

- **Windows**: unzip the “windows-x64.zip” archive and run **kastideo.exe**. The app is not signed: Windows SmartScreen shows “Windows protected your PC”; click **More info** then **Run anyway**.
- **Zorin OS 17 / Ubuntu 22.04**: “ubuntu22.04_amd64.deb” package (double-click or `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: “ubuntu24.04_amd64.deb” package.
- **Any distribution, and Raspberry Pi (64-bit)**: AppImage file; make it executable (right-click > Properties > Allow executing, or `chmod +x`) and run it.

## Next steps

1. **Interfaces**: Cinema (carousel, posters, TMDB pages), TV (zapping by number), Movies and Series.
2. **Advanced features**: TV guide, recording, timeshift, themes and alerts, MultiView, channel fixing, categories.
3. **Finishing**: Windows installer, built-in updates, full help.

## Troubleshooting

- **A channel does not start**: open the **Playback log** (Ctrl+Alt+L). “Relais :” lines show the provider's exact answer (e.g. “HTTP 200 en 0,35 s” or “HTTP 403”).
- **No picture on Linux**: check that the **libmpv** package is installed (the .deb installs it automatically; the AppImage bundles it).
- **VPN**: an active VPN can prevent the provider from serving streams.
