# Kastideo pour Windows et Linux

> Version 1.3.3-desktop1 — Journal par sujets (recherche, niveaux de détail, historique conservé), diagnostic détaillé du guide TV et bouton « Recharger le guide » ; version 1.3.1-desktop1 — tuile « Mes vidéos » (rangées, filtres, navigation par dossiers, diagnostic), sélecteur Tout / IPTV / Mes vidéos dans Films et Séries, mot de passe ou jeton facultatif, connexion Emby corrigée. Version 1.3.0-desktop1 — nouvelles sources : dossiers (disque, clé USB, NAS), Jellyfin, Emby et Plex, recherche des serveurs sur le réseau, reprise et « vu » partagés avec les serveurs, fiches TMDB des fichiers, sous-titres placés à côté. Version 1.2.2-desktop1 — programmer un enregistrement depuis le direct, modifier les récents, case « Tout sélectionner » des catégories. Kastideo ne fournit aucun contenu : vous ajoutez vos propres sources (abonnement Xtream Codes ou playlist M3U, dossiers de vidéos, serveur Jellyfin, Emby ou Plex).

## Premiers pas

1. Ouvrez les **Réglages** (roue dentée de l'accueil, bas de la barre latérale, ou **Ctrl+,**) > **Sources** > **Ajouter une source**.
2. Choisissez le type : abonnement **Xtream Codes** (serveur, identifiant, mot de passe), **playlist M3U**, **Dossiers** de vidéos (disque, clé USB, NAS), ou serveur **Jellyfin**, **Emby** ou **Plex**.
3. Kastideo charge les chaînes, les films, les séries et le guide TV. Revenez à l'**accueil** et choisissez **Direct**, **Films** ou **Séries**.

> Astuce : vous avez déjà Kastideo sur Mac ? Exportez sa configuration (Réglages > Général > Sauvegarde et transfert) et importez-la ici (Réglages > Sauvegarde).

## Les sources

### Xtream Codes

Adresse du serveur (ex. http://exemple.com:8080), identifiant et mot de passe. Le mot de passe est rangé dans le coffre du système : Gestionnaire d'identification sous Windows, trousseau GNOME ou KWallet sous Linux.

### Playlist M3U / M3U8

Adresse de la playlist ou fichier sur le disque (**Choisir un fichier…**). Une adresse « get.php?username=…&password=… » est reconnue et transformée en source Xtream, bien plus rapide et plus complète (fiches, épisodes, derniers ajouts).

### Dossiers (disque, clé USB, NAS)

Réglages > Sources > **Ajouter une source** > **Dossiers**, puis **Ajouter un dossier…** (disque interne, disque ou clé USB) ou saisissez un **chemin réseau** et cliquez sur **+** : `\\NAS\Vidéos` ou un lecteur réseau (`Z:\`) sous Windows, un partage monté (`/mnt/nas/videos`, `/media/…`) sous Linux. Plusieurs dossiers peuvent former une même source.

- **Films** reconnus par leur nom : « Inception (2010).mkv », « The.Matrix.1999.1080p.BluRay.mkv », dossier « Le Fabuleux Destin (2001) ». Rubrique « Films · nom du dossier ».
- **Séries** : « Breaking.Bad.S01E02.mkv », « Friends 1x05.mp4 », dossiers « Série/Saison 1/… ». Les épisodes sont regroupés par série et par saison dans **Séries**.
- **Autres vidéos** : rubrique **Vidéos · nom du dossier** dans Films.
- Examen à chaque lancement puis toutes les 20 minutes. Disque débranché : un message l'indique et la liste précédente est gardée. Les sous-dossiers illisibles (« System Volume Information »…) sont ignorés.
- **Sous-titres** placés à côté (« Film.srt », « Film.fr.srt ») chargés à la lecture.
- Avec une **clé TMDB**, **affiches et résumés** sont ajoutés automatiquement ; clic droit > **Corriger la fiche…** pour choisir le bon titre quand le nom du fichier trompe la recherche.

### Jellyfin, Emby et Plex

Réglages > Sources > **Ajouter une source** > **Jellyfin**, **Emby** ou **Plex**. **Rechercher sur le réseau** trouve les serveurs de la maison : cliquez sur le vôtre pour remplir le formulaire (sinon saisissez l'adresse ; sans port, 8096 ou 32400 est ajouté).

- **Jellyfin / Emby** : identifiant et mot de passe — **facultatif** si le compte n'en a pas (ou une **clé d'API** du tableau de bord). **Tester** vérifie l'adresse ; en cas d'échec, la réponse exacte du serveur s'affiche.
- **Plex** : **Se connecter avec Plex** ouvre plex.tv dans le navigateur ; autorisez Kastideo, puis choisissez le serveur de votre compte. Ou saisissez l'adresse et le **jeton** (X-Plex-Token), facultatif si le serveur autorise le réseau local sans authentification.
- Les bibliothèques apparaissent dans **Films** et **Séries** (« nom de la bibliothèque · nom du serveur »), avec les affiches, fiches, saisons et épisodes du serveur. Lecture directe, sans conversion.
- **Reprise et « vu » partagés dans les deux sens** : la position est transmise au serveur pendant la lecture et celle de vos autres appareils est reprise. Clic droit > **Marquer comme vu / non vu** ; pastille **Vu** sur les affiches.

> Pare-feu Windows : à la première recherche, autorisez Kastideo sur les réseaux privés pour que les serveurs puissent répondre.

### Guide TV (XMLTV)

Le guide indiqué par le fournisseur est chargé en arrière-plan et gardé sur le disque. Le champ facultatif **Guide TV (XMLTV)** d'une source permet d'utiliser un autre guide (.xml ou .xml.gz).

### Guide TV de secours (xmltvfr.fr)

Réglages > Général > **Guide TV** : un guide de secours complète les chaînes sans programme dans le guide du fournisseur, en les rapprochant par leur nom. Choisissez un guide xmltvfr.fr ou saisissez une adresse ; **Recharger le guide** relance tous les téléchargements. Le bouton **Journal du guide** ouvre le Journal sur le sujet *Guide TV* : adresse demandée, réponse du fournisseur (code, taille, durée), chaînes et programmes reçus, période couverte, nombre de vos chaînes reliées au fournisseur, au secours ou à aucun guide, et — si le guide est inutilisable — le début de la réponse du serveur. Les programmes du fournisseur sont filtrés sur les identifiants de vos chaînes : si le guide contient des programmes mais aucun pour vos chaînes, le journal montre les identifiants des deux côtés.

### Gérer les sources

Réglages > **Sources** : **modifier** une source (bouton crayon : nom, serveur, identifiant, mot de passe, adresse de la playlist, guide TV — favoris, récents et corrections de chaînes sont gardés), l'actualiser, la supprimer, voir l'état de son guide TV. Le bouton **œil** affiche le mot de passe (ou la clé TMDB) pour le vérifier. Les sources sont actualisées au démarrage si leur dernière mise à jour date de plus de 6 heures (réglable). Si une actualisation renvoie une section vide, la précédente est gardée.

## Naviguer

### L'écran d'accueil

Recherche globale (chaînes, films, séries), pavés **Direct**, **Films** et **Séries**, accès rapides **Favoris**, **Récents**, **Guide TV**, **MultiVue** et **Enregistrements**, rangée **Reprendre la lecture**.

### Mes vidéos

Dès qu'une source **Dossiers**, **Jellyfin**, **Emby** ou **Plex** existe, une tuile **Mes vidéos** apparaît sur l'accueil (raccourci **Ctrl+8**). Elle réunit vos vidéos, à part de l'IPTV :

- **À la une** : **Reprendre la lecture** (films et épisodes entamés), **Ajouts récents**, **Films à voir**, puis une rangée Films, Séries et Vidéos ;
- **Films**, **Séries**, **Vidéos** : grilles avec recherche, filtres (**genre**, **année**, **non vus**) et tri (titre, ajout récent, année) ;
- **Dossiers** : parcourez vos dossiers et sous-dossiers comme dans l'explorateur de fichiers (fil d'Ariane pour remonter), et les bibliothèques des serveurs ;
- **Sources** : toutes, ou une seule (NAS, Emby, Plex…). Un triangle orange signale une erreur : clic droit > **Détails de l'erreur…** (ou bouton **Détails**) affiche la requête et la **réponse exacte du serveur**, puis **Réessayer**.

Dans **Films** et **Séries**, le sélecteur **Tout / IPTV / Mes vidéos** (barre latérale, au-dessus des catégories) choisit ce qui est affiché : l'IPTV seul (par défaut), vos vidéos seules, ou les deux mélangés. Les catégories de vos vidéos ne sont jamais masquées par le réglage des pays.

### La barre latérale

Sélecteur Direct / Films / Séries, puis : toutes les chaînes ou tous les films, **Favoris**, **Récents**, et pour le direct **Thèmes**, **Guide TV** et **MultiVue** ; **Enregistrements** ; les **catégories**. En bas : enregistrement et téléchargement en cours (progression, temps restant) et **Réglages**.

### Trois interfaces au choix

Réglages > Apparence > **Interface par type de contenu** :

- **Classique** : trois colonnes (barre latérale, liste avec le programme en cours, lecteur ou fiche à droite).
- **Cinéma** : bandeau « à la une », affiches ou vignettes en rangées horizontales, fiche en page entière. Pour le direct : rangées « Sport en ce moment », « Info en direct », « Ce soir » par thème, favoris, récents, catégories ; un clic ouvre la chaîne en plein cadre, **Retour** (ou Échap) l'arrête.
- **TV** (direct seulement) : la chaîne en plein cadre, comme sur un téléviseur (voir plus bas).

### Le bandeau « à la une » (Cinéma)

Il fait défiler des films ou séries (tendances de la semaine sur TMDB disponibles chez vous, derniers ajouts, sélection d'une catégorie) ou, pour le direct, le programme en cours de vos chaînes. Flèches au survol, arrêt quand la souris le survole. Réglages > Apparence > **Bandeau « à la une »** : afficher ou masquer, hauteur, vitesse, sources.

### Pays et langues (Cinéma)

Votre fournisseur mélange souvent plusieurs pays (catégories « FR| … », « |PT| … », « ITALIA »…). Réglages > Apparence > **Pays et langues (interface Cinéma)** liste les pays repérés dans les noms de vos catégories, avec le nombre de contenus : choisissez ceux à montrer. Les **derniers ajouts**, les **tendances**, le **bandeau « à la une »** et les **rangées par catégorie** de l'interface Cinéma ne montrent alors que ces pays. **Garder les catégories sans pays indiqué** conserve les catégories comme « Action » ou « Nouveautés ». **Tous** revient à l'affichage complet. Les listes et la recherche restent complètes.

### L'interface TV (direct)

- **↑ / ↓** : chaîne précédente / suivante ; **tapez un numéro** (jusqu'à 4 chiffres).
- **←** ou bord gauche : **panneau des chaînes** (filtre, recherche, programme en cours).
- **→** ou **I** : **bandeau d'information** (programme en cours et suivant).
- **B** : chaîne précédente — **F** : favori — **M** : son — **Espace** : pause — **G** : guide TV — **H** : accueil.

### Le Guide TV en grille

Accueil, barre latérale du direct, **Ctrl+7** ou touche G en interface TV. Chaînes en lignes, heures en colonnes, trait rouge sur l'heure actuelle ; **‹ Maintenant ›**, choix du jour, durée affichée 2 h / 3 h / 6 h, filtre (toutes, favoris, récents, thème, catégorie) et recherche. Un clic sur un programme ouvre sa fiche : **Regarder**, **Enregistrer**, **Programmer l'enregistrement** (point rouge dans la grille) ou **M'alerter au début** (cloche).

### Le Direct par thème

Barre latérale > **Thèmes** : **En ce moment**, **Ce soir** (20 h – 23 h) ou **Chaînes**, filtrés par thème (Sport, Info, Films, Jeunesse, Documentaires…) et, pour le sport, par discipline. Une seule version par chaîne (FHD, HD ou SD selon la connexion). Clic droit : version de la chaîne, **thème de la chaîne** (pour corriger le classement), favoris, modifier la chaîne.

## Lecture

Le lecteur (moteur mpv) a une barre de contrôles qui se cache seule, une pastille de santé du flux, le volume, le mode cinéma (double-clic ou Ctrl+Entrée) et le plein écran (F11). Pour les films et épisodes : mini-timeline, −10 s / +30 s, **reprise de lecture** là où vous vous étiez arrêté, **Retour à la fiche**.

### Direct en différé

Mettez une chaîne en pause (ou revenez en arrière avec ← ou la barre) : elle continue d'être gardée (jusqu'à 1 h par défaut, réglable). Sans action de votre part, la chaîne reste « EN DIRECT ». La barre du différé affiche le retard, un curseur pour revenir en arrière ou rattraper en accéléré, la vitesse, **Rattraper** et **Retour au direct**. ← / → : −10 s / +30 s.

### Une seule connexion à la fois

La plupart des abonnements n'autorisent qu'une connexion. Kastideo ferme la chaîne précédente avant d'ouvrir la suivante (**relais de flux**, Réglages > Général > Lecture) et vous demande avant d'interrompre un enregistrement.

### MultiVue (plusieurs chaînes à la fois)

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

### Le Journal (diagnostic)

Le **Journal** (**Ctrl+Alt+L**, ou bouton dans l'accueil et dans les messages d'erreur) est l'outil de diagnostic de Kastideo. Les identifiants et mots de passe y sont **masqués** : vous pouvez le copier pour le partager.

- **Sujets** : *Guide TV*, *Lecture et relais*, *Sources et catalogues*, *Enregistrements*, *Fiches TMDB*, *Mises à jour*, *Affichage et divers*. Cliquez sur un ou plusieurs sujets pour ne voir que ceux-là (le nombre de lignes de chaque sujet est indiqué).
- **Rechercher** un mot, ou n'afficher que les **erreurs et alertes**.
- **Copier l'affichage** copie uniquement ce qui est affiché, avec le filtre en tête.
- **Niveau de détail** (par sujet) : *Normal*, *Détaillé* (par défaut pour le Guide TV) ou *Débogage* (tout). Le réglage s'applique aux lignes écrites ensuite ; les erreurs et alertes sont toujours gardées.
- **Session en cours / Session précédente** : le journal est conservé sur disque (le chemin du dossier est indiqué en bas de la fenêtre), pour relire ce qui s'est passé au démarrage de la session précédente.

## Enregistrements et téléchargements

### Enregistrer le direct

Bouton rond rouge de la barre du lecteur, touche **R**, ou clic droit sur une chaîne > **Enregistrer maintenant** : la chaîne est enregistrée jusqu'à la fin du programme en cours (plus la marge) ou jusqu'à l'arrêt, dans **Vidéos/Kastideo/Enregistrements**.

- Les octets du flux sont recopiés tels quels dans un fichier **.ts**, sans perte : la chaîne regardée est copiée depuis le relais (aucune seconde connexion au fournisseur) ; une autre chaîne est téléchargée directement, avec reconnexion si le flux est coupé.
- À la fin, le .ts est converti sans perte en **MKV** (format par défaut, Réglages > Enregistrements) ; si la conversion échoue, le .ts est gardé — il se lit partout.
- Les flux HLS (.m3u8) et la lecture sans relais passent encore par le moteur vidéo.

### Programmer un enregistrement

- **Clic droit sur une chaîne du direct > Programmer un enregistrement…**, ou bouton **Programmer…** de l'écran Enregistrements (choisissez alors la chaîne : favoris, récents ou recherche).
  - **Programmes du guide** : les prochains programmes de la chaîne, avec **Programmer** (ou **Enregistrer** pour celui en cours). Une coche indique ceux déjà programmés.
  - **Plage horaire** : jour, heure de début et de fin, titre facultatif — pour une chaîne sans guide TV ou une émission précise. Une fin plus tôt que le début se termine le lendemain.
  - **Répétition** (liste en haut à droite) : **une seule fois**, **tous les jours**, **du lundi au vendredi** ou **chaque semaine**. La prochaine occurrence est ajoutée automatiquement ; le bouton ⟲ d'un enregistrement répété dans la liste arrête la répétition.
- Depuis la fiche d'un programme à venir (guide TV, thèmes) : **Programmer l'enregistrement**.
- Les marges avant et après (Réglages > Enregistrements) s'ajoutent. Kastideo doit être ouvert à l'heure prévue : activez au besoin **Lancer Kastideo à l'ouverture de session** (Réglages > Général).

### Fiches dans votre langue

Avec une **clé TMDB** (Réglages > Général), titres, résumés, genres et épisodes viennent de TMDB, dans la langue de l'interface. Quand le seul résumé disponible est celui du fournisseur dans une autre langue (portugais, espagnol…), il est replié : **Afficher le résumé (portugais)** l'affiche quand même. Il n'apparaît pas dans le bandeau ni dans la liste des épisodes.

### Télécharger un film ou des épisodes

Bouton **Télécharger** de la fiche d'un film (maintenant ou **cette nuit**), **Télécharger la saison** ou icône de chaque épisode pour une série, clic droit > Télécharger. Un téléchargement à la fois, repris après une coupure, mis en pause pendant la lecture (réglable). Fichiers dans **Vidéos/Kastideo/Films** et **Séries/<série>**.

### L'écran Enregistrements

Enregistrement en cours (arrêt), téléchargements (pause, reprise, annulation), enregistrements programmés et historique, fichiers du dossier : un clic les lit, clic droit pour les afficher dans le dossier ou les supprimer.

## Alertes et notifications

- **M'alerter au début** dans la fiche d'un programme à venir (cloche dans le guide).
- **Mots-clés** (Réglages > Enregistrements) : un programme dont le titre contient un mot-clé déclenche une alerte, sur vos chaînes favorites ou sur toutes.
- L'alerte s'affiche en haut à droite de Kastideo avec **Regarder**, et la fenêtre revient si elle était réduite.
- **Notifications du système** (Réglages > Général > Notifications, activées par défaut) : alertes, début et fin d'enregistrement, téléchargement terminé ou impossible apparaissent aussi dans le centre de notifications de Windows ou de Linux, même quand Kastideo est derrière une autre fenêtre. Un clic sur la notification ramène Kastideo.

## Corriger une chaîne

Clic droit sur une chaîne > **Modifier la chaîne…** : nom, numéro, logo (adresse d'une image ou fichier copié dans Kastideo) et chaîne du **guide TV** (recherche parmi les guides du fournisseur et de secours). La correction vaut pour cette version de la chaîne (HD, FHD…) et reste après chaque actualisation. **Rétablir** revient à l'original.

## Organiser les catégories

- **Clic droit sur une catégorie** de la barre latérale : **Renommer…**, **Placer en haut**, **Monter**, **Descendre**, **Placer en bas**, **Masquer cette catégorie**, **Gérer les catégories…**.
- **Réglages > Catégories** (ou l'icône à droite de « Catégories ») : pour le direct, les films ou les séries — glissez pour changer l'ordre, décochez pour masquer partout, double-clic pour renommer, **mots-clés** pour masquer d'un coup toutes les catégories qui les contiennent (ex. « PAKISTAN »), **Trier de A à Z**, **Rétablir**.
- **Tout sélectionner / désélectionner** : la case au-dessus de la liste coche ou décoche d'un coup toutes les catégories listées. Avec la **recherche** (par exemple « PT »), elle ne concerne que les catégories trouvées : masquez tout un pays en deux clics, puis recochez seulement celles que vous voulez.

Une catégorie masquée l'est partout : listes, recherche, accueil, rangées.

## Favoris et récents

Étoile de la barre du lecteur, touche **F** ou clic droit > Ajouter aux favoris. Les récents gardent les 60 derniers contenus ouverts.

- **Modifier** (à droite du titre « Récents ») : cochez des éléments puis **Retirer la sélection**, ou la croix d'une ligne pour la retirer seule ; **Tout sélectionner** et **Tout effacer** (pour la section affichée). **Terminé** revient à la liste.
- Clic droit sur un contenu > **Retirer des récents**.
- Réglages > Général > **Effacer les récents** les efface tous, toutes sections confondues.

## Apparence

Réglages > **Apparence** :

- **Thème** : **Sombre** (par défaut), **Clair** ou **Comme le système** (suit le réglage de Windows ou de Linux). Le lecteur, l'interface TV, la MultiVue, l'accueil, les fiches et le bandeau « à la une » restent sombres, comme sur Mac.
- **Couleur d'accent** : par défaut (bleu de Kastideo), bleu, violet, rose, rouge, orange, vert ou turquoise — sélection dans les listes, boutons, interrupteurs.
- **Densité des listes** (interface Classique) : compacte, standard ou aérée.
- **Taille des vignettes** (interface Cinéma) : petites, moyennes ou grandes.
- **Interface** par type de contenu et **bandeau « à la une »** (voir plus haut).

Les changements s'appliquent tout de suite, sans redémarrer.

## Raccourcis clavier

- **Ctrl+0** : accueil — **Ctrl+1** : direct — **Ctrl+2** : films — **Ctrl+3** : séries — **Ctrl+7** : guide TV — **Ctrl+Alt+M** : MultiVue — **Ctrl+,** : réglages
- **Espace** : lecture / pause — **M** : son — **F** : favori — **R** : enregistrer / arrêter — **← / →** : −10 s / +30 s
- **Ctrl+Entrée** ou double-clic sur l'image : mode cinéma — **F11** : plein écran — **Échap** : quitter le mode cinéma, revenir à la fiche ou aux rangées
- Interface TV : **↑ / ↓** zapping, **chiffres** numéro, **←** panneau, **→ / I** bandeau, **B** chaîne précédente, **G** guide, **H** accueil
- MultiVue : **1 à 4** son, **G** en grand, **A** ajouter, **Suppr** retirer, **F** plein écran, **Échap** quitter
- **Ctrl+Alt+L** : journal

## Démarrage et fichiers .m3u

Réglages > Général > **Démarrage et fichiers** :

- **Lancer Kastideo à l'ouverture de session** (Windows et Linux), et **Démarrer réduit** dans la barre des tâches : les enregistrements programmés et les alertes n'ont lieu que si Kastideo est ouvert.
- **Ouvrir les fichiers .m3u et .m3u8 avec Kastideo** (facultatif) : un double-clic sur une playlist propose de l'ajouter comme source (Réglages > Sources) ; si Kastideo est déjà ouvert, la fenêtre existante la reçoit. Si Windows continue d'ouvrir un autre programme, faites clic droit sur le fichier > Ouvrir avec > Choisir une autre application > Kastideo.

Ces deux options sont aussi proposées par l'installateur Windows (décochées par défaut).

## Mises à jour

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

## Réglages

- **Général** : langue (au prochain lancement), reprise de lecture, relais de flux, actualisation au démarrage, effacer les récents, **connexions simultanées** (MultiVue), **notifications du système**, guide TV et guide de secours, contenus adultes (masqués par défaut), clé TMDB, **démarrage et fichiers .m3u**, **mises à jour**.
- **Apparence** : thème, couleur d'accent, densité des listes, taille des vignettes, interfaces, bandeau « à la une ».
- **Sources** : ajouter, actualiser, supprimer, état du guide.
- **Catégories** : ordre, masquage, noms, mots-clés.
- **Enregistrements** : dossier, format, marges, téléchargements, différé, alertes.
- **Sauvegarde** : exporter ou importer la configuration.

## Clé TMDB (facultative et gratuite)

Créez un compte sur themoviedb.org, puis **Paramètres > API** et demandez une clé (usage personnel). Copiez la « clé API » (v3) ou le « jeton d'accès en lecture » (v4) dans Réglages > Général, puis **Enregistrer**. Les fiches deviennent plus complètes (affiches, distribution, bandes-annonces, résumés et épisodes en français).

## Sauvegarde et transfert

Réglages > **Sauvegarde** : **Exporter la configuration…** (sources et leur guide, mots de passe si vous le souhaitez, favoris, récents, catégories, interfaces, apparence, nombre de connexions, contenus adultes, bandeau, clé TMDB) et **Importer une configuration…**. Le fichier est le même que celui de Kastideo pour Mac : vous pouvez passer d'un ordinateur à l'autre dans les deux sens. Rien n'est supprimé à l'importation. Les serveurs Jellyfin, Emby et Plex sont repris (mot de passe ou jeton compris si demandé) ; les dossiers aussi, avec leurs chemins (à corriger s'ils diffèrent sur cet ordinateur).

## Installation

- **Windows (recommandé)** : lancez **Kastideo-…-windows-x64-setup.exe**. Par défaut, Kastideo s'installe pour vous seul, sans droits administrateur (dans votre dossier AppData) ; l'installateur propose aussi de l'installer pour tous les utilisateurs, une icône sur le bureau, l'ouverture des fichiers .m3u et le lancement à l'ouverture de session. Désinstallation : Paramètres de Windows > Applications > Kastideo.
- **Windows, version portable** : décompressez l'archive « windows-x64.zip » où vous voulez et lancez **kastideo.exe** (rien n'est installé ; les mises à jour remplacent les fichiers du dossier).
- L'application n'est pas signée : si SmartScreen affiche « Windows a protégé votre ordinateur », cliquez sur **Informations complémentaires** puis **Exécuter quand même**.
- **Zorin OS 17 / Ubuntu 22.04** : paquet « ubuntu22.04_amd64.deb » (double-clic ou `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04** : paquet « ubuntu24.04_amd64.deb ».
- **Toute distribution, et Raspberry Pi (64 bits)** : fichier AppImage ; rendez-le exécutable (clic droit > Propriétés > Autoriser l'exécution, ou `chmod +x`) puis lancez-le.

## Nouveautés

- **1.3.3-desktop1** : Journal par sujets (Guide TV, Lecture et relais, Sources…, recherche, niveaux de détail, session précédente conservée), guide TV détaillé dans le journal, bouton « Recharger le guide ».
- **1.3.1-desktop1** : tuile « Mes vidéos » (reprise, ajouts récents, filtres genre / année / non vus, tri, navigation par dossiers, diagnostic des erreurs), sélecteur Tout / IPTV / Mes vidéos dans Films et Séries, mot de passe ou jeton facultatif, connexion Emby corrigée, cache des sources relu correctement au démarrage.
- **1.3.0-desktop1** : nouvelles sources — dossiers (disque, clé USB, NAS), Jellyfin, Emby et Plex — avec recherche des serveurs sur le réseau, reprise et « vu » partagés avec les serveurs, fiches TMDB et correction des fiches des fichiers, sous-titres placés à côté.
- **1.2.2-desktop1** : programmer un enregistrement depuis le direct (programmes du guide ou plage horaire, répétition quotidienne, en semaine ou hebdomadaire), modifier les récents, case « Tout sélectionner » des catégories.
- **1.2.1-desktop1** : enregistrement fiabilisé (copie directe du flux, conversion en MKV), différé corrigé, modification des sources, bouton « œil », fiches dans votre langue, pays et langues de l'interface Cinéma.
- **1.2.0-desktop8** : installateur Windows, mises à jour intégrées, nouveautés après une mise à jour, lancement à l'ouverture de session, ouverture des fichiers .m3u.
- **1.2.0-desktop7** : MultiVue (jusqu'à 4 chaînes, dispositions, grande image, groupes mémorisés), thème clair ou comme le système, couleur d'accent, densité des listes, taille des vignettes, catégories réorganisables depuis la barre latérale, notifications du système, aide complète.
- **1.2.0-desktop6** : différé du direct, enregistrement immédiat et programmé, téléchargements, alertes de programme, correction des chaînes.
- **1.2.0-desktop5** : fiches des films et séries dans la langue de l'interface.
- **1.2.0-desktop4** : guide TV en grille, interface TV, fermeture corrigée sous Windows, une seule fenêtre.
- **1.2.0-desktop3** : direct en interface Cinéma, thèmes, bandeau « à la une ».

## Prochaines étapes

1. Corrections des retours de test (Windows et Linux).
2. Version stable pour Windows et Linux.

## Dépannage

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

## Confidentialité

Kastideo ne collecte aucune donnée. Il contacte seulement vos fournisseurs IPTV, les guides TV que vous avez choisis, GitHub pour les mises à jour et, si vous avez saisi une clé, TMDB. Vos réglages, favoris et mots de passe restent sur votre ordinateur.
