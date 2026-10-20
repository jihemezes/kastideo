# Kastideo Help

Kastideo is a media player that brings your live channels, movies and series from IPTV together in a simple, fast interface. Kastideo provides no content: you add your own sources (an Xtream Codes subscription or an M3U playlist).

> Version 0.8.2 — Full screen fixed, live recording made more reliable; Home screen, removing items from Recents, app available in French and English; TV Guide grid, resume playback, download indicator; new icon; TV interface for live (channel panel, information banner, zapping by number), alongside the Classic and Cinema interfaces.

## Getting started

1. On first launch, click **Add a Source**.
2. Choose the source type: **Xtream Codes**, **Playlist (URL)** or **Playlist (file)**.
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

### TV guide (XMLTV)

Each source can have a TV guide address in XMLTV format (`.xml` or `.xml.gz`). If you leave it empty, Kastideo uses the one from the Xtream server or the one announced in the playlist (`url-tvg`). The guide is kept from 6 hours back to 48 hours ahead.

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
- **Cinema**: a large “featured” banner (what you watched last, otherwise your favorites), then **horizontal rows**: continue watching, favorites and one row per category. Movies and series appear as posters, channels as thumbnails with the current program. A click opens the player full frame; **Back** (or Esc) returns to the catalog. At the top of the window, the **Live / Movies / Series / Guide / Favorites / Recents / Recordings** tabs replace the sidebar; search works as in Classic. “See All” opens a complete category as a grid.

To change the interface:

- the **Interface** button in the toolbar (it applies to the type of content displayed),
- the **View** menu: **⌥⌘1** Classic, **⌥⌘2** Cinema, **⌥⌘3** TV (live),
- or **Settings > Appearance**.

For example: TV for live and Cinema for movies and series. The **Recordings** section is always shown in the Classic interface. The default is Classic everywhere.

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
- Click a channel name to watch it. Only channels that have programs are listed: if the grid is empty, check the guide address in the source settings.

## Playback

Kastideo plays all content with the **VLC** engine: live MPEG-TS (.ts), HLS (.m3u8), MP4, MKV, AVI…

- Playback starts as soon as you select a channel, a movie or an episode.
- While opening, the channel logo and name are shown. The **“Ready in x s”** badge then shows the start-up time (can be turned off in settings).
- Controls appear when you hover over the video: play / pause, back 10 s and forward 30 s for movies and episodes, progress bar, volume (up to 200%) and theater mode.
- A click on the video pauses it; a **double-click** turns on **theater mode**: the window goes full screen and only the **video** remains visible (no columns or toolbar; the green window button and **⌃⌘F** do the same during playback). **Esc** or **⌘↩** to leave it.
- **Resume playback**: for movies and episodes, Kastideo remembers your position. When you reopen one, playback resumes where you stopped, with a message offering to **start over**. Progress bars appear in lists, posters and episodes. This can be turned off, and positions can be erased, in settings.
- For Xtream sources, live is played in MPEG-TS (.ts) format, like the Xtream reference player; if the stream fails, Kastideo automatically tries the .m3u8 variant (and vice versa).

### If a channel does not start

If no picture arrives after **20 seconds**, Kastideo automatically tries the other stream format (.ts or .m3u8), then shows an error message with the details returned by the VLC engine.

The **Playback Log** (menu **Playback > Playback Log…**, **⌥⌘L**, or the button in the error message) shows the VLC engine's messages: stream opening, server responses, errors. User names and passwords are **hidden** there: you can copy it with **Copy Log** to share it if you have a problem.

### Live timeshift

**Pause** a live channel: the VLC engine keeps receiving the stream and stores it. When you resume, you are watching in **timeshift** (yellow “TIMESHIFT −2:34” indicator in the controls). The **Live** button returns to live. If a stream cannot be paused, the button is greyed out.

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
- At the end, the recording is **converted to MP4** with no quality loss (playable in QuickTime, on iPhone and iPad). This can be turned off in settings.

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
- **⌥⌘L**: playback log
- **⌘D**: add or remove from favorites
- **⌘R**: refresh all sources
- **⌘,**: settings and sources
- **⌘?**: this help

## Updates

Kastideo updates itself thanks to **Sparkle**, the reference tool for Mac apps distributed outside the App Store.

- Kastideo checks once a day whether a new version is available on GitHub.
- A window presents what's new, then offers **Install Update**. Kastideo quits, installs and relaunches.
- You can check at any time with **Kastideo > Check for Updates…**.
- Every update is signed: Kastideo refuses to install a file that does not come from its publisher.

In **Settings > Updates**:

- **Check automatically**: turns the daily check on or off.
- **Download and install automatically**: updates are installed without asking, when the app is closed.
- **Receive test versions (beta)**: also offers beta versions, which bring new features earlier but may be less stable. Turn the option off to return to stable versions at the next update.

> Versions 0.1.0 and earlier cannot update themselves: install 0.2.0 by hand once, and the following ones will arrive on their own.

## What's New

After each update, the **What's New** window summarizes the changes in the installed version. You can reopen it with **Help > What's New in This Version** and browse previous versions there. Release notes are written in French.

## General settings

- **Language** (**General** tab): Kastideo is available in **French** and **English**. The language is chosen at first launch, then can be changed in **Settings > General > Language** (or “System” to follow the Mac's language). The change applies after the app restarts, which Kastideo offers to do for you. Help and menus follow the chosen language; release notes remain in French.
- **Appearance** (**Appearance** tab): dark theme (default), light or same as system; **accent color** (System, blue, purple, pink, red, orange, green, teal); **interface** Classic or Cinema for each type of content; **list density** (compact, standard, spacious) for the Classic interface; **thumbnail size** (small, medium, large) for the Cinema interface.
- **Refresh at launch**: reloads sources whose last refresh is more than 6 hours old.
- **Cache**: Kastideo keeps a local copy of lists and the TV guide to start instantly. **Clear and Reload** erases this copy and restarts loading.

## Troubleshooting

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
