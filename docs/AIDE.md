# Aide de Kastideo

Kastideo est un lecteur multimédia qui réunit vos chaînes en direct, films et séries IPTV dans une interface simple et rapide. Kastideo ne fournit aucun contenu : vous ajoutez vos propres sources (abonnement Xtream Codes ou playlist M3U).

> Version 0.2.1 — mises à jour automatiques, canal bêta, fenêtre Nouveautés ; sources http:// acceptées.

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

- La lecture démarre dès que vous sélectionnez une chaîne ou un film.
- Les contrôles du lecteur apparaissent au survol : pause, volume, plein écran, image dans l'image.
- Pour les sources Xtream, les chaînes en direct sont lues au format HLS (`.m3u8`).
- Si un flux `.ts` échoue, Kastideo essaie automatiquement sa version `.m3u8`.

> Le lecteur natif d'Apple lit le HLS (.m3u8), le MP4 et le MOV. Certains films au format MKV ou AVI ne sont pas encore lisibles : un moteur de lecture étendu est prévu dans une prochaine version.

## Favoris et récents

- Ajoutez un favori avec l'étoile du panneau d'informations, le clic droit ou **⌘D**.
- La section **Récents** garde les 60 derniers contenus regardés. Vous pouvez l'effacer dans les réglages, onglet **Général**.

## Raccourcis clavier

- **⌘1 à ⌘5** : Direct, Films, Séries, Favoris, Récents
- **⌘↑ / ⌘↓** : élément précédent / suivant (zapping)
- **⌘K** : lecture / pause
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

- **« Identifiant ou mot de passe refusé »** : vérifiez vos identifiants avec **Tester la connexion**.
- **« Compte non actif »** : l'abonnement a expiré ou est suspendu chez votre fournisseur.
- **Aucun programme dans le guide** : la chaîne n'a pas d'identifiant de guide TV, ou le guide de votre source n'en contient pas pour elle.
- **« App Transport Security »** : ce message apparaissait en version 0.1.0 et 0.2.0 avec les sources en http://. Il est corrigé depuis la version 0.2.1.
- **Lecture impossible** : le format du flux n'est pas pris en charge par le lecteur natif, ou le serveur ne répond pas. Essayez **Réessayer**, puis une autre chaîne.

## Confidentialité

Kastideo fonctionne dans le bac à sable de macOS. Il n'accède qu'au réseau et aux fichiers que vous choisissez. Vos mots de passe restent dans le trousseau. Aucune donnée n'est envoyée ailleurs qu'à vos propres sources.
