# Démarrer

## Bienvenue {#bienvenue}

Kastideo réunit en une seule interface vos **chaînes en direct, films et séries IPTV**, vos **vidéos personnelles** (disque, clé USB, NAS, Jellyfin, Emby, Plex) et **YouTube**. Kastideo ne fournit **aucun contenu** : vous ajoutez vos propres sources.

![L'écran d'accueil](img:home)

1. Retour à l'accueil, de n'importe où.
2. Recherche unique dans les chaînes, films et séries.
3. Bouton **?** : l'aide, ouverte à la page de l'écran où vous êtes.

### Démarrage rapide

<!--mac-->
1. Au premier lancement, cliquez sur **Ajouter une source** (ou **Réglages ⌘,** > **Sources** > **Ajouter**).
<!--/mac-->
<!--pc-->
1. Ouvrez les **Réglages** (roue dentée de l'accueil, ou **Ctrl+,**) > **Sources** > **Ajouter une source**.
<!--/pc-->
2. Choisissez le type de source : [Xtream Codes](help:xtream), [Playlist M3U](help:m3u), [Dossiers](help:dossiers), ou un serveur [Jellyfin, Emby ou Plex](help:serveurs).
3. Renseignez les informations demandées puis cliquez sur **Ajouter** : Kastideo charge les chaînes, films, séries et le [guide TV](help:guide).
4. Revenez à l'**accueil** et ouvrez **Direct**, **Films** ou **Séries**.

### Trouver de l'aide

<!--mac-->
- Le bouton **?** de la barre d'outils ouvre l'aide à la page qui correspond à l'écran affiché.
- Menu **Aide > Aide de Kastideo** ou **⌘?**.
<!--/mac-->
<!--pc-->
- Le bouton **?** de l'accueil et des écrans principaux ouvre l'aide.
<!--/pc-->
- Le champ **Rechercher** en haut de l'aide cherche dans toutes les pages.
- Un problème ? Voyez les [questions fréquentes](help:faq) puis le [dépannage](help:depannage).

> Vous voulez regarder YouTube ? Voir [YouTube](help:youtube). Importer vos abonnements : [pas à pas](help:youtube-import).

## Questions fréquentes {#faq}

### Où trouver les chaînes à ajouter ?
Kastideo ne fournit ni chaînes ni abonnement. Votre fournisseur IPTV vous donne soit un serveur, un identifiant et un mot de passe ([Xtream Codes](help:xtream)), soit l'adresse d'une playlist ([M3U](help:m3u)). Vous pouvez aussi lire vos propres fichiers ([Dossiers](help:dossiers)).

### Une chaîne ne démarre pas ou saccade
<!--mac-->Voir [Si une chaîne ne démarre pas](help:chaine-ne-demarre-pas) et le [dépannage](help:depannage).<!--/mac--><!--pc-->Voir le [dépannage](help:depannage).<!--/pc--> Très souvent, la cause est une **seconde connexion** simultanée sur le même abonnement : voir [Une seule connexion à la fois](help:connexion-unique).

### Le guide TV est vide ou incomplet
Réglages > Sources > **Recharger le guide TV**, puis consultez [Guide TV](help:guide) et le [guide de secours](help:guide-secours).

### Comment regarder YouTube sans publicité ?
Kastideo lit les vidéos avec le lecteur officiel en **mode confidentialité avancée** : pas de cookie de suivi, donc le plus souvent aucune publicité personnalisée. Ce n'est **pas** un bloqueur de publicités : voir [Publicités, compte et confidentialité](help:youtube-confidentialite).

### Comment importer mes abonnements YouTube ?
YouTube ne permet pas de connecter un compte à une application tierce : on passe par un fichier que Google génère pour vous. Suivez le [guide pas à pas](help:youtube-import).

### La recherche YouTube demande une clé
La recherche utilise **votre** clé API Google, gratuite. Le [guide pas à pas](help:youtube-cle) l'explique en quelques minutes. Sans clé, vous pouvez quand même suivre des chaînes et lire des liens collés.

### Comment enregistrer une émission ?
Voir [Enregistrer le direct](help:enregistrer) et [Programmer un enregistrement](help:programmer).

### Comment revoir un programme déjà diffusé ?
Si votre fournisseur propose une archive : voir [Replay](help:replay).

### Comment retrouver mes réglages sur un autre ordinateur ?
Voir [Sauvegarde et transfert](help:sauvegarde).

# Les sources

## Xtream Codes {#xtream}

<!--mac-->
C'est le format le plus courant chez les fournisseurs IPTV. Il faut trois informations : l'adresse du **serveur** (par exemple `http://exemple.com:8080`), votre **identifiant** et votre **mot de passe**.

- Le bouton **Tester la connexion** vérifie vos identifiants et affiche l'état du compte, sa date d'expiration et le nombre de connexions simultanées autorisées.
- Le mot de passe est enregistré dans le **trousseau macOS**, jamais en clair sur le disque.
- Le guide TV du serveur est utilisé automatiquement.
- Les séries s'ouvrent sur une fiche avec leurs saisons et leurs épisodes.
<!--/mac-->

<!--pc-->
Adresse du serveur (ex. http://exemple.com:8080), identifiant et mot de passe. Le mot de passe est rangé dans le coffre du système : Gestionnaire d'identification sous Windows, trousseau GNOME ou KWallet sous Linux.
<!--/pc-->

## Playlist M3U / M3U8 {#m3u}

<!--mac-->
- **Par URL** : collez l'adresse de la playlist fournie par votre fournisseur.
- Si l'adresse est de la forme `get.php?username=…&password=…` (le cas le plus courant chez les fournisseurs par abonnement), Kastideo la reconnaît et l'enregistre en **Xtream Codes** : le chargement est beaucoup plus rapide, le guide TV est inclus et le mot de passe est rangé dans le trousseau. Les sources de ce type déjà enregistrées sont converties automatiquement.
- **Par fichier** : choisissez un fichier `.m3u` ou `.m3u8` sur votre Mac. Kastideo garde l'autorisation d'y accéder pour pouvoir l'actualiser.
- Les catégories proviennent de l'attribut `group-title`, les logos de `tvg-logo` et l'association au guide TV de `tvg-id`.
- Kastideo classe automatiquement les entrées en Direct, Films ou Séries d'après leur adresse.
<!--/mac-->

<!--pc-->
Adresse de la playlist ou fichier sur le disque (**Choisir un fichier…**). Une adresse « get.php?username=…&password=… » est reconnue et transformée en source Xtream, bien plus rapide et plus complète (fiches, épisodes, derniers ajouts).
<!--/pc-->

## Dossiers (disque, clé USB, NAS) {#dossiers}

<!--mac-->
Pour regarder les vidéos rangées sur le Mac, un disque externe, une clé USB ou un NAS :

1. Réglages > Sources > **Ajouter** > type **Dossiers (disque, USB, NAS)**.
2. **Ajouter un dossier…** : choisissez un ou plusieurs dossiers (par exemple « Films » et « Séries »). Pour un **NAS**, montez d'abord le partage dans le Finder (**Aller > Se connecter au serveur…**, par exemple `smb://nas.local/Vidéos`), puis choisissez-le dans la liste des volumes.
3. **Ajouter** : Kastideo examine les dossiers et leurs sous-dossiers.

Les vidéos sont reconnues d'après leur nom :

- **Films** : « Inception (2010).mkv », « The.Matrix.1999.1080p.BluRay.mkv », ou un dossier « Le Fabuleux Destin (2001) » qui contient le film. Ils apparaissent dans **Films**, rubrique « Films · nom du dossier ».
- **Séries** : « Breaking.Bad.S01E02.mkv », « Friends 1x05.mp4 », ou un dossier « Kaamelott/Saison 3/12 - Le Tourment.avi ». Les épisodes sont regroupés en une série, avec ses saisons, dans **Séries**.
- **Autres vidéos** (vacances, caméra…) : rubrique **Vidéos · nom du dossier**, dans Films.

Les dossiers sont examinés à chaque lancement puis toutes les 20 minutes : une vidéo ajoutée apparaît toute seule. Si le disque est débranché ou le partage déconnecté, un message l'indique sous la source et la liste précédente est gardée. Les **sous-titres** placés à côté d'une vidéo (« Inception (2010).srt », « Inception (2010).fr.srt ») sont chargés à la lecture.

Avec une **clé TMDB** (Réglages > Général), les films et séries reçoivent automatiquement **affiche et résumé**. Si le nom du fichier trompe la recherche, clic droit sur l'affiche (ou lien en bas de la fiche) > **Corriger la fiche…** : cherchez le bon titre et choisissez-le ; le choix est retenu.
<!--/mac-->

<!--pc-->
Réglages > Sources > **Ajouter une source** > **Dossiers**, puis **Ajouter un dossier…** (disque interne, disque ou clé USB) ou saisissez un **chemin réseau** et cliquez sur **+** : `\\NAS\Vidéos` ou un lecteur réseau (`Z:\`) sous Windows, un partage monté (`/mnt/nas/videos`, `/media/…`) sous Linux. Plusieurs dossiers peuvent former une même source.

- **Films** reconnus par leur nom : « Inception (2010).mkv », « The.Matrix.1999.1080p.BluRay.mkv », dossier « Le Fabuleux Destin (2001) ». Rubrique « Films · nom du dossier ».
- **Séries** : « Breaking.Bad.S01E02.mkv », « Friends 1x05.mp4 », dossiers « Série/Saison 1/… ». Les épisodes sont regroupés par série et par saison dans **Séries**.
- **Autres vidéos** : rubrique **Vidéos · nom du dossier** dans Films.
- Examen à chaque lancement puis toutes les 20 minutes. Disque débranché : un message l'indique et la liste précédente est gardée. Les sous-dossiers illisibles (« System Volume Information »…) sont ignorés.
- **Sous-titres** placés à côté (« Film.srt », « Film.fr.srt ») chargés à la lecture.
- Avec une **clé TMDB**, **affiches et résumés** sont ajoutés automatiquement ; clic droit > **Corriger la fiche…** pour choisir le bon titre quand le nom du fichier trompe la recherche.
<!--/pc-->

## Jellyfin, Emby et Plex {#serveurs}

<!--mac-->
### Jellyfin et Emby

1. Réglages > Sources > **Ajouter** > **Jellyfin** ou **Emby**.
2. **Rechercher sur le réseau** trouve les serveurs de la maison ; cliquez sur le vôtre pour remplir l'adresse. Sinon saisissez-la (par exemple `192.168.1.10` : le port 8096 est ajouté).
3. Votre **identifiant** et votre **mot de passe** Jellyfin / Emby — **facultatif** : laissez-le vide si le compte n'en a pas (une **clé d'API** du tableau de bord peut aussi le remplacer). **Tester la connexion** vérifie l'adresse. Une adresse copiée depuis le navigateur (« …:8096/web/index.html#!/home ») est ramenée à celle du serveur.
4. **Ajouter** : l'identifiant est vérifié, puis les bibliothèques de films, séries et vidéos apparaissent dans **Films** et **Séries** (rubriques « nom de la bibliothèque · nom du serveur »), avec les affiches et les fiches du serveur.

La lecture est **directe**, sans conversion par le serveur. Le mot de passe et la session sont rangés dans le trousseau.

### Plex

1. Réglages > Sources > **Ajouter** > **Plex**.
2. **Se connecter avec Plex** ouvre plex.tv dans le navigateur : connectez-vous et autorisez Kastideo. De retour dans Kastideo, choisissez le serveur de votre compte.
3. Vous pouvez aussi saisir l'adresse du serveur (port 32400) et son **jeton** (X-Plex-Token). Le jeton est **facultatif** si le serveur autorise le réseau local sans authentification (Plex > Réglages > Réseau > « Liste des adresses IP et réseaux autorisés sans authentification »).
4. **Ajouter** : les bibliothèques de films et de séries apparaissent dans **Films** et **Séries**.
<!--/mac-->

<!--pc-->
Réglages > Sources > **Ajouter une source** > **Jellyfin**, **Emby** ou **Plex**. **Rechercher sur le réseau** trouve les serveurs de la maison : cliquez sur le vôtre pour remplir le formulaire (sinon saisissez l'adresse ; sans port, 8096 ou 32400 est ajouté).

- **Jellyfin / Emby** : identifiant et mot de passe — **facultatif** si le compte n'en a pas (ou une **clé d'API** du tableau de bord). **Tester** vérifie l'adresse ; en cas d'échec, la réponse exacte du serveur s'affiche.
- **Plex** : **Se connecter avec Plex** ouvre plex.tv dans le navigateur ; autorisez Kastideo, puis choisissez le serveur de votre compte. Ou saisissez l'adresse et le **jeton** (X-Plex-Token), facultatif si le serveur autorise le réseau local sans authentification.
- Les bibliothèques apparaissent dans **Films** et **Séries** (« nom de la bibliothèque · nom du serveur »), avec les affiches, fiches, saisons et épisodes du serveur. Lecture directe, sans conversion.
- **Reprise et « vu » partagés dans les deux sens** : la position est transmise au serveur pendant la lecture et celle de vos autres appareils est reprise. Clic droit > **Marquer comme vu / non vu** ; pastille **Vu** sur les affiches.

> Pare-feu Windows : à la première recherche, autorisez Kastideo sur les réseaux privés pour que les serveurs puissent répondre.
<!--/pc-->

## Reprise et « vu » partagés avec les serveurs {#reprise-serveurs}

<!--mac-->
Avec Jellyfin, Emby et Plex, la position de lecture est transmise au serveur pendant la lecture : un film commencé dans Kastideo se reprend sur la télévision, et inversement. Un film vu jusqu'au bout est marqué **vu** sur le serveur. Clic droit sur un film ou un épisode > **Marquer comme vu / non vu** (aussi pour les fichiers des dossiers). Une pastille **Vu** s'affiche sur les affiches, une coche dans la liste des épisodes.

> Recherche sur le réseau : au premier usage, macOS demande l'autorisation d'accéder au **réseau local** ; acceptez-la (Réglages Système > Confidentialité et sécurité > Réseau local, sinon).
<!--/mac-->

## Guide TV (XMLTV) {#guide}

<!--mac-->
Chaque source peut avoir une adresse de guide TV au format XMLTV (`.xml` ou `.xml.gz`). Si vous la laissez vide, Kastideo utilise celle du serveur Xtream ou celle annoncée dans la playlist (`url-tvg`). Le guide est conservé de 6 h en arrière à 48 h en avant. Il est rechargé quand il arrive à moins de 12 h de sa fin (vérification toutes les heures si Kastideo reste ouvert). Si le fournisseur envoie un guide vide ou illisible, les programmes déjà connus sont conservés et un message l'indique sous la source (Réglages > Sources).

**Savoir d'où vient le guide.** Sous chaque source, Réglages > Sources indique combien de programmes le fournisseur a envoyés. Le bouton **Recharger le guide TV** (icône calendrier) relance le téléchargement du guide du fournisseur et du guide de secours. Les lignes du fournisseur qui ne sont que des **séparateurs de catégories** (« ♣♦♣---|FR| FRANCE FHD |FR|---♣♦♣ ») sont ignorées ; une version 4K ou FHD sans programme propre reprend celui de la version HD de la même chaîne ; les chaînes sans programme affichent « Programme non disponible ». Le **Journal**, sujet **Guide TV**, détaille chaque tentative : adresse demandée, réponse du serveur (code, taille, durée), nombre de chaînes et de programmes reçus, période couverte, nombre de vos chaînes reliées au guide du fournisseur, au guide de secours ou à aucun, et — si le guide ne contient rien d'exploitable — le début de la réponse du serveur.
<!--/mac-->

<!--pc-->
Le guide indiqué par le fournisseur est chargé en arrière-plan et gardé sur le disque. Le champ facultatif **Guide TV (XMLTV)** d'une source permet d'utiliser un autre guide (.xml ou .xml.gz).
<!--/pc-->

## Guide TV de secours (xmltvfr.fr) {#guide-secours}

<!--mac-->
Le guide de votre fournisseur peut être incomplet ou momentanément vide. Kastideo le complète avec un **guide de secours** gratuit, celui de **xmltvfr.fr** (guide « Complet » par défaut : environ 785 chaînes françaises et étrangères, 5 jours, mis à jour chaque jour) :

- seules les chaînes **sans programme** chez votre fournisseur sont complétées ; le guide du fournisseur reste prioritaire ;
- les chaînes sont reliées **par leur nom** : « |FR| TF1 FHD » → TF1, « |FR| FRANCE 2 UHD » → France 2, « |FR| TF1 4K » → TF1 4K ;
- le guide de secours est rechargé toutes les 12 heures.

Réglages > Général > **Guide TV de secours** : activer ou désactiver, choisir un autre guide xmltvfr.fr (France ~400 chaînes, TNT) ou saisir n'importe quelle adresse XMLTV, **Actualiser maintenant**, et voir combien de chaînes ont été reliées aux vôtres.
<!--/mac-->

<!--pc-->
Réglages > Général > **Guide TV** : un guide de secours complète les chaînes sans programme dans le guide du fournisseur, en les rapprochant par leur nom. Choisissez un guide xmltvfr.fr ou saisissez une adresse ; **Recharger le guide** relance tous les téléchargements. Le bouton **Journal du guide** ouvre le Journal sur le sujet *Guide TV* : adresse demandée, réponse du fournisseur (code, taille, durée), chaînes et programmes reçus, période couverte, nombre de vos chaînes reliées au fournisseur, au secours ou à aucun guide, et — si le guide est inutilisable — le début de la réponse du serveur. Les programmes du fournisseur sont filtrés sur les identifiants de vos chaînes : si le guide contient des programmes mais aucun pour vos chaînes, le journal montre les identifiants des deux côtés.
<!--/pc-->

## Gérer les sources {#gerer-sources}

<!--mac-->
Ouvrez **Kastideo > Réglages… (⌘,)**, onglet **Sources**, ou cliquez sur le bouton **Sources** de la barre d'outils.

- L'interrupteur active ou désactive une source sans la supprimer.
- Les boutons permettent d'actualiser, de modifier ou de supprimer une source.
- En cas d'erreur, le message s'affiche en rouge sous la source et un triangle orange apparaît dans la barre latérale.
<!--/mac-->

<!--pc-->
Réglages > **Sources** : **modifier** une source (bouton crayon : nom, serveur, identifiant, mot de passe, adresse de la playlist, guide TV — favoris, récents et corrections de chaînes sont gardés), l'actualiser, la supprimer, voir l'état de son guide TV. Le bouton **œil** affiche le mot de passe (ou la clé TMDB) pour le vérifier. Les sources sont actualisées au démarrage si leur dernière mise à jour date de plus de 6 heures (réglable). Si une actualisation renvoie une section vide, la précédente est gardée.
<!--/pc-->

# Naviguer

## L'écran d'accueil {#accueil}

![L'écran d'accueil](img:home)

<!--mac-->
Kastideo s'ouvre sur l'**accueil** : trois grands pavés **Direct**, **Films** et **Séries**, puis des boutons plus petits vers les **Favoris**, les **Récents**, le **Guide TV** et les **Enregistrements**.

- Le champ de **recherche** en haut cherche d'un coup dans les chaînes, les films et les séries ; un clic sur un résultat l'ouvre.
- La rangée **Reprendre la lecture** liste les films et épisodes entamés ; un clic reprend là où vous vous étiez arrêté.
- Si une lecture est en cours, un bandeau permet d'y **retourner** ou de l'**arrêter**.
- Pour revenir à l'accueil à tout moment : bouton **Accueil** (maison) en haut à gauche de la barre d'outils, **⌘0**, ligne **Accueil** de la barre latérale, ou touche **H** en interface TV.

Le **numéro de version** de Kastideo est affiché discrètement en bas à droite de l'accueil ; un clic ouvre les nouveautés de la version.
<!--/mac-->

<!--pc-->
Recherche globale (chaînes, films, séries), pavés **Direct**, **Films** et **Séries**, accès rapides **Favoris**, **Récents**, **Guide TV**, **MultiVue** et **Enregistrements**, rangée **Reprendre la lecture**.
<!--/pc-->

## Mes vidéos {#mes-videos}

<!--mac-->
Dès qu'une source **Dossiers**, **Jellyfin**, **Emby** ou **Plex** existe, une tuile **Mes vidéos** apparaît sur l'accueil (et une ligne dans la barre latérale, **⌘8**). Elle réunit vos vidéos, à part de l'IPTV :

- **À la une** : **Reprendre la lecture** (films et épisodes entamés), **Ajouts récents**, **Films à voir**, puis une rangée Films, Séries et Vidéos ;
- **Films**, **Séries**, **Vidéos** : grilles avec recherche, filtres (**genre**, **année**, **non vus**) et tri (titre, ajout récent, année) ;
- **Dossiers** : parcourez vos dossiers et sous-dossiers comme dans le Finder (fil d'Ariane pour remonter), et les bibliothèques des serveurs ;
- **Sources** : toutes, ou une seule (NAS, Emby, Plex…). Un triangle orange signale une erreur : clic droit > **Détails de l'erreur…** affiche la requête et la **réponse exacte du serveur** (bouton **Copier**), puis **Réessayer**.

Dans **Films** et **Séries**, le sélecteur **Tout / IPTV / Mes vidéos** (barre latérale, au-dessus des catégories) choisit ce qui est affiché : l'IPTV seul (par défaut), vos vidéos seules, ou les deux mélangés. Les catégories de vos vidéos ne sont jamais masquées par le réglage des pays.
<!--/mac-->

<!--pc-->
Dès qu'une source **Dossiers**, **Jellyfin**, **Emby** ou **Plex** existe, une tuile **Mes vidéos** apparaît sur l'accueil (raccourci **Ctrl+8**). Elle réunit vos vidéos, à part de l'IPTV :

- **À la une** : **Reprendre la lecture** (films et épisodes entamés), **Ajouts récents**, **Films à voir**, puis une rangée Films, Séries et Vidéos ;
- **Films**, **Séries**, **Vidéos** : grilles avec recherche, filtres (**genre**, **année**, **non vus**) et tri (titre, ajout récent, année) ;
- **Dossiers** : parcourez vos dossiers et sous-dossiers comme dans l'explorateur de fichiers (fil d'Ariane pour remonter), et les bibliothèques des serveurs ;
- **Sources** : toutes, ou une seule (NAS, Emby, Plex…). Un triangle orange signale une erreur : clic droit > **Détails de l'erreur…** (ou bouton **Détails**) affiche la requête et la **réponse exacte du serveur**, puis **Réessayer**.

Dans **Films** et **Séries**, le sélecteur **Tout / IPTV / Mes vidéos** (barre latérale, au-dessus des catégories) choisit ce qui est affiché : l'IPTV seul (par défaut), vos vidéos seules, ou les deux mélangés. Les catégories de vos vidéos ne sont jamais masquées par le réglage des pays.
<!--/pc-->

## Colonnes et barre latérale {#colonnes}

![Colonnes et barre latérale](img:layout)

<!--mac-->
En interface Classique, la fenêtre comporte trois colonnes :

- **Barre latérale** : Accueil, Direct, Films, Séries, Favoris, Récents, Guide TV, puis les catégories de la section choisie et l'état de vos sources.
- **Liste** : les éléments de la section ou de la catégorie, avec le programme en cours pour les chaînes. Le champ **Rechercher** filtre la liste sans tenir compte des majuscules ni des accents.
- **Lecteur** : la vidéo, avec en dessous le programme en cours, sa progression et les programmes suivants.

Un clic droit sur un élément permet de l'ajouter aux favoris ou de copier l'adresse du flux.
<!--/mac-->

<!--pc-->
Sélecteur Direct / Films / Séries, puis : toutes les chaînes ou tous les films, **Favoris**, **Récents**, et pour le direct **Thèmes**, **Guide TV** et **MultiVue** ; **Enregistrements** ; les **catégories**. En bas : enregistrement et téléchargement en cours (progression, temps restant) et **Réglages**.
<!--/pc-->

## Trois interfaces au choix {#interfaces}

<!--mac-->
Kastideo propose trois présentations, que vous choisissez **séparément pour le direct, les films, les séries, et les favoris / récents** :

- **Classique** : les trois colonnes décrites dans [Colonnes et barre latérale](help:colonnes).
- **TV** (direct uniquement) : voir [L'interface TV](help:interface-tv).
- **Cinéma** : un grand **bandeau « à la une »** qui défile (voir [Le bandeau « à la une »](help:bandeau)), puis des **rangées horizontales** : reprise, favoris et une rangée par catégorie. Les films et séries s'affichent en affiches, les chaînes en vignettes avec le programme en cours. Un clic sur une chaîne ouvre le lecteur en plein cadre. Un clic sur l'affiche d'un **film** ou d'une **série** ouvre d'abord sa **fiche** : grande image de fond, affiche, année, durée, genres, note, résumé, réalisateur, distribution (avec photos), bouton **Retour à Films** (ou Séries) en haut à gauche, boutons **Lire** / **Reprendre**, **Voir les épisodes**, **Bande-annonce**, **Télécharger** et favori. Les informations viennent de votre fournisseur IPTV ; ajoutez une clé **TMDB** gratuite (Réglages > Général > Fiches des films et séries) pour des fiches plus complètes. **Retour** (ou Échap) revient au catalogue. En haut de la fenêtre, les onglets **Direct / Films / Séries / Guide TV / Favoris / Récents / Enregistrements** remplacent la barre latérale ; la recherche fonctionne comme en Classique. « Tout voir » ouvre une catégorie complète en grille.

Pour changer d'interface :

- le bouton **Interface** de la barre d'outils (il s'applique au type de contenu affiché),
- menu **Présentation** : **⌥⌘1** Classique, **⌥⌘2** Cinéma, **⌥⌘3** TV (direct),
- ou **Réglages > Apparence**.

Par exemple : TV pour le direct et Cinéma pour les films et séries. La section **Enregistrements** s'affiche toujours en interface Classique. Le choix par défaut est Classique partout.
<!--/mac-->

<!--pc-->
Réglages > Apparence > **Interface par type de contenu** :

- **Classique** : trois colonnes (barre latérale, liste avec le programme en cours, lecteur ou fiche à droite).
- **Cinéma** : bandeau « à la une », affiches ou vignettes en rangées horizontales, fiche en page entière. Pour le direct : rangées « Sport en ce moment », « Info en direct », « Ce soir » par thème, favoris, récents, catégories ; un clic ouvre la chaîne en plein cadre, **Retour** (ou Échap) l'arrête.
- **TV** (direct seulement) : la chaîne en plein cadre, comme sur un téléviseur (voir [L'interface TV](help:interface-tv)).
<!--/pc-->

## Le bandeau « à la une » (Cinéma) {#bandeau}

<!--mac-->
En haut des sections Films et Séries, un **carrousel plein cadre** fait défiler une sélection : grande image de fond, affiche, titre, année, durée, genres, note, résumé et boutons **Lire** (ou **Reprendre** / **Voir les épisodes**), **Plus d'infos** (la fiche) et **Bande-annonce**. Il mélange :

- les **tendances de la semaine** sur TMDB que l'on retrouve dans votre catalogue (clé TMDB nécessaire) ;
- les **derniers ajouts** de votre fournisseur ;
- une **sélection d'une catégorie** de votre choix (par exemple « Nouveautés » ou « Netflix »), ou de tout le catalogue au hasard.

Le défilement s'arrête quand la souris survole le bandeau ; les flèches et les points permettent de naviguer. En **Direct**, le bandeau montre le **programme en cours** de vos chaînes favorites et récentes, avec sa progression, le programme suivant et **Regarder**.

Réglages > Apparence > **Bandeau « à la une »** : afficher ou masquer, hauteur (compact, normal, grand), vitesse de défilement, sources du carrousel et catégories des films et des séries.
<!--/mac-->

<!--pc-->
Il fait défiler des films ou séries (tendances de la semaine sur TMDB disponibles chez vous, derniers ajouts, sélection d'une catégorie) ou, pour le direct, le programme en cours de vos chaînes. Flèches au survol, arrêt quand la souris le survole. Réglages > Apparence > **Bandeau « à la une »** : afficher ou masquer, hauteur, vitesse, sources.
<!--/pc-->

## Pays et langues (Cinéma) {#pays}

<!--mac-->
Votre fournisseur mélange souvent plusieurs pays (catégories « FR| … », « |PT| … », « ITALIA »…). Réglages > Apparence > **Pays et langues (interface Cinéma)** liste les pays repérés dans les noms de vos catégories, avec le nombre de contenus : cochez ceux que vous voulez voir. Les **derniers ajouts**, les **tendances**, le **bandeau « à la une »** et les **rangées par catégorie** de l'interface Cinéma ne montrent alors que ces pays. **Garder les catégories sans pays indiqué** conserve les catégories comme « Action » ou « Nouveautés ». **Tous les pays** revient à l'affichage complet. Les listes de l'interface Classique et la recherche restent complètes.
<!--/mac-->

<!--pc-->
Votre fournisseur mélange souvent plusieurs pays (catégories « FR| … », « |PT| … », « ITALIA »…). Réglages > Apparence > **Pays et langues (interface Cinéma)** liste les pays repérés dans les noms de vos catégories, avec le nombre de contenus : choisissez ceux à montrer. Les **derniers ajouts**, les **tendances**, le **bandeau « à la une »** et les **rangées par catégorie** de l'interface Cinéma ne montrent alors que ces pays. **Garder les catégories sans pays indiqué** conserve les catégories comme « Action » ou « Nouveautés ». **Tous** revient à l'affichage complet. Les listes et la recherche restent complètes.
<!--/pc-->

## L'interface TV (direct) {#interface-tv}

<!--mac-->
La chaîne occupe tout le cadre, comme sur une télévision. Au premier affichage, Kastideo reprend la dernière chaîne regardée.

- **Panneau de chaînes** : touche **←**, **Entrée**, ou approchez la souris du bord gauche. Il liste les chaînes avec numéro, logo, programme en cours et progression. Le menu en haut filtre par **Toutes / Favoris / Récents / catégorie**, et le champ **Rechercher** filtre par nom. Il se referme seul après quelques secondes (touche **→** ou **Échap** pour le fermer tout de suite).
- **Zapping** : **↑ / ↓** chaîne précédente / suivante de la liste affichée, **B** retour à la chaîne précédente.
- **Numéro de chaîne** : tapez les chiffres (par exemple **1** puis **2**) ; la chaîne s'ouvre après 1,6 s ou avec **Entrée**. Si votre fournisseur ne numérote pas ses chaînes, le numéro désigne la position dans la liste affichée.
- **Bandeau d'information** : s'affiche cinq secondes à chaque changement de chaîne (logo, numéro, programme en cours, horaires, programme suivant, heure). **I** ou **→** l'affiche ou le masque.
- Autres touches : **F** favori, **M** muet, **Espace** pause (direct en différé).
- Double-clic sur l'image ou **⌘↩** : plein écran ; la barre d'outils se masque.
- Les touches du clavier ne fonctionnent pas pendant la saisie dans le champ de recherche. Les onglets en haut de la fenêtre permettent de passer aux Films, aux Séries, etc.
<!--/mac-->

<!--pc-->
- **↑ / ↓** : chaîne précédente / suivante ; **tapez un numéro** (jusqu'à 4 chiffres).
- **←** ou bord gauche : **panneau des chaînes** (filtre, recherche, programme en cours).
- **→** ou **I** : **bandeau d'information** (programme en cours et suivant).
- **B** : chaîne précédente — **F** : favori — **M** : son — **Espace** : pause — **G** : guide TV — **H** : accueil.
<!--/pc-->

## Le Guide TV en grille {#guide-grille}

<!--mac-->
Section **Guide TV** (barre latérale, onglet **Guide TV** des interfaces Cinéma et TV, **⌘7**, ou touche **G** en interface TV). Les chaînes sont en lignes, les heures en colonnes ; le trait rouge marque l'heure actuelle.

- **‹ ›** décalent la grille, **Maintenant** revient à l'heure actuelle, le menu de la date saute à un autre jour (19 h pour les jours suivants).
- Choisissez la durée affichée (**2 h / 3 h / 6 h**), filtrez par **favoris**, **récents** ou **catégorie**, ou recherchez une chaîne.
- Cliquez sur un programme : description, bouton **Regarder**, **Enregistrer** (programme en cours) ou **Programmer l'enregistrement** (programme à venir). Un point rouge signale un enregistrement programmé.
- Les jours passés (menu de la date, section **Revoir**) et les programmes marqués ↺ permettent le **replay** (voir [Replay](help:replay)).
- Cliquez sur le nom d'une chaîne pour la regarder. Seules les chaînes ayant des programmes sont listées : si la grille est vide, vérifiez l'adresse du guide dans les réglages de la source.
<!--/mac-->

<!--pc-->
Accueil, barre latérale du direct, **Ctrl+7** ou touche G en interface TV. Chaînes en lignes, heures en colonnes, trait rouge sur l'heure actuelle ; **‹ Maintenant ›**, choix du jour, durée affichée 2 h / 3 h / 6 h, filtre (toutes, favoris, récents, thème, catégorie) et recherche. Un clic sur un programme ouvre sa fiche : **Regarder**, **Enregistrer**, **Programmer l'enregistrement** (point rouge dans la grille) ou **M'alerter au début** (cloche). Sur un programme passé d'une chaîne à replay (↺) : **Revoir** ou **Enregistrer ce replay** ; les jours passés sont dans le menu de la date.
<!--/pc-->

## Le Direct par thème {#direct-theme}

<!--mac-->
La section **Thèmes** de la barre latérale (sous Direct) classe le direct par **thème** — Sport, Auto-Moto (sports mécaniques), Films, Séries, Info, Documentaires, Nature / Chasse & Pêche, Jeunesse, Divertissement, Cuisine & Maison, Musique, Généralistes, Régional (France 3 régions, télévisions locales), International (chaînes étrangères), Religion, Radio — sans les catégories que vous avez masquées. Trois modes :

- **En ce moment** : ce qui est diffusé maintenant, classé d'après le **genre du programme** dans le guide TV (un film sur une chaîne généraliste apparaît dans « Films »), avec la progression. Les chaînes **sans programme au guide** sont quand même proposées si leur **nom suffit à les classer** (beIN Sports → Sport…) : elles s'affichent avec leur nom, sans progression.
- **Ce soir** : les programmes qui commencent entre **20 h et 23 h**. Clic droit sur un programme à venir > **M'alerter au début du programme**.
- **Chaînes** : les chaînes classées par spécialité. Le thème est déduit automatiquement du nom de la chaîne (beIN, Eurosport → Sport ; BFM, LCI → Info…) puis de ses programmes habituels ; clic droit > **Thème de la chaîne** pour le corriger.

Chaque chaîne n'apparaît **qu'une fois**, même si votre fournisseur la propose en plusieurs versions (4K, FHD, HD, SD) : Kastideo choisit la version adaptée à **votre connexion** (réglage **Automatique**, dans Réglages > Général > Lecture > Version des chaînes) — il descend d'un cran après une lecture instable et remonte après trois lectures fluides. Clic droit > **Version** pour en choisir une autre.

Les thèmes sont aussi proposés ailleurs : rangées « Sport en ce moment », « Films en cours »… en tête du Direct en interface **Cinéma**, filtre **Thèmes** du panneau de chaînes de l'interface **TV** et du **Guide TV**, et pastilles « À la télé maintenant » (et « Ce soir ») sur l'**accueil**.

Dans **Sport**, une seconde rangée filtre par **discipline** : Football, Rugby, Tennis, Basket, Sports de combat, Golf, Cyclisme, Handball, Sports mécaniques, Sports d'hiver, Hippisme, Athlétisme & natation (d'après le titre, le genre et la description des programmes).

**Contenus adultes** : les chaînes et contenus dont le nom contient « |XX| » (ou rangés dans une catégorie adulte) sont **masqués partout** par défaut. Pour les afficher, et faire apparaître le thème **Adulte** : Réglages > Général > Lecture > **Afficher les contenus adultes**.

**Alertes de programme** (bouton 🔔 de la vue Thèmes) : Kastideo vous prévient deux minutes avant le début d'un programme dont le titre contient un mot choisi (« PSG », « Formule 1 »…), d'un thème sur vos chaînes favorites, ou d'un programme précis. Une notification et un bandeau **Regarder** apparaissent.
<!--/mac-->

<!--pc-->
Barre latérale > **Thèmes** : **En ce moment**, **Ce soir** (20 h – 23 h) ou **Chaînes**, filtrés par thème (Sport, Info, Films, Jeunesse, Documentaires…) et, pour le sport, par discipline. Une seule version par chaîne (FHD, HD ou SD selon la connexion). Clic droit : version de la chaîne, **thème de la chaîne** (pour corriger le classement), favoris, modifier la chaîne.
<!--/pc-->

# Lecture

## L'essentiel {#lecture}

<!--mac-->
Kastideo lit tous les contenus avec le moteur **VLC** : direct au format MPEG-TS (.ts), HLS (.m3u8), MP4, MKV, AVI…

- La lecture démarre dès que vous sélectionnez une chaîne, un film ou un épisode.
- Pendant l'ouverture, le logo et le nom de la chaîne s'affichent. Le badge **« Prête en x s »** indique ensuite le temps de démarrage (désactivable dans les réglages).
- Les contrôles apparaissent au survol de la vidéo : lecture / pause, recul de 10 s et avance de 30 s pour les films et épisodes, barre de progression, volume (jusqu'à 200 %) et mode cinéma.
- Un clic sur la vidéo met en pause ; un **double-clic** active le **mode cinéma** : la fenêtre passe en plein écran et seule la **vidéo** reste affichée (ni colonnes ni barre d'outils ; le bouton vert de la fenêtre et **⌃⌘F** ont le même effet pendant une lecture). **Échap** ou **⌘↩** pour en sortir.
- **Reprise de la lecture** : pour les films et épisodes, Kastideo mémorise votre position. À la réouverture, la lecture reprend là où vous vous étiez arrêté, avec un message proposant de **recommencer au début**. Des barres de progression apparaissent dans les listes, les affiches et les épisodes. Désactivable, ou positions effaçables, dans les réglages.
- Pour les sources Xtream, le direct est lu au format MPEG-TS (.ts), comme le lecteur de référence Xtream ; si le flux échoue, Kastideo essaie automatiquement la variante .m3u8 (et inversement).
<!--/mac-->

<!--pc-->
Le lecteur (moteur mpv) a une barre de contrôles qui se cache seule, une pastille de santé du flux, le volume, le mode cinéma (double-clic ou Ctrl+Entrée) et le plein écran (F11). Pour les films et épisodes : mini-timeline, −10 s / +30 s, **reprise de lecture** là où vous vous étiez arrêté, **Retour à la fiche**.
<!--/pc-->

## Barre de contrôle, timeline et panneau d'informations {#barre-controle}

<!--mac-->
- **Barre rétractable** : elle apparaît au moindre mouvement de souris et disparaît, avec le pointeur, après 3 secondes d'inactivité (elle reste visible tant que la souris est dessus, pendant la pause ou quand le panneau est ouvert).
- **Mini-timeline** (films et épisodes) : un trait fin au-dessus des boutons, qui s'épaissit au survol en affichant l'heure visée ; cliquez ou glissez pour vous déplacer.
- **Santé du flux** : une pastille **verte** (Excellent), **orange** (Correct) ou **rouge** (Instable) indique la qualité de réception, avec la définition (SD, HD, 4K). Au survol : définition exacte, débit, images par seconde, images perdues et coupures de la dernière minute.
- **Panneau « Informations »** (bouton ⓘ ou **⌘I**, Échap pour fermer) : il glisse depuis la droite par-dessus la vidéo et montre la chaîne et son programme en cours et à venir, ou le résumé et la distribution d'un film ; le choix de la **piste audio** (langue, audiodescription…) et des **sous-titres** ; la qualité de réception détaillée.
<!--/mac-->

## MultiVue (plusieurs chaînes à la fois) {#multivue}

<!--mac-->
La **MultiVue** affiche jusqu'à **4 chaînes en direct** dans une même fenêtre (1 en plein cadre, 2 côte à côte, 3 ou 4 en grille). Le **son suit la vignette active** (bordure orange) : cliquez sur une vignette ou utilisez les touches **1 à 4**.

- Ouverture : menu **Lecture > MultiVue…** (**⌥⌘M**), ou clic droit sur une chaîne > **Ajouter à la MultiVue**.
- Dans la fenêtre : **+** ajoute une chaîne (favoris, récents ou recherche) ; au survol d'une vignette, ⟳ change la chaîne et ✕ la retire ; **Tout arrêter** coupe tous les flux. Fermer la fenêtre arrête la MultiVue.
- Chaque flux utilise **une connexion** à votre fournisseur. La MultiVue est donc **désactivée par défaut** : indiquez le nombre de connexions simultanées de votre abonnement dans **Réglages > Général > Lecture** (2 à 4) pour l'activer. Le bouton **Tester la connexion** d'une source Xtream affiche ce nombre. À l'ouverture, la lecture principale s'arrête pour libérer sa connexion (sauf enregistrement en cours) ; un enregistrement ou un téléchargement occupe aussi une connexion.
<!--/mac-->

<!--pc-->
La **MultiVue** affiche jusqu'à **4 chaînes en direct** sur un même écran. Le **son suit la vignette active** (bordure orange).

- **Activation** : chaque chaîne utilise une connexion à votre fournisseur. La MultiVue est donc désactivée tant que vous n'avez pas indiqué le nombre de **connexions simultanées** de votre abonnement : Réglages > Général > Lecture (2 à 4). **Détecter** le demande à vos sources Xtream.
- **Ouverture** : accueil > **MultiVue**, barre latérale du direct > **MultiVue**, **Ctrl+Alt+M**, ou clic droit sur une chaîne > **Ajouter à la MultiVue**. La chaîne que vous regardiez devient la première vignette ; si elle est en cours d'enregistrement, elle continue en arrière-plan sans le son.
- **Ajouter** : bouton **+** (ou touche **A**) : favoris, récents, toutes les chaînes ou recherche. Une case vide de la grille propose aussi « Ajouter une chaîne ».
- **Dispositions** (en haut à droite) : **Automatique** (1 en plein cadre, 2 côte à côte, 3 ou 4 en grille), **Grille 2 × 2**, **Une grande** et les autres en petit, **Côte à côte**. La disposition est mémorisée.
- **Grande image ↔ vignette** : **double-clic** sur une vignette (ou touche **G**) pour la passer en grand avec le son ; double-clic de nouveau sur la grande image pour revenir à la grille.
- **Au survol d'une vignette** : en grand, changer de chaîne, retirer. Le nom de la chaîne et le programme en cours s'affichent en bas.
- **Groupes mémorisés** (icône signet) : **Mémoriser ce groupe…** enregistre les chaînes et la disposition sous un nom (ex. « Multiplex foot ») ; un clic sur un groupe le rouvre, la croix le supprime.
- **Clavier** : **1 à 4** son sur la vignette, **G** en grand, **A** ajouter, **M** couper le son, **Suppr** retirer la vignette active, **F** ou **F11** plein écran, **Échap** quitter le plein écran puis la MultiVue.
- **Tout arrêter** (ou Retour) coupe tous les flux et revient à l'écran précédent.

> Un enregistrement ou un téléchargement occupe aussi une connexion : une icône ⓘ le rappelle dans la barre de la MultiVue. Si une vignette affiche « La chaîne ne répond pas », le fournisseur refuse sans doute une connexion de plus : retirez une chaîne ou baissez le nombre de connexions.
<!--/pc-->

## Si une chaîne ne démarre pas {#chaine-ne-demarre-pas}

<!--mac-->
Si aucune image n'arrive au bout de **20 secondes**, Kastideo essaie automatiquement l'autre format du flux (.ts ou .m3u8), puis affiche un message d'erreur avec le détail renvoyé par le moteur VLC.

Le **Journal** (menu **Lecture > Journal de lecture…**, **⌥⌘L**, ou bouton dans le message d'erreur) est l'outil de diagnostic de Kastideo. Les identifiants et mots de passe y sont **masqués** : vous pouvez le copier pour le partager en cas de problème.

- **Sujets** : les messages sont classés en *Guide TV*, *Lecture et relais*, *Sources et catalogues*, *Enregistrements*, *Fiches TMDB*, *Mises à jour* et *Affichage et divers*. Cliquez sur un ou plusieurs sujets pour ne voir que ceux-là (le nombre de lignes de chaque sujet est indiqué).
- **Rechercher** un mot dans le journal, ou n'afficher que les **erreurs et alertes**.
- **Copier l'affichage** copie uniquement ce qui est affiché (sujets, recherche), avec la mention du filtre en tête.
- **Niveau de détail** (par sujet) : *Normal* (l'essentiel), *Détaillé* (par défaut pour le Guide TV) ou *Débogage* (tout). Le réglage s'applique aux lignes écrites à partir de ce moment ; les erreurs et alertes sont toujours gardées.
- **Session en cours / Session précédente** : le journal est conservé sur disque, ce qui permet de relire ce qui s'est passé au démarrage de la session précédente. **Afficher le dossier du journal** ouvre le fichier dans le Finder.
<!--/mac-->

## Direct en différé {#differe}

<!--mac-->
Mettez une chaîne en direct en **pause** : le moteur VLC continue de recevoir le flux et le garde en réserve. À la reprise, vous regardez en **différé** (indicateur jaune « DIFFÉRÉ −2:34 » dans les contrôles). Si un flux ne permet pas la pause, le bouton est grisé.

En différé, les contrôles proposent :

- une **timeline** : à gauche le moment de la pause, à droite le **direct**. **Glissez le curseur vers la droite** pour avancer : Kastideo accélère la lecture jusqu'au point choisi (repère jaune), puis revient à la vitesse normale ;
- **+30 s** (ou ⌘]) : avancer de 30 secondes de la même façon ;
- la **vitesse** (×1, ×1,25, ×1,5, ×2) : accélérez pour grignoter le retard ; la lecture revient d'elle-même à ×1 en rattrapant le direct ;
- **Rattraper** : accélère jusqu'au direct, sans rien sauter ;
- **Retour au direct** : revient immédiatement au direct. Le moteur VLC ne sachant pas, sur la plupart des flux, sauter dans le différé, le flux est alors rouvert et le différé effacé. Si le flux permet le déplacement, le différé est conservé et les boutons −10 s / +30 s sautent directement.

**Où est stocké le différé ?** Dans le dossier temporaire de Kastideo (`~/Library/Containers/fr.jmezes.kastideo/Data/tmp/`, fichiers `vlc-timeshift-…`), effacé au changement de chaîne ; comptez 1 à 4 Go par heure selon la qualité. Réglages > Général > Lecture : **Durée maximale du différé** (30 min à 3 h, ou sans limite ; une fois atteinte, la lecture reprend toute seule), **Vitesse pour rattraper le direct**, et bouton **Afficher** pour ouvrir le dossier.
<!--/mac-->

<!--pc-->
Mettez une chaîne en pause (ou revenez en arrière avec ← ou la barre) : elle continue d'être gardée (jusqu'à 1 h par défaut, réglable). Sans action de votre part, la chaîne reste « EN DIRECT ». La barre du différé affiche le retard, un curseur pour revenir en arrière ou rattraper en accéléré, la vitesse, **Rattraper** et **Retour au direct**. ← / → : −10 s / +30 s.
<!--/pc-->

## Replay : revoir un programme déjà diffusé {#replay}

<!--mac-->
Certains abonnements IPTV conservent les chaînes jusqu'à **14 jours** (selon le fournisseur et la chaîne). Kastideo le détecte tout seul : les chaînes concernées portent une icône **↺** dans les listes et dans le Guide TV.

- **Dans le Guide TV** : cliquez sur un programme **passé** (marqué ↺) puis **Revoir**. Sur le programme **en cours**, **Revoir depuis le début** le relit depuis son commencement. **Enregistrer ce replay** télécharge le programme depuis l'archive du fournisseur (dossier des enregistrements).
- **Jours précédents** : le menu de la date du Guide TV propose **Revoir (replay)** avec les jours passés.
- **Depuis une chaîne** : clic droit sur la chaîne > **Revoir (replay)** (programmes récents de cette chaîne). L'interface Cinéma propose aussi la rangée **À revoir** (vos chaînes préférées avec replay).
- **Pendant le replay**, la barre du lecteur permet la pause et le déplacement dans le programme. À la fin, Kastideo **revient au direct** de la chaîne (désactivable).
- **Réglages > Général > Replay** : activer ou non le replay, nombre de **jours de programmes passés gardés dans le guide** (plus de jours = plus de mémoire), **décalage de l'heure** (si le programme revu est décalé de quelques minutes ou d'une heure, corrigez-le ici ; le fuseau du serveur est lu automatiquement), retour au direct.
- Le replay compte comme **une connexion** : il ferme la chaîne en cours, comme un changement de chaîne.
- Si un replay ne démarre pas, ouvrez le **Journal** (sujet « Lecture et relais ») : l'adresse d'archive composée et le décalage utilisé y sont indiqués. Le guide du fournisseur doit contenir les programmes passés : rechargez-le après avoir augmenté le nombre de jours conservés.
<!--/mac-->

<!--pc-->
Certains abonnements IPTV conservent les chaînes jusqu'à **14 jours** (selon le fournisseur et la chaîne). Kastideo le détecte tout seul : les chaînes concernées portent une icône **↺** dans les listes et dans le Guide TV.

- **Dans le Guide TV** : cliquez sur un programme **passé** (marqué ↺) puis **Revoir**. Sur le programme **en cours**, **Revoir depuis le début** le relit depuis son commencement. **Enregistrer ce replay** télécharge le programme depuis l'archive du fournisseur (dossier des enregistrements).
- **Jours précédents** : le menu de la date du Guide TV propose **Revoir (replay)** avec les jours passés.
- **Depuis une chaîne** : clic droit sur la chaîne > **Revoir (replay)…** (programmes récents de cette chaîne). L'interface Cinéma propose aussi la rangée **À revoir** (vos chaînes préférées avec replay).
- **Pendant le replay**, la barre du lecteur permet la pause et le déplacement dans le programme. À la fin, Kastideo **revient au direct** de la chaîne (désactivable).
- **Réglages > Général > Replay** : activer ou non le replay, nombre de **jours de programmes passés gardés dans le guide** (plus de jours = plus de mémoire), **décalage de l'heure** (si le programme revu est décalé de quelques minutes ou d'une heure, corrigez-le ici ; le fuseau du serveur est lu automatiquement), retour au direct.
- Le replay compte comme **une connexion** : il ferme la chaîne en cours, comme un changement de chaîne.
- Si un replay ne démarre pas, ouvrez le **Journal** (bouton Journal, sujet « Lecture et relais ») : l'adresse d'archive composée et le décalage utilisé y sont indiqués. Le guide du fournisseur doit contenir les programmes passés : rechargez-le après avoir augmenté le nombre de jours conservés.
<!--/pc-->

## Une seule connexion à la fois {#connexion-unique}

<!--mac-->
La plupart des abonnements IPTV n'autorisent qu'**un flux simultané**. Kastideo ferme toujours le flux en cours avant d'ouvrir le suivant : vous pouvez zapper sans risque de dépasser votre limite. Si la lecture échoue, vérifiez qu'aucun autre appareil (TV, téléphone, Piboard…) ne regarde avec le même abonnement.
<!--/mac-->

<!--pc-->
La plupart des abonnements n'autorisent qu'une connexion. Kastideo ferme la chaîne précédente avant d'ouvrir la suivante (**relais de flux**, Réglages > Général > Lecture) et vous demande avant d'interrompre un enregistrement.
<!--/pc-->

## Diffuser sur un téléviseur {#cast}

Envoyez ce que vous regardez — **chaîne en direct, film, série, vidéo locale ou YouTube** — vers un téléviseur du même réseau, sans quitter Kastideo. La barre de lecture reste votre télécommande.

### Ce qui est possible

- **Chromecast, Google TV, TV Android** (et beaucoup de téléviseurs avec Chromecast intégré) : la lecture entière part sur le téléviseur.
- **Apple TV (AirPlay)** : Kastideo ne peut pas envoyer la vidéo directement. Utilisez la **recopie d'écran** de macOS (voir plus bas).
- **YouTube** : la vidéo s'ouvre dans l'application YouTube du téléviseur, ou dans le navigateur (au choix dans les réglages).

### Diffuser un contenu

1. Lancez une chaîne, un film, une série ou une vidéo.
2. Dans la barre de lecture, cliquez sur le bouton **téléviseur**.
3. Choisissez l'appareil dans la liste. Si rien n'apparaît, **Chercher à nouveau** : le téléviseur doit être allumé et sur le même réseau.
4. L'image part sur le téléviseur. Sur l'ordinateur, un écran indique « Diffusion sur… ».

La lecture **reprend là où vous en étiez**. Pause, lecture, avance et recul de 10 / 30 s, position, volume et sourdine de la barre agissent sur le téléviseur. Lancer un autre contenu pendant la diffusion l'envoie aussi au téléviseur.

Pour revenir, choisissez **Arrêter la diffusion** (ou **Reprendre sur l'ordinateur**) : la lecture reprend sur l'ordinateur à la même position.

<!--pc-->
### ffmpeg : la conversion de la vidéo

Sous Windows et Linux, Kastideo prépare la vidéo avec **ffmpeg** avant de l'envoyer au téléviseur. Il est fourni avec la version Windows et l'AppImage Linux. Avec le paquet .deb, installez-le : `sudo apt install ffmpeg`. Si Kastideo ne le trouve pas, indiquez son chemin dans **Réglages > Général > Cast**.

- **Préparation de la vidéo** : *Automatique* copie la vidéo quand elle est déjà en H.264 (léger pour l'ordinateur) et la convertit sinon ; *Toujours convertir* est le plus compatible.
- **Définition maximale** : 720p ou 1080p.
- **Ajouter un téléviseur par son adresse IP** : utile si la recherche automatique ne le voit pas (réseau Wi-Fi invité, VLAN…).

Le pare-feu de Windows peut demander d'autoriser Kastideo : acceptez sur les réseaux **privés**, sinon le téléviseur ne peut pas lire le flux.
<!--/pc-->
<!--mac-->
### Apple TV et AirPlay

VLC, le moteur de lecture de Kastideo, n'envoie pas la vidéo en AirPlay. Pour une Apple TV : menu **Centre de contrôle > Recopie de l'écran** (ou **Réglages Système > Moniteurs**), choisissez l'Apple TV, puis lisez Kastideo en plein écran. Le bouton téléviseur de la barre propose un raccourci vers les réglages d'écran.

### Autorisation réseau

Au premier usage, macOS demande si Kastideo peut **trouver des appareils sur le réseau local** : acceptez, sinon aucun téléviseur n'apparaît (Réglages Système > Confidentialité et sécurité > Réseau local).
<!--/mac-->

### YouTube sur le téléviseur

Dans **Réglages > Général > Cast**, choisissez :

- **Application YouTube du téléviseur** : Kastideo demande au téléviseur d'ouvrir YouTube sur la vidéo choisie (clic droit sur une vidéo > **Lire sur un téléviseur**). Il faut que l'application YouTube soit installée sur le téléviseur.
- **Navigateur (bouton Diffuser de Chrome)** : la vidéo s'ouvre dans votre navigateur ; utilisez le bouton **Diffuser** de Chrome pour l'envoyer sur le téléviseur.

### Limites à connaître

- Une seule connexion à votre fournisseur : pendant la diffusion, l'ordinateur ne lit plus la chaîne (voir [Une seule connexion à la fois](help:connexion-unique)).
- Le **direct** ne permet pas de se déplacer dans le temps pendant la diffusion ; le **différé** de l'ordinateur est coupé.
- L'**enregistrement** d'une chaîne et le **MultiVue** ne se combinent pas avec la diffusion.
- Il y a quelques secondes de décalage, plus qu'avec une lecture locale.
- Un téléviseur qui ne répond pas à la recherche : vérifiez qu'il est allumé et sur le même réseau Wi-Fi ou Ethernet que l'ordinateur.

## Mémoire tampon {#tampon}

<!--mac-->
Dans **Réglages > Général > Lecture**, choisissez le compromis entre rapidité et stabilité :

- **Rapide** (par défaut) : 0,4 s de réserve, le zapping le plus court.
- **Équilibré** : 1 s.
- **Stable** : 3 s, pour les connexions ou les serveurs irréguliers (moins de coupures, démarrage plus lent).
<!--/mac-->

## Le Journal (diagnostic) {#journal}

<!--pc-->
Le **Journal** (**Ctrl+Alt+L**, ou bouton dans l'accueil et dans les messages d'erreur) est l'outil de diagnostic de Kastideo. Les identifiants et mots de passe y sont **masqués** : vous pouvez le copier pour le partager.

- **Sujets** : *Guide TV*, *Lecture et relais*, *Sources et catalogues*, *Enregistrements*, *Fiches TMDB*, *Mises à jour*, *Affichage et divers*. Cliquez sur un ou plusieurs sujets pour ne voir que ceux-là (le nombre de lignes de chaque sujet est indiqué).
- **Rechercher** un mot, ou n'afficher que les **erreurs et alertes**.
- **Copier l'affichage** copie uniquement ce qui est affiché, avec le filtre en tête.
- **Niveau de détail** (par sujet) : *Normal*, *Détaillé* (par défaut pour le Guide TV) ou *Débogage* (tout). Le réglage s'applique aux lignes écrites ensuite ; les erreurs et alertes sont toujours gardées.
- **Session en cours / Session précédente** : le journal est conservé sur disque (le chemin du dossier est indiqué en bas de la fenêtre), pour relire ce qui s'est passé au démarrage de la session précédente.
<!--/pc-->

# Enregistrements et téléchargements

## Vue d'ensemble {#enregistrements}

<!--mac-->
Tout se retrouve dans la section **Enregistrements** de la barre latérale (**⌘6**) : enregistrement en cours, conversions, téléchargements, programmations et fichiers enregistrés (un clic pour les regarder, clic droit pour les afficher dans le Finder ou les supprimer).

Les fichiers sont rangés dans **~/Movies/Kastideo** (modifiable dans **Réglages > Enregistrements**) et nommés automatiquement, par exemple « TF1 – Le goût du détail – 2026-10-18 20h50 ».
<!--/mac-->

## Enregistrer le direct {#enregistrer}

<!--mac-->
- Pendant la lecture d'une chaîne, cliquez sur **●** dans les contrôles, sur **Enregistrer** sous la vidéo, ou utilisez **⇧⌘R**. La pastille **REC** indique la durée.
- L'enregistrement s'arrête automatiquement à la fin du programme en cours (d'après le guide TV, plus la marge après), ou quand vous cliquez sur **■**.
- Il utilise **la même connexion** que la lecture : rien de plus n'est consommé sur votre abonnement.
- Clic droit sur une chaîne > **Enregistrer maintenant** : si vous regardez une autre chaîne, Kastideo vous demande s'il faut arrêter la lecture, puis enregistre en arrière-plan.
- Un **bandeau** en bas de la fenêtre confirme le début et la fin de l'enregistrement et indique **le dossier** où se trouve le fichier (bouton **Afficher**). Si le dossier choisi dans les réglages n'est plus accessible, le fichier est placé dans ~/Movies/Kastideo et le bandeau le signale. Les étapes détaillées sont dans le **Journal de lecture**.
- **Pendant l'enregistrement**, le fichier est visible et grossit dans le sous-dossier **En cours** du dossier des enregistrements (un dossier au nom de l'émission). À l'arrêt, il est placé dans le dossier des enregistrements et le sous-dossier est supprimé. Si le moteur VLC ne crée pas le fichier sous 10 secondes, Kastideo réessaie automatiquement dans un dossier temporaire (le fichier n'apparaît alors qu'à l'arrêt) ; le message « Enregistrement impossible » ne s'affiche qu'après ces deux essais, et le Journal de lecture (⌥⌘L) en donne le détail. La durée n'est limitée que par l'espace disque : comptez environ 1 à 3 Go par heure selon la chaîne (un avertissement s'affiche sous 3 Go libres).
- À la fin, l'enregistrement est **converti en MP4** sans perte de qualité (lisible par QuickTime, l'iPhone, l'iPad). Le fichier .ts apparaît d'abord, puis est remplacé par le .mp4 quand la conversion est terminée (quelques minutes pour 2 h ; suivi dans la section Enregistrements). L'image est copiée sans perte ; le **son est converti en AAC** (certaines chaînes diffusent un son MP2 ou AC-3 que QuickTime lit sans son). Les sous-titres DVB et le télétexte, incompatibles avec le MP4, sont écartés ; si la conversion échoue, un second essai ne garde que l'image et le son principal, et en dernier recours le .ts est conservé. Désactivable dans les réglages.
<!--/mac-->

<!--pc-->
Bouton rond rouge de la barre du lecteur, touche **R**, ou clic droit sur une chaîne > **Enregistrer maintenant** : la chaîne est enregistrée jusqu'à la fin du programme en cours (plus la marge) ou jusqu'à l'arrêt, dans **Vidéos/Kastideo/Enregistrements**.

- Les octets du flux sont recopiés tels quels dans un fichier **.ts**, sans perte : la chaîne regardée est copiée depuis le relais (aucune seconde connexion au fournisseur) ; une autre chaîne est téléchargée directement, avec reconnexion si le flux est coupé.
- À la fin, le .ts est converti sans perte en **MKV** (format par défaut, Réglages > Enregistrements) ; si la conversion échoue, le .ts est gardé — il se lit partout.
- Les flux HLS (.m3u8) et la lecture sans relais passent encore par le moteur vidéo.
<!--/pc-->

## Programmer un enregistrement {#programmer}

<!--mac-->
- Dans le guide TV sous la vidéo, **double-cliquez** sur un programme à venir, ou faites un clic droit > **Programmer l'enregistrement**. Une pastille rouge marque les programmes programmés.
- Clic droit sur une chaîne > **Programmer un enregistrement…** (ou l'icône calendrier sous la vidéo) : choisissez un programme du guide ou des horaires libres.
- Des **marges** avant et après (2 et 5 minutes par défaut, réglables) évitent de rater le début ou la fin.
- À l'heure dite, l'enregistrement démarre en arrière-plan. Si vous regardez une autre chaîne, Kastideo vous demande s'il faut arrêter la lecture ; sans réponse, l'enregistrement démarre au bout de 60 secondes.
<!--/mac-->

<!--pc-->
- **Clic droit sur une chaîne du direct > Programmer un enregistrement…**, ou bouton **Programmer…** de l'écran Enregistrements (choisissez alors la chaîne : favoris, récents ou recherche).
  - **Programmes du guide** : les prochains programmes de la chaîne, avec **Programmer** (ou **Enregistrer** pour celui en cours). Une coche indique ceux déjà programmés.
  - **Plage horaire** : jour, heure de début et de fin, titre facultatif — pour une chaîne sans guide TV ou une émission précise. Une fin plus tôt que le début se termine le lendemain.
  - **Répétition** (liste en haut à droite) : **une seule fois**, **tous les jours**, **du lundi au vendredi** ou **chaque semaine**. La prochaine occurrence est ajoutée automatiquement ; le bouton ⟲ d'un enregistrement répété dans la liste arrête la répétition.
- Depuis la fiche d'un programme à venir (guide TV, thèmes) : **Programmer l'enregistrement**.
- Les marges avant et après (Réglages > Enregistrements) s'ajoutent. Kastideo doit être ouvert à l'heure prévue : activez au besoin **Lancer Kastideo à l'ouverture de session** (Réglages > Général).
<!--/pc-->

## Télécharger un film ou des épisodes sans les regarder {#telecharger}

<!--mac-->
- Clic droit sur un film ou un épisode > **Télécharger** ou **Télécharger cette nuit**, ou le bouton **Télécharger** sous la vidéo.
- Pour une série : bouton **Télécharger** de la fiche > la saison affichée ou toute la série.
- Les téléchargements passent **l'un après l'autre** (file d'attente). « Cette nuit » démarre à 2 h par défaut (réglable).
- Vous pouvez mettre en pause, reprendre ou annuler chaque téléchargement dans la section Enregistrements.
- **Indicateur permanent** : tant qu'un téléchargement est actif, un anneau d'avancement reste visible dans la barre d'outils. Un clic ouvre le détail : avancement du film ou de l'épisode en cours, « épisode X sur N », avancement de la série ou du lot, vitesse et **temps restant estimé** (affiné au fil du téléchargement).
<!--/mac-->

<!--pc-->
Bouton **Télécharger** de la fiche d'un film (maintenant ou **cette nuit**), **Télécharger la saison** ou icône de chaque épisode pour une série, clic droit > Télécharger. Un téléchargement à la fois, repris après une coupure, mis en pause pendant la lecture (réglable). Fichiers dans **Vidéos/Kastideo/Films** et **Séries/<série>**.
<!--/pc-->

## Connexion unique : qui a la priorité ? {#priorite}

<!--mac-->
Votre abonnement n'autorise qu'une connexion. Kastideo ne fait donc qu'une chose à la fois et **vous demande toujours** avant d'interrompre quelque chose :

- Vous changez de chaîne pendant un enregistrement : Kastideo demande s'il faut **arrêter l'enregistrement**.
- Vous lancez une lecture pendant un téléchargement : le téléchargement est **mis en pause** et reprend tout seul quand la lecture s'arrête.
- Les fichiers déjà enregistrés se regardent à tout moment, même pendant un enregistrement en arrière-plan.
<!--/mac-->

## L'écran Enregistrements {#ecran-enregistrements}

<!--pc-->
Enregistrement en cours (arrêt), téléchargements (pause, reprise, annulation), enregistrements programmés et historique, fichiers du dossier : un clic les lit, clic droit pour les afficher dans le dossier ou les supprimer.
<!--/pc-->

## Fiches dans votre langue {#fiches-langue}

<!--pc-->
Avec une **clé TMDB** (Réglages > Général), titres, résumés, genres et épisodes viennent de TMDB, dans la langue de l'interface. Quand le seul résumé disponible est celui du fournisseur dans une autre langue (portugais, espagnol…), il est replié : **Afficher le résumé (portugais)** l'affiche quand même. Il n'apparaît pas dans le bandeau ni dans la liste des épisodes.
<!--/pc-->

## Bon à savoir {#bon-a-savoir}

<!--mac-->
- Kastideo doit **rester ouvert** et le Mac **allumé** pour les enregistrements programmés et les téléchargements de nuit. Kastideo empêche la mise en veille automatique pendant l'activité et dans l'heure qui précède, mais pas l'extinction ni la mise en veille manuelle.
- Une **notification macOS** signale le début et la fin des enregistrements et des téléchargements (désactivable).
- **Nettoyage automatique** (facultatif) : les enregistrements plus anciens que le nombre de jours choisi sont placés dans la corbeille.
- Une alerte prévient quand l'espace disque devient faible.
- Les droits de copie dépendent des conditions de votre fournisseur : Kastideo enregistre pour votre usage privé ce que votre abonnement vous donne déjà.
<!--/mac-->

# Organiser et personnaliser

## Corriger une chaîne {#corriger}

<!--mac-->
Certaines chaînes sont mal référencées par le fournisseur (nom erroné, mauvais programmes, logo absent). Clic droit sur la chaîne > **Modifier la chaîne…** :

- **Nom** et **numéro** (utilisé pour le zapping par numéro de l'interface TV) ;
- **Logo** : adresse d'une image, ou **Choisir un fichier…** (l'image est copiée dans Kastideo) ;
- **Programmes du guide TV** : si les programmes affichés sont faux ou absents, cherchez la bonne chaîne dans la liste (guide du fournisseur et guide de secours) ; le programme en cours aide à la reconnaître.

La correction ne concerne que **cette version** de la chaîne (FHD, HD, SD… se corrigent séparément) et survit aux actualisations de la source. **Rétablir l'original** l'annule.
<!--/mac-->

<!--pc-->
Clic droit sur une chaîne > **Modifier la chaîne…** : nom, numéro, logo (adresse d'une image ou fichier copié dans Kastideo) et chaîne du **guide TV** (recherche parmi les guides du fournisseur et de secours). La correction vaut pour cette version de la chaîne (HD, FHD…) et reste après chaque actualisation. **Rétablir** revient à l'original.
<!--/pc-->

## Organiser les catégories {#categories}

<!--mac-->
Vous n'êtes pas obligé de subir l'ordre et la liste des catégories du fournisseur. Ouvrez **Présentation > Gérer les catégories…** (**⌥⌘C**), le bouton à droite du titre « Catégories » de la barre latérale, ou faites un clic droit sur une catégorie. Choisissez la section (**Direct**, **Films** ou **Séries**), puis :

- **Réordonner** : glissez les catégories dans la liste, ou utilisez le menu **…** > **Placer en haut / en bas**. **Trier A → Z** classe tout par ordre alphabétique.
- **Tout sélectionner / désélectionner** : la case au-dessus de la liste coche ou décoche d'un coup toutes les catégories listées. Avec une recherche (par exemple « PT »), elle ne concerne que les catégories trouvées : idéal pour masquer en une fois tout un pays, puis réafficher seulement celles que vous voulez.
- **Masquer** : décochez une catégorie (ou clic droit > **Masquer cette catégorie** dans la barre latérale). Une catégorie masquée disparaît **partout** : barre latérale, listes « Direct / Films / Séries », recherche, Guide TV, interfaces Cinéma et TV, bandeau « à la une ». Vos favoris et récents restent accessibles.
- **Masquer par mot-clé** : saisissez par exemple « PAKISTAN » ou « ARABIC » : toutes les catégories dont le nom contient ce mot sont masquées, y compris celles que le fournisseur ajoutera plus tard. Cliquez sur la croix d'un mot-clé pour l'annuler.
- **Renommer** : le crayon permet de donner un nom plus lisible (« FRANCE FHD | OTT » → « France HD ») ; **Nom d'origine** l'annule.
- **Tout afficher** réaffiche les catégories masquées ; **Réinitialiser…** revient entièrement à la présentation du fournisseur.

Les nouvelles catégories ajoutées par le fournisseur apparaissent à côté de leur voisine d'origine.
<!--/mac-->

<!--pc-->
- **Clic droit sur une catégorie** de la barre latérale : **Renommer…**, **Placer en haut**, **Monter**, **Descendre**, **Placer en bas**, **Masquer cette catégorie**, **Gérer les catégories…**.
- **Réglages > Catégories** (ou l'icône à droite de « Catégories ») : pour le direct, les films ou les séries — glissez pour changer l'ordre, décochez pour masquer partout, double-clic pour renommer, **mots-clés** pour masquer d'un coup toutes les catégories qui les contiennent (ex. « PAKISTAN »), **Trier de A à Z**, **Rétablir**.
- **Tout sélectionner / désélectionner** : la case au-dessus de la liste coche ou décoche d'un coup toutes les catégories listées. Avec la **recherche** (par exemple « PT »), elle ne concerne que les catégories trouvées : masquez tout un pays en deux clics, puis recochez seulement celles que vous voulez.

Une catégorie masquée l'est partout : listes, recherche, accueil, rangées.
<!--/pc-->

## Favoris et récents {#favoris}

<!--mac-->
- Ajoutez un favori avec l'étoile du panneau d'informations, le clic droit ou **⌘D**.
- La section **Récents** garde les 60 derniers contenus regardés.
- **Supprimer des récents** : clic droit sur un élément > **Retirer des récents** (ou touche **⌫** sur l'élément sélectionné en interface Classique). Pour plusieurs éléments, cliquez sur **Modifier**, cochez les éléments puis **Supprimer** ; **Tout sélectionner** coche toute la liste et **Tout effacer** vide l'historique.
- Après une suppression, un bandeau **Annuler** reste affiché quelques secondes pour tout restaurer.
- Les récents peuvent aussi être effacés dans les réglages, onglet **Général**.
<!--/mac-->

<!--pc-->
Étoile de la barre du lecteur, touche **F** ou clic droit > Ajouter aux favoris. Les récents gardent les 60 derniers contenus ouverts.

- **Modifier** (à droite du titre « Récents ») : cochez des éléments puis **Retirer la sélection**, ou la croix d'une ligne pour la retirer seule ; **Tout sélectionner** et **Tout effacer** (pour la section affichée). **Terminé** revient à la liste.
- Clic droit sur un contenu > **Retirer des récents**.
- Réglages > Général > **Effacer les récents** les efface tous, toutes sections confondues.
<!--/pc-->

## Alertes et notifications {#alertes}

<!--pc-->
- **M'alerter au début** dans la fiche d'un programme à venir (cloche dans le guide).
- **Mots-clés** (Réglages > Enregistrements) : un programme dont le titre contient un mot-clé déclenche une alerte, sur vos chaînes favorites ou sur toutes.
- L'alerte s'affiche en haut à droite de Kastideo avec **Regarder**, et la fenêtre revient si elle était réduite.
- **Notifications du système** (Réglages > Général > Notifications, activées par défaut) : alertes, début et fin d'enregistrement, téléchargement terminé ou impossible apparaissent aussi dans le centre de notifications de Windows ou de Linux, même quand Kastideo est derrière une autre fenêtre. Un clic sur la notification ramène Kastideo.
<!--/pc-->

## Apparence {#apparence}

<!--pc-->
Réglages > **Apparence** :

- **Thème** : **Sombre** (par défaut), **Clair** ou **Comme le système** (suit le réglage de Windows ou de Linux). Le lecteur, l'interface TV, la MultiVue, l'accueil, les fiches et le bandeau « à la une » restent sombres, comme sur Mac.
- **Couleur d'accent** : par défaut (bleu de Kastideo), bleu, violet, rose, rouge, orange, vert ou turquoise — sélection dans les listes, boutons, interrupteurs.
- **Densité des listes** (interface Classique) : compacte, standard ou aérée.
- **Taille des vignettes** (interface Cinéma) : petites, moyennes ou grandes.
- **Interface** par type de contenu et **bandeau « à la une »** (voir [Trois interfaces](help:interfaces)).

Les changements s'appliquent tout de suite, sans redémarrer.
<!--/pc-->

# YouTube

## YouTube : naviguer et lire {#youtube}

La section **YouTube** (barre latérale, bouton de l'accueil,
<!--mac-->**⌘9**<!--/mac--><!--pc-->**Ctrl+9**<!--/pc-->) fonctionne en deux temps : un **navigateur** d'abord, puis le **lecteur** dès que vous choisissez une vidéo.

![Du navigateur au lecteur](img:youtube)

### Le navigateur

- **Mes chaînes** : collez le lien d'une chaîne ou son @pseudo dans le champ du haut pour la suivre. Ses dernières vidéos s'affichent en rangée, sans clé ni compte. Pour reprendre tous vos abonnements d'un coup : [Importer mes abonnements](help:youtube-import).
- **Recherche** : tapez votre recherche dans le même champ (résultats en vignettes, tri par pertinence, date ou vues, pages suivantes). Elle demande une **clé API Google gratuite** : [le guide pas à pas](help:youtube-cle).
- **Liens collés** : une vidéo se lit, une playlist devient la file de lecture, une chaîne est suivie.
- **Favoris et historique** : clic droit sur une vignette ; l'historique garde les 80 dernières vidéos (bouton pour l'effacer).
- **À regarder plus tard** : clic droit sur une vignette pour mettre une vidéo de côté. Une vidéo entamée **reprend là où vous l'avez laissée** (une barre rouge indique l'avancement) ; elle quitte la liste quand vous l'avez vue jusqu'au bout.

### Le lecteur

<!--mac-->
Un clic sur une vidéo remplace le navigateur par le lecteur ; la liste d'où vous venez devient la file. Boutons Précédente / Suivante, **Enchaîner**, **Boucle**, **Muet** et **Ouvrir sur YouTube** dans la barre qui se masque d'elle-même ; **Échap** ou **Navigateur YouTube** ramène à la liste.
<!--/mac-->
<!--pc-->
Un clic sur une vidéo ouvre le lecteur dans **sa propre fenêtre** (Edge ou Chrome sous Windows, Chrome ou Chromium sous Linux en mode « application » ; à défaut, votre navigateur par défaut) ; la liste d'où vous venez devient la file. Boutons Précédente / Suivante, **Enchaîner**, **Boucle**, **Muet** et **Ouvrir sur YouTube** dans la barre qui se masque d'elle-même. Un bandeau rappelle la vidéo en cours dans Kastideo, avec **Rouvrir la fenêtre**.
<!--/pc-->

La lecture IPTV s'arrête pendant que YouTube joue (sauf enregistrement en cours).

> À propos des publicités et de votre compte Google : voir [Publicités, compte et confidentialité](help:youtube-confidentialite).

## Importer mes abonnements YouTube {#youtube-import}

YouTube ne permet pas à une application comme Kastideo de se connecter à votre compte. Google propose en revanche d'**exporter vos données** : on lui demande uniquement la liste de vos abonnements, un petit fichier `abonnements.csv` que Kastideo lit **sur votre ordinateur**.

![Les étapes de l'import](img:takeout)

### Étape 1 : demander l'export à Google

1. Ouvrez [Google Takeout](https://takeout.google.com/) en étant connecté au **compte Google** dont vous voulez les abonnements.
2. Cliquez sur **Tout désélectionner** (en haut de la liste).
3. Faites défiler jusqu'à **YouTube et YouTube Music** et cochez la case.
4. Cliquez sur **Toutes les données YouTube incluses**, cliquez sur **Tout désélectionner**, cochez seulement **abonnements**, puis **OK**.
5. Tout en bas, cliquez sur **Étape suivante**. Laissez **Envoyer le lien de téléchargement par e-mail**, **Exporter une fois** et le format **.zip**, puis cliquez sur **Créer l'exportation**.
6. Google prépare l'archive (quelques minutes, parfois plus) et vous envoie un e-mail. Cliquez sur **Télécharger vos fichiers** dans l'e-mail et enregistrez le `.zip`.

### Étape 2 : trouver le fichier

1. Ouvrez le `.zip` : <!--mac-->double-clic dans le Finder<!--/mac--><!--pc-->clic droit > **Extraire tout** (Windows) ou double-clic (Linux)<!--/pc-->.
2. Ouvrez les dossiers **Takeout** > **YouTube et YouTube Music** > **abonnements**.
3. Le fichier s'appelle **abonnements.csv** (ou **subscriptions.csv** si votre compte est en anglais).

### Étape 3 : l'importer dans Kastideo

1. Ouvrez **YouTube** > **Mes chaînes**.
2. Cliquez sur **Importer mes abonnements…** et choisissez le fichier.
3. Kastideo ajoute les chaînes et charge leurs dernières vidéos (avec beaucoup d'abonnements, la première actualisation peut prendre une minute).

> Les chaînes déjà suivies ne sont pas ajoutées deux fois. Le fichier n'est lu que par Kastideo, sur votre machine : rien n'est envoyé à Google ni ailleurs, et Kastideo n'accède jamais à votre compte.

### Si ça ne marche pas

- **« Aucune nouvelle chaîne trouvée dans ce fichier »** : ce n'est pas le bon fichier (par exemple l'historique de visionnage), ou les chaînes sont déjà suivies. Reprenez l'étape 2.
- **Pas d'e-mail de Google** : regardez les courriers indésirables, ou retournez sur [Google Takeout](https://takeout.google.com/) : la section « Gérer les exportations » permet de retélécharger l'archive.
- **Pas de dossier « abonnements »** : à l'étape 1.4, vérifiez que la case **abonnements** était cochée.
- Sans fichier, vous pouvez suivre une chaîne à la fois en collant son lien ou son @pseudo : voir [YouTube](help:youtube).

## Obtenir une clé API Google (recherche) {#youtube-cle}

La **recherche** YouTube utilise l'interface officielle de Google (« YouTube Data API v3 ») avec **votre propre clé**. Elle est **gratuite** et suffit pour environ **100 recherches par jour**. Sans clé, tout le reste fonctionne : suivre des chaînes, lire des liens collés, favoris, historique.

### Créer la clé (5 minutes, une seule fois)

1. Ouvrez la [console Google Cloud](https://console.cloud.google.com/) et connectez-vous avec un compte Google.
2. En haut, cliquez sur le sélecteur de projet > **Nouveau projet**. Donnez-lui un nom (par exemple « Kastideo ») puis **Créer**, et sélectionnez-le.
3. Ouvrez [la page de l'API YouTube Data v3](https://console.cloud.google.com/apis/library/youtube.googleapis.com) et cliquez sur **Activer**.
4. Menu **API et services > Identifiants** > **Créer des identifiants** > **Clé API**.
5. Copiez la clé affichée (une suite d'une quarantaine de caractères commençant par « AIza »).
6. Facultatif mais conseillé : **Modifier la clé** > **Restrictions relatives aux API** > **Limiter la clé** > cochez **YouTube Data API v3**.

### La donner à Kastideo

1. Ouvrez **Réglages > Général > YouTube**.
2. Collez la clé dans **Clé API Google** puis validez.
3. Retournez dans **YouTube** : la recherche fonctionne.

<!--mac-->
La clé est rangée dans le **trousseau macOS**, jamais en clair sur le disque, et n'est jamais publiée.
<!--/mac-->
<!--pc-->
La clé est rangée dans le **coffre du système** et n'est jamais publiée.
<!--/pc-->

> Quota : chaque recherche consomme 100 des 10 000 unités quotidiennes gratuites. Si vous atteignez la limite, Kastideo affiche « Erreur de l'API YouTube » ; la recherche revient le lendemain. Suivre des chaînes et lire des vidéos n'utilise pas ce quota.

### En cas d'erreur

- **« Clé API manquante »** : rien n'est enregistré dans les Réglages.
- **« API key not valid » / « Erreur de l'API YouTube »** : la clé est mal copiée, ou l'étape 3 (activer l'API) n'a pas été faite pour **ce** projet.
- **Erreur de restriction** : si vous avez limité la clé, vérifiez que **YouTube Data API v3** est bien cochée.

## Publicités, compte et confidentialité {#youtube-confidentialite}

### Publicités

Kastideo utilise le **lecteur officiel de YouTube en « mode confidentialité avancée »** (youtube-nocookie.com), celui que Google fournit aux sites pour intégrer des vidéos : il ne dépose pas de cookie de suivi et n'affiche donc pas de publicité personnalisée, le plus souvent aucune.

**Ce n'est pas un bloqueur de publicités** : rien n'est intercepté ni contourné, et YouTube reste libre d'y diffuser des annonces, qui financent les créateurs.
<!--pc-->
Si votre navigateur a lui-même un bloqueur de publicités, il s'applique dans la fenêtre du lecteur.
<!--/pc-->

### Pourquoi pas de connexion à mon compte ?

Le lecteur en mode confidentialité avancée ne reconnaît pas votre compte : pas de recommandations personnalisées, pas d'abonnements synchronisés automatiquement, pas de YouTube Premium (qui supprime les publicités sur youtube.com, pas dans un lecteur intégré). C'est le prix d'une lecture sans suivi. Pour retrouver vos abonnements, utilisez l'[import pas à pas](help:youtube-import).

### Ce que Kastideo garde

Vos chaînes suivies, favoris, historique (80 vidéos), liste « à regarder plus tard » et points de reprise sont enregistrés **sur votre ordinateur uniquement**. La clé API éventuelle reste dans le coffre du système. Rien n'est envoyé à Kastideo ou à un tiers autre que YouTube / Google lorsque vous cherchez ou lisez une vidéo.

# Réglages et maintenance

## Raccourcis clavier {#raccourcis}

<!--mac-->
- **⌘0** : accueil
- **⌘1 à ⌘7** : Direct, Films, Séries, Favoris, Récents, Enregistrements, Guide TV
- **⌥⌘1 / ⌥⌘2 / ⌥⌘3** : interface Classique / Cinéma / TV (pour le type de contenu affiché)
- Interface TV : **↑ ↓** zapping, **←** panneau de chaînes, chiffres = numéro de chaîne, **I** bandeau, **B** chaîne précédente, **G** guide TV, **H** accueil, **F** favori, **M** muet
- **⌘↑ / ⌘↓** : élément précédent / suivant (zapping)
- **⌘K** : lecture / pause
- **⌘[ / ⌘]** : reculer de 10 s / avancer de 30 s (films et épisodes)
- **⌘↩** ou double-clic sur la vidéo : mode cinéma (Échap pour sortir)
- **⌘.** : arrêter la lecture
- **⇧⌘R** : enregistrer la chaîne regardée / arrêter l'enregistrement
- **⌘6** : section Enregistrements
- **⌥⌘L** : journal
- **⌘D** : ajouter ou retirer des favoris
- **⌘R** : actualiser toutes les sources
- **⌘,** : réglages et sources
- **⌘?** : cette aide (ouverte à la page de l'écran affiché)
- **⌘8** : Mes vidéos, **⌘9** : YouTube
<!--/mac-->

<!--pc-->
- **Ctrl+0** : accueil — **Ctrl+1** : direct — **Ctrl+2** : films — **Ctrl+3** : séries — **Ctrl+7** : guide TV — **Ctrl+Alt+M** : MultiVue — **Ctrl+,** : réglages
- **Espace** : lecture / pause — **M** : son — **F** : favori — **R** : enregistrer / arrêter — **← / →** : −10 s / +30 s
- **Ctrl+Entrée** ou double-clic sur l'image : mode cinéma — **F11** : plein écran — **Échap** : quitter le mode cinéma, revenir à la fiche ou aux rangées
- Interface TV : **↑ / ↓** zapping, **chiffres** numéro, **←** panneau, **→ / I** bandeau, **B** chaîne précédente, **G** guide, **H** accueil
- MultiVue : **1 à 4** son, **G** en grand, **A** ajouter, **Suppr** retirer, **F** plein écran, **Échap** quitter
- **Ctrl+Alt+L** : journal
- **Ctrl+8** : Mes vidéos, **Ctrl+9** : YouTube
- **F1** : cette aide (ouverte à la page de l'écran affiché)
<!--/pc-->

## Réglages généraux {#reglages}

<!--mac-->
- **Langue** (onglet **Général**) : Kastideo existe en **français** et en **anglais**. La langue se choisit au premier lancement, puis peut être changée dans **Réglages > Général > Langue** (ou « Système » pour suivre la langue du Mac). Le changement s'applique après un redémarrage de l'application, que Kastideo propose de faire pour vous. L'aide et les menus suivent la langue choisie ; les notes de version restent en français.
- **Apparence** (onglet **Apparence**) : thème sombre (par défaut), clair ou comme le système ; **couleur d'accent** (Système, bleu, violet, rose, rouge, orange, vert, turquoise) ; **interface** Classique ou Cinéma pour chaque type de contenu ; **densité des listes** (compacte, standard, aérée) pour l'interface Classique ; **taille des vignettes** (petites, moyennes, grandes) pour l'interface Cinéma.
- **Fiches des films et séries** (onglet **Général**) : clé API **TMDB** facultative (gratuite sur themoviedb.org > Paramètres > API ; clé v3 ou jeton de lecture v4). Elle est conservée dans le trousseau. **Enregistrer et vérifier** contrôle la clé. Sans clé, les fiches utilisent les informations de votre fournisseur IPTV.
- **Actualiser au démarrage** : recharge les sources dont la dernière actualisation date de plus de 6 heures.
- **Cache** : Kastideo garde une copie locale des listes et du guide TV pour démarrer instantanément. **Vider et recharger** efface cette copie et relance le chargement.
<!--/mac-->

<!--pc-->
- **Général** : langue (au prochain lancement), reprise de lecture, relais de flux, actualisation au démarrage, effacer les récents, **connexions simultanées** (MultiVue), **notifications du système**, guide TV et guide de secours, contenus adultes (masqués par défaut), clé TMDB, **démarrage et fichiers .m3u**, **mises à jour**.
- **Apparence** : thème, couleur d'accent, densité des listes, taille des vignettes, interfaces, bandeau « à la une ».
- **Sources** : ajouter, actualiser, supprimer, état du guide.
- **Catégories** : ordre, masquage, noms, mots-clés.
- **Enregistrements** : dossier, format, marges, téléchargements, différé, alertes.
- **Sauvegarde** : exporter ou importer la configuration.
<!--/pc-->

## Obtenir une clé TMDB (gratuite) {#tmdb}

<!--mac-->
TMDB (The Movie Database) est une base de films et séries communautaire. Sa clé est **gratuite** pour un usage personnel ; elle permet à Kastideo d'afficher les photos des acteurs, les affiches et fonds en haute définition, la bande-annonce et un résumé traduit.

1. Créez un compte sur **themoviedb.org** (bouton « Rejoindre TMDB »), puis validez-le avec le lien reçu par e-mail.
2. Connecté, ouvrez **themoviedb.org/settings/api** (avatar > Paramètres > API), ou cliquez sur **Obtenir une clé gratuite** dans les réglages de Kastideo.
3. Cliquez sur **Créer**, choisissez **Developer** et acceptez les conditions d'utilisation.
4. Remplissez le formulaire : type d'usage **Personnel**, nom de l'application **Kastideo**, URL **https://github.com/jihemezes/kastideo**, un court résumé (« Lecteur IPTV personnel, affichage des fiches de films »), puis vos coordonnées.
5. Validez : la page affiche une **Clé d'API** (32 caractères) et un **Jeton d'accès en lecture** (long, commence par « eyJ »). Kastideo accepte l'un ou l'autre ; la clé d'API est la plus simple à copier.
6. Dans Kastideo : **Réglages (⌘,) > Général > Fiches des films et séries**, collez la clé puis cliquez sur **Enregistrer et vérifier**. « Clé valide ✓ » confirme la saisie.
7. Rouvrez une fiche (ou cliquez sur **Actualiser** en bas de la fiche) : elle est complétée par TMDB.

La clé est conservée dans le trousseau du Mac. **Retirer la clé** revient aux seules informations du fournisseur IPTV.
<!--/mac-->

<!--pc-->
Créez un compte sur themoviedb.org, puis **Paramètres > API** et demandez une clé (usage personnel). Copiez la « clé API » (v3) ou le « jeton d'accès en lecture » (v4) dans Réglages > Général, puis **Enregistrer**. Les fiches deviennent plus complètes (affiches, distribution, bandes-annonces, résumés et épisodes en français).
<!--/pc-->

## Démarrage et fichiers .m3u {#demarrage}

<!--pc-->
Réglages > Général > **Démarrage et fichiers** :

- **Lancer Kastideo à l'ouverture de session** (Windows et Linux), et **Démarrer réduit** dans la barre des tâches : les enregistrements programmés et les alertes n'ont lieu que si Kastideo est ouvert.
- **Ouvrir les fichiers .m3u et .m3u8 avec Kastideo** (facultatif) : un double-clic sur une playlist propose de l'ajouter comme source (Réglages > Sources) ; si Kastideo est déjà ouvert, la fenêtre existante la reçoit. Si Windows continue d'ouvrir un autre programme, faites clic droit sur le fichier > Ouvrir avec > Choisir une autre application > Kastideo.

Ces deux options sont aussi proposées par l'installateur Windows (décochées par défaut).
<!--/pc-->

## Sauvegarde et transfert {#sauvegarde}

<!--mac-->
Réglages > Général > **Sauvegarde et transfert** :

- **Exporter la configuration…** enregistre un fichier `Kastideo-configuration.json` : sources (Xtream et playlists M3U par adresse), favoris, récents, catégories personnalisées (ordre, masquage, noms, mots-clés), interfaces choisies et clé TMDB. Cochez **Inclure les mots de passe** pour ne rien avoir à ressaisir ; gardez alors le fichier en lieu sûr.
- **Importer une configuration…** ajoute le contenu d'un fichier : sur un nouveau Mac, ou depuis Kastideo pour Windows et Linux (même format). Les sources déjà présentes sont reconnues et rien n'est supprimé.

Les serveurs Jellyfin, Emby et Plex sont exportés (avec leur mot de passe ou leur jeton si vous cochez **Inclure les mots de passe**). Les playlists M3U ajoutées comme fichiers locaux et les dossiers ne sont pas importés sur un autre Mac (les fichiers n'y existent pas ou doivent être choisis à nouveau).
<!--/mac-->

<!--pc-->
Réglages > **Sauvegarde** : **Exporter la configuration…** (sources et leur guide, mots de passe si vous le souhaitez, favoris, récents, catégories, interfaces, apparence, nombre de connexions, contenus adultes, bandeau, clé TMDB) et **Importer une configuration…**. Le fichier est le même que celui de Kastideo pour Mac : vous pouvez passer d'un ordinateur à l'autre dans les deux sens. Rien n'est supprimé à l'importation. Les serveurs Jellyfin, Emby et Plex sont repris (mot de passe ou jeton compris si demandé) ; les dossiers aussi, avec leurs chemins (à corriger s'ils diffèrent sur cet ordinateur).
<!--/pc-->

## Mises à jour {#mises-a-jour}

<!--mac-->
Kastideo se met à jour tout seul grâce à **Sparkle**, l'outil de référence des applications Mac distribuées hors App Store.

- **Au démarrage** (quelques secondes après le lancement), puis une fois par jour si Kastideo reste ouvert, Kastideo vérifie discrètement si une nouvelle version est disponible sur GitHub.
- Si c'est le cas, un **bandeau** en haut de la fenêtre l'annonce — **jamais pendant un visionnage ni un enregistrement** (il attend la fin de la lecture). La mise à jour est **facultative** : **Mettre à jour…** ouvre la fenêtre des nouveautés puis **Installer la mise à jour** (Kastideo se ferme, s'installe et se relance) ; **Plus tard** masque le bandeau jusqu'au prochain lancement ; **Ignorer cette version** ne la propose plus (la suivante le sera).
- Vous pouvez vérifier à tout moment avec **Kastideo > Rechercher les mises à jour…**.
- Chaque mise à jour est signée : Kastideo refuse d'installer un fichier qui ne vient pas de son éditeur.

Dans **Réglages > Mises à jour** :

- **Rechercher les mises à jour au démarrage** : active ou désactive la vérification au lancement et quotidienne.
- **Recevoir les versions de test (bêta)** : propose aussi les versions bêta, qui apportent les nouveautés plus tôt mais peuvent être moins stables. Désactivez l'option pour revenir aux versions stables à la prochaine mise à jour.

> Les versions 0.1.0 et antérieures ne savent pas se mettre à jour : installez la 0.2.0 une fois à la main, les suivantes arriveront toutes seules.
<!--/mac-->

<!--pc-->
Kastideo recherche les nouvelles versions sur GitHub au lancement puis toutes les 12 heures (pré-versions Windows / Linux, tant que ces versions sont en aperçu).

- Une nouvelle version est annoncée par un **bandeau en bas à droite**, seulement quand vous ne regardez rien. **Voir** ouvre la fenêtre de mise à jour avec ses nouveautés ; la croix la remet à plus tard.
- **Installer et relancer** télécharge le fichier qui correspond à votre installation puis :
  - **Windows, installé** : lance le nouvel installateur en silencieux, puis relance Kastideo ;
  - **Windows, version portable** : remplace les fichiers du dossier après la fermeture, puis relance Kastideo ;
  - **AppImage** : enregistre la nouvelle AppImage à côté de l'ancienne, supprime l'ancienne et la lance ;
  - **Paquet .deb** : l'installe avec apt (votre mot de passe est demandé), puis relance Kastideo.
- Un enregistrement en cours est terminé proprement avant la fermeture.
- **Ignorer cette version** : elle ne sera plus proposée (une recherche manuelle la propose de nouveau).
- Réglages > Général > **Mises à jour** : version installée et type d'installation, **Rechercher maintenant**, recherche automatique, **Nouveautés des dernières versions**, page des versions sur GitHub.
- Au premier lancement après une mise à jour, la fenêtre **Nouveautés** résume ce qui a changé.
<!--/pc-->

## Installation {#installation}

<!--pc-->
- **Windows (recommandé)** : lancez **Kastideo-…-windows-x64-setup.exe**. Par défaut, Kastideo s'installe pour vous seul, sans droits administrateur (dans votre dossier AppData) ; l'installateur propose aussi de l'installer pour tous les utilisateurs, une icône sur le bureau, l'ouverture des fichiers .m3u et le lancement à l'ouverture de session. Désinstallation : Paramètres de Windows > Applications > Kastideo.
- **Windows, version portable** : décompressez l'archive « windows-x64.zip » où vous voulez et lancez **kastideo.exe** (rien n'est installé ; les mises à jour remplacent les fichiers du dossier).
- L'application n'est pas signée : si SmartScreen affiche « Windows a protégé votre ordinateur », cliquez sur **Informations complémentaires** puis **Exécuter quand même**.
- **Zorin OS 17 / Ubuntu 22.04** : paquet « ubuntu22.04_amd64.deb » (double-clic ou `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04** : paquet « ubuntu24.04_amd64.deb ».
- **Toute distribution, et Raspberry Pi (64 bits)** : fichier AppImage ; rendez-le exécutable (clic droit > Propriétés > Autoriser l'exécution, ou `chmod +x`) puis lancez-le.
<!--/pc-->

## Nouveautés {#nouveautes}

Après chaque mise à jour, la fenêtre **Nouveautés** résume les changements de la version installée.

<!--mac-->
Vous pouvez la rouvrir avec **Aide > Nouveautés de cette version** ou en cliquant sur le numéro de version en bas à droite de l'accueil, et y consulter les versions précédentes.
<!--/mac-->
<!--pc-->
Vous pouvez la rouvrir en cliquant sur le numéro de version en bas à droite de l'accueil, et y consulter les versions précédentes.
<!--/pc-->

L'historique complet est aussi publié sur la page [Releases de GitHub](https://github.com/jihemezes/kastideo/releases).

# Dépannage

## Dépannage {#depannage}

<!--mac-->
- **Une chaîne n'a pas de son** : Kastideo le détecte au bout de quelques secondes et répare seul : si l'horloge du flux est décalée (le son est jeté, « buffer too late » dans le journal), la chaîne est rouverte en se calant sur le son et l'image, et Kastideo s'en souvient ; sinon, relance de la piste son ou piste suivante. Si une icône 🔇 orange reste affichée près de la pastille de santé, le fournisseur envoie un flux sans son ou une piste illisible : essayez une autre version de la chaîne (HD, SD…) ou choisissez une autre piste son dans le panneau d'informations (⌘I). Le journal de lecture (lignes « Son : ») indique le format reçu.

- **« Le fournisseur refuse cette chaîne (HTTP 403) »** : le fournisseur lui-même bloque cette chaîne (hors service ou absente de votre abonnement). Kastideo n'insiste pas ; essayez une autre version (HD, SD…) ou plus tard.
- **Image figée, « Flux défectueux chez le fournisseur »** : l'horloge du flux est incohérente. Kastideo rouvre la chaîne une fois en se calant sur le son et l'image ; si cela ne suffit pas, il passe en **image seule** (sans le son) pour que l'image ne se fige plus, et s'en souvient. Clic droit sur la chaîne > **Image seule (sans le son)** pour l'activer ou la désactiver à la main. Réglages > Général > Lecture > **Réinitialiser** annule ces réparations mémorisées.
- **Relais de flux** (Réglages > Général > Lecture, activé par défaut) : Kastideo ouvre lui-même la connexion chez le fournisseur et la transmet au moteur VLC, comme Piboard, pour qu'il n'y en ait jamais deux à la fois. Le journal de lecture affiche alors les lignes « Relais : » avec la réponse exacte du fournisseur (ex. « HTTP 200 en 0,35 s »).
- **Changement de chaîne lent ou refusé (« HTTP 404 », « 403 », « 401 » ou « 520 » dans le journal de lecture)** : avec un abonnement à une connexion, le fournisseur met un instant à libérer la chaîne précédente. Kastideo attend 1,5 s avant d'ouvrir la nouvelle chaîne puis réessaie une fois si elle est refusée (« Attente… » et « nouvel essai » dans le journal). Si le refus persiste, patientez une minute puis réessayez.

Kastideo s'identifie auprès des serveurs comme le lecteur **VLC** : beaucoup de fournisseurs IPTV ne répondent qu'aux lecteurs qu'ils reconnaissent.

- **« Le serveur n'a pas répondu à temps »** : le serveur est surchargé ou indisponible. Réessayez plus tard ; si votre adresse est de type `get.php?username=…`, vérifiez qu'elle a bien été convertie en Xtream Codes (type affiché dans les réglages des sources).

- **« Identifiant ou mot de passe refusé »** : vérifiez vos identifiants avec **Tester la connexion**.
- **« Compte non actif »** : l'abonnement a expiré ou est suspendu chez votre fournisseur.
- **Aucun programme dans le guide** : la chaîne n'a pas d'identifiant de guide TV, ou le guide de votre source n'en contient pas pour elle.
- **« App Transport Security »** : ce message apparaissait en version 0.1.0 et 0.2.0 avec les sources en http://. Il est corrigé depuis la version 0.2.1.
- **Lecture impossible** : le serveur n'a pas fourni le flux. Vérifiez qu'aucun autre appareil n'utilise votre abonnement (une seule connexion autorisée), puis cliquez sur **Réessayer**. Essayez aussi la mémoire tampon **Stable**.
<!--/mac-->

<!--pc-->
- **Une chaîne ne démarre pas** : ouvrez le **Journal** (Ctrl+Alt+L, sujet *Lecture et relais*). Les lignes « Relais : » donnent la réponse exacte du fournisseur (par exemple « HTTP 200 en 0,35 s » ou « HTTP 403 »).
- **La mise à jour ne s'installe pas** : le journal de lecture (Ctrl+Alt+L) donne la raison. Paquet .deb : si la fenêtre de mot de passe n'apparaît pas, la commande à taper dans un terminal s'affiche dans la fenêtre de mise à jour. Vous pouvez toujours télécharger la nouvelle version sur la page des versions GitHub.
- **MultiVue : une vignette reste noire** : le fournisseur refuse une connexion de plus. Vérifiez le nombre de connexions de votre abonnement (Réglages > Général > Lecture > Détecter).
- **Pas de notification** : vérifiez Réglages > Général > Notifications, puis les réglages de notification de Windows (Paramètres > Système > Notifications) ou de votre bureau Linux. Sous Linux, le paquet libnotify est nécessaire (installé par le .deb, inclus dans l'AppImage).
- **Enregistrement vide** : le fournisseur n'a rien envoyé (chaîne refusée, connexion déjà utilisée par un autre appareil). Les lignes « Enregistrement » du journal donnent la réponse du fournisseur (par exemple « HTTP 403 ») et indiquent si aucune donnée n'est arrivée après 30 s.
- **Le différé ne remonte pas plus loin** : sa profondeur dépend de l'espace disque temporaire ; sans cache sur disque (certaines versions de libmpv sous Linux), il est limité à 512 Mo en mémoire.
- **Fiches dans une autre langue** : certains fournisseurs n'ont qu'une langue. Avec une **clé TMDB**, résumés, genres et épisodes sont repris de TMDB en français.
- **Une seule fenêtre** : relancé alors qu'il tourne déjà, Kastideo ramène simplement la fenêtre existante au premier plan.
- **Pas d'image sous Linux** : vérifiez que le paquet **libmpv** est installé (le .deb l'installe ; l'AppImage l'embarque).
- **VPN** : un VPN actif peut empêcher le fournisseur de servir les flux.
- **Pas de programme dans le guide** : Réglages > Sources indique l'état du guide de chaque source ; le guide de secours complète les chaînes françaises courantes.
- **Mots de passe sous Linux** : sans trousseau (GNOME Keyring ou KWallet), Kastideo garde les mots de passe dans ses préférences et le signale dans le journal.
<!--/pc-->

# À propos

## Soutenir Kastideo {#soutenir}

<!--mac-->
Kastideo est **gratuit** et le restera. Si l'application vous plaît, vous pouvez encourager son développement en m'offrant un café sur [Ko-fi](https://ko-fi.com/jihemezes) : c'est entièrement facultatif.

Le bouton **Offrir un café** apparaît discrètement sur l'accueil et dans la fenêtre Nouveautés, ainsi que dans **Réglages > À propos** et dans **Aide > Soutenir Kastideo (Ko-fi)**. Pour masquer les boutons de l'accueil et des Nouveautés, cochez **Masquer les boutons « Offrir un café »** dans **Réglages > À propos**.
<!--/mac-->

<!--pc-->
Kastideo est **gratuit** et le restera. Si l'application vous plaît, vous pouvez encourager son développement en m'offrant un café sur [Ko-fi](https://ko-fi.com/jihemezes) : c'est entièrement facultatif.

Le bouton **Offrir un café** apparaît discrètement sur l'accueil et dans la fenêtre Nouveautés, ainsi que dans **Réglages > À propos**. Pour masquer les boutons de l'accueil et des Nouveautés, cochez **Masquer les boutons « Offrir un café »** dans **Réglages > À propos**.
<!--/pc-->

## Confidentialité {#confidentialite}

<!--mac-->
Kastideo fonctionne dans le bac à sable de macOS. Il n'accède qu'au réseau et aux fichiers que vous choisissez. Vos mots de passe restent dans le trousseau. Aucune donnée n'est envoyée ailleurs qu'à vos propres sources.
<!--/mac-->

<!--pc-->
Kastideo ne collecte aucune donnée. Il contacte seulement vos fournisseurs IPTV, les guides TV que vous avez choisis, GitHub pour les mises à jour et, si vous avez saisi une clé, TMDB. Vos réglages, favoris et mots de passe restent sur votre ordinateur.
<!--/pc-->

## Licences {#licences}

<!--mac-->
Kastideo utilise **VLCKit** (moteur de VLC, © VideoLAN, licence LGPL 2.1 ou ultérieure, https://www.videolan.org/vlc/libvlc.html) et **Sparkle** (licence MIT, https://sparkle-project.org). VLCKit est intégré sous forme de bibliothèque dynamique non modifiée.
<!--/mac-->
