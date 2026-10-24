# Kastideo pour Windows et Linux

> Aperçu 1 (maquette) — version 1.1.7-desktop1. Cette préversion reprend l'écran d'accueil, le direct en interface Classique et le lecteur de la version Mac. Les autres fonctions arrivent par étapes.

## Ce que contient cet aperçu

- **Accueil** : recherche globale (chaînes, films, séries), trois grands accès Direct, Films et Séries avec leur nombre de contenus, accès rapides Favoris et Récents.
- **Direct (interface Classique)** : barre latérale avec Toutes les chaînes, Favoris, Récents et les catégories du fournisseur ; liste des chaînes avec recherche ; lecteur à droite.
- **Lecteur** (moteur mpv) : barre de contrôles compacte qui se cache seule, pastille de santé du flux (couleur, définition SD/HD/FHD/4K, coupures), volume, mode cinéma, plein écran, badge « Prête en x s ».
- **Relais de flux** : comme sur Mac, Kastideo ouvre lui-même une seule connexion chez le fournisseur et la transmet au lecteur ; la chaîne précédente est fermée avant d'ouvrir la suivante.
- **Chaînes refusées** : quand le fournisseur refuse une chaîne (HTTP 403/404), Kastideo n'insiste pas et l'explique.

## Ajouter une source

Bouton **Sources** (antenne, en haut à droite de l'accueil) > **Ajouter une source** :

- **Xtream Codes** : adresse du serveur, identifiant et mot de passe. Le mot de passe est rangé dans le coffre du système (Gestionnaire d'identification sous Windows, trousseau GNOME sous Linux).
- **Playlist M3U** : adresse de la playlist ou chemin d'un fichier. Une adresse « get.php?username=…&password=… » est reconnue et transformée en source Xtream, bien plus rapide.

Les sources sont actualisées au démarrage si leur dernière mise à jour date de plus de 6 heures.

## Raccourcis clavier

- **Ctrl+0** : accueil — **Ctrl+1** : direct
- **Espace** : lecture / pause — **M** : couper le son — **F** : favori
- **Ctrl+Entrée** ou double-clic sur l'image : mode cinéma — **Échap** : quitter le mode cinéma
- **F11** : plein écran
- **Ctrl+Alt+L** : journal de lecture

## Clic droit sur une chaîne

Regarder, ajouter aux favoris ou les retirer, copier le nom de la chaîne.

## Installation

- **Windows** : décompressez l'archive « windows-x64.zip » et lancez **kastideo.exe**. L'application n'est pas signée : Windows SmartScreen affiche « Windows a protégé votre ordinateur » ; cliquez sur **Informations complémentaires** puis **Exécuter quand même**.
- **Zorin OS 17 / Ubuntu 22.04** : paquet « ubuntu22.04_amd64.deb » (double-clic ou `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04** : paquet « ubuntu24.04_amd64.deb ».
- **Toute distribution, et Raspberry Pi (64 bits)** : fichier AppImage ; rendez-le exécutable (clic droit > Propriétés > Autoriser l'exécution, ou `chmod +x`) puis lancez-le.

## Prochaines étapes

1. **Interfaces** : Cinéma (carrousel, affiches, fiches TMDB), TV (zapping par numéro), Films et Séries.
2. **Fonctions avancées** : guide TV, enregistrement, différé, thèmes et alertes, MultiVue, correction des chaînes, catégories.
3. **Finitions** : installateur Windows, mises à jour intégrées, aide complète.

## Dépannage

- **Une chaîne ne démarre pas** : ouvrez le **Journal de lecture** (Ctrl+Alt+L). Les lignes « Relais : » donnent la réponse exacte du fournisseur (par exemple « HTTP 200 en 0,35 s » ou « HTTP 403 »).
- **Pas d'image sous Linux** : vérifiez que le paquet **libmpv** est installé (le paquet .deb l'installe automatiquement ; l'AppImage l'embarque).
- **VPN** : un VPN actif peut empêcher le fournisseur de servir les flux.
