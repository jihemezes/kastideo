# Kastideo

Kastideo est un lecteur multimédia moderne pour réunir, organiser et lire vos contenus vidéo provenant de vos propres sources : playlists IPTV, chaînes en direct, séries, films et vidéos à la demande.

Kastideo n'est pas un fournisseur de contenus : c'est un lecteur. Vous ajoutez vos listes de lecture ou abonnements compatibles, et Kastideo les transforme en une expérience de télévision claire et agréable.

## Fonctions (version 0.13.2)

- Sources **Xtream Codes** (serveur, identifiant, mot de passe) et playlists **M3U / M3U8** (URL ou fichier)
- **Guide TV** XMLTV : programme en cours et à venir
- **Écran d'accueil** (Direct, Films, Séries, accès rapides, recherche globale), suppression d'éléments dans les **Récents**, application en **français et anglais**
- **Guide TV en grille** (chaînes × heures), **reprise de lecture** des films et épisodes, **indicateur de téléchargement** permanent avec temps restant
- Navigation **Direct / Films / Séries / Favoris / Récents**, catégories, recherche
- Trois interfaces au choix par type de contenu : **Classique** (trois colonnes), **Cinéma** (affiches et rangées) et **TV** pour le direct (panneau de chaînes, zapping par numéro) ; couleur d'accent, densité et taille des vignettes réglables
- Moteur de lecture **VLC** (VLCKit) : direct MPEG-TS, HLS, MP4, MKV… ; mode cinéma, mesure du temps de démarrage
- **Enregistrement** du direct (immédiat ou programmé), **téléchargement** des films et séries (file d'attente, la nuit), conversion MP4, **direct en différé**
- **Mises à jour automatiques** (Sparkle) avec canal bêta facultatif
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
│   └── Kastideo.entitlements   Bac à sable : réseau, fichiers choisis, ~/Movies
├── Packages/KastideoCore/      Logique partagée (M3U, Xtream, XMLTV) + tests
│                               réutilisable pour iOS, iPadOS et tvOS
├── docs/AIDE.md                Aide intégrée à l'application
├── docs/branding/              Icône source en 1024 × 1024
├── scripts/kastideo-release.sh Publication d'une version
├── scripts/appcast.py          Mise à jour du flux Sparkle (utilisé par la CI)
├── .github/workflows/
│   ├── build.yml               Tests + compilation à la demande (Run workflow)
│   └── release.yml             Tests, DMG signé et notarisé, flux Sparkle à chaque tag vX.Y.Z
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
| `SPARKLE_PRIVATE_KEY` | Clé privée EdDSA Sparkle (`generate_keys --account kastideo -x fichier`) |

### Mises à jour (Sparkle)

Après chaque publication, le workflow signe le DMG avec la clé Sparkle et met à jour `appcast.xml` sur la branche **`appcast`** du dépôt. Cette branche est gérée automatiquement : ne la modifiez pas et ne la fusionnez pas dans `main`. L'application lit ce flux à l'adresse `https://raw.githubusercontent.com/jihemezes/kastideo/appcast/appcast.xml`.

Pour publier une **version de test**, utilisez un numéro `X.Y.Z-betaN` (par exemple `0.3.0-beta1`). Elle sera publiée en pré-version GitHub et proposée seulement aux utilisateurs qui ont activé le canal bêta.

La clé publique correspondante est inscrite dans `project.yml` (`SUPublicEDKey`). **Ne perdez jamais la clé privée** : sans elle, les copies installées n'accepteront plus de mise à jour.

## Licences

- [VLCKit](https://code.videolan.org/videolan/VLCKit) (VideoLAN) — LGPL 2.1+, intégré via [vlckit-spm](https://github.com/tylerjonesio/vlckit-spm) 3.6.0 (bibliothèque dynamique non modifiée)
- [Sparkle](https://sparkle-project.org) — MIT

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
