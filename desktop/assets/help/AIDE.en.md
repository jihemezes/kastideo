# Kastideo for Windows and Linux

> Preview 2 — version 1.2.0-desktop1. This pre-release brings the home screen, live TV in the Classic interface, movies and series (Classic and Cinema interfaces), the player and the settings from the Mac version. Other features will follow in steps.

## What this preview includes

- **Home**: global search (channels, movies, series), Live, Movies and Series tiles, Favorites and Recents shortcuts, “Continue watching” row.
- **Live (Classic interface)**: sidebar (all channels, favorites, recents, categories), list with search, player on the right.
- **Movies and Series**: two interfaces to choose from (Settings > Appearance).
  - **Classic**: categories, list with posters, details on the right; “Play” shows the player instead of the details.
  - **Cinema**: scrolling “featured” banner (arrows on hover), Continue watching, Latest additions, Recently watched, Favorites rows then one row per category (“See all”), full-page details.
- **Details**: poster, overview, year, runtime, genres, rating, director, cast, trailer. For a series: seasons and episodes, with each one's progress.
- **Player** (mpv engine): auto-hiding control bar, stream health pill, volume, theater mode, full screen. For movies and episodes: mini-timeline (click or drag; the target time is shown), −10 s / +30 s, **resume playback** where you left off (“Start over” to begin again), **Back to details** button.
- **Stream relay**: as on Mac, a single connection to the provider; the previous channel is closed before the next one opens.

## Adding a source

**Settings** (gear at the top right of the home screen or at the bottom of the sidebar, or Ctrl+,) > **Sources** > **Add a source**:

- **Xtream Codes**: server address, username and password. The password is stored in the system vault (Credential Manager on Windows, GNOME keyring on Linux).
- **M3U playlist**: playlist address or file path. A “get.php?username=…&password=…” address is recognised and turned into a much faster Xtream source.

Sources are refreshed at launch when their last update is more than 6 hours old.

## Settings (Ctrl+,)

- **General**: language (system, French, English — at next launch), resume playback, stream relay, refresh at launch, clear recents, **TMDB key**.
- **Appearance**: Classic or Cinema interface for movies and for series (Cinema for live TV and the TV interface come later).
- **Sources**: add, refresh, delete.
- **Categories**: for live TV, movies or series — drag to reorder, untick to hide everywhere, double-click or pencil to rename, keywords to hide every category containing them (e.g. “PAKISTAN”), Sort A to Z, Reset. Right-click a category in the sidebar: Hide this category.
- **Backup**: **Export configuration…** (sources, passwords if you wish, favorites, recents, categories, interfaces, TMDB key) and **Import configuration…**. The file is the same as Kastideo for Mac's (Settings > General > Backup and transfer): you can move from one computer to another both ways. Nothing is deleted on import.

## TMDB key (optional and free)

Create an account on themoviedb.org, then **Settings > API** and request a key (personal use). Copy the “API key” (v3) or the “API read access token” (v4) into Settings > General, then **Save**: Kastideo checks the key. Details become richer (HD posters and backdrops, cast with photos, trailers).

## Keyboard shortcuts

- **Ctrl+0**: home — **Ctrl+1**: live — **Ctrl+2**: movies — **Ctrl+3**: series — **Ctrl+,**: settings
- **Space**: play / pause — **M**: mute — **F**: favorite — **←** / **→**: −10 s / +30 s (movies and episodes)
- **Ctrl+Enter** or double-click the picture: theater mode — **Esc**: exit theater mode
- **F11**: full screen
- **Ctrl+Alt+L**: playback log

## Right-click on a channel, movie or series

Watch or open details, Play (movies), add to or remove from favorites, copy the name.

## Installation

- **Windows**: unzip the “windows-x64.zip” archive and run **kastideo.exe**. The app is not signed: Windows SmartScreen shows “Windows protected your PC”; click **More info** then **Run anyway**.
- **Zorin OS 17 / Ubuntu 22.04**: “ubuntu22.04_amd64.deb” package (double-click or `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: “ubuntu24.04_amd64.deb” package.
- **Any distribution, and Raspberry Pi (64-bit)**: AppImage file; make it executable (right-click > Properties > Allow executing, or `chmod +x`) and run it.

## Next steps

1. **Live TV interfaces**: Cinema (rows by theme) then TV (zapping by number).
2. **Advanced features**: TV guide, recording, timeshift, themes and alerts, MultiView, channel fixing, categories.
3. **Finishing**: Windows installer, built-in updates, full help.

## Troubleshooting

- **A channel does not start**: open the **Playback log** (Ctrl+Alt+L). “Relais :” lines show the provider's exact answer (e.g. “HTTP 200 en 0,35 s” or “HTTP 403”).
- **No picture on Linux**: check that the **libmpv** package is installed (the .deb installs it automatically; the AppImage bundles it).
- **VPN**: an active VPN can prevent the provider from serving streams.
- **Passwords on Linux**: without a keyring (GNOME Keyring or KWallet), Kastideo keeps passwords in its preferences and says so in the log.
