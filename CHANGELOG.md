# Journal des versions

Toutes les évolutions notables de Kastideo sont consignées ici.
Les notes de chaque version sont reprises automatiquement dans la GitHub Release correspondante.

## [1.5.0] - 2026-10-30

**YouTube dans Kastideo.** Une nouvelle section **YouTube** (barre latérale, accueil, ⌘9) : on commence par un navigateur, puis la vidéo choisie bascule sur le lecteur.

- **Navigateur** : chaînes suivies (collez un lien ou un @pseudo ; leurs dernières vidéos par flux RSS, sans clé), **recherche** en vignettes avec votre propre clé API Google gratuite (Réglages > Général > YouTube), liens de vidéos, playlists et chaînes collés, favoris et historique.
- **Lecteur** : le lecteur officiel de YouTube en « mode confidentialité avancée » (youtube-nocookie.com), sans cookie de suivi, donc le plus souvent sans publicité personnalisée. Précédente / Suivante, enchaînement, boucle, muet. **Ce n'est pas un bloqueur de publicités** : YouTube reste libre d'y diffuser des annonces.
- La lecture IPTV s'arrête pendant que YouTube joue (sauf enregistrement en cours).

## [1.4.2] - 2026-10-29

**Soutenir Kastideo (facultatif).** L'application reste gratuite ; un bouton discret **Offrir un café** (Ko-fi) apparaît sur l'accueil et dans la fenêtre Nouveautés, avec un onglet **Réglages > À propos** et l'entrée **Aide > Soutenir Kastideo (Ko-fi)**. Une option permet de masquer les boutons de l'accueil et des Nouveautés.

## [1.4.1] - 2026-10-29

**Correctif de compilation de la 1.4.0** (Mac uniquement) : « Retour au direct » du lecteur référençait un élément non défini. Aucun changement de fonctionnement.

## [1.4.0] - 2026-10-29

**Replay : revoir un programme déjà diffusé.** Les abonnements IPTV qui conservent les chaînes jusqu'à 14 jours (fonction « tv_archive » de Xtream Codes) sont maintenant exploités.

- **Détection automatique** des chaînes à replay (icône ↺ dans les listes et le Guide TV).
- **Guide TV** : les programmes passés des chaînes à replay sont conservés (nombre de jours réglable), le menu de la date propose les jours précédents ; la fiche d'un programme passé propose **Revoir** et **Enregistrer ce replay** ; sur le programme en cours, **Revoir depuis le début**.
- **Clic droit sur une chaîne** > **Revoir (replay)** ; rangée **À revoir** dans l'interface Cinéma.
- **Lecture** : timeline et pause comme pour un film, sans toucher aux « reprises » ; **retour automatique au direct** à la fin du programme ; passage par le relais de flux (une seule connexion).
- **Heure du serveur** lue automatiquement (fuseau et heure d'été du fournisseur) ; **décalage manuel** dans Réglages > Général > Replay.
- Adresses d'archive et décalage visibles dans le Journal (sujet « Lecture et relais », niveau détaillé).

## [1.3.4] - 2026-10-28

**Guide TV : des chiffres plus justes et une liste plus propre.**

- **Séparateurs de catégories ignorés** : les lignes du fournisseur comme « ♣♦♣----|FR| FRANCE FHD |FR|---♣♦♣ » ne sont pas de vraies chaînes. Elles ne sont plus comptées « sans programme » ni proposées dans les listes par thème.
- **Versions d'une même chaîne** : une version 4K, FHD ou UHD sans programme propre reprend désormais celui de la version (HD, SD) qui en a un.
- **« Programme non disponible »** affiché sous les chaînes qui n'ont aucun programme (au lieu du nom de la catégorie).
- **Journal « Guide TV »** : couverture détaillée, avec les chaînes françaises à part (les chaînes étrangères n'ont souvent pas de guide) et les exemples de chaînes françaises sans programme.
- Plus d'alerte « aucune adresse de guide connue » pour les sources Emby, Jellyfin, Plex et dossiers.

## [1.3.3] - 2026-10-28

**Diagnostic : comprendre ce que fait Kastideo, en particulier avec le guide TV.**

- **Journal par sujets** (⌥⌘L) : *Guide TV*, *Lecture et relais*, *Sources et catalogues*, *Enregistrements*, *Fiches TMDB*, *Mises à jour*, *Affichage et divers*. Filtre par sujet (avec le nombre de lignes), **recherche**, erreurs et alertes seulement, **Copier l'affichage** (uniquement ce qui est filtré).
- **Niveau de détail par sujet** : Normal, Détaillé (par défaut pour le Guide TV) ou Débogage.
- **Journal conservé sur disque** : choix entre la **session en cours** et la **session précédente** (utile pour les problèmes au démarrage).
- **Guide TV détaillé** : chaque tentative est journalisée — adresse demandée, réponse du fournisseur (code HTTP, taille, durée, compression), chaînes et programmes reçus, période couverte, nombre de vos chaînes reliées au guide du fournisseur, au guide de secours ou à aucun, début de la réponse quand elle est inutilisable. Les refus du fournisseur (HTTP 4xx/5xx) et les pannes réseau sont désormais notés dans le journal. Au démarrage, le journal indique aussi si le guide a été conservé ou rechargé.
- **Bouton « Recharger le guide TV »** par source (Réglages > Sources) et nombre de programmes reçus affiché sous la source.
- Sources : chargement journalisé (chaînes, films, séries, chaînes ayant un identifiant de guide, adresse du guide connue ou non).
- Contient le correctif de compilation de la 1.3.2.

## [1.3.2] - 2026-10-27

**Correctif de compilation de la 1.3.1 (Mac).** Aucun changement de fonctionnement : la 1.3.2 contient tout ce que la 1.3.1 apportait (tuile « Mes vidéos », sélecteur Tout / IPTV / Mes vidéos, mot de passe facultatif, connexion Emby corrigée).

## [1.3.1] - 2026-10-27

**Corrections des premiers essais avec un NAS et Emby.**

- **Tuile « Mes vidéos »** sur l'accueil (et dans la barre latérale, ⌘8), visible dès qu'une source Dossiers, Jellyfin, Emby ou Plex existe : vos vidéos sont réunies à part de l'IPTV. **À la une** (reprendre la lecture, ajouts récents, films à voir, films, séries, vidéos), grilles **Films / Séries / Vidéos** avec filtres **genre, année, non vus** et **tri**, **navigation par dossiers** (sous-dossiers du NAS, fil d'Ariane) et choix de la **source**.
- **Films et Séries** : sélecteur **Tout / IPTV / Mes vidéos** au-dessus des catégories (IPTV seul par défaut). Les catégories de vos vidéos ne sont plus masquées par le réglage des pays (cause probable des fichiers du NAS invisibles).
- **Mot de passe facultatif** pour Jellyfin et Emby (compte sans mot de passe), **jeton facultatif** pour Plex (serveur ouvert au réseau local).
- **Emby** : connexion corrigée (erreur HTTP 400). Identification de l'appareil au format attendu par Emby (en-tête « Emby », paramètres d'adresse, nom de l'ordinateur sans accents ni apostrophe typographique), corps réduit à identifiant / mot de passe, second essai sous « /emby ». Une adresse copiée depuis le navigateur (« …/web/index.html#!/home ») est ramenée à celle du serveur.
- **Diagnostic des erreurs** : en cas d'échec, la requête et la **réponse exacte du serveur** s'affichent (ajout de la source, **Détails de l'erreur…** dans Mes vidéos, journal de lecture).
- Fiches TMDB des fichiers : année et genres retenus pour les filtres ; affiches et résumés gardés d'un examen des dossiers à l'autre.

## [1.3.0] - 2026-10-26

**Nouvelles sources : vos vidéos et les serveurs de la maison.**

- **Dossiers (disque, clé USB, NAS)** : Réglages > Sources > **Ajouter** > **Dossiers**, puis **Ajouter un dossier…** (un ou plusieurs). Pour un NAS, montez d'abord le partage dans le Finder (Aller > Se connecter au serveur…). Kastideo reconnaît les films (« Titre (2020).mkv », « Titre.2020.1080p… », dossier « Titre (2020) »), les séries (« Série S01E02 », « 1x02 », dossiers « Saison 1 »), regroupées avec leurs saisons, et range les autres vidéos dans une rubrique **Vidéos · nom du dossier**. Les dossiers sont examinés à chaque lancement puis toutes les 20 minutes.
- **Fiches TMDB automatiques** des films et séries trouvés dans les dossiers (avec une clé TMDB) : affiche et résumé, et clic droit > **Corriger la fiche…** pour choisir le bon titre quand le nom du fichier trompe la recherche.
- **Sous-titres placés à côté** des vidéos (« Film.srt », « Film.fr.srt ») chargés à la lecture.
- **Jellyfin et Emby** : adresse, identifiant et mot de passe (ou clé d'API). Les bibliothèques de films, séries et vidéos apparaissent dans Films et Séries (rubriques « Films · nom du serveur »), avec affiches, fiches, saisons et épisodes du serveur. Lecture directe, sans conversion.
- **Plex** : **Se connecter avec Plex** (autorisation dans plex.tv, choix du serveur du compte) ou jeton saisi à la main.
- **Recherche sur le réseau** : bouton **Rechercher sur le réseau** pour trouver les serveurs Jellyfin, Emby et Plex de la maison et remplir l'adresse (macOS demande l'autorisation d'accès au réseau local).
- **Reprise et « vu » partagés dans les deux sens** avec Jellyfin, Emby et Plex : la position de lecture est transmise au serveur pendant la lecture, et celle des autres appareils est reprise dans Kastideo. Clic droit > **Marquer comme vu / non vu** ; pastille **Vu** sur les affiches et coche dans la liste des épisodes.
- Sauvegarde de la configuration : les serveurs (et leur mot de passe ou jeton, si demandé) sont exportés et importés, comme dans Kastideo pour Windows et Linux.

## [1.2.2] - 2026-10-25

- **Gérer les catégories** : une case **Tout sélectionner / désélectionner** au-dessus de la liste coche ou décoche d'un coup toutes les catégories listées (Direct, Films ou Séries). Avec une recherche, elle ne concerne que les catégories trouvées : masquer tout un pays se fait en deux clics. Le nombre de catégories affichées est indiqué à côté.

## [1.2.1] - 2026-10-25

- **Pays et langues des rangées Cinéma** (Réglages > Apparence) : Kastideo repère les pays dans les noms de vos catégories (« FR| », « |PT| », « FRANCE », « VOSTFR »…) et vous laisse choisir ceux à montrer. Les derniers ajouts du bandeau « à la une », les tendances TMDB, la sélection au hasard et les rangées par catégorie de l'interface Cinéma ne montrent plus que ces pays (option pour garder les catégories sans pays, comme « Action »). Les listes et la recherche restent complètes. Le choix est repris par la sauvegarde de la configuration, comme dans Kastideo pour Windows et Linux.

## [1.2.0] - 2026-10-25

- **Sauvegarde et transfert de la configuration** (Réglages > Général) : **Exporter la configuration…** crée un fichier avec vos sources (mots de passe compris si vous le souhaitez), favoris, récents, catégories personnalisées et interfaces choisies ; **Importer une configuration…** les ajoute sur un autre Mac — ou dans Kastideo pour Windows et Linux, qui lit et écrit le même fichier. Rien n'est supprimé à l'importation : les sources déjà présentes sont reconnues.

## [1.1.7] - 2026-10-24

- **Image seule (sans le son)** : quand le son d'une chaîne est inutilisable et fige l'image (horloge incohérente même après réouverture), Kastideo passe automatiquement en **image seule** : l'image ne se fige plus. Le choix est mémorisé pour la chaîne. Il est aussi disponible à la main : clic droit sur une chaîne du direct > **Image seule (sans le son)** (coché = actif ; décocher pour réessayer avec le son).
- Réglages > Général > Lecture > **Réinitialiser** annule aussi les chaînes passées en image seule.

## [1.1.6] - 2026-10-24

- **Chaînes refusées par le fournisseur** : quand le fournisseur répond nettement « refusé » ou « introuvable » pour une chaîne (HTTP 403/404, vu grâce au relais), Kastideo ne s'acharne plus (plus de nouvel essai ni de variante .m3u8) et l'explique : chaîne hors service chez lui ou absente de l'abonnement, essayer une autre version.
- **Image figée / son absent sur les flux à l'horloge incohérente** : la détection couvre maintenant aussi les sauts d'horloge (« clock gap ») et les images en retard, pas seulement le son jeté. La chaîne est rouverte sans l'horloge du fournisseur ; si le flux reste incohérent, Kastideo n'essaie plus de relancer la piste son (ce qui figeait l'image) et indique que le flux est défectueux chez le fournisseur.
- Réglages > Général > Lecture : **Réinitialiser** les chaînes à l'horloge réparée.
- Journal : les alertes d'horloge sont regroupées (une ligne toutes les 5 s).

## [1.1.5] - 2026-10-24

- **Son absent sur certaines chaînes — cause trouvée** : sur ces chaînes, l'horloge envoyée par le fournisseur (PCR) est décalée de plusieurs heures par rapport au son ; le moteur VLC jette alors tout le son (« buffer too late »). Kastideo le détecte en 2 secondes, rouvre la chaîne en se calant sur le son et l'image plutôt que sur cette horloge, et s'en souvient pour les fois suivantes.
- **Journal de lecture** : les milliers de lignes « buffer too late » sont regroupées (une ligne toutes les 5 s avec le nombre de blocs jetés), pour que le journal reste lisible.
- La lecture réparée n'est pas comptée dans la qualité automatique des chaînes.

## [1.1.4] - 2026-10-24

- **Relais de flux** : il ne démarrait pas (« Operation not permitted ») car l'autorisation réseau locale n'était pas incluse dans l'application signée. C'est corrigé : le direct passe désormais par la connexion d'Apple (comme Piboard passe par la sienne) et non plus par celle du moteur VLC, que le pare-feu Cloudflare du fournisseur refuse (HTTP 403).
- **Moins de requêtes en cas de refus** : un seul nouvel essai au lieu de deux, pour ne pas multiplier les connexions chez le fournisseur.

## [1.1.3] - 2026-10-24

- **Relais de flux pour le direct** (comme Piboard) : Kastideo ouvre lui-même **une seule** connexion chez le fournisseur (en-têtes de lecteur VLC, redirections suivies) et la transmet au moteur VLC en local. Les requêtes multiples du moteur VLC à l'ouverture d'une chaîne, qui faisaient refuser les flux avec un abonnement à une connexion (HTTP 401/403/404/520), disparaissent ; la chaîne précédente est fermée net avant d'ouvrir la suivante. Réglage : Réglages > Général > Lecture > **Relais de flux pour le direct** (activé par défaut).
- **Journal de lecture** : réponse réelle du fournisseur (code HTTP, délai, redirections) et durée/volume de chaque connexion.

## [1.1.2] - 2026-10-24

- Correctif de compilation de la 1.1.1 (type des statistiques VLC renommé `VLCMedia.Stats`). Contient toutes les nouveautés de la 1.1.1.

## [1.1.1] - 2026-10-24

- **Chaînes sans son** : Kastideo surveille désormais le son pendant la lecture. Si l'image avance mais qu'aucun son n'est joué, il répare automatiquement : relance de la piste son quand la sortie audio n'a pas pu être créée au démarrage (erreur VLC « too low audio sample frequency (0) »), ou essai de la piste son suivante quand la piste choisie est vide. Si le flux n'a vraiment pas de son, une icône 🔇 orange apparaît dans la pastille de santé avec l'explication.
- **Journal de lecture** : format des pistes son de chaque chaîne (codec, fréquence, canaux, langue) et détail des tentatives de réparation.

## [1.1.0] - 2026-10-23

- **Direct en différé** : nouvelle **timeline** (de la pause jusqu'au direct) — glissez le curseur vers la droite pour avancer, Kastideo accélère la lecture jusqu'au point choisi ; **vitesse de lecture** ×1 à ×2 qui revient seule à ×1 en rattrapant le direct ; bouton **Rattraper** (accélère jusqu'au direct) et bouton **Retour au direct** bien visible ; **+30 s** (et −10 s si le flux permet le déplacement) en différé.
- Réglages > Général > Lecture : **durée maximale du différé** (30 min à 3 h ou sans limite, la lecture reprend seule une fois atteinte), **vitesse de rattrapage**, emplacement du dossier du différé avec bouton **Afficher**.

## [1.0.3] - 2026-10-23

- **Direct — changement de chaîne** : le fournisseur refusait la nouvelle chaîne (HTTP 404/403) parce qu'il comptait encore l'ancienne connexion (abonnement à une connexion). Kastideo laisse désormais 1,5 s au serveur pour libérer la chaîne précédente avant d'ouvrir la suivante, et réessaie deux fois la même chaîne (après 2 puis 4 s) si le serveur la refuse encore, avant d'essayer la variante .m3u8.
- L'essai en http ajouté en 1.0.2 est retiré (le serveur le refuse : HTTP 403).

## [1.0.2] - 2026-10-23

- **Direct** : quand le serveur refuse un flux en https (erreur HTTP 520 de Cloudflare, alors que la chaîne fonctionne ailleurs), Kastideo réessaie automatiquement la même chaîne en http (.ts puis .m3u8).
- **Connexion libérée** : le flux est désormais fermé proprement quand on quitte Kastideo, pour que le fournisseur ne compte plus la session (abonnement à une connexion).
- **Journal de lecture** : durée de fermeture du flux précédent à chaque changement de chaîne.

## [1.0.1] - 2026-10-22

- **Thèmes — « En ce moment »** : les chaînes dont le nom est suffisamment explicite (beIN Sports, BFM, Gulli, Eurosport…) sont désormais proposées dans leur thème **même sans programme dans le guide TV**. Elles s'affichent avec le nom de la chaîne à la place du titre du programme. Les chaînes que Kastideo ne sait pas classer sans guide restent proposées dans le mode **Chaînes** (vous pouvez les classer vous-même : clic droit > Thème de la chaîne).

## [1.0.0] - 2026-10-22

**Première version stable de Kastideo.** Direct, films et séries IPTV (Xtream Codes et M3U) lus par le moteur VLC, interfaces Classique, Cinéma et TV, écran d'accueil, guide TV en grille avec guide de secours xmltvfr.fr, Direct par thème avec alertes de programme, fiches films et séries (TMDB), enregistrement et téléchargement, MultiVue, catégories personnalisables, français et anglais, mises à jour automatiques.

Nouveau dans cette version :

- **Modifier la chaîne…** (clic droit sur une chaîne du direct) : corriger le **nom**, le **numéro**, le **logo** (adresse ou fichier) et la **chaîne du guide TV** associée, pour cette version de la chaîne ; **Rétablir l'original** pour annuler. Les corrections survivent aux actualisations de la source
- Les logos choisis ne sont pas effacés par « Vider et recharger » le cache

## [0.15.0] - 2026-10-22

- **Nouveaux thèmes** : Auto-Moto (sports mécaniques), Cuisine & Maison, Nature / Chasse & Pêche, Régional (France 3 régions, télés locales), International (chaînes étrangères), Religion, Radio, et **Adulte**
- **Contenus adultes** (« |XX| » dans le nom ou catégorie adulte) **masqués partout** par défaut ; Réglages > Général > Lecture > Afficher les contenus adultes
- **Sport par discipline** : Football, Rugby, Tennis, Basket, Combat, Golf, Cyclisme, Handball, Sports mécaniques, Sports d'hiver, Hippisme, Athlétisme & natation

## [0.14.1] - 2026-10-22

- Correction de compilation (la 0.14.0 n'avait pas pu être construite) : le Guide TV gère maintenant le filtre par thème
- **Guide TV** : nouveau filtre **Thèmes** (Sport, Films, Info…)

## [0.14.0] - 2026-10-22

- **Direct par thème** (section Thèmes, sous Direct) : Sport, Films, Séries, Info, Documentaires, Jeunesse, Divertissement, Musique, Généralistes ; modes **En ce moment** (d'après le genre des programmes du guide TV), **Ce soir** (20 h – 23 h) et **Chaînes** (thème de la chaîne, automatique et modifiable par clic droit). Les catégories masquées n'y apparaissent pas
- **Une seule version par chaîne** dans les thèmes : Kastideo choisit entre 4K, FHD, HD et SD selon la **qualité de votre connexion** (mesurée pendant les lectures) ou selon votre choix (Réglages > Général > Lecture)
- Thèmes aussi dans l'interface **Cinéma** (rangées « Sport en ce moment »…), l'interface **TV** (filtre Thèmes) et l'**accueil** (« À la télé maintenant », « Ce soir »)
- **Alertes de programme** : mot du titre, thème sur vos favoris, ou programme précis ; notification et bandeau « Regarder » deux minutes avant le début
- Le guide TV mémorise maintenant le **genre** de chaque programme

## [0.13.2] - 2026-10-22

- **Mises à jour** : recherche discrète **au démarrage** (puis toutes les 24 h si Kastideo reste ouvert) ; une nouvelle version est annoncée par un **bandeau** en haut de la fenêtre, **jamais pendant un visionnage ou un enregistrement**. La mise à jour reste facultative : Mettre à jour…, Plus tard ou Ignorer cette version
- Les recherches automatiques de Sparkle, qui pouvaient ouvrir une fenêtre à n'importe quel moment, sont remplacées par cette recherche discrète

## [0.13.1] - 2026-10-21

- Numéro de version (et de build) affiché discrètement en bas à droite de l'**écran d'accueil** ; un clic ouvre les nouveautés

## [0.13.0] - 2026-10-21

- **MultiVue** : jusqu'à 4 chaînes en direct dans une même fenêtre (1, 2 côte à côte, grille 2×2), le son suit la vignette active (clic ou touches 1 à 4) ; ajout, changement et retrait de chaîne au survol, recherche parmi favoris, récents et tout le direct. Menu Lecture > MultiVue… (⌥⌘M) ou clic droit > Ajouter à la MultiVue
- Désactivée par défaut : chaque flux consomme une connexion. Réglages > Général > Lecture > **Connexions simultanées de l'abonnement** (1 à 4) pour l'activer

## [0.12.0] - 2026-10-21

- **Lecteur repensé** : barre de contrôle compacte et **rétractable** (disparaît avec le pointeur après 3 s, revient au moindre mouvement)
- **Mini-timeline** pour les films et épisodes : trait fin qui s'épaissit au survol, avec l'heure visée
- **Panneau « Informations »** (ⓘ ou ⌘I) glissant depuis la droite : chaîne et programmes en cours / à venir, ou résumé et distribution du film ; choix de la **piste audio** et des **sous-titres** ; qualité de réception
- **Santé du flux** : pastille verte / orange / rouge (Excellent, Correct, Instable) et définition (SD, HD, 4K) ; débit, images perdues et coupures au survol
- Prochaine étape prévue (0.13) : MultiVue en option, selon le nombre de connexions de l'abonnement

## [0.11.3] - 2026-10-21

- Correction probable de la **lenteur Direct (Classique) → Films (Cinéma)** (55 s mesurées) : la liste classique ne construit plus, même un instant, les ~100 000 films d'une section affichée dans une autre interface
- Journal de lecture : les étapes de construction de l'affichage sont notées quand elles tardent, pour confirmer ou affiner le diagnostic

## [0.11.2] - 2026-10-21

- **Écran d'accueil** : grand logo Kastideo en arrière-plan, en-tête plus présent ; la page occupe toute la hauteur de la fenêtre et les grands pavés s'agrandissent avec elle
- **Bandeau « à la une »** : l'image de fond est cadrée sur le haut (2e quart) plutôt qu'au centre, là où se trouvent le plus souvent visages et titres
- Bandeau préparé hors du fil principal (derniers ajouts, tirage au hasard) pour ne plus ralentir l'ouverture de Films et Séries
- **Journal de lecture** : le temps d'affichage d'une section est noté quand il dépasse une demi-seconde (pour diagnostiquer la lenteur Direct → Films)

## [0.11.1] - 2026-10-21

- **Bandeau « à la une »** : la largeur du bandeau est maintenant imposée par la fenêtre ; une image de fond très large ne peut plus repousser l'affiche, le titre, le résumé et les boutons hors du cadre

## [0.11.0] - 2026-10-21

- **Gérer les catégories** (Présentation > Gérer les catégories…, ⌥⌘C, ou bouton de la barre latérale) pour le Direct, les Films et les Séries : **réordonner** par glisser-déposer, **masquer** (partout : listes, recherche, Guide TV, Cinéma, TV, bandeau), **masquer par mot-clé** (ex. « PAKISTAN »), **renommer**, trier A → Z, tout afficher ou réinitialiser
- Clic droit sur une catégorie de la barre latérale > **Masquer cette catégorie**
- Correction du **bandeau « à la une »** : l'image de fond prenait toute la place et cachait l'affiche, le titre, le résumé et les boutons
- Titres des affiches en interface Cinéma affichés sans les étiquettes du fournisseur (« |FR| »…)

## [0.10.0] - 2026-10-21

- Nouveau **bandeau « à la une »** de l'interface Cinéma : carrousel plein cadre avec grande image de fond, affiche, titre, année, durée, genres, note, résumé et boutons **Lire / Reprendre**, **Plus d'infos** et **Bande-annonce** ; défilement automatique (pause au survol), flèches et points de navigation
- Le carrousel mélange les **tendances de la semaine TMDB** présentes dans votre catalogue, les **derniers ajouts** du fournisseur et une **catégorie au choix** (ou tout le catalogue au hasard)
- En **Direct**, le bandeau montre le **programme en cours** de vos chaînes favorites et récentes (progression, programme suivant, Regarder)
- Réglages > Apparence > **Bandeau « à la une »** : afficher/masquer, hauteur, vitesse, sources et catégories
- Les films et séries Xtream mémorisent leur **date d'ajout** (actualisez la source pour l'obtenir)

## [0.9.8] - 2026-10-21

- Passage **instantané** du Direct à Films (ou à toute autre section) : l'arrêt du flux par le moteur VLC, qui pouvait prendre jusqu'à 30 s, se fait maintenant en arrière-plan sans bloquer l'interface. La durée de l'arrêt est notée dans le Journal de lecture quand elle dépasse 1 s

## [0.9.7] - 2026-10-21

- Correction d'un **blocage de l'application** (roue multicolore) en passant du Direct à Films pendant la lecture d'une chaîne : la vidéo reste hébergée dans une fenêtre invisible le temps que le moteur VLC s'arrête
- **Enregistrements sans son** : à la conversion en MP4, le son est maintenant converti en AAC (lisible partout, y compris QuickTime, iPhone et iPad) ; l'image reste copiée sans perte

## [0.9.6] - 2026-10-21

- **Enregistrement du direct** : si le moteur VLC ne crée pas le fichier dans le dossier « En cours » sous 10 s, Kastideo réessaie automatiquement dans un dossier temporaire avant d'afficher « Enregistrement impossible » ; dossier de travail nommé sans accents ni caractères spéciaux ; chaque essai est noté dans le Journal de lecture

## [0.9.5] - 2026-10-21

- **Guide TV de secours** : le guide gratuit de **xmltvfr.fr** (Complet, ~785 chaînes) complète automatiquement les chaînes sans programme chez le fournisseur, reliées par leur nom (« |FR| TF1 FHD » → TF1). Réglages > Général > Guide TV de secours (autre guide xmltvfr.fr ou adresse XMLTV au choix)
- Correction : un guide **vide ou illisible** envoyé par le fournisseur n'efface plus les programmes déjà connus ; un message l'indique sous la source
- Le guide est rechargé automatiquement quand il arrive à moins de 12 h de sa fin, même si Kastideo reste ouvert plusieurs jours

## [0.9.4] - 2026-10-20

- **Aide** : nouvelle rubrique « Obtenir une clé TMDB (gratuite) », pas à pas, dans Réglages généraux

## [0.9.3] - 2026-10-20

- **Fiche film / série** : la page commence sous la barre d'outils (l'affiche est entière), bouton **Retour à Films / Séries** bien visible en haut (ou Échap), titre affiché sans les étiquettes du fournisseur (« |FR| », « 4K »…)

## [0.9.2] - 2026-10-20

- Correction de l'**écran noir en plein écran** (le son continuait) : pendant le passage en plein écran, l'ancien et le nouvel écran coexistent un instant ; la vidéo va maintenant toujours à l'écran affiché

## [0.9.1] - 2026-10-20

- Correction de l'**écran noir** au retour sur une chaîne (bouton « Retourner à la lecture » de l'accueil, sortie du plein écran…) : la vidéo réapparaît sans relancer le flux

## [0.9.0] - 2026-10-20

- **Fiche film / série** en interface Cinéma : un clic sur une affiche ouvre une page de présentation (fond, affiche, année, durée, genres, note, résumé, réalisateur, distribution avec photos, bande-annonce) avec **Lire / Reprendre**, **Voir les épisodes**, **Télécharger** et favori. Bouton **Plus d'infos** dans le bandeau « à la une ». Informations du fournisseur IPTV (get_vod_info / get_series_info), complétées par **TMDB** si vous saisissez une clé gratuite dans Réglages > Général
- **Enregistrement du direct visible pendant l'écriture** : le fichier grossit dans le sous-dossier « En cours » du dossier des enregistrements, puis est rangé à l'arrêt
- **Conversion MP4 fiabilisée** : sous-titres DVB et télétexte écartés, second essai avec les pistes principales, fin de conversion détectée même sans signal du moteur ; le .ts n'est conservé qu'en dernier recours
- Correction : passer de **Direct** à **Films** (ou Séries) ouvre maintenant la grille de la section au lieu du lecteur de la chaîne précédente

## [0.8.3] - 2026-10-20

- Corrections de compilation (les versions 0.8.1 et 0.8.2 n'avaient pas pu être construites) : style de couleur des cases à cocher des Récents, accès au dossier personnel depuis la recherche des fichiers d'enregistrement

## [0.8.2] - 2026-10-20

- Correction de compilation (la version 0.8.1 n'avait pas pu être construite) : dossier « Documents » mal désigné dans la recherche des fichiers d'enregistrement
- Le journal de la construction automatique affiche désormais toutes les lignes d'erreur du compilateur

## [0.8.1] - 2026-10-20

- **Plein écran** : en interface Classique, le mode plein écran (bouton de la barre de contrôle, double-clic, ⌘↩ ou bouton vert de la fenêtre) affiche maintenant **la vidéo seule**, sans colonnes ni barre d'outils, au lieu de mettre toute l'application en plein écran. Échap ou ⌘↩ pour revenir
- **Enregistrement du direct** fiabilisé : Kastideo ne se fie plus au retour du moteur VLC (qui annonce parfois un échec alors que l'enregistrement fonctionne) et retrouve lui-même le fichier écrit ; le fichier est toujours déplacé dans le **dossier d'enregistrements choisi** (si ce dossier n'est plus accessible, ~/Movies/Kastideo est utilisé et un message l'indique)
- Un **bandeau** dans la fenêtre indique maintenant le résultat de chaque enregistrement et téléchargement (avec le dossier et un bouton « Afficher »), même si les notifications macOS sont désactivées ; les étapes sont aussi inscrites dans le Journal de lecture

## [0.8.0] - 2026-10-20

- Nouvel **écran d'accueil** au lancement : trois grands pavés **Direct**, **Films** et **Séries**, boutons d'accès rapide aux **Favoris**, **Récents**, **Guide TV** et **Enregistrements**, recherche globale (chaînes, films, séries), rangée « Reprendre la lecture » et retour à la lecture en cours. On y revient avec le bouton **Accueil**, **⌘0** (ou **H** en interface TV)
- **Récents** : suppression d'un ou de plusieurs éléments (clic droit > Retirer des récents, touche ⌫, ou **Modifier** puis cases à cocher), **Tout effacer**, et bandeau **Annuler** après chaque suppression
- Kastideo est maintenant disponible en **français et en anglais** : choix de la langue au premier lancement, modifiable dans Réglages > Général > Langue (relance proposée). L'aide intégrée est traduite

## [0.7.0] - 2026-10-19

- Nouveau **Guide TV en grille** : les chaînes en lignes, les heures en colonnes, trait rouge « maintenant », navigation par demi-journée et par jour, durée affichée 2 / 3 / 6 h, filtre (favoris, récents, catégorie) et recherche ; un clic sur un programme ouvre sa fiche (description, **Regarder**, **Enregistrer**, **Programmer**). Section Guide TV dans la barre latérale (⌘7), l'onglet Cinéma et la touche G de l'interface TV
- **Reprise de la lecture** : Kastideo mémorise où vous en êtes dans chaque film et épisode et vous propose de reprendre ; barres de progression dans les listes, les affiches et les épisodes ; rangée « Reprendre la lecture » en interface Cinéma
- **Indicateur de téléchargement** toujours visible dans la barre d'outils : anneau d'avancement et, au clic, le détail : avancement du film ou de l'épisode en cours, « épisode X sur N », avancement de la série ou du lot, vitesse et **temps restant estimé**. Les lignes de la section Enregistrements affichent aussi vitesse et temps restant

## [0.6.1] - 2026-10-19

- Nouvelle **icône** de l'application : monogramme K avec bouton lecture, sur fond violet, qui remplit toute la surface (plus de marge blanche autour dans le Dock et le Finder)

## [0.6.0] - 2026-10-19

- Nouvelle interface **TV** pour le direct : la chaîne en plein cadre, **panneau de chaînes** (touche ←, Entrée ou bord gauche) avec filtre Toutes / Favoris / Récents / catégorie et recherche, **bandeau d'information** à chaque changement de chaîne (programme en cours, horaires, programme suivant, heure)
- **Zapping au clavier** : ↑ / ↓ chaîne précédente / suivante, **numéro de chaîne** tapé au clavier, **B** retour à la chaîne précédente, I bandeau, F favori, M muet, Espace pause
- Reprise automatique de la dernière chaîne regardée à l'ouverture de l'interface TV
- Choix de l'interface TV dans Réglages > Apparence, par le bouton Interface de la barre d'outils ou avec ⌥⌘3

## [0.5.0] - 2026-10-19

- Nouvelle interface **Cinéma** : bandeau « à la une », rangées horizontales (reprise, favoris, une par catégorie), affiches pour les films et séries, vignettes avec programme en cours pour les chaînes, lecteur en plein cadre
- Interface **au choix par type de contenu** : Classique ou Cinéma séparément pour le direct, les films, les séries et les favoris / récents (bouton Interface de la barre d'outils, ⌥⌘1 / ⌥⌘2, ou Réglages > Apparence)
- Nouvel onglet **Réglages > Apparence** : thème, couleur d'accent, densité des listes, taille des vignettes
- Les listes par catégorie s'affichent plus vite
- Publication : l'agrafage du ticket de notarisation est retenté en cas d'indisponibilité du service Apple (le DMG reste notarisé sans agrafe)

## [0.4.0] - 2026-10-18

- **Enregistrement du direct** pendant la lecture (●, ⇧⌘R), sur la même connexion, arrêt automatique à la fin du programme
- **Enregistrements programmés** depuis le guide TV (double-clic ou clic droit) ou à horaires libres, avec marges avant / après
- **Téléchargement des films et épisodes** sans les regarder, saison ou série entière, en file d'attente, **cette nuit** à l'heure choisie
- Connexion unique respectée : Kastideo demande avant d'arrêter un enregistrement ; les téléchargements se mettent en pause pendant la lecture
- Conversion automatique des enregistrements en **MP4** sans perte de qualité
- **Direct en différé** : pause sur une chaîne en direct, reprise en différé, bouton « Direct »
- Section **Enregistrements** (⌘6) : en cours, conversions, téléchargements, programmations, fichiers
- Réglages > Enregistrements : dossier (~/Movies/Kastideo par défaut), marges, heure de nuit, MP4, nettoyage automatique, notifications
- Notifications macOS, blocage de la mise en veille pendant l'activité, alerte d'espace disque faible

## [0.3.1] - 2026-10-18

- Correction : une chaîne qui ne répond pas ne laisse plus le chargement tourner indéfiniment ; après 20 s sans image, Kastideo essaie la variante .ts / .m3u8 puis affiche une erreur explicite
- Le démarrage est désormais détecté dès que VLC passe en lecture
- Nouveau **Journal de lecture** (menu Lecture, ⌥⌘L, ou bouton dans le message d'erreur) : messages du moteur VLC, identifiants et mots de passe masqués, copiable pour le diagnostic
- Le détail de l'erreur VLC (par exemple un refus du serveur) est affiché sous le message d'erreur

## [0.3.0] - 2026-10-18

- Nouveau moteur de lecture **VLC** (VLCKit) pour tous les contenus : direct **MPEG-TS (.ts)**, HLS, MP4, **MKV**, AVI…
- Direct Xtream lu en .ts comme le lecteur de référence (certains fournisseurs refusent le .m3u8), avec bascule automatique .ts ↔ .m3u8
- Une seule connexion au fournisseur à la fois : le flux précédent est fermé avant d'ouvrir le suivant
- Nouveaux contrôles : lecture / pause, recul 10 s / avance 30 s, barre de progression, volume jusqu'à 200 %
- **Mode cinéma** (double-clic, ⌘↩, Échap pour sortir) et écran de chargement avec logo de la chaîne
- Badge **« Prête en x s »** : temps de démarrage mesuré à chaque chaîne
- Réglage de la **mémoire tampon** : Rapide (par défaut), Équilibré, Stable
- Publication : cache des paquets Swift dans GitHub Actions pour des compilations plus rapides

## [0.2.2] - 2026-10-18

- Correction : certains fournisseurs laissaient la requête expirer ; Kastideo s'identifie désormais comme **VLC**, comme la tuile IPTV de Piboard
- Les adresses de playlist **get.php?username=…&password=…** sont reconnues et converties automatiquement en source **Xtream Codes** : chargement beaucoup plus rapide, guide TV inclus, mot de passe dans le trousseau
- Les sources de ce type déjà configurées sont converties au lancement
- Messages d'erreur réseau en français et plus explicites (délai dépassé, serveur introuvable, connexion refusée…)
- Téléchargements : jusqu'à 10 minutes pour les très grosses playlists

## [0.2.1] - 2026-10-18

- Correction : les playlists et flux en **http://** étaient refusés (« App Transport Security ») ; ils se chargent désormais normalement
- Publication : un seul workflow GitHub par livraison (Build ne se lance plus qu'à la demande)

## [0.2.0] - 2026-10-18

- Mises à jour automatiques avec Sparkle : vérification quotidienne, installation en un clic et relance
- Menu **Kastideo > Rechercher les mises à jour…** et onglet **Mises à jour** dans les réglages
- Canal bêta facultatif pour recevoir les versions de test en avant-première
- Fenêtre **Nouveautés** au premier lancement après une mise à jour (aussi dans le menu Aide)
- Publication : signature des mises à jour et flux Sparkle générés automatiquement par GitHub Actions

## [0.1.0] - 2026-10-18

- Première version de Kastideo pour macOS : lecteur IPTV avec sources Xtream Codes et playlists M3U
- Sources Xtream Codes (serveur, identifiant, mot de passe) avec test de connexion, état et expiration du compte
- Playlists M3U / M3U8 par URL ou par fichier local (catégories, logos, numéros de chaînes)
- Guide TV XMLTV (y compris .xml.gz) : programme en cours, progression et programmes suivants
- Navigation Direct / Films / Séries / Favoris / Récents, catégories et recherche sans accents
- Séries Xtream : saisons et épisodes avec lecteur intégré
- Lecteur natif (HLS, MP4) avec plein écran et image dans l'image ; bascule automatique .ts → .m3u8
- Favoris (⌘D), historique des 60 derniers contenus, zapping ⌘↑ / ⌘↓
- Cache local pour un démarrage instantané, mots de passe dans le trousseau macOS
- Aide intégrée (menu Aide, ⌘?)
- Publication automatisée : DMG signé Developer ID et notarisé via GitHub Actions, script kastideo-release
