# Kastideo for Windows and Linux

> Preview 4 — version 1.2.0-desktop4. This pre-release brings the home screen, live TV (Classic, Cinema and TV interfaces, TV guide grid, themes), movies and series (Classic and Cinema interfaces), the player and the settings from the Mac version. Other features will follow in steps.

## What this preview includes

- **Home**: global search (channels, movies, series), Live, Movies and Series tiles, Favorites and Recents shortcuts, “Continue watching” row.
- **Live TV**: two interfaces to choose from (Settings > Appearance).
  - **Classic**: sidebar (all channels, favorites, recents, **themes**, categories), list with search and the **programme on now** (title, time, progress bar), player on the right.
  - **Cinema**: “featured” banner with what your favorite and recent channels are showing (otherwise major news, sports and general channels), **“Sports on now”**, “Live news”, “Movies on now”… rows (one version per channel), Recently watched, Favorites, **“Tonight”** rows by theme (movies, sports, series, documentaries…) then one row per category. Clicking a channel opens it full frame; **Back** (or Esc) stops the channel and returns to the rows.
  - **TV**: the channel full frame, like on a television. **↑ / ↓**: previous / next channel; **type a number** (up to 4 digits, confirmed automatically or with Enter); **←** or the window's left edge: **channel panel** (All / Favorites / Recents / theme / category filter, search, programme on now; it closes by itself); **→** or **I**: **info banner** (number, name, time, programme on now and next, shown on each channel change); **B**: previously watched channel; **F**: favorite; **M**: sound; **Space**: pause; **G**: TV guide; **H**: home. The top bar (home, channels, guide, sections, settings) appears when the mouse moves.
- **TV guide** (home, live sidebar, Ctrl+7 or the G key in the TV interface): programme grid, channels in rows and hours in columns, red line at the current time; **‹ Now ›** to move, day picker (today, tomorrow… other days open at 7 pm), 2 h / 3 h / 6 h span, filter (all, favorites, recents, theme, category) and search. Click a channel to play it; click a programme to open its details (times, duration, overview) with **Watch** or **Go to channel**.
- **Themes** (live sidebar, or a row's “See all”): **On now**, **Tonight** (programmes from 8 pm to 11 pm) or **Channels**, filtered by theme (Sports, News, Movies, Kids, Documentaries…) and, for sports, by discipline (football, rugby, tennis…). Channels without guide data are still listed when their name is enough to classify them. An upcoming programme opens its details (overview, times) with “Watch channel”. Right-click: channel version (FHD, HD, SD), **channel theme** (to correct the automatic classification), favorites.
- **TV guide (data)**: the provider's guide (XMLTV) loaded in the background and kept on disk, completed by a **fallback guide** (xmltvfr.fr) for channels without programmes. The programme on now also shows in the player bar.
- **Movies and Series**: two interfaces to choose from (Settings > Appearance).
  - **Classic**: categories, list with posters, details on the right; “Play” shows the player instead of the details.
  - **Cinema**: scrolling “featured” banner (arrows on hover; TMDB trending of the week, latest additions, a chosen category), Continue watching, Latest additions, Recently watched, Favorites rows then one row per category (“See all”), full-page details.
- **Details**: poster, overview, year, runtime, genres, rating, director, cast, trailer. For a series: seasons and episodes, with each one's progress.
- **Player** (mpv engine): auto-hiding control bar, stream health pill, volume, theater mode, full screen. For movies and episodes: mini-timeline (click or drag; the target time is shown), −10 s / +30 s, **resume playback** where you left off (“Start over” to begin again), **Back to details** button.
- **Stream relay**: as on Mac, a single connection to the provider; the previous channel is closed before the next one opens.

## Adding a source

**Settings** (gear at the top right of the home screen or at the bottom of the sidebar, or Ctrl+,) > **Sources** > **Add a source**:

- **Xtream Codes**: server address, username and password. The password is stored in the system vault (Credential Manager on Windows, GNOME keyring on Linux).
- **M3U playlist**: playlist address or file path. A “get.php?username=…&password=…” address is recognised and turned into a much faster Xtream source.

Sources are refreshed at launch when their last update is more than 6 hours old. Optional **TV guide (XMLTV)** field: address of a guide other than the provider's.

## Settings (Ctrl+,)

- **General**: language (system, French, English — at next launch), resume playback, stream relay, refresh at launch, clear recents; **TV guide** (channels with programmes, Refresh guide, **fallback guide**: on/off, address or one of the xmltvfr.fr guides, loading status); **adult content** (hidden by default); **TMDB key**.
- **Appearance**: Classic or Cinema interface for live TV, movies and series, and the **TV** interface for live TV; **featured banner**: show or hide, height (compact, normal, large), scrolling (6 to 20 s), sources (TMDB trending, latest additions, chosen category for movies and for series).
- **Sources**: add, refresh, delete; TV guide status of each source.
- **Categories**: for live TV, movies or series — drag to reorder, untick to hide everywhere, double-click or pencil to rename, keywords to hide every category containing them (e.g. “PAKISTAN”), Sort A to Z, Reset. Right-click a category in the sidebar: Hide this category.
- **Backup**: **Export configuration…** (sources and their TV guide, passwords if you wish, favorites, recents, categories, interfaces, adult content, banner, TMDB key) and **Import configuration…**. The file is the same as Kastideo for Mac's (Settings > General > Backup and transfer): you can move from one computer to another both ways. Nothing is deleted on import.

## TMDB key (optional and free)

Create an account on themoviedb.org, then **Settings > API** and request a key (personal use). Copy the “API key” (v3) or the “API read access token” (v4) into Settings > General, then **Save**: Kastideo checks the key. Details become richer (HD posters and backdrops, cast with photos, trailers).

## Keyboard shortcuts

- **Ctrl+0**: home — **Ctrl+1**: live — **Ctrl+2**: movies — **Ctrl+3**: series — **Ctrl+7**: TV guide — **Ctrl+,**: settings
- TV interface: **↑ / ↓** zapping, **digits** channel number, **←** panel, **→ / I** banner, **B** previous channel, **G** guide, **H** home
- **Space**: play / pause — **M**: mute — **F**: favorite — **←** / **→**: −10 s / +30 s (movies and episodes)
- **Ctrl+Enter** or double-click the picture: theater mode — **Esc**: exit theater mode, then go back to the rows (live TV in the Cinema interface, the channel stops) or to the details
- **F11**: full screen
- **Ctrl+Alt+L**: playback log

## Right-click on a channel, movie or series

Watch or open details, Play (movies), add to or remove from favorites, channel theme (live TV), copy the name. Horizontal rows scroll with Shift + mouse wheel, the touchpad, or by dragging with the mouse.

## Installation

- **Windows**: unzip the “windows-x64.zip” archive and run **kastideo.exe**. The app is not signed: Windows SmartScreen shows “Windows protected your PC”; click **More info** then **Run anyway**.
- **Zorin OS 17 / Ubuntu 22.04**: “ubuntu22.04_amd64.deb” package (double-click or `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: “ubuntu24.04_amd64.deb” package.
- **Any distribution, and Raspberry Pi (64-bit)**: AppImage file; make it executable (right-click > Properties > Allow executing, or `chmod +x`) and run it.

## Next steps

1. **Advanced features**: recording, timeshift (pause live and catch up), programme alerts, MultiView, channel fixing.
2. **Personalisation**: light theme, accent colour, tile size.
3. **Finishing**: Windows installer, built-in updates, full help.

## Troubleshooting

- **A single window**: Kastideo opens only once; launched again while running, it simply brings the existing window to the front. On closing, playback is stopped and the video engine released before quitting.

- **A channel does not start**: open the **Playback log** (Ctrl+Alt+L). “Relais :” lines show the provider's exact answer (e.g. “HTTP 200 en 0,35 s” or “HTTP 403”).
- **No picture on Linux**: check that the **libmpv** package is installed (the .deb installs it automatically; the AppImage bundles it).
- **VPN**: an active VPN can prevent the provider from serving streams.
- **No programmes in the guide**: Settings > Sources shows each source's guide status (“empty or unreadable guide”, HTTP code…). The fallback guide covers common French channels; Settings > General > TV guide > **Refresh guide** restarts all downloads.
- **Passwords on Linux**: without a keyring (GNOME Keyring or KWallet), Kastideo keeps passwords in its preferences and says so in the log.
