# Kastideo pour iPhone et iPad — journal des versions

Versions envoyées à TestFlight avec les tags `vX.Y.Z-iosN` (le numéro X.Y.Z est celui de la version de référence).

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
