# Kastideo pour Apple TV — journal des versions

Versions envoyées à TestFlight avec les tags `vX.Y.Z-tvosN` (même app « fr.jmezes.kastideo » que l'iPhone, plateforme tvOS).

## [1.19.1-tvos20] - 2026-11-15

- **Catégories** : cocher ou décocher une catégorie, « Tout afficher » et « Tout masquer » sont maintenant instantanés. Le recalcul du catalogue (long) se fait une seule fois, en quittant l'écran.

## [1.19.1-tvos19] - 2026-11-15

- **Correctif important** : quand on quittait le lecteur avec le bouton Menu, le flux restait ouvert chez le fournisseur ; avec un abonnement à une seule connexion, la chaîne demandée ensuite était refusée (« votre abonnement n'autorise peut-être qu'un seul flux »). Le flux est maintenant toujours fermé à la sortie du lecteur.
- Journal de lecture : les clics de la télécommande dans le lecteur et les choix de chaîne y sont notés, pour diagnostiquer le clic de la liste des chaînes.

## [1.19.1-tvos18] - 2026-11-15

- **Ordre des sources** : Réglages > Sources > (source) > Monter / Descendre. Les sources du haut s'affichent en premier dans Direct, Films et Séries.
- **Catégories** : nouveau bouton « Tout masquer » (puis on ne coche que celles que l'on veut), en plus de « Tout afficher ».
- **Bandeau de chargement** aussi pendant le recalcul de l'affichage (afficher les chaînes adultes, masquer ou afficher des catégories, changer l'ordre des sources) : l'application peut se figer quelques secondes, le bandeau l'explique.

## [1.19.1-tvos17] - 2026-11-15

- **Bandeau de chargement** : pendant la vérification et le téléchargement des chaînes, films et séries d'une source, un message s'affiche au premier plan pour indiquer que l'application travaille et peut sembler figée.

## [1.19.1-tvos16] - 2026-11-15

- **Journal de lecture sur Apple TV** : Réglages > Diagnostic > Journal de lecture (dernières lignes du moteur et de l'application, identifiants masqués), pour comprendre un échec de replay ou de chaîne.

## [1.19.1-tvos15] - 2026-11-15

- **Correctif** : l'aide Apple TV n'apparaissait plus (« Aide introuvable ») car ses fichiers n'étaient pas inclus dans l'application. Ils le sont maintenant.

## [1.19.1-tvos14] - 2026-11-15

- Image « Top Shelf » (à la une de l'écran d'accueil de l'Apple TV) fournie en 1x et 2x : supprime l'avertissement d'App Store Connect « ITMS-90471 : Top Shelf Image Wide 2x manquante ».

## [1.19.1-tvos13] - 2026-11-15

- **Choix de la langue** : Réglages > Langue de l'application (Système, français, anglais, espagnol, allemand, italien, portugais du Portugal ou du Brésil), appliqué tout de suite.
- **Aide dédiée à l'Apple TV** (onglet Aide, bouton Aide de l'accueil et entrée dans Réglages > À propos) : démarrage, ajout de sources, télécommande, direct, guide TV, films et séries, lecteur, réglages, dépannage. Disponible dans les six langues.
- YouTube n'est plus mentionné sur Apple TV (avertissement légal et aide), puisqu'il n'y est pas disponible.

## [1.19.0-tvos12] - 2026-11-15

- **Aide traduite** en espagnol, allemand, italien et portugais (une seule version portugaise pour le Portugal et le Brésil), avec les images de l'aide dans chaque langue. L'aide suit la langue de l'interface ; anglais si elle n'est pas gérée.
- Correction : quelques liens de l'aide pointaient vers la mauvaise page.
- Page d'aide « Langue » mise à jour pour les six langues.

## [1.18.0-tvos11] - 2026-11-15

- **Nouvelles langues** : espagnol, allemand, italien et portugais (Portugal et Brésil), en plus du français et de l'anglais. La langue suit celle de l'Apple TV ; anglais si elle n'est pas gérée.
- Avertissement légal traduit dans toutes les langues. L'aide reste en français ou en anglais ; les noms de genres TMDB restent en anglais.

## [1.17.0-tvos10] - 2026-11-15

- **Correctif** : l'accueil restait vide et le lecteur ne réagissait plus (ni menu au clic, ni liste de chaînes). Le nouveau style de bouton est simplifié et n'est plus utilisé que là où le fond est coloré (tuiles, petits boutons de l'accueil, programmes du guide, bandeau Cinéma) ; affiches et chaînes reviennent au style système.

## [1.17.0-tvos9] - 2026-11-14

- **Boutons corrigés** : la plaque translucide qui dépassait derrière les tuiles et les petits boutons a disparu ; chaque bouton a une seule forme arrondie, avec un liseré orange et un léger agrandissement au focus.
- **Trois affichages** comme sur Mac et iPad : **Classique** (grille), **Cinéma** (bandeau « à la une » + rangées Reprendre, Favoris, Récents, catégories) et, pour le Direct, **TV** (la dernière chaîne démarre en plein écran, ↑ / ↓ pour zapper). Choix par type de contenu : bouton « Affichage » en haut de Direct, Films et Séries, ou Réglages > Affichage.

## [1.17.0-tvos8] - 2026-11-14

- **Réception depuis l'iPhone / iPad** : Réglages > Ajouter depuis un téléphone accepte aussi « Envoyer vers l'Apple TV » (sources, favoris, catégories, réglages, clé TMDB) depuis l'app iPhone ou iPad, sans ressaisie.
- **Guide TV** : réglage « À l'ouverture du guide » (Maintenant / Dernière position : catégorie et chaîne mémorisées).
- **Vu / non vu** : pastille sur les affiches, « Marquer comme vu / non vu » sur les films, les épisodes (appui long) et les saisons.

## [1.17.0-tvos7] - 2026-11-14

- **Accueil refait comme sur iPad** : fond dégradé violet / magenta avec le logo, grandes tuiles Direct, Films, Séries (et Mes vidéos si une source existe) qui tiennent à l'écran, petits boutons Reprendre, Récents, Favoris (ouvrent une liste), Guide TV, Recherche, Réglages. Plus de bandeau ni de chaînes en boutons.
- **Mes vidéos** : sources Emby, Jellyfin et Plex (ajout sur la télévision ou depuis le téléphone) ; nouvel onglet Mes vidéos, avec choix du groupe.
- **Page web de configuration (téléphone)** : le formulaire s'adapte au type de source (Xtream, M3U, Jellyfin, Emby, Plex) et permet aussi de saisir la clé TMDB.
- **Avertissement légal** : lu page par page avec les boutons Précédent / Suivant, sans défilement : on ne peut plus se retrouver coincé.
- YouTube : non disponible sur Apple TV (tvOS n'a pas de navigateur intégré).

## [1.17.0-tvos6] - 2026-11-14

- **Sélecteurs lisibles** : les choix des Réglages (page de départ, zapping, mémoire tampon) s'ouvrent en liste verticale avec une coche ; la catégorie de Direct, Films, Séries et Guide TV se choisit via un bouton « Catégorie : … » qui ouvre une fenêtre (fini la rangée de petits boutons).
- **Recherche** : nouvel onglet pour chercher dans les chaînes, films et séries.
- **Favoris** : appui long sur une vignette, ou option du lecteur, pour ajouter / retirer des favoris.
- **Minuterie de veille** dans les options du lecteur (30, 60, 90, 120 min).

## [1.17.0-tvos5] - 2026-11-14

Retours de test sur Apple TV :

- **Zapping moins sensible** : le pavé tactile de la télécommande ne change plus de chaîne au moindre effleurement. Par défaut, ↑ / ↓ affichent une liste de chaînes et un clic valide ; un mode « Direct » (changement immédiat, avec anti-rebond) est disponible dans Réglages > Lecture. Les sauts −10 s / +30 s sont aussi espacés.
- **Sources** : chaque source s'ouvre pour être modifiée (nom, adresse, identifiant, mot de passe, guide TV), actualisée ou supprimée (avec confirmation).
- **Réglages complétés** : page de départ (appliquée à Direct, Films, Séries), catégories à afficher / masquer, chaînes adultes, mémoire tampon, reprise de lecture, décodage logiciel.
- **Accueil** : raccourcis vers Direct, Films, Séries, Guide TV et Réglages ; rangée « En ce moment » ; plus jamais vide (à défaut de dates d'ajout, les premiers contenus sont proposés).

## [1.17.0-tvos4] - 2026-11-14

- Correction : l'avertissement légal ne pouvait pas être accepté à la télécommande (bouton hors de portée sous le texte). Le bouton « J'accepte » est maintenant toujours visible sous le texte et sélectionné d'office.

## [1.17.0-tvos3] - 2026-11-14

- **Accueil** : bandeau à la une (reprise ou dernier ajout) et rangées Reprendre la lecture, chaînes favorites et récentes, tendances TMDB, derniers films et séries.
- **Guide TV en grille horaire** : fenêtre de 3 h (−3 h / Maintenant / +3 h), colonne des chaînes, programmes cliquables : regarder la chaîne ou revoir le programme (replay).
- **Lecteur** : appui central = options (pistes audio, sous-titres, vitesse 0,5–2×, dernière chaîne, aller à la chaîne n°, épisode suivant) ; l'épisode suivant démarre automatiquement.
- **Fiches** : résumé, genres, note, distribution via TMDB (clé dans Réglages).
- **Sources sans clavier** : Réglages > Ajouter depuis un téléphone — QR code, adresse locale et code à 4 chiffres ; formulaire Xtream / M3U sur le téléphone.

## [1.17.0-tvos2] - 2026-11-14

Première version Apple TV (tvOS 17) — tvos1 n'a pas compilé (API de diffusion absente de TVVLCKit, titre des sources) :

- **Direct, Films, Séries** : barre de catégories (Toutes, Favoris, Récents, catégories) et grille ; appui sur une chaîne = lecture, sur un film ou une série = fiche (résumé, lecture / reprise, favoris, saisons et épisodes).
- **Lecteur plein écran à la télécommande** : ↑ / ↓ changent de chaîne, ← / → reculent de 10 s / avancent de 30 s (films), lecture/pause, Menu pour quitter ; bandeau d'information (programme en cours avec progression, suivant, qualité du flux).
- **Guide TV** : une ligne par chaîne (programme en cours, progression, suivant) — la grille horaire viendra plus tard.
- **Réglages** : ajout d'une source Xtream Codes ou d'une liste M3U (adresse), suppression, actualisation ; avertissement légal.
- La synchronisation iCloud Drive n'existe pas sur Apple TV (pas d'accès aux fichiers iCloud) : les sources se saisissent sur la télévision.
