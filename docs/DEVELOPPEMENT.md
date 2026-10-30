# Kastideo — notes de développement

Ce document s'adresse à la maintenance du projet (le README présente l'application aux utilisateurs).

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
├── docs/help/aide-fr.md, aide-en.md   Aide intégrée (source unique Mac + Windows/Linux, voir ci-dessous)
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

## Windows et Linux (préversion)

La version Windows / Linux (Flutter + moteur mpv) est en cours dans le dossier `desktop/`. Ses préversions sont publiées avec les tags `vX.Y.Z-desktopN` (workflow `desktop.yml`), sans toucher aux versions Mac ni aux mises à jour Sparkle.

Construction locale de la version Windows / Linux : voir [desktop/README.md](../desktop/README.md).

## L'aide intégrée

L'aide est un seul jeu de fichiers, partagé par l'application Mac et la version Windows / Linux :

- `docs/help/aide-fr.md` et `aide-en.md` : une rubrique par `# Titre`, une page par `## Titre {#identifiant}` ;
- `<!--mac-->…<!--/mac-->` et `<!--pc-->…<!--/pc-->` gardent un bloc pour une seule plateforme (aussi possible au milieu d'une ligne) ;
- `[texte](help:identifiant)` renvoie à une autre page, `![texte](img:nom)` insère le schéma `docs/help/img/help-<nom>-fr.png` / `-en.png` ;
- après une modification, lancer `scripts/sync-help.sh` (copie vers `desktop/assets/help`), puis les tests : `KastideoCoreTests` et `desktop/test/help_test.dart` vérifient que tous les liens internes existent et que les deux copies sont identiques.
