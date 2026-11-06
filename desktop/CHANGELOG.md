# Kastideo pour Windows et Linux — journal des versions

Préversions publiées sur GitHub avec les tags `vX.Y.Z-desktopN` (le numéro X.Y.Z est celui de la version Mac de référence).

## [1.14.0-android1] - 2026-11-06

- **Nettoyer la liste des enregistrements** : bouton corbeille au survol d'une ligne, menu clic droit, mode **Sélectionner** et **Vider la liste…**. La boîte de dialogue propose de supprimer aussi les fichiers (par défaut : seule la liste est nettoyée), affiche l'espace libéré, mémorise le choix et permet d'annuler le retrait. Avertissements en notification, ou en liste s'il y en a plusieurs.

## [1.14.0-desktop1] - 2026-11-06

- **Nettoyer la liste des enregistrements** : bouton corbeille au survol d'une ligne, menu clic droit, mode **Sélectionner** et **Vider la liste…**. La boîte de dialogue propose de supprimer aussi les fichiers (par défaut : seule la liste est nettoyée), affiche l'espace libéré, mémorise le choix et permet d'annuler le retrait. Avertissements en notification, ou en liste s'il y en a plusieurs.

## [1.13.2-android1] - 2026-11-03

- **Sélecteur de chaînes de la MultiVue** : Favoris, Récents et catégories de la source de l'écran (ordre, masquage, noms et arrangement respectés), programme en cours, clic = zapping sans fermer, double-clic = valider, chaînes déjà affichées grisées.

## [1.13.2-desktop1] - 2026-11-03

- **Sélecteur de chaînes de la MultiVue** : Favoris, Récents et catégories de la source de l'écran (ordre, masquage, noms et arrangement respectés), programme en cours, clic = zapping sans fermer, double-clic = valider, chaînes déjà affichées grisées.

## [1.13.1-android1] - 2026-11-03

- **Vrai PIP** dans la MultiVue (disposition « une grande ») : vignettes 16:9 flottantes, déplaçables et accrochées aux coins, double-clic pour échanger avec la grande, taille réglable.
- Bouton MultiVue dans la barre de lecture des chaînes en direct (ouvre la MultiVue avec la chaîne regardée).

## [1.13.1-desktop1] - 2026-11-03

- **Vrai PIP** dans la MultiVue (disposition « une grande ») : vignettes 16:9 flottantes, déplaçables et accrochées aux coins, double-clic pour échanger avec la grande, taille réglable.
- Bouton MultiVue dans la barre de lecture des chaînes en direct (ouvre la MultiVue avec la chaîne regardée).

## [1.13.0-android1] - 2026-11-03

- **MultiVue multi-abonnements** : une ligne de connexions par abonnement (Détecter pour les comptes Xtream), choix du nombre d'écrans (±), disposition (grille, une grande, côte à côte, empilé) et source réservée à chaque écran.

## [1.13.0-desktop1] - 2026-11-03

- Mêmes nouveautés qu'en 1.13.0-android1 (Windows et Linux).

## [1.12.1-desktop1] - 2026-11-03

- **Windows / Linux** : la fenêtre pouvait s'ouvrir à moitié hors écran, barre de titre inaccessible, surtout avec plusieurs écrans après une mise à jour. Kastideo mémorise maintenant la position de la fenêtre, vérifie au démarrage que sa barre de titre est visible sur un écran (écran débranché, mise à l'échelle changée…), sinon la recentre sur l'écran principal, et revérifie juste après l'affichage.

## [1.12.0-android1] - 2026-11-03

- **Mes vidéos** : filtre **Source** et pastille de la source sur les affiches, filtres **Pays**, **Langue**, **Qualité** (4K/HD) et **État** (Non vus, En cours, Vus, Favoris), tri par **note TMDB** et par **durée** ; filtres et tri mémorisés.
- **MultiVue multi-sources** : un nombre de connexions par source (abonnement ou liste publique), mélange de plusieurs sources, 4 flux au plus ; fonctionne aussi avec deux abonnements.
- **Image dans l'image** : seconde chaîne en miniature dans le lecteur (direct), échangeable en un clic.

## [1.12.0-desktop1] - 2026-11-03

- Mêmes nouveautés qu'en 1.12.0-android1 (Windows et Linux).

## [1.11.1-android1] - 2026-11-03

- **Réglages** : dans plusieurs sections (connexions simultanées, page de départ, Replay, YouTube), une valeur choisie dans une liste déroulante ou un interrupteur ne s'affichait qu'après avoir fermé puis rouvert la fenêtre. L'affichage suit maintenant le choix immédiatement (Windows, Linux, Android).

## [1.11.1-desktop1] - 2026-11-03

- Mêmes corrections qu'en 1.11.1-android1.
- **Linux** : « Ouvrir les fichiers .m3u et .m3u8 avec Kastideo » ne pouvait pas être activé (les outils du système échouaient dans l'AppImage). L'association est maintenant écrite directement dans `~/.config/mimeapps.list`, puis vérifiée ; un message indique la cause en cas d'échec. L'interrupteur répond aussitôt.

## [1.11.0-android1] - 2026-11-03

- **Corriger la fiche par code TMDB** (Windows, Linux, Android) : numéro ou adresse themoviedb.org, aperçu, puis « Utiliser cette fiche » ; recherche par titre avec le numéro TMDB affiché ; fiche personnalisée (titre, année, affiche, résumé) ; « Retirer la correction ». Disponible aussi pour les films et séries de l'abonnement IPTV.
- Liste des fiches corrigées dans Réglages, corrections incluses dans l'export/import de la configuration (format commun avec le Mac).
- Aide : nouvelle page « Corriger la fiche d'un film ou d'une série ».

## [1.11.0-desktop1] - 2026-11-03

- Mêmes nouveautés que 1.11.0-android1 pour Windows et Linux.

## [1.10.0-android1] - 2026-11-02

- **Menu Source** dans la barre latérale (Windows, Linux, Android) : choisir un compte IPTV sans désactiver les autres, avec les compteurs chaînes · films · séries ; choix retenu ; filtre Direct, Films, Séries, recherche et guide. Option « Fusionner les doublons » pour « Toutes les sources ».
- **Diagnostic de la source** (Réglages > Sources) : statut du compte, contenus renvoyés par le fournisseur et affichés, masqués ou fusionnés ; bouton Copier.
- **Vidéos personnelles** : affiches et résumés TMDB par titre exact (noms collés « TearsOfSteel » gérés), réglage « Chercher aussi les vidéos personnelles ».
- Aide : deux nouvelles pages.

## [1.10.0-desktop1] - 2026-11-02

- Mêmes nouveautés que 1.10.0-android1 pour Windows et Linux.

## [1.9.1-android2] - 2026-11-01

- **Android** : le coin inférieur droit de l'accueil affichait « Aperçu Windows / Linux ». Il indique maintenant « Android » (ou « Android TV »). Même correction dans Réglages > Mises à jour (texte propre à Android) et dans les réglages Cast (plus de mention d'ffmpeg, absent sur Android).

## [1.9.1-android1] - 2026-11-01

- **Aide** : la page « L'écran d'accueil » est réécrite pour correspondre à l'écran livré (en-tête avec Aide, Journal et Réglages, pavés dont Mes vidéos, accès rapides dont MultiVue et YouTube, bandeau de lecture, accueil à deux colonnes sur téléphone) avec un nouveau schéma ; la page « Bienvenue » est alignée.

## [1.9.1-desktop1] - 2026-11-01

- **Aide** : la page « L'écran d'accueil » est réécrite pour correspondre à l'écran livré (en-tête avec Aide, Journal et Réglages, pavés dont Mes vidéos, accès rapides dont MultiVue et YouTube, bandeau de lecture, accueil à deux colonnes sur téléphone) avec un nouveau schéma ; la page « Bienvenue » est alignée.

## [1.9.0-android3] - 2026-11-01

- **Mode Arranger** (Android, Windows, Linux) : dans une catégorie, le bouton ↑↓ à droite du titre permet de changer l'ordre des chaînes, films ou séries avec une grande poignée ⋮⋮ (la liste défile librement ailleurs, au doigt comme à la souris). Menu ⋮ : tout en haut / tout en bas, **déplacer vers une autre catégorie ou une liste personnelle**, remettre dans la catégorie d'origine. Tri A → Z, par numéro, retour à l'ordre du fournisseur.
- **Catégories** : poignée de déplacement agrandie dans Réglages > Catégories (glisser-déposer impossible au doigt jusqu'ici). « Rétablir » remet aussi à zéro les ordres de chaînes et les déplacements.
- L'ordre, les listes personnelles et les déplacements sont inclus dans l'export / import de configuration.
- Aide : nouvelle page « Arranger l'ordre des chaînes et des catégories ».

## [1.9.0-android2] - 2026-11-01

- **Android, Windows et Linux** : Réglages > Général > Page de départ : le choix d'une catégorie n'avait aucun effet au toucher sur tablette. Le menu déroulant est remplacé par une fenêtre de choix avec recherche et lignes à toucher.

## [1.9.0-android1] - 2026-10-31

**Première version pour Android et Android TV** (téléphones, tablettes, Google TV, Chromecast avec Google TV, Nvidia Shield…). Un seul APK par processeur, mêmes fonctions que la version Windows / Linux : Direct, Films, Séries, Guide TV, Replay, Thèmes, MultiVue, enregistrements, téléchargements, YouTube, Mes vidéos et serveurs (Jellyfin, Emby, Plex), aide intégrée.

- **Téléphone et tablette** : barre latérale en tiroir (menu ☰), liste et lecteur sur une colonne, chaîne en plein écran en paysage, appui long = menu contextuel, gestes dans le lecteur (double appui ±10 / +30 s ou pause, glisser pour le volume, la luminosité et la position), touche Retour d'Android.
- **Android TV** : sélection à la télécommande avec liseré visible, interface TV du direct par défaut (↑/↓ et Chaîne +/− pour zapper, chiffres, liste, bandeau), interface Cinéma pour les films et séries, touche Menu = menu contextuel, touches Lecture/Pause et Avance/Retour rapide, bannière sur l'écran d'accueil de la TV.
- **Cast** en mode direct (l'adresse du flux est envoyée au téléviseur, le direct passe en HLS) : pas de conversion ffmpeg sur Android.
- **Mises à jour intégrées** : l'APK de la nouvelle version est téléchargé puis ouvert par l'installateur d'Android.
- **Signature** : APK signés avec une clé unique, ce qui permet les mises à jour sans désinstaller. Guide : docs/ANDROID.md.
- Enregistrements et téléchargements dans le dossier de l'application (Android/data/fr.jmezes.kastideo/files/Movies). Pas de lancement à l'ouverture de session ni d'association des fichiers .m3u.
- Nouvelle page d'aide « Kastideo sur Android et Android TV ».

## [1.9.0-desktop1] - 2026-10-31

**Navigation au clavier et au doigt** (code partagé avec la version Android).

- Les éléments cliquables prennent le focus avec Tab et les flèches, avec un liseré visible ; Entrée ou Espace les active ; la touche Menu ouvre le menu contextuel.
- Mises en page qui s'adaptent aux fenêtres étroites (barre latérale en tiroir sous 900 px).
- Nouvelle page d'aide « Kastideo sur Android et Android TV ».

## [1.8.1-desktop1] - 2026-10-31

**Repli en décodage logiciel pour les chaînes qui se figent** (comme Kastideo 1.8.1 pour Mac).

- Réglages > Général > Lecture : repli automatique (activé par défaut), « Toujours décoder en logiciel », et bouton pour oublier les chaînes mémorisées.
- Clic droit sur un contenu : « Décodage logiciel (image figée) ». Le Journal de lecture explique chaque bascule.
- Détection fondée sur le compteur d'images de mpv et sur ses erreurs de décodeur matériel : non vérifiée sur du matériel réel, à confirmer à l'usage. Nouvelle page d'aide.

## [1.8.0-desktop1] - 2026-10-31

**Page de départ de Direct, Films et Séries** (comme Kastideo 1.8.0 pour Mac).

- Réglages > Général > Page de départ : pour Direct, Films et Séries, choisissez la liste complète, les Favoris, les Récents, la dernière catégorie consultée ou une catégorie précise. Elle s'applique à chaque ouverture de la section depuis une autre (accueil, guide TV…), y compris au lancement.
- Clic droit sur une catégorie de la barre latérale : « Définir comme catégorie de départ ». Nouvelle page d'aide.

## [1.7.10-desktop1] - 2026-10-31

**Texte sur la gratuité** (comme Kastideo 1.7.10 pour Mac) : la promesse qu'il « le restera » est retirée partout (Réglages > À propos, info-bulle du bouton Ko-fi, aide).

## [1.7.9-desktop1] - 2026-10-31

**Avertissement légal** (comme Kastideo 1.7.9 pour Mac).

- Au premier lancement et après chaque mise à jour, un avertissement en français ou en anglais s'affiche : « J'ai compris et j'accepte » ou « Quitter ». Il se relit dans Réglages > À propos > Avertissement légal et dans l'aide.

## [1.7.8-desktop1] - 2026-10-31

**Bouton Arrêt dans la barre de lecture** (comme Kastideo 1.7.8 pour Mac).

- Un bouton ■ à côté de lecture / pause (et **Ctrl+.**) arrête le flux sans quitter l'écran. La zone vidéo affiche « Aucune lecture » avec un bouton **Relancer** (et **Retour** dans le lecteur plein cadre).
- La position d'un film ou d'un épisode est mémorisée pour la reprise ; pendant une diffusion, l'arrêt ferme la diffusion et le téléviseur reprend son programme ; si la chaîne est en cours d'enregistrement, Kastideo demande confirmation.

## [1.7.0-desktop1] - 2026-10-30

**Diffuser sur un téléviseur (Cast)** (comme Kastideo 1.7.0 pour Mac).

- **Bouton Diffuser dans la barre de lecture** : chaîne en direct, film, série ou vidéo locale vers un **Chromecast, Google TV ou TV Android** du réseau (protocole Chromecast écrit pour Kastideo, recherche automatique ou par adresse IP). Reprise à la position atteinte ; pause, avance / recul, position, volume et sourdine de la barre agissent sur le téléviseur ; « Reprendre sur l'ordinateur » ramène la lecture.
- **ffmpeg** convertit la vidéo pour le téléviseur : fourni avec la version Windows et l'AppImage Linux (le .deb dépend du paquet ffmpeg). Réglages > Général > Cast : préparation (automatique ou toujours convertir), définition maximale, chemin de ffmpeg, téléviseurs ajoutés par adresse IP.
- **YouTube sur le téléviseur** : clic droit sur une vidéo > « Lire sur un téléviseur » (application YouTube du téléviseur par DIAL) ou ouverture dans le navigateur, au choix.
- Nouvelle page d'aide « Diffuser sur un téléviseur ». Testé contre un faux récepteur Chromecast, pas encore avec un vrai téléviseur.

## [1.6.1-desktop1] - 2026-10-30

**Correctif de la 1.6.0-desktop1** : fichiers d'aide renommés (aide-fr.md, aide-en.md) pour éviter une collision de noms sur les systèmes de fichiers qui ignorent la casse.

## [1.6.0-desktop1] - 2026-10-30

**Une aide refaite de A à Z** (comme Kastideo 1.6.0 pour Mac). Même contenu que sur Mac, partagé : sommaire par rubriques, **recherche** dans toutes les pages (extraits, mots surlignés), liens entre pages, pages précédente / suivante, schémas. **F1** ouvre l'aide à la page de l'écran affiché. Nouveaux pas-à-pas : **importer ses abonnements YouTube** (Google Takeout, avec un lien « Comment obtenir mon fichier ? » dans l'écran d'import), clé API Google, publicités et confidentialité, questions fréquentes.

## [1.5.1-desktop1] - 2026-10-30

**YouTube : plus pratique** (comme Kastideo 1.5.1 pour Mac). **À regarder plus tard** avec reprise là où vous vous êtes arrêté (barre d'avancement, retrait automatique une fois la vidéo vue) et **import des abonnements** d'un export Google Takeout (CSV/JSON) ou d'une liste de liens.

## [1.5.0-desktop1] - 2026-10-30

**YouTube dans Kastideo** (comme Kastideo 1.5.0 pour Mac). Section **YouTube** (barre latérale, accueil, Ctrl+9) : navigateur (chaînes suivies par flux RSS, recherche avec votre clé API Google gratuite, liens collés, favoris, historique), puis lecture avec le lecteur officiel en « mode confidentialité avancée » (youtube-nocookie.com) dans sa propre fenêtre (Edge/Chrome/Chromium en mode application, à défaut le navigateur par défaut) via une page locale. Ce n'est pas un bloqueur de publicités.

## [1.4.2-desktop1] - 2026-10-29

**Soutenir Kastideo (facultatif).** L'application est gratuite ; un bouton discret **Offrir un café** (Ko-fi) apparaît sur l'accueil et dans la fenêtre Nouveautés, avec un onglet **Réglages > À propos**. Une option permet de masquer les boutons de l'accueil et des Nouveautés.

## [1.4.0-desktop1] - 2026-10-29

**Replay : revoir un programme déjà diffusé** (comme Kastideo 1.4.0 pour Mac).

- Chaînes à replay détectées (icône ↺), programmes passés gardés dans le guide, jours précédents dans le menu de la date, **Revoir**, **Revoir depuis le début**, **Enregistrer ce replay**, clic droit > **Revoir (replay)…**, rangée **À revoir** en Cinéma, retour au direct à la fin.
- Heure du serveur lue automatiquement (fuseau, heure d'été européenne) et décalage manuel dans Réglages > Général > Replay.
- Tests : adresse d'archive, horloge du serveur, conservation du passé dans le guide.

## [1.3.4-desktop1] - 2026-10-28

**Guide TV : chiffres plus justes** (comme Kastideo 1.3.4 pour Mac).

- **Séparateurs de catégories ignorés** (« ♣♦♣----|FR| FRANCE FHD |FR|---♣♦♣ »…) : plus comptés « sans programme », plus proposés dans les listes par thème.
- Une version 4K / FHD / UHD sans programme propre reprend celui de l'autre version de la chaîne (déjà le cas à l'affichage, désormais aussi dans le comptage).
- **« Programme non disponible »** sous les chaînes sans programme dans les listes.
- **Journal « Guide TV »** : chaînes françaises comptées à part, avec exemples de chaînes françaises sans programme.

## [1.3.3-desktop1] - 2026-10-28

**Diagnostic** (comme Kastideo 1.3.3 pour Mac).

- **Journal par sujets** (Ctrl+Alt+L) : Guide TV, Lecture et relais, Sources et catalogues, Enregistrements, Fiches TMDB, Mises à jour, Affichage et divers. Filtre par sujet, recherche, erreurs et alertes seulement, **Copier l'affichage**.
- **Niveau de détail par sujet** (Normal, Détaillé, Débogage) et **journal conservé sur disque** (session en cours et précédente).
- **Guide TV détaillé** : adresse, réponse du fournisseur (code HTTP, taille, durée), programmes dans le document / dans les 48 h / gardés pour vos chaînes, exemples d'identifiants des deux côtés quand rien ne correspond, période couverte, couverture de vos chaînes (fournisseur, secours, aucune). Un refus HTTP ou une page d'erreur du fournisseur n'est plus silencieux.
- Réglages > Guide TV : boutons **Journal du guide** et **Recharger le guide**.

## [1.3.1-desktop1] - 2026-10-27

**Corrections des premiers essais avec un NAS et Emby** (comme Kastideo 1.3.1 pour Mac).

- **Tuile « Mes vidéos »** sur l'accueil (Ctrl+8), visible dès qu'une source Dossiers, Jellyfin, Emby ou Plex existe : à la une (reprendre, ajouts récents, films à voir), grilles Films / Séries / Vidéos avec filtres genre, année, non vus et tri, navigation par dossiers, choix de la source.
- **Films et Séries** : sélecteur **Tout / IPTV / Mes vidéos** au-dessus des catégories (IPTV seul par défaut) ; les catégories de vos vidéos ne sont pas masquées par le réglage des pays.
- **Mot de passe facultatif** (Jellyfin, Emby) et **jeton facultatif** (Plex).
- **Emby** : connexion corrigée (erreur HTTP 400), adresse copiée depuis le navigateur acceptée.
- **Diagnostic** : réponse exacte du serveur affichée en cas d'échec.
- Correction : le cache des sources n'était pas relu au démarrage (listes rechargées à chaque lancement).

## [1.3.0-desktop1] - 2026-10-26

**Nouvelles sources : vos vidéos et les serveurs de la maison** (comme Kastideo 1.3.0 pour Mac).

- **Dossiers (disque, clé USB, NAS)** : Réglages > Sources > **Ajouter une source** > **Dossiers**, puis **Ajouter un dossier…** ou un **chemin réseau** (`\\NAS\Vidéos` sous Windows, partage monté sous Linux). Films (« Titre (2020).mkv », « Titre.2020.1080p… »), séries (« Série S01E02 », « 1x02 », dossiers « Saison 1 ») regroupées par saison, et autres vidéos dans **Vidéos · nom du dossier**. Examen à chaque lancement puis toutes les 20 minutes ; un sous-dossier illisible (« System Volume Information » d'une clé USB) est ignoré.
- **Fiches TMDB automatiques** des films et séries des dossiers (avec une clé TMDB), et clic droit > **Corriger la fiche…**.
- **Sous-titres placés à côté** des vidéos chargés à la lecture.
- **Jellyfin et Emby** (identifiant et mot de passe ou clé d'API, bouton **Tester**) et **Plex** (**Se connecter avec Plex** ou jeton) : bibliothèques dans Films et Séries (« Films · nom du serveur »), fiches, saisons et épisodes du serveur, lecture directe.
- **Rechercher sur le réseau** : trouve les serveurs Jellyfin, Emby et Plex de la maison et remplit le formulaire.
- **Reprise et « vu » partagés dans les deux sens** avec les serveurs ; clic droit > **Marquer comme vu / non vu**, pastille **Vu** sur les affiches.
- Les boutons de téléchargement sont masqués pour les fichiers déjà sur l'ordinateur.
- Affiches de secours lisibles en thème clair.

## [1.2.2-desktop1] - 2026-10-25

**Corrections des retours de test (suite).**

- **Programmer un enregistrement depuis le direct** : clic droit sur une chaîne > **Programmer un enregistrement…**, ou bouton **Programmer…** de l'écran Enregistrements. Choix parmi les **prochains programmes du guide**, ou **plage horaire** manuelle (jour, début, fin, titre) pour une chaîne sans guide. **Répétition** : tous les jours, du lundi au vendredi ou chaque semaine (la prochaine occurrence est ajoutée seule ; bouton pour arrêter la répétition).
- **Récents** : mode **Modifier** comme sur Mac (cases à cocher, Tout sélectionner, Retirer la sélection, Tout effacer), et clic droit > **Retirer des récents**.
- **Gérer les catégories** : case **Tout sélectionner / désélectionner** et **recherche** ; la case ne concerne que les catégories trouvées (masquer tout un pays en deux clics). Même case sur Mac (1.2.2).
- Calendrier et sélecteur d'heure en français (éléments standard traduits).
- Correction : le jour du changement d'heure, « Ce soir » et les plages horaires après minuit étaient décalés d'une heure.

## [1.2.1-desktop1] - 2026-10-25

**Corrections des retours de test.**

- **Enregistrement (Windows)** : l'enregistrement restait vide (« le fournisseur n'a rien envoyé »). Il ne passe plus par le moteur vidéo : les octets du flux sont recopiés tels quels dans un fichier .ts — pour la chaîne regardée, depuis le relais (aucune seconde connexion au fournisseur) ; pour une autre chaîne, par un téléchargement direct qui se reconnecte si le flux est coupé. À la fin, le .ts est converti sans perte en MKV (format par défaut) ; en cas d'échec, le .ts est gardé. Le journal indique la réponse exacte du fournisseur.
- **Différé du direct** : passer la souris sur l'image affichait un différé qui grandissait alors que la chaîne était en direct. L'écart naturel du cache du moteur n'est plus compté comme du retard : le différé ne commence qu'avec une pause ou un retour en arrière.
- **Modifier une source** (Réglages > Sources, bouton crayon) : nom, serveur, identifiant, mot de passe, adresse de la playlist et guide TV. Les favoris, récents et corrections de chaînes sont gardés.
- **Bouton « œil »** pour afficher ou masquer le mot de passe d'une source et la clé TMDB.
- **Fiches en portugais** : avec une clé TMDB, les informations de TMDB (dans votre langue) passent toujours en premier. Un résumé du fournisseur dans une autre langue est replié (« Afficher le résumé (portugais) »), et masqué dans le bandeau et la liste des épisodes.
- **Pays et langues (interface Cinéma)** (Réglages > Apparence) : choisissez les pays repérés dans les noms de vos catégories (« FR| », « |PT| », « FRANCE »…) ; les derniers ajouts, les tendances, le bandeau « à la une » et les rangées par catégorie ne montrent plus que ceux-ci. Même réglage sur Mac (1.2.1), repris par la sauvegarde de la configuration.
- Le journal de lecture reste lisible en thème clair.

## [1.2.0-desktop8] - 2026-10-25

**Aperçu 7 — installateur Windows et mises à jour intégrées.**

- **Installateur Windows** (Kastideo-…-windows-x64-setup.exe) : installation pour vous seul sans droits administrateur (ou pour tous les utilisateurs), menu Démarrer, icône sur le bureau en option, désinstallation depuis les Paramètres de Windows. Options facultatives : ouvrir les fichiers .m3u / .m3u8 avec Kastideo, lancer Kastideo à l'ouverture de session. L'archive portable (zip) reste disponible.
- **Mises à jour intégrées** : Kastideo recherche les nouvelles pré-versions Windows / Linux sur GitHub au lancement puis toutes les 12 heures, et les propose en dehors du visionnage (bandeau en haut à droite). La fenêtre de mise à jour affiche les nouveautés ; **Installer et relancer** télécharge le bon fichier et l'installe selon votre installation : installateur silencieux (Windows), remplacement des fichiers (version portable), nouvelle AppImage, ou paquet .deb installé par apt (mot de passe demandé). « Ignorer cette version » et « Plus tard » sont possibles. Réglages > Général > **Mises à jour** : rechercher maintenant, recherche automatique, version installée.
- **Nouveautés** affichées au premier lancement après une mise à jour (journal des versions), et à tout moment depuis Réglages > Général > Mises à jour.
- **Lancer Kastideo à l'ouverture de session**, réduit dans la barre des tâches si vous le souhaitez (Windows et Linux) : utile pour les enregistrements programmés et les alertes.
- **Fichiers .m3u / .m3u8** (facultatif) : un double-clic sur une playlist propose de l'ajouter comme source ; si Kastideo est déjà ouvert, la fenêtre existante la reçoit.

## [1.2.0-desktop7] - 2026-10-25

**Aperçu 6 — MultiVue et personnalisation.**

- **MultiVue** : jusqu'à 4 chaînes en direct sur un même écran, le son suit la vignette active (bordure orange, touches 1 à 4). Dispositions au choix (automatique, grille 2 × 2, une grande et les autres en petit, côte à côte), double-clic pour passer une vignette en grand, **groupes mémorisés** (ex. « Multiplex foot ») rouverts en un clic, changer ou retirer une chaîne au survol, nouvel essai automatique si le flux coupe, plein écran. Ouverture depuis l'accueil, la barre latérale du direct, Ctrl+Alt+M ou clic droit > Ajouter à la MultiVue.
- **Connexions simultanées** (Réglages > Général > Lecture) : active la MultiVue (2 à 4), avec **Détecter** qui interroge les sources Xtream.
- **Apparence** : thème **sombre, clair ou comme le système**, **couleur d'accent** (8 choix), **densité des listes** (Classique) et **taille des vignettes** (Cinéma), appliqués tout de suite. Le lecteur, l'interface TV, la MultiVue, l'accueil, les fiches et le bandeau restent sombres, comme sur Mac.
- **Catégories** : clic droit dans la barre latérale pour renommer, placer en haut ou en bas, monter, descendre.
- **Notifications du système** (Windows et Linux) : alertes de programme, début et fin d'enregistrement, téléchargement terminé ou impossible ; un clic ramène Kastideo (désactivables dans Réglages > Général).
- **Aide complète** : sommaire, recherche avec surlignage, toutes les fonctions décrites.
- La sauvegarde de la configuration inclut l'apparence et le nombre de connexions.
- Linux : dépendance libnotify ajoutée (paquet .deb ; incluse dans l'AppImage).

## [1.2.0-desktop6] - 2026-10-25

**Aperçu 5 — différé, enregistrement, téléchargements, alertes, correction des chaînes.**

- **Différé du direct** : pause gardée sur le disque (cache de mpv, jusqu'à 1 h par défaut), barre de différé (retard, retour en arrière, rattrapage accéléré jusqu'au point choisi, vitesse ×1 à ×2, Rattraper, Retour au direct), −10 s / +30 s dans le différé, reprise automatique quand la durée maximale est atteinte.
- **Enregistrement du direct** : immédiat (bouton du lecteur, touche R, clic droit) ou programmé depuis le guide TV et les thèmes ; flux recopié sans perte en MKV (repli en TS) dans Vidéos/Kastideo ; la chaîne regardée est enregistrée par le lecteur, une autre par un second lecteur sans image ; marges avant / après ; conflits de connexion demandés avant de couper un enregistrement.
- **Téléchargements** des films et épisodes (saison entière) : file d'attente, reprise après coupure, « cette nuit », pause pendant la lecture, progression et temps restant en bas de la barre latérale.
- **Écran Enregistrements** (accueil, barre latérale) : en cours, téléchargements, programmés, fichiers du dossier lus dans le lecteur intégré.
- **Alertes de programme** : « M'alerter au début » et mots-clés (favoris ou toutes les chaînes, avance réglable), bannière avec Regarder.
- **Modifier la chaîne…** : nom, numéro, logo (adresse ou fichier) et chaîne du guide TV, par version de chaîne.
- **Réglages > Enregistrements** : dossier, format, marges, téléchargements, différé, alertes.
- Corrections : une actualisation qui renvoie une section vide (serveur qui hoquette) ne l'efface plus ; la barre de progression des films se met à jour en continu.

## [1.2.0-desktop5] - 2026-10-25

**Correctif — langue des fiches des films et séries.**

- Les fiches (résumés, genres, épisodes) s'affichaient en espagnol ou dans une autre langue : Kastideo n'indiquait pas sa langue au fournisseur, qui répondait alors dans sa langue par défaut. Les requêtes envoient maintenant la langue de l'interface (en-tête Accept-Language), comme la version Mac.
- Avec une clé TMDB : titres et résumés des **épisodes** en français (saisons TMDB) ; recherche TMDB aussi par le titre original quand le titre affiché n'est pas trouvé.
- Si un résumé reste dans une autre langue, la fiche le signale et indique comment l'obtenir en français.

## [1.2.0-desktop4] - 2026-10-25

**Aperçu 4 — interface TV et guide TV en grille.**

- **Correction (Windows)** : à la fermeture, des fenêtres Kastideo s'ouvraient en série. Le moteur vidéo mpv continuait de tourner après la fermeture de la fenêtre et ouvrait ses propres fenêtres. Désormais la fermeture arrête la lecture, libère mpv puis quitte le processus. Kastideo ne s'ouvre plus qu'une fois : une seconde ouverture ramène la fenêtre existante.
- **Guide TV en grille** (accueil, barre latérale du direct, Ctrl+7) : chaînes en lignes, heures en colonnes, trait de l'heure actuelle, navigation ‹ Maintenant ›, choix du jour, 2 h / 3 h / 6 h, filtre (toutes, favoris, récents, thèmes, catégories), recherche, fiche des programmes avec Regarder / Aller sur la chaîne.
- **Interface TV du direct** (Réglages > Apparence) : chaîne en plein cadre, zapping ↑ / ↓, numéro de chaîne au clavier, panneau des chaînes (← ou bord gauche, filtres et recherche, fermeture automatique), bandeau d'information (→ ou I), chaîne précédente (B), favori (F), guide (G), accueil (H), barre du haut qui se cache seule.

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
