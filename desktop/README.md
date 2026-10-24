# Kastideo pour Windows et Linux

Version Flutter de Kastideo (moteur de lecture mpv via media_kit), en préversion. Le code de la version Mac (SwiftUI) est à la racine du dépôt.

- `lib/core/` : logique (sources Xtream / M3U, bibliothèque, relais de flux, lecteur, journal)
- `lib/ui/` : écrans (accueil, direct, lecteur, sources, aide, journal)
- `assets/help/` : aide intégrée (fr / en)
- `packaging/linux/` : fichiers du paquet .deb et de l'AppImage
- Construction et publication : `.github/workflows/desktop.yml` (tags `vX.Y.Z-desktopN`)

Construction locale sous Linux : `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libmpv-dev libsecret-1-dev`, puis `flutter build linux`.
