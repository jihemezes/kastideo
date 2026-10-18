# Kastideo

Kastideo est un lecteur multimédia moderne pour réunir, organiser et lire vos contenus vidéo provenant de vos propres sources : playlists IPTV, chaînes en direct, séries, films et vidéos à la demande.

Kastideo n'est pas un fournisseur de contenus : c'est un lecteur. Vous ajoutez vos listes de lecture ou abonnements compatibles, et Kastideo les transforme en une expérience de télévision claire et agréable.

## Fonctions (version 0.1.0)

- Sources **Xtream Codes** (serveur, identifiant, mot de passe) et playlists **M3U / M3U8** (URL ou fichier)
- **Guide TV** XMLTV : programme en cours et à venir
- Navigation **Direct / Films / Séries / Favoris / Récents**, catégories, recherche
- Lecteur natif avec plein écran et image dans l'image
- Aide intégrée : voir [docs/AIDE.md](docs/AIDE.md)

## Installation

Téléchargez le fichier `Kastideo-X.Y.Z.dmg` de la dernière version dans les [Releases](https://github.com/jihemezes/kastideo/releases), ouvrez-le et glissez Kastideo dans **Applications**. L'application est signée et notarisée par Apple.

Configuration requise : macOS 14 Sonoma ou plus récent.

## Organisation du projet

```
kastideo/
├── project.yml                 Définition du projet Xcode (XcodeGen)
├── App/
│   ├── Sources/                Application SwiftUI macOS
│   ├── Resources/              Icône et couleurs (Assets.xcassets)
│   ├── Info.plist
│   └── Kastideo.entitlements   Bac à sable : réseau + fichiers choisis
├── Packages/KastideoCore/      Logique partagée (M3U, Xtream, XMLTV) + tests
│                               réutilisable pour iOS, iPadOS et tvOS
├── docs/AIDE.md                Aide intégrée à l'application
├── scripts/kastideo-release.sh Publication d'une version
├── .github/workflows/
│   ├── build.yml               Tests + compilation à chaque push
│   └── release.yml             DMG signé et notarisé à chaque tag vX.Y.Z
└── CHANGELOG.md                Notes de version (reprises dans les Releases)
```

## Publier une version

Chaque livraison arrive sous forme de zip `kastideo-vX.Y.Z.zip` dans `~/Downloads`. Depuis `~/Documents/kastideo` :

```bash
./scripts/kastideo-release.sh X.Y.Z "Descriptif"
```

Le push du tag `vX.Y.Z` déclenche le workflow **Release**. Il compile l'app, la signe avec le certificat Developer ID, crée le DMG, le fait notariser par Apple et publie la GitHub Release.

### Secrets GitHub nécessaires

| Secret | Contenu |
|---|---|
| `APPLE_CERTIFICATE` | Certificat « Developer ID Application » exporté en `.p12`, encodé en base64 |
| `APPLE_CERTIFICATE_PASSWORD` | Mot de passe du `.p12` |
| `APPLE_TEAM_ID` | Identifiant d'équipe Apple |
| `APPLE_API_KEY` | Contenu du fichier `AuthKey_XXXX.p8` (App Store Connect) |
| `APPLE_API_KEY_ID` | Identifiant de la clé API |
| `APPLE_API_ISSUER_ID` | Identifiant d'émetteur (Issuer ID) |

## Développer en local (facultatif)

Il faut Xcode 16 et XcodeGen :

```bash
brew install xcodegen
cd ~/Documents/kastideo
xcodegen generate
open Kastideo.xcodeproj
```

Dans Xcode, choisissez votre équipe dans **Signing & Capabilities** pour lancer l'app. Les tests du module partagé se lancent avec `swift test --package-path Packages/KastideoCore`.

Le fichier `Kastideo.xcodeproj` est généré : il n'est pas versionné.
