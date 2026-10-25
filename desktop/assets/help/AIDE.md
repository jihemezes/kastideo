# Kastideo pour Windows et Linux

> Aperçu 2 — version 1.2.0-desktop2. Cette préversion reprend l'accueil, le direct en interface Classique, les films et les séries (interfaces Classique et Cinéma), le lecteur et les réglages de la version Mac. Les autres fonctions arrivent par étapes.

## Ce que contient cet aperçu

- **Accueil** : recherche globale (chaînes, films, séries), pavés Direct, Films et Séries, accès rapides Favoris et Récents, rangée « Reprendre la lecture ».
- **Direct (interface Classique)** : barre latérale (toutes les chaînes, favoris, récents, catégories), liste avec recherche, lecteur à droite.
- **Films et Séries** : deux interfaces au choix (Réglages > Apparence).
  - **Classique** : catégories, liste avec affiches, fiche à droite ; « Lire » affiche le lecteur à la place de la fiche.
  - **Cinéma** : bandeau « à la une » qui défile (flèches au survol), rangées Reprendre la lecture, Derniers ajouts, Regardés récemment, Favoris puis une rangée par catégorie (« Tout voir »), fiche en page entière.
- **Fiches** : affiche, résumé, année, durée, genres, note, réalisation, distribution, bande-annonce. Pour une série : saisons et épisodes, avec la progression de chacun.
- **Lecteur** (moteur mpv) : barre de contrôles qui se cache seule, pastille de santé du flux, volume, mode cinéma, plein écran. Pour les films et épisodes : mini-timeline (cliquez ou glissez ; l'heure visée s'affiche), −10 s / +30 s, **reprise de lecture** là où vous vous étiez arrêté (« Reprendre au début » pour repartir de zéro), bouton **Retour à la fiche**.
- **Relais de flux** : comme sur Mac, une seule connexion chez le fournisseur ; la chaîne précédente est fermée avant d'ouvrir la suivante.

## Ajouter une source

**Réglages** (roue dentée en haut à droite de l'accueil ou en bas de la barre latérale, ou Ctrl+,) > **Sources** > **Ajouter une source** :

- **Xtream Codes** : adresse du serveur, identifiant et mot de passe. Le mot de passe est rangé dans le coffre du système (Gestionnaire d'identification sous Windows, trousseau GNOME sous Linux).
- **Playlist M3U** : adresse de la playlist ou chemin d'un fichier. Une adresse « get.php?username=…&password=… » est reconnue et transformée en source Xtream, bien plus rapide.

Les sources sont actualisées au démarrage si leur dernière mise à jour date de plus de 6 heures.

## Réglages (Ctrl+,)

- **Général** : langue (système, français, anglais — au prochain lancement), reprise de lecture, relais de flux, actualisation au démarrage, effacer les récents, **clé TMDB**.
- **Apparence** : interface Classique ou Cinéma pour les films et pour les séries (l'interface Cinéma du direct et l'interface TV arrivent plus tard).
- **Sources** : ajouter, actualiser, supprimer.
- **Catégories** : pour le direct, les films ou les séries — glissez pour changer l'ordre, décochez pour masquer partout, double-clic ou crayon pour renommer, mots-clés pour masquer d'un coup toutes les catégories qui les contiennent (ex. « PAKISTAN »), Trier de A à Z, Rétablir. Clic droit sur une catégorie de la barre latérale : Masquer cette catégorie.
- **Sauvegarde** : **Exporter la configuration…** (sources, mots de passe si vous le souhaitez, favoris, récents, catégories, interfaces, clé TMDB) et **Importer une configuration…**. Le fichier est le même que celui de Kastideo pour Mac (Réglages > Général > Sauvegarde et transfert) : vous pouvez passer d'un ordinateur à l'autre dans les deux sens. Rien n'est supprimé à l'importation.

## Clé TMDB (facultative et gratuite)

Créez un compte sur themoviedb.org, puis **Paramètres > API** et demandez une clé (usage personnel). Copiez la « clé API » (v3) ou le « jeton d'accès en lecture » (v4) dans Réglages > Général, puis **Enregistrer** : Kastideo vérifie la clé. Les fiches deviennent plus complètes (affiches et fonds en haute définition, distribution avec photos, bandes-annonces).

## Raccourcis clavier

- **Ctrl+0** : accueil — **Ctrl+1** : direct — **Ctrl+2** : films — **Ctrl+3** : séries — **Ctrl+,** : réglages
- **Espace** : lecture / pause — **M** : couper le son — **F** : favori — **←** / **→** : −10 s / +30 s (films et épisodes)
- **Ctrl+Entrée** ou double-clic sur l'image : mode cinéma — **Échap** : quitter le mode cinéma
- **F11** : plein écran
- **Ctrl+Alt+L** : journal de lecture

## Clic droit sur une chaîne, un film ou une série

Regarder ou ouvrir la fiche, Lire (films), ajouter aux favoris ou les retirer, copier le nom.

## Installation

- **Windows** : décompressez l'archive « windows-x64.zip » et lancez **kastideo.exe**. L'application n'est pas signée : Windows SmartScreen affiche « Windows a protégé votre ordinateur » ; cliquez sur **Informations complémentaires** puis **Exécuter quand même**.
- **Zorin OS 17 / Ubuntu 22.04** : paquet « ubuntu22.04_amd64.deb » (double-clic ou `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04** : paquet « ubuntu24.04_amd64.deb ».
- **Toute distribution, et Raspberry Pi (64 bits)** : fichier AppImage ; rendez-le exécutable (clic droit > Propriétés > Autoriser l'exécution, ou `chmod +x`) puis lancez-le.

## Prochaines étapes

1. **Interfaces du direct** : Cinéma (rangées par thème) puis TV (zapping par numéro).
2. **Fonctions avancées** : guide TV, enregistrement, différé, thèmes et alertes, MultiVue, correction des chaînes, catégories.
3. **Finitions** : installateur Windows, mises à jour intégrées, aide complète.

## Dépannage

- **Une chaîne ne démarre pas** : ouvrez le **Journal de lecture** (Ctrl+Alt+L). Les lignes « Relais : » donnent la réponse exacte du fournisseur (par exemple « HTTP 200 en 0,35 s » ou « HTTP 403 »).
- **Pas d'image sous Linux** : vérifiez que le paquet **libmpv** est installé (le paquet .deb l'installe automatiquement ; l'AppImage l'embarque).
- **VPN** : un VPN actif peut empêcher le fournisseur de servir les flux.
- **Mots de passe sous Linux** : sans trousseau (GNOME Keyring ou KWallet), Kastideo garde les mots de passe dans ses préférences et le signale dans le journal.
