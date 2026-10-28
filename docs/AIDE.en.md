# Kastideo Help

Kastideo is a media player that brings your live channels, movies and series from IPTV together in a simple, fast interface. Kastideo provides no content: you add your own sources (an Xtream Codes subscription or an M3U playlist, video folders on a disk, USB drive or NAS, a Jellyfin, Emby or Plex server).

> Version 1.4.0 — replay: watch a programme that already aired (provider archive, up to 14 days) from the TV Guide or a channel, “Watch from the start”, saving a replay, return to live at the end; version 1.3.4 — TV guide: category separators ignored, 4K/FHD versions reuse the HD version's programme, “Program not available”, coverage by country in the log; version 1.3.3 — Log sorted by topic (TV Guide, Playback, Sources…) with search, levels of detail and kept history, detailed TV guide diagnostics and a “Reload the TV guide” button; version 1.3.2 — build fix of 1.3.1; version 1.3.1 — “My videos” tile (rows, filters, folder browsing, diagnostics), All / IPTV / My videos selector in Movies and Series, optional password or token, Emby sign-in fixed; version 1.3.0 — new sources: folders (disk, USB drive, NAS), Jellyfin, Emby and Plex, network search for servers, resume and “watched” shared with servers, TMDB details for files, subtitles placed next to videos; version 1.2.2 — “Select / deselect all” box for categories; version 1.2.1 — countries and languages of Cinema rows and the banner; version 1.2.0 — configuration backup and transfer (Mac, Windows, Linux); version 1.1.7 — picture only (no sound) for channels with faulty sound; version 1.1.6 — refused channels explained, streams with an inconsistent clock handled better; version 1.1.5 — sound fixed on channels with a shifted clock; version 1.1.4 — stream relay fixed (local network permission); version 1.1.3 — stream relay for live TV (a single connection to the provider); version 1.1.2 — 1.1.1 fix; version 1.1.1 — automatic repair of missing sound on some channels; version 1.1.0 — timeshift: timeline, playback speed, Catch up, Back to live, maximum duration; version 1.0.3 — live: more reliable channel switching (waits for the connection to be released, retries), stream closed on quit; version 1.0.1 — themes: channels recognised by name are listed even without TV guide data; first stable release; channel fixing (name, number, logo, TV guide); new themes (Auto & Moto, Food & Home, Nature, Regional, International, Religion, Radio, Adult), sports disciplines; live TV by theme (on now, tonight, channels), one version per channel based on the connection, program alerts; update check at launch, offered outside playback; version number on the home screen; MultiView (up to 4 channels, depending on your subscription); redesigned player: auto-hiding bar, mini-timeline, information panel (audio tracks, subtitles), stream health; fast switch from Live (Classic) to Movies (Cinema); redesigned home, banner framing; featured banner fixed; categories can be reordered, hidden and renamed; “featured” banner carousel (TMDB trends, latest additions, chosen category, what's on now); instant switch from live TV to other sections; freeze fixed when leaving live TV, recording audio converted to AAC; more reliable start of live recording; xmltvfr.fr backup TV guide; TMDB key procedure in the help; movie/series page layout fixed; black screen fixed when returning to playback and in full screen; Movie and series details pages (Xtream + TMDB) in the Cinema interface, recordings visible while being written, more reliable MP4 conversion; full screen fixed, live recording made more reliable; Home screen, removing items from Recents, app available in French and English; TV Guide grid, resume playback, download indicator; new icon; TV interface for live (channel panel, information banner, zapping by number), alongside the Classic and Cinema interfaces.

## Getting started

1. On first launch, click **Add a Source**.
2. Choose the source type: **Xtream Codes**, **Playlist (URL)**, **Playlist (file)**, **Folders (disk, USB, NAS)**, **Jellyfin**, **Emby** or **Plex**.
3. Fill in the requested information, then click **Add**.
4. Kastideo loads the list of channels, movies and series, then the TV guide.

## Sources

### Xtream Codes

This is the most common format among IPTV providers. You need three pieces of information: the **server** address (for example `http://example.com:8080`), your **username** and your **password**.

- The **Test Connection** button checks your credentials and shows the account status, its expiration date and the number of simultaneous connections allowed.
- The password is stored in the **macOS keychain**, never in clear text on disk.
- The server's TV guide is used automatically.
- Series open on a page with their seasons and episodes.

### M3U / M3U8 playlist

- **By URL**: paste the playlist address supplied by your provider.
- If the address looks like `get.php?username=…&password=…` (the most common case with subscription providers), Kastideo recognizes it and saves it as **Xtream Codes**: loading is much faster, the TV guide is included and the password is kept in the keychain. Sources of this kind that were already saved are converted automatically.
- **By file**: choose an `.m3u` or `.m3u8` file on your Mac. Kastideo keeps the permission to access it so that it can refresh it.
- Categories come from the `group-title` attribute, logos from `tvg-logo` and the link to the TV guide from `tvg-id`.
- Kastideo automatically sorts entries into Live, Movies or Series based on their address.

### Folders (disk, USB drive, NAS)

To watch videos stored on the Mac, an external disk, a USB drive or a NAS:

1. Settings > Sources > **Add** > type **Folders (disk, USB, NAS)**.
2. **Add a folder…**: choose one or more folders (for example “Movies” and “Series”). For a **NAS**, first mount the share in the Finder (**Go > Connect to Server…**, for example `smb://nas.local/Videos`), then choose it among the volumes.
3. **Add**: Kastideo scans the folders and their subfolders.

Videos are recognized from their names:

- **Movies**: “Inception (2010).mkv”, “The.Matrix.1999.1080p.BluRay.mkv”, or a folder “Amélie (2001)” containing the movie. They appear in **Movies**, category “Movies · folder name”.
- **Series**: “Breaking.Bad.S01E02.mkv”, “Friends 1x05.mp4”, or a folder “Kaamelott/Season 3/12 - Le Tourment.avi”. Episodes are grouped into one series, with its seasons, in **Series**.
- **Other videos** (holidays, camera…): category **Videos · folder name**, in Movies.

Folders are scanned at each launch and then every 20 minutes: a new video shows up by itself. If the disk is unplugged or the share disconnected, a message says so under the source and the previous list is kept. **Subtitles** placed next to a video (“Inception (2010).srt”, “Inception (2010).en.srt”) are loaded on playback.

With a **TMDB key** (Settings > General), movies and series automatically get a **poster and summary**. If the file name misleads the search, right-click the poster (or the link at the bottom of the details page) > **Fix details…**: search for the right title and pick it; the choice is remembered.

### Jellyfin and Emby

1. Settings > Sources > **Add** > **Jellyfin** or **Emby**.
2. **Search the network** finds the servers at home; click yours to fill in the address. Otherwise type it (for example `192.168.1.10`: port 8096 is added).
3. Your Jellyfin / Emby **username** and **password** — **optional**: leave it empty if the account has none (an **API key** from the dashboard can also replace it). **Test Connection** checks the address. An address copied from the browser (“…:8096/web/index.html#!/home”) is reduced to the server's.
4. **Add**: the username is checked, then the server's movie, series and video libraries appear in **Movies** and **Series** (categories “library name · server name”), with the server's posters and details.

Playback is **direct**, without transcoding by the server. The password and session are stored in the keychain.

### Plex

1. Settings > Sources > **Add** > **Plex**.
2. **Sign in with Plex** opens plex.tv in the browser: sign in and authorize Kastideo. Back in Kastideo, choose the server from your account.
3. You can also type the server address (port 32400) and its **token** (X-Plex-Token). The token is **optional** if the server allows the local network without authentication (Plex > Settings > Network > “List of IP addresses and networks that are allowed without auth”).
4. **Add**: the movie and series libraries appear in **Movies** and **Series**.

### Resume and “watched” shared with servers

With Jellyfin, Emby and Plex, the playback position is sent to the server while you watch: a movie started in Kastideo can be resumed on the TV, and the other way round. A movie watched to the end is marked **watched** on the server. Right-click a movie or an episode > **Mark as watched / unwatched** (also for files from folders). A **Watched** badge appears on posters, and a check mark in the episode list.

> Network search: the first time, macOS asks for permission to access the **local network**; accept it (otherwise System Settings > Privacy & Security > Local Network).

### TV guide (XMLTV)

Each source can have a TV guide address in XMLTV format (`.xml` or `.xml.gz`). If you leave it empty, Kastideo uses the one from the Xtream server or the one announced in the playlist (`url-tvg`). The guide is kept from 6 hours back to 48 hours ahead.

### Backup TV guide (xmltvfr.fr)

Your provider's guide can be incomplete or temporarily empty. Kastideo completes it with a free **backup guide** from **xmltvfr.fr** (“Complete” guide by default: about 785 French and foreign channels, 5 days, updated daily):

- only channels **without programs** from your provider are completed; the provider's guide keeps priority;
- channels are matched **by name**: “|FR| TF1 FHD” → TF1, “|FR| FRANCE 2 UHD” → France 2, “|FR| TF1 4K” → TF1 4K;
- the backup guide is reloaded every 12 hours. If the provider sends an empty or unreadable guide, programs already known are kept and a message appears under the source.

**Finding out where the guide comes from.** Under each source, Settings > Sources shows how many programs the provider sent. The **Reload the TV guide** button (calendar icon) restarts the download of the provider's guide and the backup guide. Provider lines that are only **category separators** (“♣♦♣---|FR| FRANCE FHD |FR|---♣♦♣”) are ignored; a 4K or FHD version without its own programme reuses the HD version's; channels without a programme show “Program not available”. The **Log**, topic **TV Guide**, details every attempt: address requested, server response (code, size, time), number of channels and programs received, period covered, how many of your channels are linked to the provider's guide, the backup guide or neither, and — if the guide holds nothing usable — the beginning of the server's answer.

Settings > General > **Backup TV Guide**: turn it on or off, pick another xmltvfr.fr guide (France ~400 channels, DTT) or enter any XMLTV address, **Refresh Now**, and see how many channels were linked to yours.

### Managing sources

Open **Kastideo > Settings… (⌘,)**, **Sources** tab, or click the **Sources** button in the toolbar.

- The switch enables or disables a source without deleting it.
- The buttons let you refresh, edit or delete a source.
- If there is an error, the message appears in red under the source and an orange triangle appears in the sidebar.

## Navigating

### The Home screen

Kastideo opens on the **Home** screen: three large tiles, **Live**, **Movies** and **Series**, then smaller buttons for **Favorites**, **Recents**, the **TV Guide** and **Recordings**.

- The **search** field at the top searches channels, movies and series at once; click a result to open it.
- The **Continue Watching** row lists the movies and episodes you have started; click one to resume where you left off.
- If something is playing, a banner lets you **go back to it** or **stop** it.
- To return to Home at any time: the **Home** button (house) at the top left of the toolbar, **⌘0**, the **Home** row in the sidebar, or the **H** key in the TV interface.

Kastideo's **version number** is shown discreetly at the bottom right of the Home screen; clicking it opens the release notes.

### My videos

As soon as a **Folders**, **Jellyfin**, **Emby** or **Plex** source exists, a **My videos** tile appears on the home screen (and a row in the sidebar, **⌘8**). It gathers your videos, apart from IPTV:

- **Featured**: **Resume playback** (started movies and episodes), **Recently added**, **Movies to watch**, then a Movies, Series and Videos row;
- **Movies**, **Series**, **Videos**: grids with search, filters (**genre**, **year**, **unwatched**) and sorting (title, recently added, year);
- **Folders**: browse your folders and subfolders as in the Finder (breadcrumb to go back up), and the servers' libraries;
- **Sources**: all, or just one (NAS, Emby, Plex…). An orange triangle flags an error: right-click > **Error details…** shows the request and the **exact server response** (**Copy** button), then **Retry**.

In **Movies** and **Series**, the **All / IPTV / My videos** selector (sidebar, above the categories) chooses what is shown: IPTV only (default), your videos only, or both mixed. The categories of your videos are never hidden by the countries setting.

### The window columns

In the Classic interface, the window has three columns:

- **Sidebar**: Home, Live, Movies, Series, Favorites, Recents, TV Guide, then the categories of the chosen section and the status of your sources.
- **List**: the items of the section or category, with the current program for channels. The **Search** field filters the list regardless of case and accents.
- **Player**: the video, with the current program, its progress and the upcoming programs below it.

Right-clicking an item lets you add it to favorites or copy the stream address.

### Three interfaces to choose from

Kastideo offers three presentations, which you choose **separately for live, movies, series, and favorites / recents**:

- **Classic**: the three columns described above.
- **TV** (live only): see below.
- **Cinema**: a large scrolling **“featured” banner** (see below), then **horizontal rows**: continue watching, favorites and one row per category. Movies and series appear as posters, channels as thumbnails with the current program. A click on a channel opens the player full frame. A click on a **movie** or **series** poster first opens its **details page**: backdrop, poster, year, runtime, genres, rating, synopsis, director, cast (with photos), a **Back to Movies** (or Series) button at the top left, **Play** / **Resume**, **View Episodes**, **Trailer**, **Download** and favorite buttons. Information comes from your IPTV provider; add a free **TMDB** key (Settings > General > Movie and Series Details) for richer pages. **Back** (or Esc) returns to the catalog. At the top of the window, the **Live / Movies / Series / Guide / Favorites / Recents / Recordings** tabs replace the sidebar; search works as in Classic. “See All” opens a complete category as a grid.

To change the interface:

- the **Interface** button in the toolbar (it applies to the type of content displayed),
- the **View** menu: **⌥⌘1** Classic, **⌥⌘2** Cinema, **⌥⌘3** TV (live),
- or **Settings > Appearance**.

For example: TV for live and Cinema for movies and series. The **Recordings** section is always shown in the Classic interface. The default is Classic everywhere.

### The “featured” banner (Cinema)

At the top of Movies and Series, a **full-width carousel** scrolls through a selection: backdrop, poster, title, year, runtime, genres, rating, synopsis and **Play** (or **Resume** / **View Episodes**), **More Info** (the details page) and **Trailer** buttons. It mixes:

- this week's **TMDB trends** found in your catalog (TMDB key required);
- your provider's **latest additions**;
- a **selection from a category** of your choice (for example “New releases” or “Netflix”), or from the whole catalog at random.

Scrolling pauses while the mouse is over the banner; arrows and dots let you navigate. In **Live**, the banner shows **what's on now** on your favorite and recent channels, with progress, the next program and **Watch**.

Settings > Appearance > **“Featured” Banner**: show or hide, height (compact, normal, large), scrolling speed, carousel sources and movie and series categories.

### Countries and languages (Cinema)

Providers often mix several countries (categories “FR| …”, “|PT| …”, “ITALIA”…). Settings > Appearance > **Countries and languages (Cinema interface)** lists the countries found in your category names, with the number of items: tick the ones you want to see. **Latest additions**, **trends**, the **featured banner** and **category rows** of the Cinema interface then only show those countries. **Keep categories without a country** keeps categories such as “Action” or “New”. **All countries** goes back to the full display. Classic lists and search stay complete.

### The TV interface (live)

The channel fills the whole frame, like on a television. The first time it appears, Kastideo resumes the last channel you watched.

- **Channel panel**: **←** key, **Return**, or move the mouse to the left edge. It lists channels with number, logo, current program and progress. The menu at the top filters by **All / Favorites / Recents / category**, and the **Search** field filters by name. It closes by itself after a few seconds (**→** or **Esc** to close it right away).
- **Zapping**: **↑ / ↓** previous / next channel in the displayed list, **B** back to the previous channel.
- **Channel number**: type the digits (for example **1** then **2**); the channel opens after 1.6 s or with **Return**. If your provider does not number its channels, the number refers to the position in the displayed list.
- **Information banner**: shown for five seconds at each channel change (logo, number, current program, times, next program, time). **I** or **→** shows or hides it.
- Other keys: **F** favorite, **M** mute, **Space** pause (live timeshift).
- Double-click the picture or **⌘↩**: full screen; the toolbar is hidden.
- Keyboard keys do not work while typing in the search field. The tabs at the top of the window let you switch to Movies, Series, etc.

### The TV Guide grid

The **TV Guide** section (sidebar, **TV Guide** tab of the Cinema and TV interfaces, **⌘7**, or the **G** key in the TV interface). Channels are in rows, hours in columns; the red line marks the current time.

- **‹ ›** shift the grid, **Now** goes back to the current time, the date menu jumps to another day (7 p.m. for the following days).
- Choose the time span shown (**2 h / 3 h / 6 h**), filter by **favorites**, **recents** or **category**, or search for a channel.
- Click a program: description, **Watch** button, **Record** (current program) or **Schedule Recording** (upcoming program). A red dot marks a scheduled recording.
- Past days (date menu, **Watch again** section) and programmes marked ↺ allow **replay** (see “Replay”).
- Click a channel name to watch it. Only channels that have programs are listed: if the grid is empty, check the guide address in the source settings.

### Live TV by theme

The **Themes** section of the sidebar (under Live) sorts live TV by **theme** — Sports, Auto & Moto (motorsport), Movies, Series, News, Documentaries, Nature / Hunting & Fishing, Kids, Entertainment, Food & Home, Music, General, Regional (France 3 regions, local TV), International (foreign channels), Religion, Radio — without the categories you hid. Three modes:

- **On now**: what is airing now, sorted by the **program's genre** in the TV guide (a movie on a general channel shows up in “Movies”), with progress. Channels **with no guide data** are still listed when their **name is enough to classify them** (beIN Sports → Sport…): they show their name, without progress.
- **Tonight**: programs starting between **8 and 11 pm**. Right-click an upcoming program > **Alert Me When It Starts**.
- **Channels**: channels sorted by specialty. The theme is deduced automatically from the channel name (beIN, Eurosport → Sports; BFM, LCI → News…) then from its usual programs; right-click > **Channel Theme** to correct it.

Each channel appears **only once**, even if your provider offers it in several versions (4K, FHD, HD, SD): Kastideo picks the version suited to **your connection** (**Automatic** setting in Settings > General > Playback > Channel version) — it steps down after unstable playback and back up after three smooth ones. Right-click > **Version** to choose another.

Themes are also offered elsewhere: “Sports On Now”, “Movies On Now”… rows at the top of Live in the **Cinema** interface, a **Themes** filter in the **TV** interface's channel panel and the **TV Guide**, and “On TV Now” (and “Tonight”) chips on the **Home** screen.

In **Sports**, a second row filters by **discipline**: Football, Rugby, Tennis, Basketball, Combat sports, Golf, Cycling, Handball, Motorsport, Winter sports, Horse racing, Athletics & swimming (from program titles, genres and descriptions).

**Adult content**: channels and content whose name contains “|XX|” (or in an adult category) are **hidden everywhere** by default. To show them, and the **Adult** theme: Settings > General > Playback > **Show adult content**.

**Program alerts** (🔔 button of the Themes view): Kastideo alerts you two minutes before a program starts whose title contains a chosen word (“PSG”, “Formula 1”…), of a theme on your favorite channels, or a specific program. A notification and a **Watch** banner appear.

## Playback

Kastideo plays all content with the **VLC** engine: live MPEG-TS (.ts), HLS (.m3u8), MP4, MKV, AVI…

- Playback starts as soon as you select a channel, a movie or an episode.
- While opening, the channel logo and name are shown. The **“Ready in x s”** badge then shows the start-up time (can be turned off in settings).
- Controls appear when you hover over the video: play / pause, back 10 s and forward 30 s for movies and episodes, progress bar, volume (up to 200%) and theater mode.
- A click on the video pauses it; a **double-click** turns on **theater mode**: the window goes full screen and only the **video** remains visible (no columns or toolbar; the green window button and **⌃⌘F** do the same during playback). **Esc** or **⌘↩** to leave it.
- **Resume playback**: for movies and episodes, Kastideo remembers your position. When you reopen one, playback resumes where you stopped, with a message offering to **start over**. Progress bars appear in lists, posters and episodes. This can be turned off, and positions can be erased, in settings.
- For Xtream sources, live is played in MPEG-TS (.ts) format, like the Xtream reference player; if the stream fails, Kastideo automatically tries the .m3u8 variant (and vice versa).

### Control bar, timeline and information panel

- **Auto-hiding bar**: it appears on the slightest mouse movement and hides, along with the pointer, after 3 seconds of inactivity (it stays while the mouse is over it, while paused or when the panel is open).
- **Mini-timeline** (movies and episodes): a thin line above the buttons that thickens on hover and shows the target time; click or drag to move.
- **Stream health**: a **green** (Excellent), **orange** (Fair) or **red** (Unstable) dot shows reception quality, with the definition (SD, HD, 4K). On hover: exact resolution, bitrate, frames per second, dropped pictures and interruptions in the last minute.
- **Information panel** (ⓘ button or **⌘I**, Esc to close): it slides in from the right over the video and shows the channel with its current and upcoming programs, or a movie's synopsis and cast; the **audio track** (language, audio description…) and **subtitles** choice; detailed reception quality.

### MultiView (several channels at once)

**MultiView** shows up to **4 live channels** in one window (1 full frame, 2 side by side, 3 or 4 in a grid). **Sound follows the active tile** (orange border): click a tile or use keys **1 to 4**.

- Open it: **Playback > MultiView…** (**⌥⌘M**), or right-click a channel > **Add to MultiView**.
- In the window: **+** adds a channel (favorites, recents or search); hovering a tile, ⟳ changes the channel and ✕ removes it; **Stop All** stops every stream. Closing the window stops MultiView.
- Each stream uses **one connection** to your provider, so MultiView is **off by default**: enter your subscription's number of simultaneous connections in **Settings > General > Playback** (2 to 4) to enable it. An Xtream source's **Test Connection** button shows this number. When opened, main playback stops to free its connection (unless recording); a recording or download also uses a connection.

### If a channel does not start

If no picture arrives after **20 seconds**, Kastideo automatically tries the other stream format (.ts or .m3u8), then shows an error message with the details returned by the VLC engine.

The **Log** (menu **Playback > Playback Log…**, **⌥⌘L**, or the button in the error message) is Kastideo's diagnostic tool. User names and passwords are **hidden** in it: you can copy it to share it if you have a problem.

- **Topics**: messages are sorted into *TV Guide*, *Playback and relay*, *Sources and catalogues*, *Recordings*, *TMDB details*, *Updates* and *Display and other*. Click one or more topics to see only those (the number of lines for each topic is shown).
- **Search** a word in the log, or show only **errors and warnings**.
- **Copy what is shown** copies only what is displayed (topics, search), with the filter noted at the top.
- **Level of detail** (per topic): *Normal* (the essentials), *Detailed* (default for the TV Guide) or *Debug* (everything). The setting applies to lines written from then on; errors and warnings are always kept.
- **Current session / Previous session**: the log is kept on disk, so you can read what happened at startup in the previous session. **Show the log folder** reveals the file in the Finder.

### Live timeshift

**Pause** a live channel: the VLC engine keeps receiving the stream and stores it. When you resume, you are watching in **timeshift** (yellow “TIMESHIFT −2:34” indicator in the controls). If a stream cannot be paused, the button is greyed out.

In timeshift, the controls offer:

- a **timeline**: the pause point on the left, **live** on the right. **Drag the cursor to the right** to move forward: Kastideo speeds up playback until the chosen point (yellow marker), then returns to normal speed;
- **+30 s** (or ⌘]): move forward 30 seconds the same way;
- the **speed** (×1, ×1.25, ×1.5, ×2): speed up to reduce the delay; playback returns to ×1 by itself when it catches up with live;
- **Catch up**: speeds up until live, without skipping anything;
- **Back to live**: returns to live immediately. As the VLC engine usually cannot jump inside the timeshift buffer, the stream is reopened and the buffer cleared. If the stream allows seeking, the buffer is kept and −10 s / +30 s jump directly.

**Where is the timeshift stored?** In Kastideo's temporary folder (`~/Library/Containers/fr.jmezes.kastideo/Data/tmp/`, `vlc-timeshift-…` files), cleared when you change channel; allow 1 to 4 GB per hour depending on quality. Settings > General > Playback: **Maximum timeshift duration** (30 min to 3 h, or unlimited; once reached, playback resumes by itself), **Catch-up speed**, and a **Show** button to open the folder.

### Replay: watching a programme that already aired

Some IPTV subscriptions keep channels for up to **14 days** (depending on the provider and the channel). Kastideo detects this by itself: channels with replay show a **↺** icon in lists and in the TV Guide.

- **In the TV Guide**: click a **past** programme (marked ↺), then **Watch again**. On the **current** programme, **Watch from the start** replays it from the beginning. **Save this replay** downloads the programme from the provider's archive (recordings folder).
- **Previous days**: the date menu of the TV Guide offers **Watch again (replay)** with the past days.
- **From a channel**: right-click the channel > **Watch again (replay)** (recent programmes of that channel). The Cinema interface also has a **To watch again** row (your favourite channels with replay).
- **During a replay**, the player bar lets you pause and move within the programme. At the end, Kastideo **returns to the channel's live stream** (can be turned off).
- **Settings > General > Replay**: turn replay on or off, number of **days of past programmes kept in the guide** (more days = more memory), **time offset** (if the replayed programme is shifted by a few minutes or an hour, fix it here; the server's time zone is read automatically), return to live.
- A replay counts as **one connection**: it closes the current channel, like switching channels.
- If a replay does not start, open the **Log** (topic “Playback and relay”): the archive address built and the offset used are listed there. The provider's guide must contain past programmes: reload it after increasing the number of days kept.

### One connection at a time

Most IPTV subscriptions allow only **one simultaneous stream**. Kastideo always closes the current stream before opening the next one: you can zap without risk of exceeding your limit. If playback fails, check that no other device (TV, phone, Piboard…) is watching with the same subscription.

### Buffer

In **Settings > General > Playback**, choose the trade-off between speed and stability:

- **Fast** (default): 0.4 s of reserve, the shortest zapping.
- **Balanced**: 1 s.
- **Stable**: 3 s, for unreliable connections or servers (fewer interruptions, slower start).

## Recordings and downloads

Everything is in the **Recordings** section of the sidebar (**⌘6**): current recording, conversions, downloads, schedules and recorded files (click to watch them, right-click to show them in Finder or delete them).

Files are stored in **~/Movies/Kastideo** (can be changed in **Settings > Recordings**) and named automatically, for example “TF1 – Le goût du détail – 2026-10-18 20h50”.

### Recording live

- While a channel is playing, click **●** in the controls, **Record** under the video, or use **⇧⌘R**. The **REC** badge shows the duration.
- Recording stops automatically at the end of the current program (according to the TV guide, plus the margin after), or when you click **■**.
- It uses **the same connection** as playback: nothing more is consumed from your subscription.
- Right-click a channel > **Record Now**: if you are watching another channel, Kastideo asks whether to stop playback, then records in the background.
- A **banner** at the bottom of the window confirms when a recording starts and ends and shows **the folder** where the file is (**Show** button). If the folder chosen in settings is no longer accessible, the file is placed in ~/Movies/Kastideo and the banner says so. Detailed steps are in the **Playback Log**.
- **While recording**, the file is visible and growing in the **In progress** subfolder of the recordings folder (a folder named after the program). When stopped, it is moved to the recordings folder and the subfolder is removed. If the VLC engine does not create the file within 10 seconds, Kastideo automatically retries in a temporary folder (the file then appears only when stopped); “Recording impossible” is shown only after both attempts, with details in the Playback Log (⌥⌘L). Length is limited only by disk space: count about 1 to 3 GB per hour depending on the channel (a warning appears below 3 GB free).
- At the end, the recording is **converted to MP4** with no quality loss (playable in QuickTime, on iPhone and iPad). The .ts file appears first, then is replaced by the .mp4 when conversion is done (a few minutes for 2 hours; shown in the Recordings section). The picture is copied with no loss; **audio is converted to AAC** (some channels broadcast MP2 or AC-3 audio that QuickTime plays silently). DVB subtitles and teletext, which MP4 cannot hold, are dropped; if conversion fails, a second attempt keeps only the picture and main audio, and as a last resort the .ts is kept. This can be turned off in settings.

### Scheduling a recording

- In the TV guide under the video, **double-click** an upcoming program, or right-click > **Schedule Recording**. A red dot marks scheduled programs.
- Right-click a channel > **Schedule a Recording…** (or the calendar icon under the video): choose a program from the guide or custom times.
- **Margins** before and after (2 and 5 minutes by default, adjustable) avoid missing the beginning or the end.
- At the scheduled time, recording starts in the background. If you are watching another channel, Kastideo asks whether to stop playback; without a reply, recording starts after 60 seconds.

### Downloading a movie or episodes without watching

- Right-click a movie or an episode > **Download** or **Download Tonight**, or the **Download** button under the video.
- For a series: the **Download** button on its page > the displayed season or the whole series.
- Downloads run **one after the other** (queue). “Tonight” starts at 2 a.m. by default (adjustable).
- You can pause, resume or cancel each download in the Recordings section.
- **Permanent indicator**: as long as a download is active, a progress ring stays visible in the toolbar. A click opens the details: progress of the current movie or episode, “episode X of N”, progress of the series or batch, speed and **estimated time remaining** (refined as the download goes on).

### Single connection: who has priority?

Your subscription allows only one connection. Kastideo therefore does only one thing at a time and **always asks you** before interrupting something:

- You change channel during a recording: Kastideo asks whether to **stop the recording**.
- You start playback during a download: the download is **paused** and resumes by itself when playback stops.
- Files that are already recorded can be watched at any time, even during a background recording.

### Good to know

- Kastideo must **stay open** and the Mac **on** for scheduled recordings and overnight downloads. Kastideo prevents automatic sleep during activity and in the hour before, but not manual shutdown or sleep.
- A **macOS notification** signals the start and end of recordings and downloads (can be turned off).
- **Automatic cleanup** (optional): recordings older than the chosen number of days are moved to the Trash.
- An alert warns you when disk space gets low.
- Copying rights depend on your provider's conditions: Kastideo records for your private use what your subscription already gives you.

## Fixing a channel

Some channels are badly referenced by the provider (wrong name, wrong programs, missing logo). Right-click the channel > **Edit Channel…**:

- **Name** and **number** (used for number zapping in the TV interface);
- **Logo**: an image address, or **Choose a File…** (the image is copied into Kastideo);
- **TV guide programs**: if the programs shown are wrong or missing, search the right channel in the list (provider guide and backup guide); the program on now helps recognize it.

The fix only applies to **this version** of the channel (FHD, HD, SD… are fixed separately) and survives source refreshes. **Restore Original** undoes it.

## Organizing categories

You don't have to put up with your provider's category list and order. Open **View > Manage Categories…** (**⌥⌘C**), the button next to the “Categories” title in the sidebar, or right-click a category. Choose the section (**Live**, **Movies** or **Series**), then:

- **Reorder**: drag categories in the list, or use the **…** menu > **Move to Top / Bottom**. **Sort A → Z** sorts everything alphabetically.
- **Select / deselect all**: the box above the list ticks or unticks all listed categories at once. With a search (for example “PT”), it only affects the categories found: handy to hide a whole country in one go, then show only the ones you want.
- **Hide**: uncheck a category (or right-click > **Hide This Category** in the sidebar). A hidden category disappears **everywhere**: sidebar, Live / Movies / Series lists, search, TV Guide, Cinema and TV interfaces, featured banner. Your favorites and recents stay available.
- **Hide by keyword**: type for example “PAKISTAN” or “ARABIC”: every category whose name contains it is hidden, including ones the provider adds later. Click a keyword's cross to undo it.
- **Rename**: the pencil gives a more readable name (“FRANCE FHD | OTT” → “France HD”); **Original Name** undoes it.
- **Show All** shows hidden categories again; **Reset…** goes back entirely to the provider's layout.

New categories added by the provider appear next to their original neighbor.

## Favorites and recents

- Add a favorite with the star in the information panel, right-click or **⌘D**.
- The **Recents** section keeps the last 60 items you watched.
- **Removing from recents**: right-click an item > **Remove from Recents** (or the **⌫** key on the selected item in the Classic interface). For several items, click **Edit**, tick the items, then **Delete**; **Select All** ticks the whole list and **Clear All** empties the history.
- After a deletion, an **Undo** banner stays visible for a few seconds to restore everything.
- Recents can also be cleared in settings, **General** tab.

## Keyboard shortcuts

- **⌘0**: Home
- **⌘1 to ⌘7**: Live, Movies, Series, Favorites, Recents, Recordings, TV Guide
- **⌥⌘1 / ⌥⌘2 / ⌥⌘3**: Classic / Cinema / TV interface (for the type of content displayed)
- TV interface: **↑ ↓** zapping, **←** channel panel, digits = channel number, **I** banner, **B** previous channel, **G** TV guide, **H** home, **F** favorite, **M** mute
- **⌘↑ / ⌘↓**: previous / next item (zapping)
- **⌘K**: play / pause
- **⌘[ / ⌘]**: back 10 s / forward 30 s (movies and episodes)
- **⌘↩** or double-click the video: theater mode (Esc to leave)
- **⌘.**: stop playback
- **⇧⌘R**: record the channel being watched / stop recording
- **⌥⌘L**: log
- **⌘D**: add or remove from favorites
- **⌘R**: refresh all sources
- **⌘,**: settings and sources
- **⌘?**: this help

## Updates

Kastideo updates itself thanks to **Sparkle**, the reference tool for Mac apps distributed outside the App Store.

- **At launch** (a few seconds after starting), then once a day if Kastideo stays open, Kastideo discreetly checks whether a new version is available on GitHub.
- If so, a **banner** at the top of the window announces it — **never while watching or recording** (it waits for playback to end). The update is **optional**: **Update…** opens the release notes window then **Install Update** (Kastideo quits, installs and relaunches); **Later** hides the banner until the next launch; **Skip This Version** stops offering it (the next one will be offered).
- You can check at any time with **Kastideo > Check for Updates…**.
- Every update is signed: Kastideo refuses to install a file that does not come from its publisher.

In **Settings > Updates**:

- **Check for updates at launch**: turns the launch and daily check on or off.
- **Receive test versions (beta)**: also offers beta versions, which bring new features earlier but may be less stable. Turn the option off to return to stable versions at the next update.

> Versions 0.1.0 and earlier cannot update themselves: install 0.2.0 by hand once, and the following ones will arrive on their own.

## What's New

After each update, the **What's New** window summarizes the changes in the installed version. You can reopen it with **Help > What's New in This Version** and browse previous versions there. Release notes are written in French.

## General settings

- **Language** (**General** tab): Kastideo is available in **French** and **English**. The language is chosen at first launch, then can be changed in **Settings > General > Language** (or “System” to follow the Mac's language). The change applies after the app restarts, which Kastideo offers to do for you. Help and menus follow the chosen language; release notes remain in French.
- **Appearance** (**Appearance** tab): dark theme (default), light or same as system; **accent color** (System, blue, purple, pink, red, orange, green, teal); **interface** Classic or Cinema for each type of content; **list density** (compact, standard, spacious) for the Classic interface; **thumbnail size** (small, medium, large) for the Cinema interface.
- **Movie and Series Details** (**General** tab): optional **TMDB** API key (free at themoviedb.org > Settings > API; v3 key or v4 read token), stored in the keychain. **Save and Verify** checks it. Without a key, details come from your IPTV provider.
- **Refresh at launch**: reloads sources whose last refresh is more than 6 hours old.
- **Cache**: Kastideo keeps a local copy of lists and the TV guide to start instantly. **Clear and Reload** erases this copy and restarts loading.

### Getting a TMDB key (free)

TMDB (The Movie Database) is a community movie and TV database. Its key is **free** for personal use; it lets Kastideo show cast photos, HD posters and backdrops, the trailer and a translated synopsis.

1. Create an account on **themoviedb.org** (“Join TMDB”), then confirm it with the link sent by e-mail.
2. Signed in, open **themoviedb.org/settings/api** (avatar > Settings > API), or click **Get a Free Key** in Kastideo's settings.
3. Click **Create**, choose **Developer** and accept the terms of use.
4. Fill in the form: usage type **Personal**, application name **Kastideo**, URL **https://github.com/jihemezes/kastideo**, a short summary (“Personal IPTV player, shows movie details”), then your contact details.
5. Submit: the page shows an **API Key** (32 characters) and an **API Read Access Token** (long, starts with “eyJ”). Kastideo accepts either; the API key is easier to copy.
6. In Kastideo: **Settings (⌘,) > General > Movie and Series Details**, paste the key and click **Save and Verify**. “Valid key ✓” confirms it.
7. Reopen a details page (or click **Refresh** at its bottom): it is now completed by TMDB.

The key is stored in the Mac keychain. **Remove Key** goes back to IPTV provider information only.

## Backup and transfer

Settings > General > **Backup and transfer**:

- **Export configuration…** saves a `Kastideo-configuration.json` file: sources (Xtream and M3U playlists by address), favorites, recents, custom categories (order, hidden, names, keywords), chosen interfaces and TMDB key. Tick **Include passwords** so nothing has to be typed again; keep the file somewhere safe.
- **Import configuration…** adds the content of a file: on a new Mac, or from Kastideo for Windows and Linux (same format). Sources already present are recognised and nothing is deleted.

Jellyfin, Emby and Plex servers are exported (with their password or token if you tick **Include passwords**). M3U playlists added as local files and folders are not imported on another Mac (the files do not exist there or must be chosen again).

## Troubleshooting

- **A channel has no sound**: Kastideo detects it within a few seconds and repairs it on its own: if the stream clock is shifted (sound is dropped, “buffer too late” in the log), the channel is reopened synced on sound and picture, and Kastideo remembers it; otherwise it restarts the audio track or tries the next one. If an orange 🔇 icon stays next to the health pill, the provider is sending a stream without sound or an unreadable track: try another version of the channel (HD, SD…) or pick another audio track in the information panel (⌘I). The playback log (“Son :” lines) shows the format received.

- **“The provider refuses this channel (HTTP 403)”**: the provider itself blocks this channel (out of service or not in your subscription). Kastideo does not insist; try another version (HD, SD…) or later.
- **Frozen picture, “Faulty stream at the provider”**: the stream clock is inconsistent. Kastideo reopens the channel once, synced on sound and picture; if that is not enough, it switches to **picture only** (no sound) so the picture no longer freezes, and remembers it. Right-click the channel > **Image seule (sans le son)** / picture only to turn it on or off manually. Settings > General > Playback > **Reset** cancels these remembered repairs.
- **Stream relay** (Settings > General > Playback, on by default): Kastideo opens the connection to the provider itself and passes it to the VLC engine, like Piboard, so there are never two at once. The playback log then shows “Relais :” lines with the provider's exact answer (e.g. “HTTP 200 en 0,35 s”).
- **Slow or refused channel switch (“HTTP 404”, “403”, “401” or “520” in the playback log)**: with a one-connection subscription, the provider takes a moment to release the previous channel. Kastideo waits 1.5 s before opening the new channel and retries once if it is refused (“Attente…” and “nouvel essai” in the log). If refusals persist, wait a minute and try again.

Kastideo identifies itself to servers as the **VLC** player: many IPTV providers only answer players they recognize.

- **“The server did not respond in time”**: the server is overloaded or unavailable. Try again later; if your address looks like `get.php?username=…`, check that it was converted to Xtream Codes (type shown in the sources settings).

- **“Username or password refused”**: check your credentials with **Test Connection**.
- **“Account not active”**: the subscription has expired or is suspended at your provider.
- **No program in the guide**: the channel has no TV guide identifier, or your source's guide does not contain any for it.
- **“App Transport Security”**: this message appeared in versions 0.1.0 and 0.2.0 with http:// sources. It has been fixed since version 0.2.1.
- **Cannot play**: the server did not provide the stream. Check that no other device is using your subscription (only one connection allowed), then click **Try Again**. Also try the **Stable** buffer.

## Privacy

Kastideo runs in the macOS sandbox. It only accesses the network and the files that you choose. Your passwords stay in the keychain. No data is sent anywhere other than to your own sources.

## Licenses

Kastideo uses **VLCKit** (VLC's engine, © VideoLAN, LGPL 2.1 or later license, https://www.videolan.org/vlc/libvlc.html) and **Sparkle** (MIT license, https://sparkle-project.org). VLCKit is embedded as an unmodified dynamic library.
