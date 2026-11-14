# Kastideo pour Apple TV — journal des versions

Versions envoyées à TestFlight avec les tags `vX.Y.Z-tvosN` (même app « fr.jmezes.kastideo » que l'iPhone, plateforme tvOS).

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
