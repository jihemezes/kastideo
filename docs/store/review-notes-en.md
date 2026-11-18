# App Review notes (paste into App Store Connect > App Review Information > Notes)

Kastideo is a generic media player, similar to any playlist/stream player. It does not contain, offer, sell, host or recommend any content, channel or provider. The user adds their own sources (M3U playlist, Xtream Codes account, Jellyfin/Emby/Plex server, local folders or the device library). A legal notice is shown at first launch (the user must accept it) and can be read again in Settings.

No account is required, there are no in-app purchases, no advertising, no tracking and no data collected by the publisher.

HOW TO TEST (no subscription needed)
- iPhone/iPad: on the Home screen, tap "Try the demo" (Essayer la démo). It adds a public playlist containing only royalty-free test streams (Apple's own HLS example, Blender open movies "Big Buck Bunny" and "Sintel", and test streams). Then open Live, Movies, the TV Guide, and play any item.
- Apple TV: on the welcome screen, select "Try the demo".
- The same playlist can be added manually: Settings > Add a source > "M3U list (URL)" and paste https://raw.githubusercontent.com/jihemezes/kastideo/main/docs/store/demo.m3u

NOTES
- Local network permission is used to discover the user's own Jellyfin/Emby/Plex servers and Chromecast/Apple TV devices (Bonjour). The photo library permission is requested only if the user adds a "device videos" source; nothing is copied or uploaded.
- The YouTube section uses the official embedded player and the official API with the user's own key; it is not an ad blocker and does not download videos.
- Privacy policy: https://github.com/jihemezes/kastideo/blob/main/docs/PRIVACY.md — contact: contact@kastideo.com
