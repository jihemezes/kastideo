# Kastideo pour Windows et Linux

> Aperçu 3 — version 1.2.0-desktop3. Cette préversion reprend l'accueil, le direct (interfaces Classique et Cinéma, guide TV, thèmes), les films et les séries (interfaces Classique et Cinéma), le lecteur et les réglages de la version Mac. Les autres fonctions arrivent par étapes.

## Ce que contient cet aperçu

- **Accueil** : recherche globale (chaînes, films, séries), pavés Direct, Films et Séries, accès rapides Favoris et Récents, rangée « Reprendre la lecture ».
- **Direct** : deux interfaces au choix (Réglages > Apparence).
  - **Classique** : barre latérale (toutes les chaînes, favoris, récents, **thèmes**, catégories), liste avec recherche et **programme en cours** (titre, heure, barre d'avancement), lecteur à droite.
  - **Cinéma** : bandeau « à la une » avec le programme en cours de vos chaînes favorites et récentes (à défaut, des grandes chaînes d'info, de sport et généralistes), rangées **« Sport en ce moment »**, « Info en direct », « Films en cours »… (une version par chaîne), Regardées récemment, Favoris, rangées **« Ce soir »** par thème (films, sport, séries, documentaires…) puis une rangée par catégorie. Un clic sur une chaîne l'ouvre en plein cadre ; **Retour** (ou Échap) arrête la chaîne et revient aux rangées.
- **Thèmes** (barre latérale du direct, ou « Tout voir » d'une rangée) : **En ce moment**, **Ce soir** (programmes de 20 h à 23 h) ou **Chaînes**, filtrés par thème (Sport, Info, Films, Jeunesse, Documentaires…) et, pour le sport, par discipline (football, rugby, tennis…). Les chaînes sans programme dans le guide restent proposées quand leur nom suffit à les classer. Un programme à venir ouvre sa fiche (résumé, horaires) avec « Regarder la chaîne ». Clic droit : version de la chaîne (FHD, HD, SD), **thème de la chaîne** (pour corriger le classement automatique), favoris.
- **Guide TV** : guide du fournisseur (XMLTV) chargé en arrière-plan et gardé sur le disque, complété par un **guide de secours** (xmltvfr.fr) pour les chaînes sans programme. Le programme en cours apparaît aussi dans la barre du lecteur.
- **Films et Séries** : deux interfaces au choix (Réglages > Apparence).
  - **Classique** : catégories, liste avec affiches, fiche à droite ; « Lire » affiche le lecteur à la place de la fiche.
  - **Cinéma** : bandeau « à la une » qui défile (flèches au survol ; tendances de la semaine sur TMDB, derniers ajouts, sélection d'une catégorie), rangées Reprendre la lecture, Derniers ajouts, Regardés récemment, Favoris puis une rangée par catégorie (« Tout voir »), fiche en page entière.
- **Fiches** : affiche, résumé, année, durée, genres, note, réalisation, distribution, bande-annonce. Pour une série : saisons et épisodes, avec la progression de chacun.
- **Lecteur** (moteur mpv) : barre de contrôles qui se cache seule, pastille de santé du flux, volume, mode cinéma, plein écran. Pour les films et épisodes : mini-timeline (cliquez ou glissez ; l'heure visée s'affiche), −10 s / +30 s, **reprise de lecture** là où vous vous étiez arrêté (« Reprendre au début » pour repartir de zéro), bouton **Retour à la fiche**.
- **Relais de flux** : comme sur Mac, une seule connexion chez le fournisseur ; la chaîne précédente est fermée avant d'ouvrir la suivante.

## Ajouter une source

**Réglages** (roue dentée en haut à droite de l'accueil ou en bas de la barre latérale, ou Ctrl+,) > **Sources** > **Ajouter une source** :

- **Xtream Codes** : adresse du serveur, identifiant et mot de passe. Le mot de passe est rangé dans le coffre du système (Gestionnaire d'identification sous Windows, trousseau GNOME sous Linux).
- **Playlist M3U** : adresse de la playlist ou chemin d'un fichier. Une adresse « get.php?username=…&password=… » est reconnue et transformée en source Xtream, bien plus rapide.

Les sources sont actualisées au démarrage si leur dernière mise à jour date de plus de 6 heures. Champ facultatif **Guide TV (XMLTV)** : adresse d'un autre guide que celui indiqué par le fournisseur.

## Réglages (Ctrl+,)

- **Général** : langue (système, français, anglais — au prochain lancement), reprise de lecture, relais de flux, actualisation au démarrage, effacer les récents ; **Guide TV** (nombre de chaînes avec programme, Actualiser le guide, **guide de secours** : activation, adresse ou choix parmi les guides xmltvfr.fr, état du chargement) ; **contenus adultes** (masqués par défaut) ; **clé TMDB**.
- **Apparence** : interface Classique ou Cinéma pour le direct, les films et les séries (l'interface TV arrive plus tard) ; **bandeau « à la une »** : afficher ou non, hauteur (compact, normal, grand), défilement (6 à 20 s), sources (tendances TMDB, derniers ajouts, catégorie choisie pour les films et pour les séries).
- **Sources** : ajouter, actualiser, supprimer ; état du guide TV de chaque source.
- **Catégories** : pour le direct, les films ou les séries — glissez pour changer l'ordre, décochez pour masquer partout, double-clic ou crayon pour renommer, mots-clés pour masquer d'un coup toutes les catégories qui les contiennent (ex. « PAKISTAN »), Trier de A à Z, Rétablir. Clic droit sur une catégorie de la barre latérale : Masquer cette catégorie.
- **Sauvegarde** : **Exporter la configuration…** (sources et leur guide TV, mots de passe si vous le souhaitez, favoris, récents, catégories, interfaces, contenus adultes, bandeau, clé TMDB) et **Importer une configuration…**. Le fichier est le même que celui de Kastideo pour Mac (Réglages > Général > Sauvegarde et transfert) : vous pouvez passer d'un ordinateur à l'autre dans les deux sens. Rien n'est supprimé à l'importation.

## Clé TMDB (facultative et gratuite)

Créez un compte sur themoviedb.org, puis **Paramètres > API** et demandez une clé (usage personnel). Copiez la « clé API » (v3) ou le « jeton d'accès en lecture » (v4) dans Réglages > Général, puis **Enregistrer** : Kastideo vérifie la clé. Les fiches deviennent plus complètes (affiches et fonds en haute définition, distribution avec photos, bandes-annonces).

## Raccourcis clavier

- **Ctrl+0** : accueil — **Ctrl+1** : direct — **Ctrl+2** : films — **Ctrl+3** : séries — **Ctrl+,** : réglages
- **Espace** : lecture / pause — **M** : couper le son — **F** : favori — **←** / **→** : −10 s / +30 s (films et épisodes)
- **Ctrl+Entrée** ou double-clic sur l'image : mode cinéma — **Échap** : quitter le mode cinéma, puis revenir aux rangées (direct en interface Cinéma, la chaîne s'arrête) ou à la fiche
- **F11** : plein écran
- **Ctrl+Alt+L** : journal de lecture

## Clic droit sur une chaîne, un film ou une série

Regarder ou ouvrir la fiche, Lire (films), ajouter aux favoris ou les retirer, thème de la chaîne (direct), copier le nom. Les rangées horizontales se font défiler à la molette avec Maj, au pavé tactile ou en les faisant glisser à la souris.

## Installation

- **Windows** : décompressez l'archive « windows-x64.zip » et lancez **kastideo.exe**. L'application n'est pas signée : Windows SmartScreen affiche « Windows a protégé votre ordinateur » ; cliquez sur **Informations complémentaires** puis **Exécuter quand même**.
- **Zorin OS 17 / Ubuntu 22.04** : paquet « ubuntu22.04_amd64.deb » (double-clic ou `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04** : paquet « ubuntu24.04_amd64.deb ».
- **Toute distribution, et Raspberry Pi (64 bits)** : fichier AppImage ; rendez-le exécutable (clic droit > Propriétés > Autoriser l'exécution, ou `chmod +x`) puis lancez-le.

## Prochaines étapes

1. **Interface TV** du direct (zapping par numéro).
2. **Fonctions avancées** : grille du guide TV, enregistrement, différé, alertes de programme, MultiVue, correction des chaînes.
3. **Finitions** : installateur Windows, mises à jour intégrées, aide complète.

## Dépannage

- **Une chaîne ne démarre pas** : ouvrez le **Journal de lecture** (Ctrl+Alt+L). Les lignes « Relais : » donnent la réponse exacte du fournisseur (par exemple « HTTP 200 en 0,35 s » ou « HTTP 403 »).
- **Pas d'image sous Linux** : vérifiez que le paquet **libmpv** est installé (le paquet .deb l'installe automatiquement ; l'AppImage l'embarque).
- **VPN** : un VPN actif peut empêcher le fournisseur de servir les flux.
- **Pas de programme dans le guide** : Réglages > Sources indique l'état du guide de chaque source (« guide vide ou illisible », code HTTP…). Le guide de secours complète les chaînes françaises courantes ; Réglages > Général > Guide TV > **Actualiser le guide** relance tous les téléchargements.
- **Mots de passe sous Linux** : sans trousseau (GNOME Keyring ou KWallet), Kastideo garde les mots de passe dans ses préférences et le signale dans le journal.
