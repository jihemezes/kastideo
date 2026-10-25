# Kastideo pour Windows et Linux — journal des versions

Préversions publiées sur GitHub avec les tags `vX.Y.Z-desktopN` (le numéro X.Y.Z est celui de la version Mac de référence).

## [1.2.0-desktop3] - 2026-10-25

**Aperçu 3 — Direct en interface Cinéma, guide TV et thèmes.**

- **Guide TV** : guide du fournisseur (xmltv.php, url-tvg de la playlist ou adresse saisie) téléchargé en arrière-plan, analysé en flux (gzip reconnu), gardé sur le disque et rechargé quand il se termine bientôt ; **guide de secours** xmltvfr.fr pour les chaînes sans programme, rapprochées par leur nom (« |FR| TF1 FHD » → TF1). Réglages > Général > Guide TV ; état par source dans Réglages > Sources.
- **Direct en interface Cinéma** : bandeau « à la une » (programme en cours de vos favoris et récents, ou des grandes chaînes d'info, de sport et généralistes), rangées « en ce moment » par thème, Regardées récemment, Favoris, rangées **« Ce soir »** par thème, catégories ; vignettes 16/9 avec programme et avancement ; lecteur plein cadre avec **Retour** (ou Échap) qui arrête la chaîne.
- **Thèmes** : vue En ce moment / Ce soir / Chaînes, filtres par thème et par discipline sportive, chaînes regroupées par versions (FHD, HD, SD), fiche des programmes à venir, **thème de la chaîne** modifiable (clic droit).
- **Interface Classique du direct** : programme en cours sous chaque chaîne, entrée **Thèmes** dans la barre latérale.
- **Lecteur** : programme en cours dans la barre de contrôles (résumé en info-bulle).
- **Bandeau « à la une »** (films et séries) : réglages comme sur Mac — hauteur, rythme, **tendances de la semaine TMDB**, derniers ajouts, catégorie choisie.
- **Contenus adultes** masqués par défaut (Réglages > Général), comme sur Mac.
- Sauvegarde : guide TV des sources, contenus adultes et réglages du bandeau inclus.
- Rangées horizontales : défilement en faisant glisser à la souris.

## [1.2.0-desktop2] - 2026-10-25

**Aperçu 2 — Films et Séries.** (La construction 1.2.0-desktop1 a échoué sous Linux : d'anciens fichiers de la maquette restaient dans le dépôt.)

- **Films et Séries** en interface **Classique** (catégories, liste avec affiches, fiche à droite) ou **Cinéma** (bandeau « à la une » en carrousel, rangées Reprendre / Derniers ajouts / Récents / Favoris puis une par catégorie, grilles d'affiches, fiche en page entière) — au choix dans Réglages > Apparence.
- **Fiches** des films et séries : affiche, fond, résumé, année, durée, genres, note, réalisation, distribution, bande-annonce ; informations du fournisseur complétées par **TMDB** si une clé est saisie (Réglages > Général).
- **Séries** : saisons et épisodes (vignette, résumé, progression), lecture d'un clic.
- **Lecteur** pour les films et épisodes : mini-timeline avec l'heure visée, −10 s / +30 s (flèches ← →), durée ; **reprise de lecture** (« Reprise à 12:34 », Reprendre au début) ; bouton **Retour à la fiche**.
- **Réglages** complets (Ctrl+,) : Général (langue, reprise, relais, actualisation, TMDB), Apparence (interface par type), Sources, **Catégories** (ordre par glisser-déposer, masquage, renommage, mots-clés, tri A→Z), **Sauvegarde** (exporter / importer la configuration, compatible avec la version Mac 1.2.0).
- Accueil : rangée « Reprendre la lecture » ; raccourcis Ctrl+1 / Ctrl+2 / Ctrl+3 pour Direct / Films / Séries.
- Mots de passe : repli sur les préférences locales si le système n'a pas de coffre (certains Raspberry Pi).

## [1.1.7-desktop1] - 2026-10-24

**Aperçu 1 — maquette.** Première version de Kastideo pour Windows et Linux (Flutter, moteur de lecture mpv), pour valider la fidélité visuelle avec la version Mac.

- Écran d'accueil identique à la version Mac : dégradés, grand logo en filigrane, recherche globale, pavés Direct / Films / Séries, accès rapides, numéro de version.
- Direct en interface Classique : barre latérale (toutes les chaînes, favoris, récents, catégories), liste avec recherche, clic droit (favoris).
- Lecteur mpv : barre de contrôles compacte qui se cache seule, pastille de santé du flux et définition, volume, mode cinéma, plein écran, badge « Prête en x s », écran d'erreur avec Réessayer et Journal de lecture.
- Relais de flux local (une seule connexion au fournisseur, comme la version Mac 1.1.3) ; chaînes refusées par le fournisseur (HTTP 403/404) expliquées sans nouvel essai.
- Sources Xtream Codes et M3U (URL ou fichier ; les URL get.php deviennent des sources Xtream), mot de passe dans le coffre du système, cache local pour un démarrage rapide.
- Français et anglais (selon la langue du système), aide intégrée, journal de lecture (Ctrl+Alt+L).
- Paquets : Windows x64 (archive portable), .deb pour Ubuntu 22.04 / Zorin OS 17 et Ubuntu 24.04 / Zorin OS 18, AppImage x64 et ARM64 (Raspberry Pi).
