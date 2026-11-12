# Kastideo pour iPhone et iPad — journal des versions

Versions envoyées à TestFlight avec les tags `vX.Y.Z-iosN` (le numéro X.Y.Z est celui de la version de référence).

## [1.17.0-ios18] - 2026-11-12

- **Nouvel accueil**, dans l'esprit de la version de bureau : fond dégradé violet / magenta avec le gros logo flouté et transparent, titre et logo en haut, recherche, puis les grandes tuiles **Direct, Films, Séries, YouTube** et **Mes vidéos** (seulement si vous avez une galerie, un dossier ou un serveur) avec le nombre de contenus, et en dessous les petits boutons **Reprendre, Récents, Favoris, Guide TV, Enregistrements** (avec pastilles).
- **Reprendre, Récents, Favoris** : chacun ouvre une page en grille ; retrait par appui long ou **Sélectionner**, **Tout vider**, et **Annuler** juste après (le retrait d'un élément était impossible depuis l'accueil).
- **Barre du bas simplifiée** : plus de Direct / Films / Séries / YouTube (tout passe par l'accueil) ; **Accueil**, **Contenu** (sources, galerie, catégories, TMDB, YouTube, iCloud, sauvegarde), **Application** (lecture, MultiVue, enregistrements, replay, Cinéma, apparence, à propos) et **Aide**. Le bouton « Autre » disparaît.
- **Aide** intégrée : pages iPhone / iPad (dont iCloud) en tête, puis le guide complet, avec recherche. Les images du guide n'y sont pas encore affichées.

## [1.17.0-ios17] - 2026-11-12

- Correction de compilation de la synchronisation iCloud. Même contenu que 1.17.0-ios16.

## [1.17.0-ios16] - 2026-11-12

- **Synchronisation iCloud revue** : elle passe maintenant par un **dossier de votre iCloud Drive** (Réglages > iCloud > Dossier de synchronisation), le même que sur le Mac, au lieu du Trousseau iCloud. Les iPhone, iPad et Mac se synchronisent entre eux (sources, favoris, historique, catégories, réglages, reprise de lecture, fiches). Les **mots de passe** et la clé TMDB sont **chiffrés** par une phrase secrète (la même sur chaque appareil). Réglages d'affichage propres à chaque plateforme gardés séparément.
- Le moteur est partagé avec le Mac (`App/Sources/CloudSync.swift`).

## [1.17.0-ios15] - 2026-11-12

- **Synchronisation iCloud** (Réglages > iCloud, désactivée par défaut) : retrouvez sur tous vos iPhone et iPad vos **sources** (Xtream, M3U par adresse, Jellyfin, Emby, Plex), **favoris**, **historique**, **catégories** (ordre, masquages, renommages) et **réglages d'affichage**, la **reprise de lecture** (positions et contenus vus), les **fiches corrigées** et la **clé TMDB**, et — au choix — les **mots de passe des sources**.
- Passe par le Trousseau iCloud (chiffré de bout en bout, sans capacité iCloud à activer) : il doit être activé sur chaque appareil. La modification la plus récente l'emporte ; première synchronisation : les listes sont réunies. Choix des éléments, « Synchroniser maintenant », date de dernière synchronisation, effacement des données iCloud.
- Dossiers, fichiers M3U et galerie restent propres à chaque appareil. Synchro automatique toutes les 30 secondes, au retour dans l'app et à sa mise en arrière-plan. Le Mac suivra dans une prochaine version.

## [1.17.0-ios14] - 2026-11-12

- Correction de compilation (accessibilité de `SourceKind.isLocalFiles`). Même contenu que 1.17.0-ios13.

## [1.17.0-ios13] - 2026-11-12

- **Vidéos locales** : nouvelle source « Galerie de l'iPhone » (Réglages > Ajouter les vidéos de la galerie, ou Ajouter une source). Toutes les vidéos ou certains albums ; elles apparaissent dans Films sous « Mes vidéos » avec leur miniature, triées par date de prise de vue. Un film nommé correctement (titre exact) reçoit une fiche TMDB, les vidéos de la caméra n'en cherchent pas.
- **Accès limité** respecté (seules les photos et vidéos autorisées apparaissent, bouton « Choisir d'autres vidéos… »), accès refusé expliqué avec raccourci vers les réglages de l'iPhone. Vidéos iCloud téléchargées avant la lecture ; ralentis convertis pour la lecture. Réglage « Actualiser à l'ouverture de l'app ».
- Les fiches TMDB des dossiers de vidéos fonctionnent maintenant aussi sur iPhone / iPad.
- Core : nouveau type de source `gallery` (Mac et Windows/Linux ne le proposent pas).

## [1.17.0-ios12] - 2026-11-12

- **Fiches TMDB** (comme sur Mac) : la fiche d'un film ou d'une série affiche l'affiche HD, le titre traduit, le résumé, les genres, la note, la durée, les réalisateurs, la **distribution avec photos** et la bande-annonce. Réglages > Fiches des films et séries : clé TMDB (facultative, vérifiée à l'enregistrement).
- **Corriger la fiche…** (fiche d'un film ou d'une série) : numéro ou adresse TMDB, recherche par titre, ou titre / année / affiche / résumé saisis à la main ; retirer la correction ; liste des fiches corrigées dans Réglages (elles voyagent dans la sauvegarde et se relisent à l'importation).
- **Tendances de la semaine (TMDB)** dans le bandeau « à la une » de Films et Séries : les titres en tendance qui sont dans votre catalogue (réglable dans Affichage Cinéma).
- La logique des fiches est partagée avec le Mac (`App/Sources/MediaInfo.swift` ; les vues Mac sont dans `Views/MediaInfoViews.swift`).

## [1.17.0-ios11] - 2026-11-12

- **Modifier une source** : Réglages > Sources, toucher une source (ou balayer > Modifier) — nom, adresse, identifiants (mot de passe ou jeton vide = conservé), guide TV, dossiers ; test de connexion Xtream ; tous les types (Xtream, M3U, Jellyfin, Emby, Plex, dossiers, fichier M3U).

## [1.17.0-ios10] - 2026-11-12

- **MultiVue** (iPhone et iPad) : 2 à 4 chaînes en même temps, une source réservée par écran, dispositions côte à côte / empilé / grille / une grande + vignettes déplaçables (accrochées aux coins, taille réglable), son sur l'écran actif, choix de chaîne par favoris, récents et catégories de la source. Boutons dans Direct et dans le lecteur ; Réglages > MultiVue : connexions de chaque abonnement.
- La logique de la MultiVue est partagée avec le Mac (`App/Sources/MultiViewModel.swift`, déplacée hors de `MultiView.swift`).

## [1.17.0-ios9] - 2026-11-11

- **Téléchargements en file d'attente** : un seul téléchargement à la fois (une série ou une saison s'enchaîne épisode après épisode), au lieu de tous en même temps qui coupaient la connexion unique de l'abonnement. Les suivants affichent « En attente ».

## [1.17.0-ios8] - 2026-11-11

- **YouTube** : onglet (et tuile de l'Accueil) avec chaînes suivies (liens, @pseudo, flux RSS), recherche avec votre clé API Google, liens de vidéos et de playlists, « À regarder plus tard », favoris, historique, reprise de lecture, import Google Takeout. Lecteur officiel de YouTube (mode confidentialité avancée) en plein écran. Réglages > YouTube : clé API, enchaînement, répétition, sans le son.
- Le code YouTube est maintenant partagé avec le Mac (`App/Sources/YouTube.swift`).

## [1.17.0-ios7] - 2026-11-11

- Correction de compilation (nom des enregistrements). Même contenu que 1.17.0-ios6.

## [1.17.0-ios6] - 2026-11-11

- **Enregistrer le direct** : bouton rond rouge du lecteur (arrêt automatique réglable) ; fichiers .ts dans Fichiers > Kastideo > Enregistrements (lecture, partage, suppression).
- **Téléchargements** de films et d'épisodes (fiche, « Télécharger la saison », appui long sur un épisode) : continuent application fermée, pause / reprise, notification à la fin ; dossier Fichiers > Kastideo > Téléchargements.
- **Direct en différé** : pause du direct, −10 s / +30 s, ligne de temps, vitesse de rattrapage, « Retour au direct » ; réglages de durée et de vitesse.
- **Alertes de programmes** : mot-clé, thème sur les chaînes favorites, « Me prévenir au début » ; notifications locales programmées à l'avance (48 h), reçues application fermée ; un toucher ouvre la chaîne.
- **Mes vidéos** : ajout de serveurs Jellyfin, Emby, Plex et de dossiers (iPhone, iCloud Drive, clé USB, NAS) ; sélecteur Tout / IPTV / Mes vidéos dans Films et Séries.
- Le dossier de l'application est visible dans l'app Fichiers.

## [1.17.0-ios5] - 2026-11-11

- **Gérer les catégories** (Réglages) : ordre par glisser-déposer, masquer, renommer, masquer par mot-clé, tri A→Z, réinitialiser ; **Pays et langues** pour l'affichage Cinéma.
- **Ordre des chaînes** d'une catégorie : Direct en liste > catégorie > « Réordonner les chaînes… » (glisser, A→Z, par numéro).
- **Modifier une chaîne** (appui long) : nom, numéro, logo (adresse ou photo), thème, chaîne du guide TV.
- **Apparence** : couleur d'accent, taille des affiches, densité des listes, affichage par défaut de Direct, Films et Séries.
- **Départ** : onglet au lancement, page de départ de Direct, Films et Séries.
- **Abonnements** : choix de la source affichée, fusion des doublons entre comptes, diagnostic d'une source.

## [1.17.0-ios4] - 2026-11-11

- **Direct** : le bouton en haut à gauche change l'affichage — Liste, **Cinéma** (bandeau « à la une », rangées « en ce moment » par thème, « À revoir », récents, favoris, rangées par catégorie), **Thèmes** (en ce moment, ce soir, toutes les chaînes, disciplines du sport) et **Guide TV** (jour et heure au choix, programme en cours et suivant, fiche du programme).
- **Replay** des chaînes à archive (↺) : « Revoir » depuis la fiche d'un programme ou par appui long, « Retour au direct » dans le lecteur, retour automatique à la fin. Réglages > Replay : jours passés, correction de l'heure.
- **Films et Séries** : affichage Cinéma (bandeau qui défile, reprise, récents, favoris, rangées par catégorie, filtre par pays) ou Grille. Réglages > Affichage Cinéma.
- Appui long sur une chaîne : favori, thème de la chaîne, version (qualité), replay.

## [1.17.0-ios3] - 2026-11-10

- Envoi à TestFlight : compilation avec Xcode 26 (SDK iOS 26), désormais exigé par Apple. Même contenu que 1.17.0-ios1.

## [1.17.0-ios2] - 2026-11-10

- Correction de compilation (document de configuration). Même contenu que 1.17.0-ios1.

## [1.17.0-ios1] - 2026-11-09

- **Première version iPhone et iPad (iOS 17 ou plus récent), via TestFlight.** Application native SwiftUI avec le même moteur de lecture VLC que le Mac : accueil (reprendre la lecture, favoris, récents), direct avec programme en cours, films et séries avec fiches, saisons et épisodes, lecteur plein écran (pistes audio, sous-titres, déplacement), mini-lecteur, son en arrière-plan, AirPlay, import et export de la configuration (même fichier que sur les autres versions), avertissement légal, journal de lecture partageable.
- Pas encore : enregistrement, guide en grille, thèmes, MultiVue, image dans l'image, YouTube, Cast. Apple TV viendra ensuite.
