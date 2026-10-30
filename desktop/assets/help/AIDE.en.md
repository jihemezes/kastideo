# Kastideo for Windows and Linux

> Version 1.4.2-desktop1 — optional “Buy me a coffee” (Ko-fi) button on the home screen, in What's New and in Settings > About, can be hidden; version 1.4.0-desktop1 — replay: watch a programme that already aired (provider archive, up to 14 days) from the TV Guide or a channel, “Watch from the start”, saving a replay, return to live at the end; version 1.3.4-desktop1 — TV guide: category separators ignored, “Program not available”, French channel coverage in the log; version 1.3.3-desktop1 — Log sorted by topic (search, levels of detail, kept history), detailed TV guide diagnostics and a “Reload the guide” button; version 1.3.1-desktop1 — “My videos” tile (rows, filters, folder browsing, diagnostics), All / IPTV / My videos selector in Movies and Series, optional password or token, Emby sign-in fixed. Version 1.3.0-desktop1 — new sources: folders (disk, USB drive, NAS), Jellyfin, Emby and Plex, network search for servers, resume and “watched” shared with servers, TMDB details for files, subtitles placed next to videos. Version 1.2.2-desktop1 — schedule a recording from live TV, edit recents, “Select all” box for categories. Kastideo provides no content: you add your own sources (Xtream Codes subscription or M3U playlist, video folders, Jellyfin, Emby or Plex server).

## Getting started

1. Open **Settings** (gear on the home screen, bottom of the sidebar, or **Ctrl+,**) > **Sources** > **Add a source**.
2. Choose the type: **Xtream Codes** subscription (server, username, password), **M3U playlist**, video **Folders** (disk, USB drive, NAS), or a **Jellyfin**, **Emby** or **Plex** server.
3. Kastideo loads channels, movies, series and the TV guide. Go back **home** and choose **Live**, **Movies** or **Series**.

> Tip: already using Kastideo on Mac? Export its configuration (Settings > General > Backup and transfer) and import it here (Settings > Backup).

## Sources

### Xtream Codes

Server address (e.g. http://example.com:8080), username and password. The password is stored in the system vault: Credential Manager on Windows, GNOME Keyring or KWallet on Linux.

### M3U / M3U8 playlist

Playlist address or file on disk (**Choose a file…**). A "get.php?username=…&password=…" address is recognized and turned into an Xtream source, much faster and more complete (details, episodes, latest additions).

### Folders (disk, USB drive, NAS)

Settings > Sources > **Add a source** > **Folders**, then **Add a folder…** (internal disk, USB disk or stick) or type a **network path** and click **+**: `\\NAS\Videos` or a network drive (`Z:\`) on Windows, a mounted share (`/mnt/nas/videos`, `/media/…`) on Linux. Several folders can make up one source.

- **Movies** recognized from their names: “Inception (2010).mkv”, “The.Matrix.1999.1080p.BluRay.mkv”, folder “Amélie (2001)”. Category “Movies · folder name”.
- **Series**: “Breaking.Bad.S01E02.mkv”, “Friends 1x05.mp4”, folders “Show/Season 1/…”. Episodes are grouped by series and season in **Series**.
- **Other videos**: category **Videos · folder name** in Movies.
- Scanned at each launch and then every 20 minutes. Disk unplugged: a message says so and the previous list is kept. Unreadable subfolders (“System Volume Information”…) are skipped.
- **Subtitles** placed next to a video (“Movie.srt”, “Movie.en.srt”) are loaded on playback.
- With a **TMDB key**, **posters and summaries** are added automatically; right-click > **Fix details…** to pick the right title when the file name misleads the search.

### Jellyfin, Emby and Plex

Settings > Sources > **Add a source** > **Jellyfin**, **Emby** or **Plex**. **Search the network** finds the servers at home: click yours to fill in the form (otherwise type the address; without a port, 8096 or 32400 is added).

- **Jellyfin / Emby**: username and password — **optional** if the account has none (or an **API key** from the dashboard). **Test** checks the address; on failure, the exact server response is shown.
- **Plex**: **Sign in with Plex** opens plex.tv in the browser; authorize Kastideo, then choose the server from your account. Or type the address and the **token** (X-Plex-Token), optional if the server allows the local network without authentication.
- Libraries appear in **Movies** and **Series** (“library name · server name”), with the server's posters, details, seasons and episodes. Direct playback, no transcoding.
- **Resume and “watched” shared both ways**: the position is sent to the server while you watch, and the one from your other devices is picked up. Right-click > **Mark as watched / unwatched**; **Watched** badge on posters.

> Windows firewall: on the first search, allow Kastideo on private networks so that servers can answer.

### TV guide (XMLTV)

The guide provided by your provider loads in the background and is kept on disk. The optional **TV guide (XMLTV)** field of a source lets you use another guide (.xml or .xml.gz).

### Fallback TV guide (xmltvfr.fr)

Settings > General > **TV guide**: a fallback guide fills in channels without programmes in your provider's guide, matching them by name. Pick an xmltvfr.fr guide or type an address; **Reload the guide** downloads everything again. The **TV guide log** button opens the Log on the *TV Guide* topic: address requested, provider response (code, size, time), channels and programmes received, period covered, how many of your channels are linked to the provider, the backup or no guide, and — if the guide is unusable — the beginning of the server's answer. The provider's programmes are filtered on your channels' identifiers: if the guide holds programmes but none for your channels, the log shows the identifiers on both sides.

### Managing sources

Settings > **Sources**: **edit** a source (pencil button: name, server, username, password, playlist address, TV guide — favorites, recents and channel fixes are kept), refresh it, delete it, see the state of its TV guide. The **eye** button shows the password (or the TMDB key) so you can check it. Sources refresh at startup when their last update is more than 6 hours old (adjustable). If a refresh returns an empty section, the previous one is kept.

## Navigating

### Home screen

Global search (channels, movies, series), **Live**, **Movies** and **Series** tiles, quick access to **Favorites**, **Recents**, **TV Guide**, **MultiView** and **Recordings**, and the **Continue watching** row.

### My videos

As soon as a **Folders**, **Jellyfin**, **Emby** or **Plex** source exists, a **My videos** tile appears on the home screen (shortcut **Ctrl+8**). It gathers your videos, apart from IPTV:

- **Featured**: **Resume playback** (started movies and episodes), **Recently added**, **Movies to watch**, then a Movies, Series and Videos row;
- **Movies**, **Series**, **Videos**: grids with search, filters (**genre**, **year**, **unwatched**) and sorting (title, recently added, year);
- **Folders**: browse your folders and subfolders as in the file explorer (breadcrumb to go back up), and the servers' libraries;
- **Sources**: all, or just one (NAS, Emby, Plex…). An orange triangle flags an error: right-click > **Error details…** shows the request and the **exact server response**, then **Retry**.

In **Movies** and **Series**, the **All / IPTV / My videos** selector (sidebar, above the categories) chooses what is shown: IPTV only (default), your videos only, or both mixed. The categories of your videos are never hidden by the countries setting.

### Sidebar

Live / Movies / Series picker, then: all channels or movies, **Favorites**, **Recents**, and for live TV **Themes**, **TV Guide** and **MultiView**; **Recordings**; the **categories**. At the bottom: the current recording and download (progress, time left) and **Settings**.

### Three interfaces

Settings > Appearance > **Interface per content type**:

- **Classic**: three columns (sidebar, list with the current programme, player or details on the right).
- **Cinema**: featured banner, posters or thumbnails in horizontal rows, full-page details. For live TV: "Sport right now", "Live news", "Tonight" rows per theme, favorites, recents, categories; a click opens the channel full frame, **Back** (or Esc) stops it.
- **TV** (live only): the channel full frame, like a television (see below).

### Featured banner (Cinema)

It cycles through movies or series (this week's TMDB trends available to you, latest additions, a category selection) or, for live TV, the current programme of your channels. Arrows on hover, pauses while the mouse is over it. Settings > Appearance > **Featured banner**: show or hide, height, speed, sources.

### Countries and languages (Cinema)

Providers often mix several countries (categories “FR| …”, “|PT| …”, “ITALIA”…). Settings > Appearance > **Countries and languages (Cinema interface)** lists the countries found in your category names, with the number of items: choose the ones to show. **Latest additions**, **trends**, the **featured banner** and **category rows** of the Cinema interface then only show those countries. **Keep categories without a country** keeps categories such as “Action” or “New”. **All** goes back to the full display. Lists and search stay complete.

### TV interface (live)

- **↑ / ↓**: previous / next channel; **type a number** (up to 4 digits).
- **←** or left edge: **channel panel** (filter, search, current programme).
- **→** or **I**: **info banner** (current and next programme).
- **B**: previous channel — **F**: favorite — **M**: sound — **Space**: pause — **G**: TV guide — **H**: home.

### TV guide grid

Home, live sidebar, **Ctrl+7** or the G key in the TV interface. Channels in rows, hours in columns, a red line at the current time; **‹ Now ›**, day picker, 2 h / 3 h / 6 h span, filter (all, favorites, recents, theme, category) and search. A click on a programme opens its details: **Watch**, **Record**, **Schedule recording** (red dot in the grid) or **Alert me when it starts** (bell). On a past programme of a channel with replay (↺): **Watch again** or **Save this replay**; past days are in the date menu.

### Live by theme

Sidebar > **Themes**: **Right now**, **Tonight** (8–11 pm) or **Channels**, filtered by theme (Sport, News, Movies, Kids, Documentaries…) and, for sport, by discipline. One version per channel (FHD, HD or SD depending on your connection). Right-click: channel version, **channel theme** (to fix the classification), favorites, edit the channel.

## Playback

The player (mpv engine) has a control bar that hides by itself, a stream health dot, volume, cinema mode (double-click or Ctrl+Enter) and full screen (F11). For movies and episodes: mini timeline, −10 s / +30 s, **resume** where you left off, **Back to details**.

### Live timeshift

Pause a channel (or go back with ← or the bar): it keeps being buffered (up to 1 h by default, adjustable). Without any action from you, the channel stays “LIVE”. The timeshift bar shows the delay, a slider to go back or catch up faster, the speed, **Catch up** and **Back to live**. ← / →: −10 s / +30 s.

### Replay: watching a programme that already aired

Some IPTV subscriptions keep channels for up to **14 days** (depending on the provider and the channel). Kastideo detects this by itself: channels with replay show a **↺** icon in lists and in the TV Guide.

- **In the TV Guide**: click a **past** programme (marked ↺), then **Watch again**. On the **current** programme, **Watch from the start** replays it from the beginning. **Save this replay** downloads the programme from the provider's archive (recordings folder).
- **Previous days**: the date menu of the TV Guide offers **Watch again (replay)** with the past days.
- **From a channel**: right-click the channel > **Watch again (replay)…** (recent programmes of that channel). The Cinema interface also has a **To watch again** row (your favourite channels with replay).
- **During a replay**, the player bar lets you pause and move within the programme. At the end, Kastideo **returns to the channel's live stream** (can be turned off).
- **Settings > General > Replay**: turn replay on or off, number of **days of past programmes kept in the guide** (more days = more memory), **time offset** (if the replayed programme is shifted by a few minutes or an hour, fix it here; the server's time zone is read automatically), return to live.
- A replay counts as **one connection**: it closes the current channel, like switching channels.
- If a replay does not start, open the **Log** (button Log, topic “Playback and relay”): the archive address built and the offset used are listed there. The provider's guide must contain past programmes: reload it after increasing the number of days kept.

### One connection at a time

Most subscriptions allow a single connection. Kastideo closes the previous channel before opening the next (**stream relay**, Settings > General > Playback) and asks before interrupting a recording.

### MultiView (several channels at once)

**MultiView** shows up to **4 live channels** on one screen. **Sound follows the active tile** (orange border).

- **Enabling**: each channel uses a connection to your provider, so MultiView stays off until you set the number of **simultaneous connections** of your subscription: Settings > General > Playback (2 to 4). **Detect** asks your Xtream sources.
- **Opening**: home > **MultiView**, live sidebar > **MultiView**, **Ctrl+Alt+M**, or right-click a channel > **Add to MultiView**. The channel you were watching becomes the first tile; if it is being recorded, it keeps recording in the background, muted.
- **Adding**: **+** button (or **A** key): favorites, recents, all channels or search. An empty cell of the grid also offers "Add a channel".
- **Layouts** (top right): **Automatic** (1 full frame, 2 side by side, 3 or 4 in a grid), **2 × 2 grid**, **One large** and the others small, **Side by side**. The layout is remembered.
- **Large view ↔ tile**: **double-click** a tile (or press **G**) to make it large with sound; double-click the large view again to go back to the grid.
- **When hovering a tile**: enlarge, change channel, remove. The channel name and current programme show at the bottom.
- **Saved groups** (bookmark icon): **Save this group…** stores the channels and the layout under a name (e.g. "Football multiplex"); click a group to reopen it, the cross deletes it.
- **Keyboard**: **1 to 4** sound on that tile, **G** enlarge, **A** add, **M** mute, **Del** remove the active tile, **F** or **F11** full screen, **Esc** leave full screen then MultiView.
- **Stop all** (or Back) stops every stream and returns to the previous screen.

> A recording or a download also uses a connection: an ⓘ icon reminds you in the MultiView bar. If a tile says "The channel is not responding", the provider is probably refusing an extra connection: remove a channel or lower the number of connections.

### The Log (diagnostics)

The **Log** (**Ctrl+Alt+L**, or the button on the home screen and in error messages) is Kastideo's diagnostic tool. User names and passwords are **hidden** in it: you can copy it to share it.

- **Topics**: *TV Guide*, *Playback and relay*, *Sources and catalogues*, *Recordings*, *TMDB details*, *Updates*, *Display and other*. Click one or more topics to see only those (the number of lines per topic is shown).
- **Search** a word, or show only **errors and warnings**.
- **Copy what is shown** copies only what is displayed, with the filter at the top.
- **Level of detail** (per topic): *Normal*, *Detailed* (default for the TV Guide) or *Debug* (everything). The setting applies to lines written afterwards; errors and warnings are always kept.
- **Current session / Previous session**: the log is kept on disk (the folder path is shown at the bottom of the window), so you can read what happened at startup in the previous session.

## Recordings and downloads

### Recording live TV

Red round button in the player bar, **R** key, or right-click a channel > **Record now**: the channel is recorded until the end of the current programme (plus the margin) or until you stop it, in **Videos/Kastideo/Enregistrements**.

- The stream bytes are copied as is to a **.ts** file, losslessly: the watched channel is copied from the relay (no second connection to the provider); another channel is downloaded directly, reconnecting if the stream drops.
- At the end, the .ts is converted losslessly to **MKV** (default format, Settings > Recordings); if conversion fails, the .ts is kept — it plays everywhere.
- HLS streams (.m3u8) and playback without the relay still go through the video engine.

### Scheduling a recording

- **Right-click a live channel > Schedule a recording…**, or the **Schedule…** button of the Recordings screen (then choose the channel: favorites, recents or search).
  - **Guide programmes**: the channel's next programmes, with **Schedule** (or **Record** for the current one). A check mark shows those already scheduled.
  - **Time slot**: day, start and end time, optional title — for a channel without TV guide or a specific show. An end earlier than the start finishes the next day.
  - **Repetition** (list at the top right): **once**, **every day**, **Monday to Friday** or **every week**. The next occurrence is added automatically; the ⟲ button of a repeated recording in the list stops repeating.
- From the details of an upcoming programme (TV guide, themes): **Schedule recording**.
- Margins before and after (Settings > Recordings) are added. Kastideo must be open at the scheduled time: turn on **Start Kastideo when I sign in** if needed (Settings > General).

### Details in your language

With a **TMDB key** (Settings > General), titles, summaries, genres and episodes come from TMDB, in the interface language. When the only summary available is the provider's in another language (Portuguese, Spanish…), it is folded: **Show the summary (Portuguese)** shows it anyway. It doesn't appear in the banner or the episode list.

### Downloading a movie or episodes

**Download** button on a movie's details (now or **tonight**), **Download the season** or each episode's icon for a series, right-click > Download. One download at a time, resumed after an interruption, paused during playback (adjustable). Files go to **Videos/Kastideo/Films** and **Séries/<series>**.

### Recordings screen

Current recording (stop), downloads (pause, resume, cancel), scheduled recordings and history, files in the folder: a click plays them, right-click to show them in the folder or delete them.

## Alerts and notifications

- **Alert me when it starts** on an upcoming programme's details (bell in the guide).
- **Keywords** (Settings > Recordings): a programme whose title contains a keyword triggers an alert, on your favorite channels or on all of them.
- The alert shows at the top right of Kastideo with **Watch**, and the window comes back if it was minimized.
- **System notifications** (Settings > General > Notifications, on by default): alerts, recording start and end, download finished or failed also appear in the Windows or Linux notification center, even when Kastideo is behind another window. Clicking the notification brings Kastideo back.

## Editing a channel

Right-click a channel > **Edit channel…**: name, number, logo (image address or a file copied into Kastideo) and **TV guide** channel (search among the provider and fallback guides). The fix applies to this version of the channel (HD, FHD…) and survives every refresh. **Restore** goes back to the original.

## Organizing categories

- **Right-click a category** in the sidebar: **Rename…**, **Move to top**, **Move up**, **Move down**, **Move to bottom**, **Hide this category**, **Manage categories…**.
- **Settings > Categories** (or the icon next to "Categories"): for live TV, movies or series — drag to reorder, untick to hide everywhere, double-click to rename, **keywords** to hide every category containing them at once (e.g. "PAKISTAN"), **Sort A to Z**, **Restore**.
- **Select / deselect all**: the box above the list ticks or unticks all listed categories at once. With the **search** (e.g. "PT"), it only affects the categories found: hide a whole country in two clicks, then tick only the ones you want.

A hidden category is hidden everywhere: lists, search, home, rows.

## Favorites and recents

Star in the player bar, **F** key or right-click > Add to favorites. Recents keep the last 60 items opened.

- **Edit** (next to the "Recents" title): tick items then **Remove selection**, or a row's cross to remove it alone; **Select all** and **Clear all** (for the section shown). **Done** goes back to the list.
- Right-click an item > **Remove from recents**.
- Settings > General > **Clear recents** clears them all, every section.

## Appearance

Settings > **Appearance**:

- **Theme**: **Dark** (default), **Light** or **Same as system** (follows Windows or Linux). The player, TV interface, MultiView, home screen, details pages and the featured banner stay dark, as on Mac.
- **Accent color**: default (Kastideo blue), blue, purple, pink, red, orange, green or teal — used for selections, buttons, switches.
- **List density** (Classic interface): compact, standard or spacious.
- **Thumbnail size** (Cinema interface): small, medium or large.
- **Interface** per content type and **featured banner** (see above).

Changes apply immediately, without restarting.

## Keyboard shortcuts

- **Ctrl+0**: home — **Ctrl+1**: live — **Ctrl+2**: movies — **Ctrl+3**: series — **Ctrl+7**: TV guide — **Ctrl+Alt+M**: MultiView — **Ctrl+,**: settings
- **Space**: play / pause — **M**: sound — **F**: favorite — **R**: record / stop — **← / →**: −10 s / +30 s
- **Ctrl+Enter** or double-click the picture: cinema mode — **F11**: full screen — **Esc**: leave cinema mode, back to details or rows
- TV interface: **↑ / ↓** zapping, **digits** channel number, **←** panel, **→ / I** banner, **B** previous channel, **G** guide, **H** home
- MultiView: **1 to 4** sound, **G** enlarge, **A** add, **Del** remove, **F** full screen, **Esc** leave
- **Ctrl+Alt+L**: log

## Startup and .m3u files

Settings > General > **Startup and files**:

- **Start Kastideo when I sign in** (Windows and Linux), and **Start minimized** in the taskbar: scheduled recordings and alerts only happen while Kastideo is open.
- **Open .m3u and .m3u8 files with Kastideo** (optional): double-clicking a playlist offers to add it as a source (Settings > Sources); if Kastideo is already open, the existing window receives it. If Windows keeps opening another program, right-click the file > Open with > Choose another app > Kastideo.

Both options are also offered by the Windows installer (unticked by default).

## Updates

Kastideo checks GitHub for new versions at launch and then every 12 hours (Windows / Linux pre-releases, while these versions are in preview).

- A new version is announced by a **banner at the bottom right**, only when you are not watching anything. **View** opens the update window with its release notes; the cross postpones it.
- **Install and restart** downloads the file matching your installation, then:
  - **Windows, installed**: runs the new installer silently, then restarts Kastideo;
  - **Windows, portable**: replaces the folder's files after closing, then restarts Kastideo;
  - **AppImage**: saves the new AppImage next to the old one, deletes the old one and launches it;
  - **.deb package**: installs it with apt (your password is asked), then restarts Kastideo.
- A recording in progress is finished cleanly before closing.
- **Skip this version**: it won't be offered again (a manual check offers it again).
- Settings > General > **Updates**: installed version and installation type, **Check now**, automatic checks, **What's new in recent versions**, releases page on GitHub.
- On the first launch after an update, the **What's new** window sums up the changes.

## Settings

- **General**: language (on next launch), resume playback, stream relay, refresh at startup, clear recents, **simultaneous connections** (MultiView), **system notifications**, TV guide and fallback guide, adult content (hidden by default), TMDB key, **startup and .m3u files**, **updates**.
- **Appearance**: theme, accent color, list density, thumbnail size, interfaces, featured banner.
- **Sources**: add, refresh, delete, guide state.
- **Categories**: order, hiding, names, keywords.
- **Recordings**: folder, format, margins, downloads, timeshift, alerts.
- **Backup**: export or import the configuration.

## TMDB key (optional and free)

Create an account on themoviedb.org, then **Settings > API** and request a key (personal use). Paste the "API key" (v3) or the "read access token" (v4) into Settings > General, then **Save**. Details become richer (posters, cast, trailers, summaries and episodes in your language).

## Backup and transfer

Settings > **Backup**: **Export configuration…** (sources and their guide, passwords if you wish, favorites, recents, categories, interfaces, appearance, number of connections, adult content, banner, TMDB key) and **Import configuration…**. The file is the same as Kastideo for Mac: you can move from one computer to the other in both directions. Nothing is deleted on import. Jellyfin, Emby and Plex servers are included (password or token too, if requested); folders as well, with their paths (to fix if they differ on this computer).

## Installation

- **Windows (recommended)**: run **Kastideo-…-windows-x64-setup.exe**. By default Kastideo installs for you only, without administrator rights (in your AppData folder); the installer also offers to install for all users, a desktop icon, opening .m3u files and starting at sign-in. Uninstall: Windows Settings > Apps > Kastideo.
- **Windows, portable**: unzip the "windows-x64.zip" archive anywhere and run **kastideo.exe** (nothing is installed; updates replace the folder's files).
- The app is not signed: if SmartScreen says "Windows protected your PC", click **More info** then **Run anyway**.
- **Zorin OS 17 / Ubuntu 22.04**: "ubuntu22.04_amd64.deb" package (double-click or `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: "ubuntu24.04_amd64.deb" package.
- **Any distribution, and Raspberry Pi (64-bit)**: AppImage file; make it executable (right-click > Properties > Allow executing, or `chmod +x`) and run it.

## What's new

- **1.4.0-desktop1**: replay — watch a programme that already aired from the provider's archive (up to 14 days): TV Guide (past programmes, previous days, “Watch from the start”), right-click a channel, saving a replay, “To watch again” row in Cinema, return to live at the end, settings (days kept in the guide, time offset).
- **1.3.4-desktop1**: more accurate TV guide (category separators ignored, “Program not available”, French channels counted separately in the log).
- **1.3.3-desktop1**: Log sorted by topic (TV Guide, Playback and relay, Sources…, search, levels of detail, previous session kept), detailed TV guide entries in the log, “Reload the guide” button.
- **1.3.1-desktop1**: “My videos” tile (resume, recently added, genre / year / unwatched filters, sorting, folder browsing, error diagnostics), All / IPTV / My videos selector in Movies and Series, optional password or token, Emby sign-in fixed, source cache read correctly at startup.
- **1.3.0-desktop1**: new sources — folders (disk, USB drive, NAS), Jellyfin, Emby and Plex — with network search for servers, resume and “watched” shared with servers, TMDB details and detail fixing for files, subtitles placed next to videos.
- **1.2.2-desktop1**: schedule a recording from live TV (guide programmes or time slot, daily, weekday or weekly repetition), edit recents, "Select all" box for categories.
- **1.2.1-desktop1**: more reliable recording (direct stream copy, MKV conversion), timeshift fixed, source editing, “eye” button, details in your language, countries and languages of the Cinema interface.
- **1.2.0-desktop8**: Windows installer, built-in updates, what's new after an update, start at sign-in, opening .m3u files.
- **1.2.0-desktop7**: MultiView (up to 4 channels, layouts, large view, saved groups), light or system theme, accent color, list density, thumbnail size, categories reordered from the sidebar, system notifications, full help.
- **1.2.0-desktop6**: live timeshift, immediate and scheduled recording, downloads, programme alerts, channel editing.
- **1.2.0-desktop5**: movie and series details in the interface language.
- **1.2.0-desktop4**: TV guide grid, TV interface, Windows close fixed, single window.
- **1.2.0-desktop3**: live in the Cinema interface, themes, featured banner.

## Next steps

1. Fixes from test feedback (Windows and Linux).
2. Stable release for Windows and Linux.

## Troubleshooting

- **A channel won't start**: open the **Log** (Ctrl+Alt+L, topic *Playback and relay*). "Relais :" lines give the provider's exact answer (e.g. "HTTP 200 en 0,35 s" or "HTTP 403").
- **The update doesn't install**: the playback log (Ctrl+Alt+L) gives the reason. .deb package: if the password window doesn't appear, the command to type in a terminal is shown in the update window. You can always download the new version from the GitHub releases page.
- **MultiView: a tile stays black**: the provider refuses an extra connection. Check your subscription's number of connections (Settings > General > Playback > Detect).
- **No notification**: check Settings > General > Notifications, then the notification settings of Windows (Settings > System > Notifications) or of your Linux desktop. On Linux, the libnotify package is required (installed by the .deb, included in the AppImage).
- **Empty recording**: the provider sent nothing (channel refused, connection already used by another device). "Enregistrement" lines in the log give the provider's answer (e.g. "HTTP 403") and say if no data arrived after 30 s.
- **Timeshift doesn't go back further**: its depth depends on temporary disk space; without a disk cache (some libmpv versions on Linux), it is limited to 512 MB in memory.
- **Details in another language**: some providers only have one language. With a **TMDB key**, summaries, genres and episodes come from TMDB in your language.
- **Single window**: launched while already running, Kastideo just brings the existing window to the front.
- **No picture on Linux**: make sure the **libmpv** package is installed (the .deb installs it; the AppImage bundles it).
- **VPN**: an active VPN may prevent the provider from serving streams.
- **No programmes in the guide**: Settings > Sources shows each source's guide state; the fallback guide fills in common French channels.
- **Passwords on Linux**: without a keyring (GNOME Keyring or KWallet), Kastideo keeps passwords in its preferences and says so in the log.

## Support Kastideo

Kastideo is **free** and will stay free. If you enjoy the app, you can encourage its development by buying me a coffee on [Ko-fi](https://ko-fi.com/jihemezes): it is entirely optional.

The **Buy me a coffee** button appears discreetly on the home screen and in the What's New window, as well as in **Settings > About**. To hide the buttons on the home screen and in What's New, tick **Hide the “Buy me a coffee” buttons** in **Settings > About**.

## Privacy

Kastideo collects no data. It only contacts your IPTV providers, the TV guides you chose, GitHub for updates and, if you entered a key, TMDB. Your settings, favorites and passwords stay on your computer.
