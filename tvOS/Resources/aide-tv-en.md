# Getting started

## Welcome {#tv-bienvenue}

Kastideo is a **player**: it provides no channel, movie or subscription. You add your own source, then everything is controlled with the remote.

The home screen shows large **Live**, **Movies** and **Series** tiles (and **My videos** if you have a Jellyfin, Emby or Plex server), then buttons: **Resume**, **Recents**, **Favorites**, **TV Guide**, **Search**, **Settings** and **Help**. The same sections are in the top bar.

> This help is specific to Apple TV. The full Kastideo guide (Mac, iPhone, iPad, Windows, Linux, Android) is available inside the app on those devices.

## Add a source {#tv-sources}

Typing an address and a password with the remote is tedious, so Kastideo offers three ways. To try it without a subscription, select **Try the demo**: Kastideo adds a few royalty-free videos.

1. **From a phone (QR code)**: **Settings > Sources > Add from a phone**. Scan the QR code with a phone, or open the address shown on a computer on the same Wi-Fi network, fill in the form and enter the **4-digit code** shown on screen. Keep this screen open while you type.
2. **From an iPhone or iPad**: in Kastideo on the iPhone, **Settings > Backup > Send to Apple TV** sends your sources, favorites and settings in one go (same Wi-Fi network, same 4-digit code).
3. **With the keyboard**: **Settings > Sources > Add a source with the keyboard…**

Source types: **Xtream Codes** subscription, **M3U** playlist (address) and **Jellyfin, Emby, Plex** servers (**My videos** section). iCloud sync is not available on Apple TV.

To edit, refresh, delete or **reorder** a source (Move up / Move down: sources at the top appear first): **Settings > Sources**, then the source.

# Using Kastideo

## The remote {#tv-telecommande}

- **Touch surface / arrows**: move around; **click**: select.
- **Menu (back) button**: go back; in the player it stops playback.
- **Play / Pause**: pause or resume.
- **Long press on a poster or a channel**: opens a small menu (add or remove favorites). On an episode: mark as watched or unwatched.
- **In the player**: ↑ / ↓ change channel in live TV, ← goes back 10 s and → forward 30 s in a movie or episode, a **click** opens the options.

## Live and channel zapping {#tv-direct}

Open **Live**: channels are sorted by category (**Category** button) and the display button picks the **Classic**, **Cinema** or **TV** interface. The **TV** interface works like a television: zapping by number and the last channel starting on opening (adjustable).

While playing, ↑ / ↓ change channel. Depending on **Settings > Playback > Zapping**, a click confirms your choice in the list (**with confirmation**) or the change is **immediate**. In the player options: **Last channel** (back to the previous one) and **Go to channel no.…**.

## TV Guide and replay {#tv-guide}

The **TV Guide** tab shows a 3-hour grid. Click a programme: **Watch the channel**, or **Watch this programme again** when your provider keeps past broadcasts (replay). **Settings > TV Guide > When opening the guide** chooses between **Now** and **Last position**.

> The guide comes from your provider; a backup guide is used if it is incomplete.

## Movies and series {#tv-films}

**Movies** and **Series** appear as a **Classic** grid or in **Cinema** view (banner and rows by category). Click a poster to open its page: summary and cast (with a TMDB key), then **Play**. For a series, pick the season and episode; the next episode can follow automatically.

**Search** looks through channels, movies and series.

## The player {#tv-lecteur}

A **click** during playback opens the **Options**:

- add or remove **favorites**;
- **Sleep timer**: stops playback after a few minutes;
- **Audio tracks** and **Subtitles**;
- **Playback speed** (movies and episodes);
- in live TV: **Last channel** and **Go to channel no.**;
- for a series: **Next episode**.

An information banner appears for a few seconds (channel, current programme).

## Favorites, resume and “watched” {#tv-favoris}

- **Favorites**: long press on a poster or a channel, or the player **Options**. The list is in the **Favorites** button on the home screen.
- **Resume**: movies and episodes you started resume where you stopped (adjustable in **Settings > Playback**). With Jellyfin, Emby and Plex, resume is shared with the server.
- **Watched**: a watched episode is marked; long press to change it.
- **Recents**: the latest content you watched.

# Settings

## Language and display {#tv-reglages}

- **Language**: **Settings > Application language**. “System” follows the Apple TV language; you can choose French, English, Spanish, German, Italian, Portuguese (Portugal) or Portuguese (Brazil). The change is immediate.
- **Start page**: for Live, Movies and Series, the first category, favorites, recents, the last one viewed or a specific category.
- **Display**: Classic, Cinema or TV, separately for live, movies and series.
- **Categories**: show or hide categories (**Hide all**, then tick only the ones you want); adult channels (hidden by default). Recalculating the display can take a few seconds: a banner says so.
- **Playback**: zapping, **Buffer** (Fast, Balanced, Stable: pick Stable if the picture stutters), movie resume and software decoding.

## Posters and summaries (TMDB) {#tv-tmdb}

Posters, summaries, cast and trends come from **TMDB**, a free service. You need a personal **API key**: create a free account on themoviedb.org, open **Settings > API**, then enter the key in **Settings > TMDB**. Without a key, Kastideo works with the information from your provider.

# Troubleshooting

## If a channel does not start {#tv-depannage}

1. Wait a few seconds: some channels take time to start.
2. Try another channel, then come back.
3. Your subscription may allow only **one connection at a time**: close Kastideo on your other devices.
4. Turn off any **VPN** on the network.
5. Frozen or stuttering picture: **Settings > Playback > Always decode in software**, or **Buffer: Stable**.
6. Empty content: **Settings > Sources > Refresh all**.

To understand a specific problem, the **Playback log** can be viewed on the Mac, iPhone or iPad.

## Legal notice and privacy {#tv-legal}

Kastideo does not provide, host or sell any content: you are responsible for the legality of your sources. The full notice is in **Settings > About > Legal notice**.

Kastideo collects no data: your sources and settings stay on the Apple TV, and credentials are only sent to the services you configure (your provider, your servers, TMDB if you enter a key). Full policy: https://github.com/jihemezes/kastideo/blob/main/docs/PRIVACY.md
