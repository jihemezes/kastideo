# Kastideo pour Apple TV — journal des versions

Versions envoyées à TestFlight avec les tags `vX.Y.Z-tvosN` (même app « fr.jmezes.kastideo » que l'iPhone, plateforme tvOS).

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
