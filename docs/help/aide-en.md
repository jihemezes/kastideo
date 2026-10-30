# Getting started

## Welcome {#bienvenue}

Kastideo brings together your **live channels, IPTV movies and series**, your **personal videos** (disk, USB drive, NAS, Jellyfin, Emby, Plex) and **YouTube** in a single interface. Kastideo provides **no content** of its own: you add your own sources.

![The Home screen](img:home)

1. Back to Home, from anywhere.
2. One search for channels, movies and series.
3. The **?** button: help, opened on the page that matches the screen you are on.

### Quick start

<!--mac-->
1. On first launch, click **Add a source** (or **Settings ⌘,** > **Sources** > **Add**).
<!--/mac-->
<!--pc-->
1. Open **Settings** (the gear on Home, or **Ctrl+,**) > **Sources** > **Add a source**.
<!--/pc-->
2. Choose the source type: [Xtream Codes](help:xtream), [M3U playlist](help:m3u), [Folders](help:dossiers), or a [Jellyfin, Emby or Plex](help:serveurs) server.
3. Fill in the requested details and click **Add**: Kastideo loads the channels, movies, series and the [TV guide](help:guide).
4. Go back to **Home** and open **Live**, **Movies** or **Series**.

### Getting help

<!--mac-->
- The **?** button in the toolbar opens help on the page that matches the current screen.
- **Help > Kastideo Help** menu or **⌘?**.
<!--/mac-->
<!--pc-->
- The **?** button on Home and on the main screens opens help.
<!--/pc-->
- The **Search** field at the top of help searches every page.
- Something wrong? See the [FAQ](help:faq) and then [Troubleshooting](help:depannage).

> Want to watch YouTube? See [YouTube](help:youtube). Importing your subscriptions: [step by step](help:youtube-import).

## FAQ {#faq}

### Where do I find channels to add?
Kastideo provides neither channels nor a subscription. Your IPTV provider gives you either a server, a username and a password ([Xtream Codes](help:xtream)), or a playlist address ([M3U](help:m3u)). You can also play your own files ([Folders](help:dossiers)).

### A channel does not start or stutters
<!--mac-->See [If a channel does not start](help:chaine-ne-demarre-pas) and [Troubleshooting](help:depannage).<!--/mac--><!--pc-->See [Troubleshooting](help:depannage).<!--/pc--> Very often the cause is a **second simultaneous connection** on the same subscription: see [One connection at a time](help:connexion-unique).

### The TV guide is empty or incomplete
Settings > Sources > **Reload TV guide**, then read [TV guide](help:guide) and the [backup guide](help:guide-secours).

### How can I watch YouTube without ads?
Kastideo plays videos with the official player in **privacy-enhanced mode**: no tracking cookie, so usually no personalised ads. It is **not** an ad blocker: see [Ads, account and privacy](help:youtube-confidentialite).

### How do I import my YouTube subscriptions?
YouTube does not let you connect an account to a third-party app: you use a file that Google generates for you. Follow the [step-by-step guide](help:youtube-import).

### YouTube search asks for a key
Search uses **your own** free Google API key. The [step-by-step guide](help:youtube-cle) explains it in a few minutes. Without a key you can still follow channels and play pasted links.

### How do I record a programme?
See [Recording live TV](help:enregistrer) and [Scheduling a recording](help:programmer).

### How do I watch a programme that already aired?
If your provider offers an archive: see [Replay](help:replay).

### How do I get my settings on another computer?
See [Backup and transfer](help:sauvegarde).

# Sources

## Xtream Codes {#xtream}

<!--mac-->
This is the most common format among IPTV providers. You need three pieces of information: the **server** address (for example `http://example.com:8080`), your **username** and your **password**.

- The **Test Connection** button checks your credentials and shows the account status, its expiration date and the number of simultaneous connections allowed.
- The password is stored in the **macOS keychain**, never in clear text on disk.
- The server's TV guide is used automatically.
- Series open on a page with their seasons and episodes.
<!--/mac-->

<!--pc-->
Server address (e.g. http://example.com:8080), username and password. The password is stored in the system vault: Credential Manager on Windows, GNOME Keyring or KWallet on Linux.
<!--/pc-->

## M3U / M3U8 playlist {#m3u}

<!--mac-->
- **By URL**: paste the playlist address supplied by your provider.
- If the address looks like `get.php?username=…&password=…` (the most common case with subscription providers), Kastideo recognizes it and saves it as **Xtream Codes**: loading is much faster, the TV guide is included and the password is kept in the keychain. Sources of this kind that were already saved are converted automatically.
- **By file**: choose an `.m3u` or `.m3u8` file on your Mac. Kastideo keeps the permission to access it so that it can refresh it.
- Categories come from the `group-title` attribute, logos from `tvg-logo` and the link to the TV guide from `tvg-id`.
- Kastideo automatically sorts entries into Live, Movies or Series based on their address.
<!--/mac-->

<!--pc-->
Playlist address or file on disk (**Choose a file…**). A "get.php?username=…&password=…" address is recognized and turned into an Xtream source, much faster and more complete (details, episodes, latest additions).
<!--/pc-->

## Folders (disk, USB drive, NAS) {#dossiers}

<!--mac-->
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
<!--/mac-->

<!--pc-->
Settings > Sources > **Add a source** > **Folders**, then **Add a folder…** (internal disk, USB disk or stick) or type a **network path** and click **+**: `\\NAS\Videos` or a network drive (`Z:\`) on Windows, a mounted share (`/mnt/nas/videos`, `/media/…`) on Linux. Several folders can make up one source.

- **Movies** recognized from their names: “Inception (2010).mkv”, “The.Matrix.1999.1080p.BluRay.mkv”, folder “Amélie (2001)”. Category “Movies · folder name”.
- **Series**: “Breaking.Bad.S01E02.mkv”, “Friends 1x05.mp4”, folders “Show/Season 1/…”. Episodes are grouped by series and season in **Series**.
- **Other videos**: category **Videos · folder name** in Movies.
- Scanned at each launch and then every 20 minutes. Disk unplugged: a message says so and the previous list is kept. Unreadable subfolders (“System Volume Information”…) are skipped.
- **Subtitles** placed next to a video (“Movie.srt”, “Movie.en.srt”) are loaded on playback.
- With a **TMDB key**, **posters and summaries** are added automatically; right-click > **Fix details…** to pick the right title when the file name misleads the search.
<!--/pc-->

## Jellyfin, Emby and Plex {#serveurs}

<!--mac-->
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
<!--/mac-->

<!--pc-->
Settings > Sources > **Add a source** > **Jellyfin**, **Emby** or **Plex**. **Search the network** finds the servers at home: click yours to fill in the form (otherwise type the address; without a port, 8096 or 32400 is added).

- **Jellyfin / Emby**: username and password — **optional** if the account has none (or an **API key** from the dashboard). **Test** checks the address; on failure, the exact server response is shown.
- **Plex**: **Sign in with Plex** opens plex.tv in the browser; authorize Kastideo, then choose the server from your account. Or type the address and the **token** (X-Plex-Token), optional if the server allows the local network without authentication.
- Libraries appear in **Movies** and **Series** (“library name · server name”), with the server's posters, details, seasons and episodes. Direct playback, no transcoding.
- **Resume and “watched” shared both ways**: the position is sent to the server while you watch, and the one from your other devices is picked up. Right-click > **Mark as watched / unwatched**; **Watched** badge on posters.

> Windows firewall: on the first search, allow Kastideo on private networks so that servers can answer.
<!--/pc-->

## Resume and “watched” shared with servers {#reprise-serveurs}

<!--mac-->
With Jellyfin, Emby and Plex, the playback position is sent to the server while you watch: a movie started in Kastideo can be resumed on the TV, and the other way round. A movie watched to the end is marked **watched** on the server. Right-click a movie or an episode > **Mark as watched / unwatched** (also for files from folders). A **Watched** badge appears on posters, and a check mark in the episode list.

> Network search: the first time, macOS asks for permission to access the **local network**; accept it (otherwise System Settings > Privacy & Security > Local Network).
<!--/mac-->

## TV guide (XMLTV) {#guide}

<!--mac-->
Each source can have a TV guide address in XMLTV format (`.xml` or `.xml.gz`). If you leave it empty, Kastideo uses the one from the Xtream server or the one announced in the playlist (`url-tvg`). The guide is kept from 6 hours back to 48 hours ahead.
<!--/mac-->

<!--pc-->
The guide provided by your provider loads in the background and is kept on disk. The optional **TV guide (XMLTV)** field of a source lets you use another guide (.xml or .xml.gz).
<!--/pc-->

## Backup TV guide (xmltvfr.fr) {#guide-secours}

<!--mac-->
Your provider's guide can be incomplete or temporarily empty. Kastideo completes it with a free **backup guide** from **xmltvfr.fr** (“Complete” guide by default: about 785 French and foreign channels, 5 days, updated daily):

- only channels **without programs** from your provider are completed; the provider's guide keeps priority;
- channels are matched **by name**: “|FR| TF1 FHD” → TF1, “|FR| FRANCE 2 UHD” → France 2, “|FR| TF1 4K” → TF1 4K;
- the backup guide is reloaded every 12 hours. If the provider sends an empty or unreadable guide, programs already known are kept and a message appears under the source.

**Finding out where the guide comes from.** Under each source, Settings > Sources shows how many programs the provider sent. The **Reload the TV guide** button (calendar icon) restarts the download of the provider's guide and the backup guide. Provider lines that are only **category separators** (“♣♦♣---|FR| FRANCE FHD |FR|---♣♦♣”) are ignored; a 4K or FHD version without its own programme reuses the HD version's; channels without a programme show “Program not available”. The **Log**, topic **TV Guide**, details every attempt: address requested, server response (code, size, time), number of channels and programs received, period covered, how many of your channels are linked to the provider's guide, the backup guide or neither, and — if the guide holds nothing usable — the beginning of the server's answer.

Settings > General > **Backup TV Guide**: turn it on or off, pick another xmltvfr.fr guide (France ~400 channels, DTT) or enter any XMLTV address, **Refresh Now**, and see how many channels were linked to yours.
<!--/mac-->

<!--pc-->
Settings > General > **TV guide**: a fallback guide fills in channels without programmes in your provider's guide, matching them by name. Pick an xmltvfr.fr guide or type an address; **Reload the guide** downloads everything again. The **TV guide log** button opens the Log on the *TV Guide* topic: address requested, provider response (code, size, time), channels and programmes received, period covered, how many of your channels are linked to the provider, the backup or no guide, and — if the guide is unusable — the beginning of the server's answer. The provider's programmes are filtered on your channels' identifiers: if the guide holds programmes but none for your channels, the log shows the identifiers on both sides.
<!--/pc-->

## Managing sources {#gerer-sources}

<!--mac-->
Open **Kastideo > Settings… (⌘,)**, **Sources** tab, or click the **Sources** button in the toolbar.

- The switch enables or disables a source without deleting it.
- The buttons let you refresh, edit or delete a source.
- If there is an error, the message appears in red under the source and an orange triangle appears in the sidebar.
<!--/mac-->

<!--pc-->
Settings > **Sources**: **edit** a source (pencil button: name, server, username, password, playlist address, TV guide — favorites, recents and channel fixes are kept), refresh it, delete it, see the state of its TV guide. The **eye** button shows the password (or the TMDB key) so you can check it. Sources refresh at startup when their last update is more than 6 hours old (adjustable). If a refresh returns an empty section, the previous one is kept.
<!--/pc-->

# Navigating

## The Home screen {#accueil}

![The Home screen](img:home)

<!--mac-->
Kastideo opens on the **Home** screen: three large tiles, **Live**, **Movies** and **Series**, then smaller buttons for **Favorites**, **Recents**, the **TV Guide** and **Recordings**.

- The **search** field at the top searches channels, movies and series at once; click a result to open it.
- The **Continue Watching** row lists the movies and episodes you have started; click one to resume where you left off.
- If something is playing, a banner lets you **go back to it** or **stop** it.
- To return to Home at any time: the **Home** button (house) at the top left of the toolbar, **⌘0**, the **Home** row in the sidebar, or the **H** key in the TV interface.

Kastideo's **version number** is shown discreetly at the bottom right of the Home screen; clicking it opens the release notes.
<!--/mac-->

<!--pc-->
Global search (channels, movies, series), **Live**, **Movies** and **Series** tiles, quick access to **Favorites**, **Recents**, **TV Guide**, **MultiView** and **Recordings**, and the **Continue watching** row.
<!--/pc-->

## My videos {#mes-videos}

<!--mac-->
As soon as a **Folders**, **Jellyfin**, **Emby** or **Plex** source exists, a **My videos** tile appears on the home screen (and a row in the sidebar, **⌘8**). It gathers your videos, apart from IPTV:

- **Featured**: **Resume playback** (started movies and episodes), **Recently added**, **Movies to watch**, then a Movies, Series and Videos row;
- **Movies**, **Series**, **Videos**: grids with search, filters (**genre**, **year**, **unwatched**) and sorting (title, recently added, year);
- **Folders**: browse your folders and subfolders as in the Finder (breadcrumb to go back up), and the servers' libraries;
- **Sources**: all, or just one (NAS, Emby, Plex…). An orange triangle flags an error: right-click > **Error details…** shows the request and the **exact server response** (**Copy** button), then **Retry**.

In **Movies** and **Series**, the **All / IPTV / My videos** selector (sidebar, above the categories) chooses what is shown: IPTV only (default), your videos only, or both mixed. The categories of your videos are never hidden by the countries setting.
<!--/mac-->

<!--pc-->
As soon as a **Folders**, **Jellyfin**, **Emby** or **Plex** source exists, a **My videos** tile appears on the home screen (shortcut **Ctrl+8**). It gathers your videos, apart from IPTV:

- **Featured**: **Resume playback** (started movies and episodes), **Recently added**, **Movies to watch**, then a Movies, Series and Videos row;
- **Movies**, **Series**, **Videos**: grids with search, filters (**genre**, **year**, **unwatched**) and sorting (title, recently added, year);
- **Folders**: browse your folders and subfolders as in the file explorer (breadcrumb to go back up), and the servers' libraries;
- **Sources**: all, or just one (NAS, Emby, Plex…). An orange triangle flags an error: right-click > **Error details…** shows the request and the **exact server response**, then **Retry**.

In **Movies** and **Series**, the **All / IPTV / My videos** selector (sidebar, above the categories) chooses what is shown: IPTV only (default), your videos only, or both mixed. The categories of your videos are never hidden by the countries setting.
<!--/pc-->

## Window layout and sidebar {#colonnes}

![Window layout and sidebar](img:layout)

<!--mac-->
In the Classic interface, the window has three columns:

- **Sidebar**: Home, Live, Movies, Series, Favorites, Recents, TV Guide, then the categories of the chosen section and the status of your sources.
- **List**: the items of the section or category, with the current program for channels. The **Search** field filters the list regardless of case and accents.
- **Player**: the video, with the current program, its progress and the upcoming programs below it.

Right-clicking an item lets you add it to favorites or copy the stream address.
<!--/mac-->

<!--pc-->
Live / Movies / Series picker, then: all channels or movies, **Favorites**, **Recents**, and for live TV **Themes**, **TV Guide** and **MultiView**; **Recordings**; the **categories**. At the bottom: the current recording and download (progress, time left) and **Settings**.
<!--/pc-->

## Three interfaces to choose from {#interfaces}

<!--mac-->
Kastideo offers three presentations, which you choose **separately for live, movies, series, and favorites / recents**:

- **Classic**: the three columns described in [Window layout and sidebar](help:colonnes).
- **TV** (live only): see [The TV interface](help:interface-tv).
- **Cinema**: a large scrolling **“featured” banner** (see [The “featured” banner](help:bandeau)), then **horizontal rows**: continue watching, favorites and one row per category. Movies and series appear as posters, channels as thumbnails with the current program. A click on a channel opens the player full frame. A click on a **movie** or **series** poster first opens its **details page**: backdrop, poster, year, runtime, genres, rating, synopsis, director, cast (with photos), a **Back to Movies** (or Series) button at the top left, **Play** / **Resume**, **View Episodes**, **Trailer**, **Download** and favorite buttons. Information comes from your IPTV provider; add a free **TMDB** key (Settings > General > Movie and Series Details) for richer pages. **Back** (or Esc) returns to the catalog. At the top of the window, the **Live / Movies / Series / Guide / Favorites / Recents / Recordings** tabs replace the sidebar; search works as in Classic. “See All” opens a complete category as a grid.

To change the interface:

- the **Interface** button in the toolbar (it applies to the type of content displayed),
- the **View** menu: **⌥⌘1** Classic, **⌥⌘2** Cinema, **⌥⌘3** TV (live),
- or **Settings > Appearance**.

For example: TV for live and Cinema for movies and series. The **Recordings** section is always shown in the Classic interface. The default is Classic everywhere.
<!--/mac-->

<!--pc-->
Settings > Appearance > **Interface per content type**:

- **Classic**: three columns (sidebar, list with the current programme, player or details on the right).
- **Cinema**: featured banner, posters or thumbnails in horizontal rows, full-page details. For live TV: "Sport right now", "Live news", "Tonight" rows per theme, favorites, recents, categories; a click opens the channel full frame, **Back** (or Esc) stops it.
- **TV** (live only): the channel full frame, like a television (see [The TV interface](help:interface-tv)).
<!--/pc-->

## The “featured” banner (Cinema) {#bandeau}

<!--mac-->
At the top of Movies and Series, a **full-width carousel** scrolls through a selection: backdrop, poster, title, year, runtime, genres, rating, synopsis and **Play** (or **Resume** / **View Episodes**), **More Info** (the details page) and **Trailer** buttons. It mixes:

- this week's **TMDB trends** found in your catalog (TMDB key required);
- your provider's **latest additions**;
- a **selection from a category** of your choice (for example “New releases” or “Netflix”), or from the whole catalog at random.

Scrolling pauses while the mouse is over the banner; arrows and dots let you navigate. In **Live**, the banner shows **what's on now** on your favorite and recent channels, with progress, the next program and **Watch**.

Settings > Appearance > **“Featured” Banner**: show or hide, height (compact, normal, large), scrolling speed, carousel sources and movie and series categories.
<!--/mac-->

<!--pc-->
It cycles through movies or series (this week's TMDB trends available to you, latest additions, a category selection) or, for live TV, the current programme of your channels. Arrows on hover, pauses while the mouse is over it. Settings > Appearance > **Featured banner**: show or hide, height, speed, sources.
<!--/pc-->

## Countries and languages (Cinema) {#pays}

<!--mac-->
Providers often mix several countries (categories “FR| …”, “|PT| …”, “ITALIA”…). Settings > Appearance > **Countries and languages (Cinema interface)** lists the countries found in your category names, with the number of items: tick the ones you want to see. **Latest additions**, **trends**, the **featured banner** and **category rows** of the Cinema interface then only show those countries. **Keep categories without a country** keeps categories such as “Action” or “New”. **All countries** goes back to the full display. Classic lists and search stay complete.
<!--/mac-->

<!--pc-->
Providers often mix several countries (categories “FR| …”, “|PT| …”, “ITALIA”…). Settings > Appearance > **Countries and languages (Cinema interface)** lists the countries found in your category names, with the number of items: choose the ones to show. **Latest additions**, **trends**, the **featured banner** and **category rows** of the Cinema interface then only show those countries. **Keep categories without a country** keeps categories such as “Action” or “New”. **All** goes back to the full display. Lists and search stay complete.
<!--/pc-->

## The TV interface (live) {#interface-tv}

<!--mac-->
The channel fills the whole frame, like on a television. The first time it appears, Kastideo resumes the last channel you watched.

- **Channel panel**: **←** key, **Return**, or move the mouse to the left edge. It lists channels with number, logo, current program and progress. The menu at the top filters by **All / Favorites / Recents / category**, and the **Search** field filters by name. It closes by itself after a few seconds (**→** or **Esc** to close it right away).
- **Zapping**: **↑ / ↓** previous / next channel in the displayed list, **B** back to the previous channel.
- **Channel number**: type the digits (for example **1** then **2**); the channel opens after 1.6 s or with **Return**. If your provider does not number its channels, the number refers to the position in the displayed list.
- **Information banner**: shown for five seconds at each channel change (logo, number, current program, times, next program, time). **I** or **→** shows or hides it.
- Other keys: **F** favorite, **M** mute, **Space** pause (live timeshift).
- Double-click the picture or **⌘↩**: full screen; the toolbar is hidden.
- Keyboard keys do not work while typing in the search field. The tabs at the top of the window let you switch to Movies, Series, etc.
<!--/mac-->

<!--pc-->
- **↑ / ↓**: previous / next channel; **type a number** (up to 4 digits).
- **←** or left edge: **channel panel** (filter, search, current programme).
- **→** or **I**: **info banner** (current and next programme).
- **B**: previous channel — **F**: favorite — **M**: sound — **Space**: pause — **G**: TV guide — **H**: home.
<!--/pc-->

## The TV Guide grid {#guide-grille}

<!--mac-->
The **TV Guide** section (sidebar, **TV Guide** tab of the Cinema and TV interfaces, **⌘7**, or the **G** key in the TV interface). Channels are in rows, hours in columns; the red line marks the current time.

- **‹ ›** shift the grid, **Now** goes back to the current time, the date menu jumps to another day (7 p.m. for the following days).
- Choose the time span shown (**2 h / 3 h / 6 h**), filter by **favorites**, **recents** or **category**, or search for a channel.
- Click a program: description, **Watch** button, **Record** (current program) or **Schedule Recording** (upcoming program). A red dot marks a scheduled recording.
- Past days (date menu, **Watch again** section) and programmes marked ↺ allow **replay** (see [Replay](help:replay)).
- Click a channel name to watch it. Only channels that have programs are listed: if the grid is empty, check the guide address in the source settings.
<!--/mac-->

<!--pc-->
Home, live sidebar, **Ctrl+7** or the G key in the TV interface. Channels in rows, hours in columns, a red line at the current time; **‹ Now ›**, day picker, 2 h / 3 h / 6 h span, filter (all, favorites, recents, theme, category) and search. A click on a programme opens its details: **Watch**, **Record**, **Schedule recording** (red dot in the grid) or **Alert me when it starts** (bell). On a past programme of a channel with replay (↺): **Watch again** or **Save this replay**; past days are in the date menu.
<!--/pc-->

## Live TV by theme {#direct-theme}

<!--mac-->
The **Themes** section of the sidebar (under Live) sorts live TV by **theme** — Sports, Auto & Moto (motorsport), Movies, Series, News, Documentaries, Nature / Hunting & Fishing, Kids, Entertainment, Food & Home, Music, General, Regional (France 3 regions, local TV), International (foreign channels), Religion, Radio — without the categories you hid. Three modes:

- **On now**: what is airing now, sorted by the **program's genre** in the TV guide (a movie on a general channel shows up in “Movies”), with progress. Channels **with no guide data** are still listed when their **name is enough to classify them** (beIN Sports → Sport…): they show their name, without progress.
- **Tonight**: programs starting between **8 and 11 pm**. Right-click an upcoming program > **Alert Me When It Starts**.
- **Channels**: channels sorted by specialty. The theme is deduced automatically from the channel name (beIN, Eurosport → Sports; BFM, LCI → News…) then from its usual programs; right-click > **Channel Theme** to correct it.

Each channel appears **only once**, even if your provider offers it in several versions (4K, FHD, HD, SD): Kastideo picks the version suited to **your connection** (**Automatic** setting in Settings > General > Playback > Channel version) — it steps down after unstable playback and back up after three smooth ones. Right-click > **Version** to choose another.

Themes are also offered elsewhere: “Sports On Now”, “Movies On Now”… rows at the top of Live in the **Cinema** interface, a **Themes** filter in the **TV** interface's channel panel and the **TV Guide**, and “On TV Now” (and “Tonight”) chips on the **Home** screen.

In **Sports**, a second row filters by **discipline**: Football, Rugby, Tennis, Basketball, Combat sports, Golf, Cycling, Handball, Motorsport, Winter sports, Horse racing, Athletics & swimming (from program titles, genres and descriptions).

**Adult content**: channels and content whose name contains “|XX|” (or in an adult category) are **hidden everywhere** by default. To show them, and the **Adult** theme: Settings > General > Playback > **Show adult content**.

**Program alerts** (🔔 button of the Themes view): Kastideo alerts you two minutes before a program starts whose title contains a chosen word (“PSG”, “Formula 1”…), of a theme on your favorite channels, or a specific program. A notification and a **Watch** banner appear.
<!--/mac-->

<!--pc-->
Sidebar > **Themes**: **Right now**, **Tonight** (8–11 pm) or **Channels**, filtered by theme (Sport, News, Movies, Kids, Documentaries…) and, for sport, by discipline. One version per channel (FHD, HD or SD depending on your connection). Right-click: channel version, **channel theme** (to fix the classification), favorites, edit the channel.
<!--/pc-->

# Playback

## The essentials {#lecture}

<!--mac-->
Kastideo plays all content with the **VLC** engine: live MPEG-TS (.ts), HLS (.m3u8), MP4, MKV, AVI…

- Playback starts as soon as you select a channel, a movie or an episode.
- While opening, the channel logo and name are shown. The **“Ready in x s”** badge then shows the start-up time (can be turned off in settings).
- Controls appear when you hover over the video: play / pause, back 10 s and forward 30 s for movies and episodes, progress bar, volume (up to 200%) and theater mode.
- A click on the video pauses it; a **double-click** turns on **theater mode**: the window goes full screen and only the **video** remains visible (no columns or toolbar; the green window button and **⌃⌘F** do the same during playback). **Esc** or **⌘↩** to leave it.
- **Resume playback**: for movies and episodes, Kastideo remembers your position. When you reopen one, playback resumes where you stopped, with a message offering to **start over**. Progress bars appear in lists, posters and episodes. This can be turned off, and positions can be erased, in settings.
- For Xtream sources, live is played in MPEG-TS (.ts) format, like the Xtream reference player; if the stream fails, Kastideo automatically tries the .m3u8 variant (and vice versa).
<!--/mac-->

<!--pc-->
The player (mpv engine) has a control bar that hides by itself, a stream health dot, volume, cinema mode (double-click or Ctrl+Enter) and full screen (F11). For movies and episodes: mini timeline, −10 s / +30 s, **resume** where you left off, **Back to details**.
<!--/pc-->

## Control bar, timeline and information panel {#barre-controle}

<!--mac-->
- **Auto-hiding bar**: it appears on the slightest mouse movement and hides, along with the pointer, after 3 seconds of inactivity (it stays while the mouse is over it, while paused or when the panel is open).
- **Mini-timeline** (movies and episodes): a thin line above the buttons that thickens on hover and shows the target time; click or drag to move.
- **Stream health**: a **green** (Excellent), **orange** (Fair) or **red** (Unstable) dot shows reception quality, with the definition (SD, HD, 4K). On hover: exact resolution, bitrate, frames per second, dropped pictures and interruptions in the last minute.
- **Information panel** (ⓘ button or **⌘I**, Esc to close): it slides in from the right over the video and shows the channel with its current and upcoming programs, or a movie's synopsis and cast; the **audio track** (language, audio description…) and **subtitles** choice; detailed reception quality.
<!--/mac-->

## MultiView (several channels at once) {#multivue}

<!--mac-->
**MultiView** shows up to **4 live channels** in one window (1 full frame, 2 side by side, 3 or 4 in a grid). **Sound follows the active tile** (orange border): click a tile or use keys **1 to 4**.

- Open it: **Playback > MultiView…** (**⌥⌘M**), or right-click a channel > **Add to MultiView**.
- In the window: **+** adds a channel (favorites, recents or search); hovering a tile, ⟳ changes the channel and ✕ removes it; **Stop All** stops every stream. Closing the window stops MultiView.
- Each stream uses **one connection** to your provider, so MultiView is **off by default**: enter your subscription's number of simultaneous connections in **Settings > General > Playback** (2 to 4) to enable it. An Xtream source's **Test Connection** button shows this number. When opened, main playback stops to free its connection (unless recording); a recording or download also uses a connection.
<!--/mac-->

<!--pc-->
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
<!--/pc-->

## If a channel does not start {#chaine-ne-demarre-pas}

<!--mac-->
If no picture arrives after **20 seconds**, Kastideo automatically tries the other stream format (.ts or .m3u8), then shows an error message with the details returned by the VLC engine.

The **Log** (menu **Playback > Playback Log…**, **⌥⌘L**, or the button in the error message) is Kastideo's diagnostic tool. User names and passwords are **hidden** in it: you can copy it to share it if you have a problem.

- **Topics**: messages are sorted into *TV Guide*, *Playback and relay*, *Sources and catalogues*, *Recordings*, *TMDB details*, *Updates* and *Display and other*. Click one or more topics to see only those (the number of lines for each topic is shown).
- **Search** a word in the log, or show only **errors and warnings**.
- **Copy what is shown** copies only what is displayed (topics, search), with the filter noted at the top.
- **Level of detail** (per topic): *Normal* (the essentials), *Detailed* (default for the TV Guide) or *Debug* (everything). The setting applies to lines written from then on; errors and warnings are always kept.
- **Current session / Previous session**: the log is kept on disk, so you can read what happened at startup in the previous session. **Show the log folder** reveals the file in the Finder.
<!--/mac-->

## Live timeshift {#differe}

<!--mac-->
**Pause** a live channel: the VLC engine keeps receiving the stream and stores it. When you resume, you are watching in **timeshift** (yellow “TIMESHIFT −2:34” indicator in the controls). If a stream cannot be paused, the button is greyed out.

In timeshift, the controls offer:

- a **timeline**: the pause point on the left, **live** on the right. **Drag the cursor to the right** to move forward: Kastideo speeds up playback until the chosen point (yellow marker), then returns to normal speed;
- **+30 s** (or ⌘]): move forward 30 seconds the same way;
- the **speed** (×1, ×1.25, ×1.5, ×2): speed up to reduce the delay; playback returns to ×1 by itself when it catches up with live;
- **Catch up**: speeds up until live, without skipping anything;
- **Back to live**: returns to live immediately. As the VLC engine usually cannot jump inside the timeshift buffer, the stream is reopened and the buffer cleared. If the stream allows seeking, the buffer is kept and −10 s / +30 s jump directly.

**Where is the timeshift stored?** In Kastideo's temporary folder (`~/Library/Containers/fr.jmezes.kastideo/Data/tmp/`, `vlc-timeshift-…` files), cleared when you change channel; allow 1 to 4 GB per hour depending on quality. Settings > General > Playback: **Maximum timeshift duration** (30 min to 3 h, or unlimited; once reached, playback resumes by itself), **Catch-up speed**, and a **Show** button to open the folder.
<!--/mac-->

<!--pc-->
Pause a channel (or go back with ← or the bar): it keeps being buffered (up to 1 h by default, adjustable). Without any action from you, the channel stays “LIVE”. The timeshift bar shows the delay, a slider to go back or catch up faster, the speed, **Catch up** and **Back to live**. ← / →: −10 s / +30 s.
<!--/pc-->

## Replay: watching a programme that already aired {#replay}

<!--mac-->
Some IPTV subscriptions keep channels for up to **14 days** (depending on the provider and the channel). Kastideo detects this by itself: channels with replay show a **↺** icon in lists and in the TV Guide.

- **In the TV Guide**: click a **past** programme (marked ↺), then **Watch again**. On the **current** programme, **Watch from the start** replays it from the beginning. **Save this replay** downloads the programme from the provider's archive (recordings folder).
- **Previous days**: the date menu of the TV Guide offers **Watch again (replay)** with the past days.
- **From a channel**: right-click the channel > **Watch again (replay)** (recent programmes of that channel). The Cinema interface also has a **To watch again** row (your favourite channels with replay).
- **During a replay**, the player bar lets you pause and move within the programme. At the end, Kastideo **returns to the channel's live stream** (can be turned off).
- **Settings > General > Replay**: turn replay on or off, number of **days of past programmes kept in the guide** (more days = more memory), **time offset** (if the replayed programme is shifted by a few minutes or an hour, fix it here; the server's time zone is read automatically), return to live.
- A replay counts as **one connection**: it closes the current channel, like switching channels.
- If a replay does not start, open the **Log** (topic “Playback and relay”): the archive address built and the offset used are listed there. The provider's guide must contain past programmes: reload it after increasing the number of days kept.
<!--/mac-->

<!--pc-->
Some IPTV subscriptions keep channels for up to **14 days** (depending on the provider and the channel). Kastideo detects this by itself: channels with replay show a **↺** icon in lists and in the TV Guide.

- **In the TV Guide**: click a **past** programme (marked ↺), then **Watch again**. On the **current** programme, **Watch from the start** replays it from the beginning. **Save this replay** downloads the programme from the provider's archive (recordings folder).
- **Previous days**: the date menu of the TV Guide offers **Watch again (replay)** with the past days.
- **From a channel**: right-click the channel > **Watch again (replay)…** (recent programmes of that channel). The Cinema interface also has a **To watch again** row (your favourite channels with replay).
- **During a replay**, the player bar lets you pause and move within the programme. At the end, Kastideo **returns to the channel's live stream** (can be turned off).
- **Settings > General > Replay**: turn replay on or off, number of **days of past programmes kept in the guide** (more days = more memory), **time offset** (if the replayed programme is shifted by a few minutes or an hour, fix it here; the server's time zone is read automatically), return to live.
- A replay counts as **one connection**: it closes the current channel, like switching channels.
- If a replay does not start, open the **Log** (button Log, topic “Playback and relay”): the archive address built and the offset used are listed there. The provider's guide must contain past programmes: reload it after increasing the number of days kept.
<!--/pc-->

## One connection at a time {#connexion-unique}

<!--mac-->
Most IPTV subscriptions allow only **one simultaneous stream**. Kastideo always closes the current stream before opening the next one: you can zap without risk of exceeding your limit. If playback fails, check that no other device (TV, phone, Piboard…) is watching with the same subscription.
<!--/mac-->

<!--pc-->
Most subscriptions allow a single connection. Kastideo closes the previous channel before opening the next (**stream relay**, Settings > General > Playback) and asks before interrupting a recording.
<!--/pc-->

## Buffer {#tampon}

<!--mac-->
In **Settings > General > Playback**, choose the trade-off between speed and stability:

- **Fast** (default): 0.4 s of reserve, the shortest zapping.
- **Balanced**: 1 s.
- **Stable**: 3 s, for unreliable connections or servers (fewer interruptions, slower start).
<!--/mac-->

## The Log (diagnostics) {#journal}

<!--pc-->
The **Log** (**Ctrl+Alt+L**, or the button on the home screen and in error messages) is Kastideo's diagnostic tool. User names and passwords are **hidden** in it: you can copy it to share it.

- **Topics**: *TV Guide*, *Playback and relay*, *Sources and catalogues*, *Recordings*, *TMDB details*, *Updates*, *Display and other*. Click one or more topics to see only those (the number of lines per topic is shown).
- **Search** a word, or show only **errors and warnings**.
- **Copy what is shown** copies only what is displayed, with the filter at the top.
- **Level of detail** (per topic): *Normal*, *Detailed* (default for the TV Guide) or *Debug* (everything). The setting applies to lines written afterwards; errors and warnings are always kept.
- **Current session / Previous session**: the log is kept on disk (the folder path is shown at the bottom of the window), so you can read what happened at startup in the previous session.
<!--/pc-->

# Recordings and downloads

## Overview {#enregistrements}

<!--mac-->
Everything is in the **Recordings** section of the sidebar (**⌘6**): current recording, conversions, downloads, schedules and recorded files (click to watch them, right-click to show them in Finder or delete them).

Files are stored in **~/Movies/Kastideo** (can be changed in **Settings > Recordings**) and named automatically, for example “TF1 – Le goût du détail – 2026-10-18 20h50”.
<!--/mac-->

## Recording live {#enregistrer}

<!--mac-->
- While a channel is playing, click **●** in the controls, **Record** under the video, or use **⇧⌘R**. The **REC** badge shows the duration.
- Recording stops automatically at the end of the current program (according to the TV guide, plus the margin after), or when you click **■**.
- It uses **the same connection** as playback: nothing more is consumed from your subscription.
- Right-click a channel > **Record Now**: if you are watching another channel, Kastideo asks whether to stop playback, then records in the background.
- A **banner** at the bottom of the window confirms when a recording starts and ends and shows **the folder** where the file is (**Show** button). If the folder chosen in settings is no longer accessible, the file is placed in ~/Movies/Kastideo and the banner says so. Detailed steps are in the **Playback Log**.
- **While recording**, the file is visible and growing in the **In progress** subfolder of the recordings folder (a folder named after the program). When stopped, it is moved to the recordings folder and the subfolder is removed. If the VLC engine does not create the file within 10 seconds, Kastideo automatically retries in a temporary folder (the file then appears only when stopped); “Recording impossible” is shown only after both attempts, with details in the Playback Log (⌥⌘L). Length is limited only by disk space: count about 1 to 3 GB per hour depending on the channel (a warning appears below 3 GB free).
- At the end, the recording is **converted to MP4** with no quality loss (playable in QuickTime, on iPhone and iPad). The .ts file appears first, then is replaced by the .mp4 when conversion is done (a few minutes for 2 hours; shown in the Recordings section). The picture is copied with no loss; **audio is converted to AAC** (some channels broadcast MP2 or AC-3 audio that QuickTime plays silently). DVB subtitles and teletext, which MP4 cannot hold, are dropped; if conversion fails, a second attempt keeps only the picture and main audio, and as a last resort the .ts is kept. This can be turned off in settings.
<!--/mac-->

<!--pc-->
Red round button in the player bar, **R** key, or right-click a channel > **Record now**: the channel is recorded until the end of the current programme (plus the margin) or until you stop it, in **Videos/Kastideo/Enregistrements**.

- The stream bytes are copied as is to a **.ts** file, losslessly: the watched channel is copied from the relay (no second connection to the provider); another channel is downloaded directly, reconnecting if the stream drops.
- At the end, the .ts is converted losslessly to **MKV** (default format, Settings > Recordings); if conversion fails, the .ts is kept — it plays everywhere.
- HLS streams (.m3u8) and playback without the relay still go through the video engine.
<!--/pc-->

## Scheduling a recording {#programmer}

<!--mac-->
- In the TV guide under the video, **double-click** an upcoming program, or right-click > **Schedule Recording**. A red dot marks scheduled programs.
- Right-click a channel > **Schedule a Recording…** (or the calendar icon under the video): choose a program from the guide or custom times.
- **Margins** before and after (2 and 5 minutes by default, adjustable) avoid missing the beginning or the end.
- At the scheduled time, recording starts in the background. If you are watching another channel, Kastideo asks whether to stop playback; without a reply, recording starts after 60 seconds.
<!--/mac-->

<!--pc-->
- **Right-click a live channel > Schedule a recording…**, or the **Schedule…** button of the Recordings screen (then choose the channel: favorites, recents or search).
  - **Guide programmes**: the channel's next programmes, with **Schedule** (or **Record** for the current one). A check mark shows those already scheduled.
  - **Time slot**: day, start and end time, optional title — for a channel without TV guide or a specific show. An end earlier than the start finishes the next day.
  - **Repetition** (list at the top right): **once**, **every day**, **Monday to Friday** or **every week**. The next occurrence is added automatically; the ⟲ button of a repeated recording in the list stops repeating.
- From the details of an upcoming programme (TV guide, themes): **Schedule recording**.
- Margins before and after (Settings > Recordings) are added. Kastideo must be open at the scheduled time: turn on **Start Kastideo when I sign in** if needed (Settings > General).
<!--/pc-->

## Downloading a movie or episodes without watching {#telecharger}

<!--mac-->
- Right-click a movie or an episode > **Download** or **Download Tonight**, or the **Download** button under the video.
- For a series: the **Download** button on its page > the displayed season or the whole series.
- Downloads run **one after the other** (queue). “Tonight” starts at 2 a.m. by default (adjustable).
- You can pause, resume or cancel each download in the Recordings section.
- **Permanent indicator**: as long as a download is active, a progress ring stays visible in the toolbar. A click opens the details: progress of the current movie or episode, “episode X of N”, progress of the series or batch, speed and **estimated time remaining** (refined as the download goes on).
<!--/mac-->

<!--pc-->
**Download** button on a movie's details (now or **tonight**), **Download the season** or each episode's icon for a series, right-click > Download. One download at a time, resumed after an interruption, paused during playback (adjustable). Files go to **Videos/Kastideo/Films** and **Séries/<series>**.
<!--/pc-->

## Single connection: who has priority? {#priorite}

<!--mac-->
Your subscription allows only one connection. Kastideo therefore does only one thing at a time and **always asks you** before interrupting something:

- You change channel during a recording: Kastideo asks whether to **stop the recording**.
- You start playback during a download: the download is **paused** and resumes by itself when playback stops.
- Files that are already recorded can be watched at any time, even during a background recording.
<!--/mac-->

## Recordings screen {#ecran-enregistrements}

<!--pc-->
Current recording (stop), downloads (pause, resume, cancel), scheduled recordings and history, files in the folder: a click plays them, right-click to show them in the folder or delete them.
<!--/pc-->

## Details in your language {#fiches-langue}

<!--pc-->
With a **TMDB key** (Settings > General), titles, summaries, genres and episodes come from TMDB, in the interface language. When the only summary available is the provider's in another language (Portuguese, Spanish…), it is folded: **Show the summary (Portuguese)** shows it anyway. It doesn't appear in the banner or the episode list.
<!--/pc-->

## Good to know {#bon-a-savoir}

<!--mac-->
- Kastideo must **stay open** and the Mac **on** for scheduled recordings and overnight downloads. Kastideo prevents automatic sleep during activity and in the hour before, but not manual shutdown or sleep.
- A **macOS notification** signals the start and end of recordings and downloads (can be turned off).
- **Automatic cleanup** (optional): recordings older than the chosen number of days are moved to the Trash.
- An alert warns you when disk space gets low.
- Copying rights depend on your provider's conditions: Kastideo records for your private use what your subscription already gives you.
<!--/mac-->

# Organize and customize

## Fixing a channel {#corriger}

<!--mac-->
Some channels are badly referenced by the provider (wrong name, wrong programs, missing logo). Right-click the channel > **Edit Channel…**:

- **Name** and **number** (used for number zapping in the TV interface);
- **Logo**: an image address, or **Choose a File…** (the image is copied into Kastideo);
- **TV guide programs**: if the programs shown are wrong or missing, search the right channel in the list (provider guide and backup guide); the program on now helps recognize it.

The fix only applies to **this version** of the channel (FHD, HD, SD… are fixed separately) and survives source refreshes. **Restore Original** undoes it.
<!--/mac-->

<!--pc-->
Right-click a channel > **Edit channel…**: name, number, logo (image address or a file copied into Kastideo) and **TV guide** channel (search among the provider and fallback guides). The fix applies to this version of the channel (HD, FHD…) and survives every refresh. **Restore** goes back to the original.
<!--/pc-->

## Organizing categories {#categories}

<!--mac-->
You don't have to put up with your provider's category list and order. Open **View > Manage Categories…** (**⌥⌘C**), the button next to the “Categories” title in the sidebar, or right-click a category. Choose the section (**Live**, **Movies** or **Series**), then:

- **Reorder**: drag categories in the list, or use the **…** menu > **Move to Top / Bottom**. **Sort A → Z** sorts everything alphabetically.
- **Select / deselect all**: the box above the list ticks or unticks all listed categories at once. With a search (for example “PT”), it only affects the categories found: handy to hide a whole country in one go, then show only the ones you want.
- **Hide**: uncheck a category (or right-click > **Hide This Category** in the sidebar). A hidden category disappears **everywhere**: sidebar, Live / Movies / Series lists, search, TV Guide, Cinema and TV interfaces, featured banner. Your favorites and recents stay available.
- **Hide by keyword**: type for example “PAKISTAN” or “ARABIC”: every category whose name contains it is hidden, including ones the provider adds later. Click a keyword's cross to undo it.
- **Rename**: the pencil gives a more readable name (“FRANCE FHD | OTT” → “France HD”); **Original Name** undoes it.
- **Show All** shows hidden categories again; **Reset…** goes back entirely to the provider's layout.

New categories added by the provider appear next to their original neighbor.
<!--/mac-->

<!--pc-->
- **Right-click a category** in the sidebar: **Rename…**, **Move to top**, **Move up**, **Move down**, **Move to bottom**, **Hide this category**, **Manage categories…**.
- **Settings > Categories** (or the icon next to "Categories"): for live TV, movies or series — drag to reorder, untick to hide everywhere, double-click to rename, **keywords** to hide every category containing them at once (e.g. "PAKISTAN"), **Sort A to Z**, **Restore**.
- **Select / deselect all**: the box above the list ticks or unticks all listed categories at once. With the **search** (e.g. "PT"), it only affects the categories found: hide a whole country in two clicks, then tick only the ones you want.

A hidden category is hidden everywhere: lists, search, home, rows.
<!--/pc-->

## Favorites and recents {#favoris}

<!--mac-->
- Add a favorite with the star in the information panel, right-click or **⌘D**.
- The **Recents** section keeps the last 60 items you watched.
- **Removing from recents**: right-click an item > **Remove from Recents** (or the **⌫** key on the selected item in the Classic interface). For several items, click **Edit**, tick the items, then **Delete**; **Select All** ticks the whole list and **Clear All** empties the history.
- After a deletion, an **Undo** banner stays visible for a few seconds to restore everything.
- Recents can also be cleared in settings, **General** tab.
<!--/mac-->

<!--pc-->
Star in the player bar, **F** key or right-click > Add to favorites. Recents keep the last 60 items opened.

- **Edit** (next to the "Recents" title): tick items then **Remove selection**, or a row's cross to remove it alone; **Select all** and **Clear all** (for the section shown). **Done** goes back to the list.
- Right-click an item > **Remove from recents**.
- Settings > General > **Clear recents** clears them all, every section.
<!--/pc-->

## Alerts and notifications {#alertes}

<!--pc-->
- **Alert me when it starts** on an upcoming programme's details (bell in the guide).
- **Keywords** (Settings > Recordings): a programme whose title contains a keyword triggers an alert, on your favorite channels or on all of them.
- The alert shows at the top right of Kastideo with **Watch**, and the window comes back if it was minimized.
- **System notifications** (Settings > General > Notifications, on by default): alerts, recording start and end, download finished or failed also appear in the Windows or Linux notification center, even when Kastideo is behind another window. Clicking the notification brings Kastideo back.
<!--/pc-->

## Appearance {#apparence}

<!--pc-->
Settings > **Appearance**:

- **Theme**: **Dark** (default), **Light** or **Same as system** (follows Windows or Linux). The player, TV interface, MultiView, home screen, details pages and the featured banner stay dark, as on Mac.
- **Accent color**: default (Kastideo blue), blue, purple, pink, red, orange, green or teal — used for selections, buttons, switches.
- **List density** (Classic interface): compact, standard or spacious.
- **Thumbnail size** (Cinema interface): small, medium or large.
- **Interface** per content type and **featured banner** (see [Three interfaces](help:interfaces)).

Changes apply immediately, without restarting.
<!--/pc-->

# YouTube

## YouTube: browse and play {#youtube}

The **YouTube** section (sidebar, Home button,
<!--mac-->**⌘9**<!--/mac--><!--pc-->**Ctrl+9**<!--/pc-->) works in two steps: a **browser** first, then the **player** as soon as you pick a video.

![From browser to player](img:youtube)

### The browser

- **My channels**: paste a channel link or its @handle in the field at the top to follow it. Its latest videos appear in a row, with no key and no account. To bring in all your subscriptions at once: [Import my subscriptions](help:youtube-import).
- **Search**: type your search in the same field (thumbnail results, sorted by relevance, date or views, more pages). It needs a **free Google API key**: [the step-by-step guide](help:youtube-cle).
- **Pasted links**: a video plays, a playlist becomes the play queue, a channel is followed.
- **Favorites and history**: right-click a thumbnail; the history keeps the last 80 videos (with a button to clear it).
- **Watch later**: right-click a thumbnail to set a video aside. A video you started **resumes where you left off** (a red bar shows progress); it leaves the list once watched to the end.

### The player

<!--mac-->
Clicking a video replaces the browser with the player; the list you came from becomes the queue. Previous / Next buttons, **Autoplay next**, **Loop**, **Mute** and **Open on YouTube** sit in a bar that hides itself; **Esc** or **YouTube browser** takes you back to the list.
<!--/mac-->
<!--pc-->
Clicking a video opens the player in **its own window** (Edge or Chrome on Windows, Chrome or Chromium on Linux in “app” mode; otherwise your default browser); the list you came from becomes the queue. Previous / Next buttons, **Autoplay next**, **Loop**, **Mute** and **Open on YouTube** sit in a bar that hides itself. A banner in Kastideo reminds you of the current video, with **Reopen window**.
<!--/pc-->

IPTV playback stops while YouTube plays (unless a recording is in progress).

> About ads and your Google account: see [Ads, account and privacy](help:youtube-confidentialite).

## Import my YouTube subscriptions {#youtube-import}

YouTube does not let an app like Kastideo sign in to your account. Google does let you **export your data**, though: you ask only for your list of subscriptions, a small `subscriptions.csv` file that Kastideo reads **on your computer**.

![The import steps](img:takeout)

### Step 1: ask Google for the export

1. Open [Google Takeout](https://takeout.google.com/) while signed in to the **Google account** whose subscriptions you want.
2. Click **Deselect all** (at the top of the list).
3. Scroll down to **YouTube and YouTube Music** and tick the box.
4. Click **All YouTube data included**, click **Deselect all**, tick only **subscriptions**, then **OK**.
5. At the very bottom, click **Next step**. Keep **Send download link via email**, **Export once** and the **.zip** format, then click **Create export**.
6. Google prepares the archive (a few minutes, sometimes more) and sends you an e-mail. Click **Download your files** in the e-mail and save the `.zip`.

### Step 2: find the file

1. Open the `.zip`: <!--mac-->double-click it in the Finder<!--/mac--><!--pc-->right-click > **Extract all** (Windows) or double-click (Linux)<!--/pc-->.
2. Open **Takeout** > **YouTube and YouTube Music** > **subscriptions**.
3. The file is called **subscriptions.csv** (or **abonnements.csv** if your account is in French).

### Step 3: import it in Kastideo

1. Open **YouTube** > **My channels**.
2. Click **Import my subscriptions…** and choose the file.
3. Kastideo adds the channels and loads their latest videos (with many subscriptions, the first refresh can take a minute).

> Channels you already follow are not added twice. The file is read only by Kastideo, on your machine: nothing is sent to Google or anywhere else, and Kastideo never accesses your account.

### If it does not work

- **“No new channel found in this file”**: it is not the right file (for example the watch history), or the channels are already followed. Go back to step 2.
- **No e-mail from Google**: check your junk folder, or go back to [Google Takeout](https://takeout.google.com/): the “Manage exports” section lets you download the archive again.
- **No “subscriptions” folder**: in step 1.4, check that the **subscriptions** box was ticked.
- Without a file, you can follow one channel at a time by pasting its link or @handle: see [YouTube](help:youtube).

## Getting a Google API key (search) {#youtube-cle}

YouTube **search** uses Google's official interface (“YouTube Data API v3”) with **your own key**. It is **free** and enough for about **100 searches a day**. Without a key everything else works: following channels, playing pasted links, favorites, history.

### Create the key (5 minutes, once)

1. Open the [Google Cloud console](https://console.cloud.google.com/) and sign in with a Google account.
2. At the top, click the project selector > **New project**. Give it a name (for example “Kastideo”), click **Create**, then select it.
3. Open [the YouTube Data API v3 page](https://console.cloud.google.com/apis/library/youtube.googleapis.com) and click **Enable**.
4. Menu **APIs & Services > Credentials** > **Create credentials** > **API key**.
5. Copy the key shown (about forty characters starting with “AIza”).
6. Optional but recommended: **Edit key** > **API restrictions** > **Restrict key** > tick **YouTube Data API v3**.

### Give it to Kastideo

1. Open **Settings > General > YouTube**.
2. Paste the key in **Google API key** and confirm.
3. Go back to **YouTube**: search now works.

<!--mac-->
The key is stored in the **macOS keychain**, never in clear on disk, and is never published.
<!--/mac-->
<!--pc-->
The key is stored in the **system vault** and is never published.
<!--/pc-->

> Quota: each search uses 100 of the 10,000 free daily units. If you reach the limit, Kastideo shows “YouTube API error”; search comes back the next day. Following channels and playing videos does not use this quota.

### When something goes wrong

- **“API key missing”**: nothing is saved in Settings.
- **“API key not valid” / “YouTube API error”**: the key was copied incorrectly, or step 3 (enabling the API) was not done for **this** project.
- **Restriction error**: if you restricted the key, check that **YouTube Data API v3** is ticked.

## Ads, account and privacy {#youtube-confidentialite}

### Ads

Kastideo uses the **official YouTube player in “privacy-enhanced mode”** (youtube-nocookie.com), the one Google gives websites to embed videos: it sets no tracking cookie and so shows no personalised ads, usually none at all.

**This is not an ad blocker**: nothing is intercepted or bypassed, and YouTube remains free to show ads, which fund creators.
<!--pc-->
If your browser has its own ad blocker, it applies in the player window.
<!--/pc-->

### Why can't I sign in to my account?

The privacy-enhanced player does not recognise your account: no personalised recommendations, no automatically synced subscriptions, no YouTube Premium (which removes ads on youtube.com, not in an embedded player). That is the price of tracking-free playback. To get your subscriptions back, use the [step-by-step import](help:youtube-import).

### What Kastideo keeps

Your followed channels, favorites, history (80 videos), “watch later” list and resume points are stored **on your computer only**. Any API key stays in the system vault. Nothing is sent to Kastideo or to anyone other than YouTube / Google when you search or play a video.

# Settings and maintenance

## Keyboard shortcuts {#raccourcis}

<!--mac-->
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
- **⌘?**: this help (opens on the page for the current screen)
- **⌘8**: My videos, **⌘9**: YouTube
<!--/mac-->

<!--pc-->
- **Ctrl+0**: home — **Ctrl+1**: live — **Ctrl+2**: movies — **Ctrl+3**: series — **Ctrl+7**: TV guide — **Ctrl+Alt+M**: MultiView — **Ctrl+,**: settings
- **Space**: play / pause — **M**: sound — **F**: favorite — **R**: record / stop — **← / →**: −10 s / +30 s
- **Ctrl+Enter** or double-click the picture: cinema mode — **F11**: full screen — **Esc**: leave cinema mode, back to details or rows
- TV interface: **↑ / ↓** zapping, **digits** channel number, **←** panel, **→ / I** banner, **B** previous channel, **G** guide, **H** home
- MultiView: **1 to 4** sound, **G** enlarge, **A** add, **Del** remove, **F** full screen, **Esc** leave
- **Ctrl+Alt+L**: log
- **Ctrl+8**: My videos, **Ctrl+9**: YouTube
- **F1**: this help (opens on the page for the current screen)
<!--/pc-->

## General settings {#reglages}

<!--mac-->
- **Language** (**General** tab): Kastideo is available in **French** and **English**. The language is chosen at first launch, then can be changed in **Settings > General > Language** (or “System” to follow the Mac's language). The change applies after the app restarts, which Kastideo offers to do for you. Help and menus follow the chosen language; release notes remain in French.
- **Appearance** (**Appearance** tab): dark theme (default), light or same as system; **accent color** (System, blue, purple, pink, red, orange, green, teal); **interface** Classic or Cinema for each type of content; **list density** (compact, standard, spacious) for the Classic interface; **thumbnail size** (small, medium, large) for the Cinema interface.
- **Movie and Series Details** (**General** tab): optional **TMDB** API key (free at themoviedb.org > Settings > API; v3 key or v4 read token), stored in the keychain. **Save and Verify** checks it. Without a key, details come from your IPTV provider.
- **Refresh at launch**: reloads sources whose last refresh is more than 6 hours old.
- **Cache**: Kastideo keeps a local copy of lists and the TV guide to start instantly. **Clear and Reload** erases this copy and restarts loading.
<!--/mac-->

<!--pc-->
- **General**: language (on next launch), resume playback, stream relay, refresh at startup, clear recents, **simultaneous connections** (MultiView), **system notifications**, TV guide and fallback guide, adult content (hidden by default), TMDB key, **startup and .m3u files**, **updates**.
- **Appearance**: theme, accent color, list density, thumbnail size, interfaces, featured banner.
- **Sources**: add, refresh, delete, guide state.
- **Categories**: order, hiding, names, keywords.
- **Recordings**: folder, format, margins, downloads, timeshift, alerts.
- **Backup**: export or import the configuration.
<!--/pc-->

## Getting a TMDB key (free) {#tmdb}

<!--mac-->
TMDB (The Movie Database) is a community movie and TV database. Its key is **free** for personal use; it lets Kastideo show cast photos, HD posters and backdrops, the trailer and a translated synopsis.

1. Create an account on **themoviedb.org** (“Join TMDB”), then confirm it with the link sent by e-mail.
2. Signed in, open **themoviedb.org/settings/api** (avatar > Settings > API), or click **Get a Free Key** in Kastideo's settings.
3. Click **Create**, choose **Developer** and accept the terms of use.
4. Fill in the form: usage type **Personal**, application name **Kastideo**, URL **https://github.com/jihemezes/kastideo**, a short summary (“Personal IPTV player, shows movie details”), then your contact details.
5. Submit: the page shows an **API Key** (32 characters) and an **API Read Access Token** (long, starts with “eyJ”). Kastideo accepts either; the API key is easier to copy.
6. In Kastideo: **Settings (⌘,) > General > Movie and Series Details**, paste the key and click **Save and Verify**. “Valid key ✓” confirms it.
7. Reopen a details page (or click **Refresh** at its bottom): it is now completed by TMDB.

The key is stored in the Mac keychain. **Remove Key** goes back to IPTV provider information only.
<!--/mac-->

<!--pc-->
Create an account on themoviedb.org, then **Settings > API** and request a key (personal use). Paste the "API key" (v3) or the "read access token" (v4) into Settings > General, then **Save**. Details become richer (posters, cast, trailers, summaries and episodes in your language).
<!--/pc-->

## Startup and .m3u files {#demarrage}

<!--pc-->
Settings > General > **Startup and files**:

- **Start Kastideo when I sign in** (Windows and Linux), and **Start minimized** in the taskbar: scheduled recordings and alerts only happen while Kastideo is open.
- **Open .m3u and .m3u8 files with Kastideo** (optional): double-clicking a playlist offers to add it as a source (Settings > Sources); if Kastideo is already open, the existing window receives it. If Windows keeps opening another program, right-click the file > Open with > Choose another app > Kastideo.

Both options are also offered by the Windows installer (unticked by default).
<!--/pc-->

## Backup and transfer {#sauvegarde}

<!--mac-->
Settings > General > **Backup and transfer**:

- **Export configuration…** saves a `Kastideo-configuration.json` file: sources (Xtream and M3U playlists by address), favorites, recents, custom categories (order, hidden, names, keywords), chosen interfaces and TMDB key. Tick **Include passwords** so nothing has to be typed again; keep the file somewhere safe.
- **Import configuration…** adds the content of a file: on a new Mac, or from Kastideo for Windows and Linux (same format). Sources already present are recognised and nothing is deleted.

Jellyfin, Emby and Plex servers are exported (with their password or token if you tick **Include passwords**). M3U playlists added as local files and folders are not imported on another Mac (the files do not exist there or must be chosen again).
<!--/mac-->

<!--pc-->
Settings > **Backup**: **Export configuration…** (sources and their guide, passwords if you wish, favorites, recents, categories, interfaces, appearance, number of connections, adult content, banner, TMDB key) and **Import configuration…**. The file is the same as Kastideo for Mac: you can move from one computer to the other in both directions. Nothing is deleted on import. Jellyfin, Emby and Plex servers are included (password or token too, if requested); folders as well, with their paths (to fix if they differ on this computer).
<!--/pc-->

## Updates {#mises-a-jour}

<!--mac-->
Kastideo updates itself thanks to **Sparkle**, the reference tool for Mac apps distributed outside the App Store.

- **At launch** (a few seconds after starting), then once a day if Kastideo stays open, Kastideo discreetly checks whether a new version is available on GitHub.
- If so, a **banner** at the top of the window announces it — **never while watching or recording** (it waits for playback to end). The update is **optional**: **Update…** opens the release notes window then **Install Update** (Kastideo quits, installs and relaunches); **Later** hides the banner until the next launch; **Skip This Version** stops offering it (the next one will be offered).
- You can check at any time with **Kastideo > Check for Updates…**.
- Every update is signed: Kastideo refuses to install a file that does not come from its publisher.

In **Settings > Updates**:

- **Check for updates at launch**: turns the launch and daily check on or off.
- **Receive test versions (beta)**: also offers beta versions, which bring new features earlier but may be less stable. Turn the option off to return to stable versions at the next update.

> Versions 0.1.0 and earlier cannot update themselves: install 0.2.0 by hand once, and the following ones will arrive on their own.
<!--/mac-->

<!--pc-->
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
<!--/pc-->

## Installation {#installation}

<!--pc-->
- **Windows (recommended)**: run **Kastideo-…-windows-x64-setup.exe**. By default Kastideo installs for you only, without administrator rights (in your AppData folder); the installer also offers to install for all users, a desktop icon, opening .m3u files and starting at sign-in. Uninstall: Windows Settings > Apps > Kastideo.
- **Windows, portable**: unzip the "windows-x64.zip" archive anywhere and run **kastideo.exe** (nothing is installed; updates replace the folder's files).
- The app is not signed: if SmartScreen says "Windows protected your PC", click **More info** then **Run anyway**.
- **Zorin OS 17 / Ubuntu 22.04**: "ubuntu22.04_amd64.deb" package (double-click or `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: "ubuntu24.04_amd64.deb" package.
- **Any distribution, and Raspberry Pi (64-bit)**: AppImage file; make it executable (right-click > Properties > Allow executing, or `chmod +x`) and run it.
<!--/pc-->

## What's new {#nouveautes}

After each update, the **What's New** window summarises the changes in the installed version.

<!--mac-->
You can reopen it with **Help > What's New in This Version** or by clicking the version number at the bottom right of Home, and browse earlier versions there.
<!--/mac-->
<!--pc-->
You can reopen it by clicking the version number at the bottom right of Home, and browse earlier versions there.
<!--/pc-->

The full history is also published on the [GitHub Releases](https://github.com/jihemezes/kastideo/releases) page.

# Troubleshooting

## Troubleshooting {#depannage}

<!--mac-->
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
<!--/mac-->

<!--pc-->
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
<!--/pc-->

# About

## Support Kastideo {#soutenir}

<!--mac-->
Kastideo is **free** and will stay free. If you enjoy the app, you can encourage its development by buying me a coffee on [Ko-fi](https://ko-fi.com/jihemezes): it is entirely optional.

The **Buy me a coffee** button appears discreetly on the home screen and in the What's New window, as well as in **Settings > About** and **Help > Support Kastideo (Ko-fi)**. To hide the buttons on the home screen and in What's New, tick **Hide the “Buy me a coffee” buttons** in **Settings > About**.
<!--/mac-->

<!--pc-->
Kastideo is **free** and will stay free. If you enjoy the app, you can encourage its development by buying me a coffee on [Ko-fi](https://ko-fi.com/jihemezes): it is entirely optional.

The **Buy me a coffee** button appears discreetly on the home screen and in the What's New window, as well as in **Settings > About**. To hide the buttons on the home screen and in What's New, tick **Hide the “Buy me a coffee” buttons** in **Settings > About**.
<!--/pc-->

## Privacy {#confidentialite}

<!--mac-->
Kastideo runs in the macOS sandbox. It only accesses the network and the files that you choose. Your passwords stay in the keychain. No data is sent anywhere other than to your own sources.
<!--/mac-->

<!--pc-->
Kastideo collects no data. It only contacts your IPTV providers, the TV guides you chose, GitHub for updates and, if you entered a key, TMDB. Your settings, favorites and passwords stay on your computer.
<!--/pc-->

## Licenses {#licences}

<!--mac-->
Kastideo uses **VLCKit** (VLC's engine, © VideoLAN, LGPL 2.1 or later license, https://www.videolan.org/vlc/libvlc.html) and **Sparkle** (MIT license, https://sparkle-project.org). VLCKit is embedded as an unmodified dynamic library.
<!--/mac-->
