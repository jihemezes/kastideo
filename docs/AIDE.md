# Aide de Kastideo

Kastideo est un lecteur multimédia qui réunit vos chaînes en direct, films et séries IPTV dans une interface simple et rapide. Kastideo ne fournit aucun contenu : vous ajoutez vos propres sources (abonnement Xtream Codes ou playlist M3U).

> Version 0.3.0 — nouveau moteur de lecture VLC : direct MPEG-TS, MKV, AVI, contrôles et mode cinéma.

## Premiers pas

1. Au premier lancement, cliquez sur **Ajouter une source**.
2. Choisissez le type de source : **Xtream Codes**, **Playlist (URL)** ou **Playlist (fichier)**.
3. Renseignez les informations demandées puis cliquez sur **Ajouter**.
4. Kastideo charge la liste des chaînes, films et séries, puis le guide TV.

## Les sources

### Xtream Codes

C'est le format le plus courant chez les fournisseurs IPTV. Il faut trois informations : l'adresse du **serveur** (par exemple `http://exemple.com:8080`), votre **identifiant** et votre **mot de passe**.

- Le bouton **Tester la connexion** vérifie vos identifiants et affiche l'état du compte, sa date d'expiration et le nombre de connexions simultanées autorisées.
- Le mot de passe est enregistré dans le **trousseau macOS**, jamais en clair sur le disque.
- Le guide TV du serveur est utilisé automatiquement.
- Les séries s'ouvrent sur une fiche avec leurs saisons et leurs épisodes.

### Playlist M3U / M3U8

- **Par URL** : collez l'adresse de la playlist fournie par votre fournisseur.
- Si l'adresse est de la forme `get.php?username=…&password=…` (le cas le plus courant chez les fournisseurs par abonnement), Kastideo la reconnaît et l'enregistre en **Xtream Codes** : le chargement est beaucoup plus rapide, le guide TV est inclus et le mot de passe est rangé dans le trousseau. Les sources de ce type déjà enregistrées sont converties automatiquement.
- **Par fichier** : choisissez un fichier `.m3u` ou `.m3u8` sur votre Mac. Kastideo garde l'autorisation d'y accéder pour pouvoir l'actualiser.
- Les catégories proviennent de l'attribut `group-title`, les logos de `tvg-logo` et l'association au guide TV de `tvg-id`.
- Kastideo classe automatiquement les entrées en Direct, Films ou Séries d'après leur adresse.

### Guide TV (XMLTV)

Chaque source peut avoir une adresse de guide TV au format XMLTV (`.xml` ou `.xml.gz`). Si vous la laissez vide, Kastideo utilise celle du serveur Xtream ou celle annoncée dans la playlist (`url-tvg`). Le guide est conservé de 6 h en arrière à 48 h en avant.

### Gérer les sources

Ouvrez **Kastideo > Réglages… (⌘,)**, onglet **Sources**, ou cliquez sur le bouton **Sources** de la barre d'outils.

- L'interrupteur active ou désactive une source sans la supprimer.
- Les boutons permettent d'actualiser, de modifier ou de supprimer une source.
- En cas d'erreur, le message s'affiche en rouge sous la source et un triangle orange apparaît dans la barre latérale.

## Naviguer

La fenêtre principale comporte trois colonnes :

- **Barre latérale** : Direct, Films, Séries, Favoris, Récents, puis les catégories de la section choisie et l'état de vos sources.
- **Liste** : les éléments de la section ou de la catégorie, avec le programme en cours pour les chaînes. Le champ **Rechercher** filtre la liste sans tenir compte des majuscules ni des accents.
- **Lecteur** : la vidéo, avec en dessous le programme en cours, sa progression et les programmes suivants.

Un clic droit sur un élément permet de l'ajouter aux favoris ou de copier l'adresse du flux.

## Lecture

Kastideo lit tous les contenus avec le moteur **VLC** : direct au format MPEG-TS (.ts), HLS (.m3u8), MP4, MKV, AVI…

- La lecture démarre dès que vous sélectionnez une chaîne, un film ou un épisode.
- Pendant l'ouverture, le logo et le nom de la chaîne s'affichent. Le badge **« Prête en x s »** indique ensuite le temps de démarrage (désactivable dans les réglages).
- Les contrôles apparaissent au survol de la vidéo : lecture / pause, recul de 10 s et avance de 30 s pour les films et épisodes, barre de progression, volume (jusqu'à 200 %) et mode cinéma.
- Un clic sur la vidéo met en pause ; un **double-clic** active le **mode cinéma** (vidéo en plein écran, colonnes masquées). **Échap** ou **⌘↩** pour en sortir.
- Pour les sources Xtream, le direct est lu au format MPEG-TS (.ts), comme le lecteur de référence Xtream ; si le flux échoue, Kastideo essaie automatiquement la variante .m3u8 (et inversement).

### Une seule connexion à la fois

La plupart des abonnements IPTV n'autorisent qu'**un flux simultané**. Kastideo ferme toujours le flux en cours avant d'ouvrir le suivant : vous pouvez zapper sans risque de dépasser votre limite. Si la lecture échoue, vérifiez qu'aucun autre appareil (TV, téléphone, Piboard…) ne regarde avec le même abonnement.

### Mémoire tampon

Dans **Réglages > Général > Lecture**, choisissez le compromis entre rapidité et stabilité :

- **Rapide** (par défaut) : 0,4 s de réserve, le zapping le plus court.
- **Équilibré** : 1 s.
- **Stable** : 3 s, pour les connexions ou les serveurs irréguliers (moins de coupures, démarrage plus lent).

## Favoris et récents

- Ajoutez un favori avec l'étoile du panneau d'informations, le clic droit ou **⌘D**.
- La section **Récents** garde les 60 derniers contenus regardés. Vous pouvez l'effacer dans les réglages, onglet **Général**.

## Raccourcis clavier

- **⌘1 à ⌘5** : Direct, Films, Séries, Favoris, Récents
- **⌘↑ / ⌘↓** : élément précédent / suivant (zapping)
- **⌘K** : lecture / pause
- **⌘[ / ⌘]** : reculer de 10 s / avancer de 30 s (films et épisodes)
- **⌘↩** ou double-clic sur la vidéo : mode cinéma (Échap pour sortir)
- **⌘.** : arrêter la lecture
- **⌘D** : ajouter ou retirer des favoris
- **⌘R** : actualiser toutes les sources
- **⌘,** : réglages et sources
- **⌘?** : cette aide

## Mises à jour

Kastideo se met à jour tout seul grâce à **Sparkle**, l'outil de référence des applications Mac distribuées hors App Store.

- Kastideo vérifie une fois par jour si une nouvelle version est disponible sur GitHub.
- Une fenêtre présente les nouveautés, puis propose **Installer la mise à jour**. Kastideo se ferme, s'installe et se relance.
- Vous pouvez vérifier à tout moment avec **Kastideo > Rechercher les mises à jour…**.
- Chaque mise à jour est signée : Kastideo refuse d'installer un fichier qui ne vient pas de son éditeur.

Dans **Réglages > Mises à jour** :

- **Rechercher automatiquement** : active ou désactive la vérification quotidienne.
- **Télécharger et installer automatiquement** : les mises à jour s'installent sans rien demander, à la fermeture de l'application.
- **Recevoir les versions de test (bêta)** : propose aussi les versions bêta, qui apportent les nouveautés plus tôt mais peuvent être moins stables. Désactivez l'option pour revenir aux versions stables à la prochaine mise à jour.

> Les versions 0.1.0 et antérieures ne savent pas se mettre à jour : installez la 0.2.0 une fois à la main, les suivantes arriveront toutes seules.

## Nouveautés

Après chaque mise à jour, la fenêtre **Nouveautés** résume les changements de la version installée. Vous pouvez la rouvrir avec **Aide > Nouveautés de cette version** et y consulter les versions précédentes.

## Réglages généraux

- **Apparence** : sombre (par défaut), clair ou comme le système.
- **Actualiser au démarrage** : recharge les sources dont la dernière actualisation date de plus de 6 heures.
- **Cache** : Kastideo garde une copie locale des listes et du guide TV pour démarrer instantanément. **Vider et recharger** efface cette copie et relance le chargement.

## Dépannage

Kastideo s'identifie auprès des serveurs comme le lecteur **VLC** : beaucoup de fournisseurs IPTV ne répondent qu'aux lecteurs qu'ils reconnaissent.

- **« Le serveur n'a pas répondu à temps »** : le serveur est surchargé ou indisponible. Réessayez plus tard ; si votre adresse est de type `get.php?username=…`, vérifiez qu'elle a bien été convertie en Xtream Codes (type affiché dans les réglages des sources).

- **« Identifiant ou mot de passe refusé »** : vérifiez vos identifiants avec **Tester la connexion**.
- **« Compte non actif »** : l'abonnement a expiré ou est suspendu chez votre fournisseur.
- **Aucun programme dans le guide** : la chaîne n'a pas d'identifiant de guide TV, ou le guide de votre source n'en contient pas pour elle.
- **« App Transport Security »** : ce message apparaissait en version 0.1.0 et 0.2.0 avec les sources en http://. Il est corrigé depuis la version 0.2.1.
- **Lecture impossible** : le serveur n'a pas fourni le flux. Vérifiez qu'aucun autre appareil n'utilise votre abonnement (une seule connexion autorisée), puis cliquez sur **Réessayer**. Essayez aussi la mémoire tampon **Stable**.

## Confidentialité

Kastideo fonctionne dans le bac à sable de macOS. Il n'accède qu'au réseau et aux fichiers que vous choisissez. Vos mots de passe restent dans le trousseau. Aucune donnée n'est envoyée ailleurs qu'à vos propres sources.

## Licences

Kastideo utilise **VLCKit** (moteur de VLC, © VideoLAN, licence LGPL 2.1 ou ultérieure, https://www.videolan.org/vlc/libvlc.html) et **Sparkle** (licence MIT, https://sparkle-project.org). VLCKit est intégré sous forme de bibliothèque dynamique non modifiée.
