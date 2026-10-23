# Aide de Kastideo

Kastideo est un lecteur multimédia qui réunit vos chaînes en direct, films et séries IPTV dans une interface simple et rapide. Kastideo ne fournit aucun contenu : vous ajoutez vos propres sources (abonnement Xtream Codes ou playlist M3U).

> Version 1.0.3 — direct : changement de chaîne fiabilisé (attente de libération de la connexion, nouveaux essais), flux fermé en quittant ; version 1.0.1 — thèmes : chaînes reconnues par leur nom proposées même sans guide TV ; première version stable ; correction des chaînes (nom, numéro, logo, guide TV) ; nouveaux thèmes (Auto-Moto, Cuisine & Maison, Nature, Régional, International, Religion, Radio, Adulte), disciplines du sport ; Direct par thème (en ce moment, ce soir, chaînes), une version par chaîne selon la connexion, alertes de programme ; recherche de mise à jour au démarrage, proposée hors visionnage ; numéro de version sur l'accueil ; MultiVue (jusqu'à 4 chaînes, selon votre abonnement) ; lecteur repensé : barre rétractable, mini-timeline, panneau d'informations (pistes audio, sous-titres), santé du flux ; passage rapide du Direct (Classique) aux Films (Cinéma) ; accueil redessiné, cadrage du bandeau ; bandeau « à la une » corrigé ; catégories réordonnables, masquables et renommables ; bandeau « à la une » en carrousel (tendances TMDB, derniers ajouts, catégorie au choix, programmes en cours) ; passage instantané du direct aux autres sections ; blocage corrigé en quittant le direct, son des enregistrements en AAC ; démarrage de l'enregistrement du direct fiabilisé ; guide TV de secours xmltvfr.fr ; procédure pour la clé TMDB dans l'aide ; fiche film/série remise en page ; écran noir corrigé au retour à la lecture et en plein écran ; fiches des films et séries (Xtream + TMDB) en interface Cinéma, enregistrement visible pendant son écriture, conversion MP4 fiabilisée ; plein écran corrigé, enregistrement du direct fiabilisé ; écran d'accueil, suppression dans les Récents, application disponible en français et en anglais ; Guide TV en grille, reprise de lecture, indicateur de téléchargement ; nouvelle icône (monogramme K) ; interface TV pour le direct (panneau de chaînes, bandeau d'information, zapping par numéro), en plus des interfaces Classique et Cinéma.

## Premiers pas

1. Au premier lancement, cliquez sur **Ajouter une source**.
2. Choisissez le type de source : **Xtream Codes**, **Playlist (URL)** ou **Playlist (fichier)**.
3. Renseignez les informations demandées puis cliquez sur **Ajouter**.
4. Kastideo charge la liste des chaînes, films et séries, puis le guide TV.

## Les sources

### Xtream Codes

C'est le format le plus courant chez les fournisseurs IPTV. Il faut trois informations : l'adresse du **serveur** (par exemple `http://exemple.com:8080`), votre **identifiant** et votre **mot de passe**.

- Le bouton **Tester la connexion** vérifie vos identifiants et affiche l'état du compte, sa date d'expiration et le nombre de connexions simultanées autorisées.
- Le mot de passe est enregistré dans le **trousseau macOS**, jamais en clair sur le disque.
- Le guide TV du serveur est utilisé automatiquement.
- Les séries s'ouvrent sur une fiche avec leurs saisons et leurs épisodes.

### Playlist M3U / M3U8

- **Par URL** : collez l'adresse de la playlist fournie par votre fournisseur.
- Si l'adresse est de la forme `get.php?username=…&password=…` (le cas le plus courant chez les fournisseurs par abonnement), Kastideo la reconnaît et l'enregistre en **Xtream Codes** : le chargement est beaucoup plus rapide, le guide TV est inclus et le mot de passe est rangé dans le trousseau. Les sources de ce type déjà enregistrées sont converties automatiquement.
- **Par fichier** : choisissez un fichier `.m3u` ou `.m3u8` sur votre Mac. Kastideo garde l'autorisation d'y accéder pour pouvoir l'actualiser.
- Les catégories proviennent de l'attribut `group-title`, les logos de `tvg-logo` et l'association au guide TV de `tvg-id`.
- Kastideo classe automatiquement les entrées en Direct, Films ou Séries d'après leur adresse.

### Guide TV (XMLTV)

Chaque source peut avoir une adresse de guide TV au format XMLTV (`.xml` ou `.xml.gz`). Si vous la laissez vide, Kastideo utilise celle du serveur Xtream ou celle annoncée dans la playlist (`url-tvg`). Le guide est conservé de 6 h en arrière à 48 h en avant. Il est rechargé quand il arrive à moins de 12 h de sa fin (vérification toutes les heures si Kastideo reste ouvert). Si le fournisseur envoie un guide vide ou illisible, les programmes déjà connus sont conservés et un message l'indique sous la source (Réglages > Sources).

### Guide TV de secours (xmltvfr.fr)

Le guide de votre fournisseur peut être incomplet ou momentanément vide. Kastideo le complète avec un **guide de secours** gratuit, celui de **xmltvfr.fr** (guide « Complet » par défaut : environ 785 chaînes françaises et étrangères, 5 jours, mis à jour chaque jour) :

- seules les chaînes **sans programme** chez votre fournisseur sont complétées ; le guide du fournisseur reste prioritaire ;
- les chaînes sont reliées **par leur nom** : « |FR| TF1 FHD » → TF1, « |FR| FRANCE 2 UHD » → France 2, « |FR| TF1 4K » → TF1 4K ;
- le guide de secours est rechargé toutes les 12 heures.

Réglages > Général > **Guide TV de secours** : activer ou désactiver, choisir un autre guide xmltvfr.fr (France ~400 chaînes, TNT) ou saisir n'importe quelle adresse XMLTV, **Actualiser maintenant**, et voir combien de chaînes ont été reliées aux vôtres.

### Gérer les sources

Ouvrez **Kastideo > Réglages… (⌘,)**, onglet **Sources**, ou cliquez sur le bouton **Sources** de la barre d'outils.

- L'interrupteur active ou désactive une source sans la supprimer.
- Les boutons permettent d'actualiser, de modifier ou de supprimer une source.
- En cas d'erreur, le message s'affiche en rouge sous la source et un triangle orange apparaît dans la barre latérale.

## Naviguer

### L'écran d'accueil

Kastideo s'ouvre sur l'**accueil** : trois grands pavés **Direct**, **Films** et **Séries**, puis des boutons plus petits vers les **Favoris**, les **Récents**, le **Guide TV** et les **Enregistrements**.

- Le champ de **recherche** en haut cherche d'un coup dans les chaînes, les films et les séries ; un clic sur un résultat l'ouvre.
- La rangée **Reprendre la lecture** liste les films et épisodes entamés ; un clic reprend là où vous vous étiez arrêté.
- Si une lecture est en cours, un bandeau permet d'y **retourner** ou de l'**arrêter**.
- Pour revenir à l'accueil à tout moment : bouton **Accueil** (maison) en haut à gauche de la barre d'outils, **⌘0**, ligne **Accueil** de la barre latérale, ou touche **H** en interface TV.

Le **numéro de version** de Kastideo est affiché discrètement en bas à droite de l'accueil ; un clic ouvre les nouveautés de la version.

### Les colonnes de la fenêtre

En interface Classique, la fenêtre comporte trois colonnes :

- **Barre latérale** : Accueil, Direct, Films, Séries, Favoris, Récents, Guide TV, puis les catégories de la section choisie et l'état de vos sources.
- **Liste** : les éléments de la section ou de la catégorie, avec le programme en cours pour les chaînes. Le champ **Rechercher** filtre la liste sans tenir compte des majuscules ni des accents.
- **Lecteur** : la vidéo, avec en dessous le programme en cours, sa progression et les programmes suivants.

Un clic droit sur un élément permet de l'ajouter aux favoris ou de copier l'adresse du flux.

### Trois interfaces au choix

Kastideo propose trois présentations, que vous choisissez **séparément pour le direct, les films, les séries, et les favoris / récents** :

- **Classique** : les trois colonnes décrites ci-dessus.
- **TV** (direct uniquement) : voir ci-dessous.
- **Cinéma** : un grand **bandeau « à la une »** qui défile (voir ci-dessous), puis des **rangées horizontales** : reprise, favoris et une rangée par catégorie. Les films et séries s'affichent en affiches, les chaînes en vignettes avec le programme en cours. Un clic sur une chaîne ouvre le lecteur en plein cadre. Un clic sur l'affiche d'un **film** ou d'une **série** ouvre d'abord sa **fiche** : grande image de fond, affiche, année, durée, genres, note, résumé, réalisateur, distribution (avec photos), bouton **Retour à Films** (ou Séries) en haut à gauche, boutons **Lire** / **Reprendre**, **Voir les épisodes**, **Bande-annonce**, **Télécharger** et favori. Les informations viennent de votre fournisseur IPTV ; ajoutez une clé **TMDB** gratuite (Réglages > Général > Fiches des films et séries) pour des fiches plus complètes. **Retour** (ou Échap) revient au catalogue. En haut de la fenêtre, les onglets **Direct / Films / Séries / Guide TV / Favoris / Récents / Enregistrements** remplacent la barre latérale ; la recherche fonctionne comme en Classique. « Tout voir » ouvre une catégorie complète en grille.

Pour changer d'interface :

- le bouton **Interface** de la barre d'outils (il s'applique au type de contenu affiché),
- menu **Présentation** : **⌥⌘1** Classique, **⌥⌘2** Cinéma, **⌥⌘3** TV (direct),
- ou **Réglages > Apparence**.

Par exemple : TV pour le direct et Cinéma pour les films et séries. La section **Enregistrements** s'affiche toujours en interface Classique. Le choix par défaut est Classique partout.

### Le bandeau « à la une » (Cinéma)

En haut des sections Films et Séries, un **carrousel plein cadre** fait défiler une sélection : grande image de fond, affiche, titre, année, durée, genres, note, résumé et boutons **Lire** (ou **Reprendre** / **Voir les épisodes**), **Plus d'infos** (la fiche) et **Bande-annonce**. Il mélange :

- les **tendances de la semaine** sur TMDB que l'on retrouve dans votre catalogue (clé TMDB nécessaire) ;
- les **derniers ajouts** de votre fournisseur ;
- une **sélection d'une catégorie** de votre choix (par exemple « Nouveautés » ou « Netflix »), ou de tout le catalogue au hasard.

Le défilement s'arrête quand la souris survole le bandeau ; les flèches et les points permettent de naviguer. En **Direct**, le bandeau montre le **programme en cours** de vos chaînes favorites et récentes, avec sa progression, le programme suivant et **Regarder**.

Réglages > Apparence > **Bandeau « à la une »** : afficher ou masquer, hauteur (compact, normal, grand), vitesse de défilement, sources du carrousel et catégories des films et des séries.

### L'interface TV (direct)

La chaîne occupe tout le cadre, comme sur une télévision. Au premier affichage, Kastideo reprend la dernière chaîne regardée.

- **Panneau de chaînes** : touche **←**, **Entrée**, ou approchez la souris du bord gauche. Il liste les chaînes avec numéro, logo, programme en cours et progression. Le menu en haut filtre par **Toutes / Favoris / Récents / catégorie**, et le champ **Rechercher** filtre par nom. Il se referme seul après quelques secondes (touche **→** ou **Échap** pour le fermer tout de suite).
- **Zapping** : **↑ / ↓** chaîne précédente / suivante de la liste affichée, **B** retour à la chaîne précédente.
- **Numéro de chaîne** : tapez les chiffres (par exemple **1** puis **2**) ; la chaîne s'ouvre après 1,6 s ou avec **Entrée**. Si votre fournisseur ne numérote pas ses chaînes, le numéro désigne la position dans la liste affichée.
- **Bandeau d'information** : s'affiche cinq secondes à chaque changement de chaîne (logo, numéro, programme en cours, horaires, programme suivant, heure). **I** ou **→** l'affiche ou le masque.
- Autres touches : **F** favori, **M** muet, **Espace** pause (direct en différé).
- Double-clic sur l'image ou **⌘↩** : plein écran ; la barre d'outils se masque.
- Les touches du clavier ne fonctionnent pas pendant la saisie dans le champ de recherche. Les onglets en haut de la fenêtre permettent de passer aux Films, aux Séries, etc.

### Le Guide TV en grille

Section **Guide TV** (barre latérale, onglet **Guide TV** des interfaces Cinéma et TV, **⌘7**, ou touche **G** en interface TV). Les chaînes sont en lignes, les heures en colonnes ; le trait rouge marque l'heure actuelle.

- **‹ ›** décalent la grille, **Maintenant** revient à l'heure actuelle, le menu de la date saute à un autre jour (19 h pour les jours suivants).
- Choisissez la durée affichée (**2 h / 3 h / 6 h**), filtrez par **favoris**, **récents** ou **catégorie**, ou recherchez une chaîne.
- Cliquez sur un programme : description, bouton **Regarder**, **Enregistrer** (programme en cours) ou **Programmer l'enregistrement** (programme à venir). Un point rouge signale un enregistrement programmé.
- Cliquez sur le nom d'une chaîne pour la regarder. Seules les chaînes ayant des programmes sont listées : si la grille est vide, vérifiez l'adresse du guide dans les réglages de la source.

### Le Direct par thème

La section **Thèmes** de la barre latérale (sous Direct) classe le direct par **thème** — Sport, Auto-Moto (sports mécaniques), Films, Séries, Info, Documentaires, Nature / Chasse & Pêche, Jeunesse, Divertissement, Cuisine & Maison, Musique, Généralistes, Régional (France 3 régions, télévisions locales), International (chaînes étrangères), Religion, Radio — sans les catégories que vous avez masquées. Trois modes :

- **En ce moment** : ce qui est diffusé maintenant, classé d'après le **genre du programme** dans le guide TV (un film sur une chaîne généraliste apparaît dans « Films »), avec la progression. Les chaînes **sans programme au guide** sont quand même proposées si leur **nom suffit à les classer** (beIN Sports → Sport…) : elles s'affichent avec leur nom, sans progression.
- **Ce soir** : les programmes qui commencent entre **20 h et 23 h**. Clic droit sur un programme à venir > **M'alerter au début du programme**.
- **Chaînes** : les chaînes classées par spécialité. Le thème est déduit automatiquement du nom de la chaîne (beIN, Eurosport → Sport ; BFM, LCI → Info…) puis de ses programmes habituels ; clic droit > **Thème de la chaîne** pour le corriger.

Chaque chaîne n'apparaît **qu'une fois**, même si votre fournisseur la propose en plusieurs versions (4K, FHD, HD, SD) : Kastideo choisit la version adaptée à **votre connexion** (réglage **Automatique**, dans Réglages > Général > Lecture > Version des chaînes) — il descend d'un cran après une lecture instable et remonte après trois lectures fluides. Clic droit > **Version** pour en choisir une autre.

Les thèmes sont aussi proposés ailleurs : rangées « Sport en ce moment », « Films en cours »… en tête du Direct en interface **Cinéma**, filtre **Thèmes** du panneau de chaînes de l'interface **TV** et du **Guide TV**, et pastilles « À la télé maintenant » (et « Ce soir ») sur l'**accueil**.

Dans **Sport**, une seconde rangée filtre par **discipline** : Football, Rugby, Tennis, Basket, Sports de combat, Golf, Cyclisme, Handball, Sports mécaniques, Sports d'hiver, Hippisme, Athlétisme & natation (d'après le titre, le genre et la description des programmes).

**Contenus adultes** : les chaînes et contenus dont le nom contient « |XX| » (ou rangés dans une catégorie adulte) sont **masqués partout** par défaut. Pour les afficher, et faire apparaître le thème **Adulte** : Réglages > Général > Lecture > **Afficher les contenus adultes**.

**Alertes de programme** (bouton 🔔 de la vue Thèmes) : Kastideo vous prévient deux minutes avant le début d'un programme dont le titre contient un mot choisi (« PSG », « Formule 1 »…), d'un thème sur vos chaînes favorites, ou d'un programme précis. Une notification et un bandeau **Regarder** apparaissent.

## Lecture

Kastideo lit tous les contenus avec le moteur **VLC** : direct au format MPEG-TS (.ts), HLS (.m3u8), MP4, MKV, AVI…

- La lecture démarre dès que vous sélectionnez une chaîne, un film ou un épisode.
- Pendant l'ouverture, le logo et le nom de la chaîne s'affichent. Le badge **« Prête en x s »** indique ensuite le temps de démarrage (désactivable dans les réglages).
- Les contrôles apparaissent au survol de la vidéo : lecture / pause, recul de 10 s et avance de 30 s pour les films et épisodes, barre de progression, volume (jusqu'à 200 %) et mode cinéma.
- Un clic sur la vidéo met en pause ; un **double-clic** active le **mode cinéma** : la fenêtre passe en plein écran et seule la **vidéo** reste affichée (ni colonnes ni barre d'outils ; le bouton vert de la fenêtre et **⌃⌘F** ont le même effet pendant une lecture). **Échap** ou **⌘↩** pour en sortir.
- **Reprise de la lecture** : pour les films et épisodes, Kastideo mémorise votre position. À la réouverture, la lecture reprend là où vous vous étiez arrêté, avec un message proposant de **recommencer au début**. Des barres de progression apparaissent dans les listes, les affiches et les épisodes. Désactivable, ou positions effaçables, dans les réglages.
- Pour les sources Xtream, le direct est lu au format MPEG-TS (.ts), comme le lecteur de référence Xtream ; si le flux échoue, Kastideo essaie automatiquement la variante .m3u8 (et inversement).

### Barre de contrôle, timeline et panneau d'informations

- **Barre rétractable** : elle apparaît au moindre mouvement de souris et disparaît, avec le pointeur, après 3 secondes d'inactivité (elle reste visible tant que la souris est dessus, pendant la pause ou quand le panneau est ouvert).
- **Mini-timeline** (films et épisodes) : un trait fin au-dessus des boutons, qui s'épaissit au survol en affichant l'heure visée ; cliquez ou glissez pour vous déplacer.
- **Santé du flux** : une pastille **verte** (Excellent), **orange** (Correct) ou **rouge** (Instable) indique la qualité de réception, avec la définition (SD, HD, 4K). Au survol : définition exacte, débit, images par seconde, images perdues et coupures de la dernière minute.
- **Panneau « Informations »** (bouton ⓘ ou **⌘I**, Échap pour fermer) : il glisse depuis la droite par-dessus la vidéo et montre la chaîne et son programme en cours et à venir, ou le résumé et la distribution d'un film ; le choix de la **piste audio** (langue, audiodescription…) et des **sous-titres** ; la qualité de réception détaillée.

### MultiVue (plusieurs chaînes à la fois)

La **MultiVue** affiche jusqu'à **4 chaînes en direct** dans une même fenêtre (1 en plein cadre, 2 côte à côte, 3 ou 4 en grille). Le **son suit la vignette active** (bordure orange) : cliquez sur une vignette ou utilisez les touches **1 à 4**.

- Ouverture : menu **Lecture > MultiVue…** (**⌥⌘M**), ou clic droit sur une chaîne > **Ajouter à la MultiVue**.
- Dans la fenêtre : **+** ajoute une chaîne (favoris, récents ou recherche) ; au survol d'une vignette, ⟳ change la chaîne et ✕ la retire ; **Tout arrêter** coupe tous les flux. Fermer la fenêtre arrête la MultiVue.
- Chaque flux utilise **une connexion** à votre fournisseur. La MultiVue est donc **désactivée par défaut** : indiquez le nombre de connexions simultanées de votre abonnement dans **Réglages > Général > Lecture** (2 à 4) pour l'activer. Le bouton **Tester la connexion** d'une source Xtream affiche ce nombre. À l'ouverture, la lecture principale s'arrête pour libérer sa connexion (sauf enregistrement en cours) ; un enregistrement ou un téléchargement occupe aussi une connexion.

### Si une chaîne ne démarre pas

Si aucune image n'arrive au bout de **20 secondes**, Kastideo essaie automatiquement l'autre format du flux (.ts ou .m3u8), puis affiche un message d'erreur avec le détail renvoyé par le moteur VLC.

Le **Journal de lecture** (menu **Lecture > Journal de lecture…**, **⌥⌘L**, ou bouton dans le message d'erreur) affiche les messages du moteur VLC : ouverture du flux, réponses du serveur, erreurs. Les identifiants et mots de passe y sont **masqués** : vous pouvez le copier avec **Copier le journal** pour le partager en cas de problème.

### Direct en différé

Mettez une chaîne en direct en **pause** : le moteur VLC continue de recevoir le flux et le garde en réserve. À la reprise, vous regardez en **différé** (indicateur jaune « DIFFÉRÉ −2:34 » dans les contrôles). Le bouton **Direct** revient au direct. Si un flux ne permet pas la pause, le bouton est grisé.

### Une seule connexion à la fois

La plupart des abonnements IPTV n'autorisent qu'**un flux simultané**. Kastideo ferme toujours le flux en cours avant d'ouvrir le suivant : vous pouvez zapper sans risque de dépasser votre limite. Si la lecture échoue, vérifiez qu'aucun autre appareil (TV, téléphone, Piboard…) ne regarde avec le même abonnement.

### Mémoire tampon

Dans **Réglages > Général > Lecture**, choisissez le compromis entre rapidité et stabilité :

- **Rapide** (par défaut) : 0,4 s de réserve, le zapping le plus court.
- **Équilibré** : 1 s.
- **Stable** : 3 s, pour les connexions ou les serveurs irréguliers (moins de coupures, démarrage plus lent).

## Enregistrements et téléchargements

Tout se retrouve dans la section **Enregistrements** de la barre latérale (**⌘6**) : enregistrement en cours, conversions, téléchargements, programmations et fichiers enregistrés (un clic pour les regarder, clic droit pour les afficher dans le Finder ou les supprimer).

Les fichiers sont rangés dans **~/Movies/Kastideo** (modifiable dans **Réglages > Enregistrements**) et nommés automatiquement, par exemple « TF1 – Le goût du détail – 2026-10-18 20h50 ».

### Enregistrer le direct

- Pendant la lecture d'une chaîne, cliquez sur **●** dans les contrôles, sur **Enregistrer** sous la vidéo, ou utilisez **⇧⌘R**. La pastille **REC** indique la durée.
- L'enregistrement s'arrête automatiquement à la fin du programme en cours (d'après le guide TV, plus la marge après), ou quand vous cliquez sur **■**.
- Il utilise **la même connexion** que la lecture : rien de plus n'est consommé sur votre abonnement.
- Clic droit sur une chaîne > **Enregistrer maintenant** : si vous regardez une autre chaîne, Kastideo vous demande s'il faut arrêter la lecture, puis enregistre en arrière-plan.
- Un **bandeau** en bas de la fenêtre confirme le début et la fin de l'enregistrement et indique **le dossier** où se trouve le fichier (bouton **Afficher**). Si le dossier choisi dans les réglages n'est plus accessible, le fichier est placé dans ~/Movies/Kastideo et le bandeau le signale. Les étapes détaillées sont dans le **Journal de lecture**.
- **Pendant l'enregistrement**, le fichier est visible et grossit dans le sous-dossier **En cours** du dossier des enregistrements (un dossier au nom de l'émission). À l'arrêt, il est placé dans le dossier des enregistrements et le sous-dossier est supprimé. Si le moteur VLC ne crée pas le fichier sous 10 secondes, Kastideo réessaie automatiquement dans un dossier temporaire (le fichier n'apparaît alors qu'à l'arrêt) ; le message « Enregistrement impossible » ne s'affiche qu'après ces deux essais, et le Journal de lecture (⌥⌘L) en donne le détail. La durée n'est limitée que par l'espace disque : comptez environ 1 à 3 Go par heure selon la chaîne (un avertissement s'affiche sous 3 Go libres).
- À la fin, l'enregistrement est **converti en MP4** sans perte de qualité (lisible par QuickTime, l'iPhone, l'iPad). Le fichier .ts apparaît d'abord, puis est remplacé par le .mp4 quand la conversion est terminée (quelques minutes pour 2 h ; suivi dans la section Enregistrements). L'image est copiée sans perte ; le **son est converti en AAC** (certaines chaînes diffusent un son MP2 ou AC-3 que QuickTime lit sans son). Les sous-titres DVB et le télétexte, incompatibles avec le MP4, sont écartés ; si la conversion échoue, un second essai ne garde que l'image et le son principal, et en dernier recours le .ts est conservé. Désactivable dans les réglages.

### Programmer un enregistrement

- Dans le guide TV sous la vidéo, **double-cliquez** sur un programme à venir, ou faites un clic droit > **Programmer l'enregistrement**. Une pastille rouge marque les programmes programmés.
- Clic droit sur une chaîne > **Programmer un enregistrement…** (ou l'icône calendrier sous la vidéo) : choisissez un programme du guide ou des horaires libres.
- Des **marges** avant et après (2 et 5 minutes par défaut, réglables) évitent de rater le début ou la fin.
- À l'heure dite, l'enregistrement démarre en arrière-plan. Si vous regardez une autre chaîne, Kastideo vous demande s'il faut arrêter la lecture ; sans réponse, l'enregistrement démarre au bout de 60 secondes.

### Télécharger un film ou des épisodes sans les regarder

- Clic droit sur un film ou un épisode > **Télécharger** ou **Télécharger cette nuit**, ou le bouton **Télécharger** sous la vidéo.
- Pour une série : bouton **Télécharger** de la fiche > la saison affichée ou toute la série.
- Les téléchargements passent **l'un après l'autre** (file d'attente). « Cette nuit » démarre à 2 h par défaut (réglable).
- Vous pouvez mettre en pause, reprendre ou annuler chaque téléchargement dans la section Enregistrements.
- **Indicateur permanent** : tant qu'un téléchargement est actif, un anneau d'avancement reste visible dans la barre d'outils. Un clic ouvre le détail : avancement du film ou de l'épisode en cours, « épisode X sur N », avancement de la série ou du lot, vitesse et **temps restant estimé** (affiné au fil du téléchargement).

### Connexion unique : qui a la priorité ?

Votre abonnement n'autorise qu'une connexion. Kastideo ne fait donc qu'une chose à la fois et **vous demande toujours** avant d'interrompre quelque chose :

- Vous changez de chaîne pendant un enregistrement : Kastideo demande s'il faut **arrêter l'enregistrement**.
- Vous lancez une lecture pendant un téléchargement : le téléchargement est **mis en pause** et reprend tout seul quand la lecture s'arrête.
- Les fichiers déjà enregistrés se regardent à tout moment, même pendant un enregistrement en arrière-plan.

### Bon à savoir

- Kastideo doit **rester ouvert** et le Mac **allumé** pour les enregistrements programmés et les téléchargements de nuit. Kastideo empêche la mise en veille automatique pendant l'activité et dans l'heure qui précède, mais pas l'extinction ni la mise en veille manuelle.
- Une **notification macOS** signale le début et la fin des enregistrements et des téléchargements (désactivable).
- **Nettoyage automatique** (facultatif) : les enregistrements plus anciens que le nombre de jours choisi sont placés dans la corbeille.
- Une alerte prévient quand l'espace disque devient faible.
- Les droits de copie dépendent des conditions de votre fournisseur : Kastideo enregistre pour votre usage privé ce que votre abonnement vous donne déjà.

## Corriger une chaîne

Certaines chaînes sont mal référencées par le fournisseur (nom erroné, mauvais programmes, logo absent). Clic droit sur la chaîne > **Modifier la chaîne…** :

- **Nom** et **numéro** (utilisé pour le zapping par numéro de l'interface TV) ;
- **Logo** : adresse d'une image, ou **Choisir un fichier…** (l'image est copiée dans Kastideo) ;
- **Programmes du guide TV** : si les programmes affichés sont faux ou absents, cherchez la bonne chaîne dans la liste (guide du fournisseur et guide de secours) ; le programme en cours aide à la reconnaître.

La correction ne concerne que **cette version** de la chaîne (FHD, HD, SD… se corrigent séparément) et survit aux actualisations de la source. **Rétablir l'original** l'annule.

## Organiser les catégories

Vous n'êtes pas obligé de subir l'ordre et la liste des catégories du fournisseur. Ouvrez **Présentation > Gérer les catégories…** (**⌥⌘C**), le bouton à droite du titre « Catégories » de la barre latérale, ou faites un clic droit sur une catégorie. Choisissez la section (**Direct**, **Films** ou **Séries**), puis :

- **Réordonner** : glissez les catégories dans la liste, ou utilisez le menu **…** > **Placer en haut / en bas**. **Trier A → Z** classe tout par ordre alphabétique.
- **Masquer** : décochez une catégorie (ou clic droit > **Masquer cette catégorie** dans la barre latérale). Une catégorie masquée disparaît **partout** : barre latérale, listes « Direct / Films / Séries », recherche, Guide TV, interfaces Cinéma et TV, bandeau « à la une ». Vos favoris et récents restent accessibles.
- **Masquer par mot-clé** : saisissez par exemple « PAKISTAN » ou « ARABIC » : toutes les catégories dont le nom contient ce mot sont masquées, y compris celles que le fournisseur ajoutera plus tard. Cliquez sur la croix d'un mot-clé pour l'annuler.
- **Renommer** : le crayon permet de donner un nom plus lisible (« FRANCE FHD | OTT » → « France HD ») ; **Nom d'origine** l'annule.
- **Tout afficher** réaffiche les catégories masquées ; **Réinitialiser…** revient entièrement à la présentation du fournisseur.

Les nouvelles catégories ajoutées par le fournisseur apparaissent à côté de leur voisine d'origine.

## Favoris et récents

- Ajoutez un favori avec l'étoile du panneau d'informations, le clic droit ou **⌘D**.
- La section **Récents** garde les 60 derniers contenus regardés.
- **Supprimer des récents** : clic droit sur un élément > **Retirer des récents** (ou touche **⌫** sur l'élément sélectionné en interface Classique). Pour plusieurs éléments, cliquez sur **Modifier**, cochez les éléments puis **Supprimer** ; **Tout sélectionner** coche toute la liste et **Tout effacer** vide l'historique.
- Après une suppression, un bandeau **Annuler** reste affiché quelques secondes pour tout restaurer.
- Les récents peuvent aussi être effacés dans les réglages, onglet **Général**.

## Raccourcis clavier

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
- **⌥⌘L** : journal de lecture
- **⌘D** : ajouter ou retirer des favoris
- **⌘R** : actualiser toutes les sources
- **⌘,** : réglages et sources
- **⌘?** : cette aide

## Mises à jour

Kastideo se met à jour tout seul grâce à **Sparkle**, l'outil de référence des applications Mac distribuées hors App Store.

- **Au démarrage** (quelques secondes après le lancement), puis une fois par jour si Kastideo reste ouvert, Kastideo vérifie discrètement si une nouvelle version est disponible sur GitHub.
- Si c'est le cas, un **bandeau** en haut de la fenêtre l'annonce — **jamais pendant un visionnage ni un enregistrement** (il attend la fin de la lecture). La mise à jour est **facultative** : **Mettre à jour…** ouvre la fenêtre des nouveautés puis **Installer la mise à jour** (Kastideo se ferme, s'installe et se relance) ; **Plus tard** masque le bandeau jusqu'au prochain lancement ; **Ignorer cette version** ne la propose plus (la suivante le sera).
- Vous pouvez vérifier à tout moment avec **Kastideo > Rechercher les mises à jour…**.
- Chaque mise à jour est signée : Kastideo refuse d'installer un fichier qui ne vient pas de son éditeur.

Dans **Réglages > Mises à jour** :

- **Rechercher les mises à jour au démarrage** : active ou désactive la vérification au lancement et quotidienne.
- **Recevoir les versions de test (bêta)** : propose aussi les versions bêta, qui apportent les nouveautés plus tôt mais peuvent être moins stables. Désactivez l'option pour revenir aux versions stables à la prochaine mise à jour.

> Les versions 0.1.0 et antérieures ne savent pas se mettre à jour : installez la 0.2.0 une fois à la main, les suivantes arriveront toutes seules.

## Nouveautés

Après chaque mise à jour, la fenêtre **Nouveautés** résume les changements de la version installée. Vous pouvez la rouvrir avec **Aide > Nouveautés de cette version** et y consulter les versions précédentes.

## Réglages généraux

- **Langue** (onglet **Général**) : Kastideo existe en **français** et en **anglais**. La langue se choisit au premier lancement, puis peut être changée dans **Réglages > Général > Langue** (ou « Système » pour suivre la langue du Mac). Le changement s'applique après un redémarrage de l'application, que Kastideo propose de faire pour vous. L'aide et les menus suivent la langue choisie ; les notes de version restent en français.
- **Apparence** (onglet **Apparence**) : thème sombre (par défaut), clair ou comme le système ; **couleur d'accent** (Système, bleu, violet, rose, rouge, orange, vert, turquoise) ; **interface** Classique ou Cinéma pour chaque type de contenu ; **densité des listes** (compacte, standard, aérée) pour l'interface Classique ; **taille des vignettes** (petites, moyennes, grandes) pour l'interface Cinéma.
- **Fiches des films et séries** (onglet **Général**) : clé API **TMDB** facultative (gratuite sur themoviedb.org > Paramètres > API ; clé v3 ou jeton de lecture v4). Elle est conservée dans le trousseau. **Enregistrer et vérifier** contrôle la clé. Sans clé, les fiches utilisent les informations de votre fournisseur IPTV.
- **Actualiser au démarrage** : recharge les sources dont la dernière actualisation date de plus de 6 heures.
- **Cache** : Kastideo garde une copie locale des listes et du guide TV pour démarrer instantanément. **Vider et recharger** efface cette copie et relance le chargement.

### Obtenir une clé TMDB (gratuite)

TMDB (The Movie Database) est une base de films et séries communautaire. Sa clé est **gratuite** pour un usage personnel ; elle permet à Kastideo d'afficher les photos des acteurs, les affiches et fonds en haute définition, la bande-annonce et un résumé traduit.

1. Créez un compte sur **themoviedb.org** (bouton « Rejoindre TMDB »), puis validez-le avec le lien reçu par e-mail.
2. Connecté, ouvrez **themoviedb.org/settings/api** (avatar > Paramètres > API), ou cliquez sur **Obtenir une clé gratuite** dans les réglages de Kastideo.
3. Cliquez sur **Créer**, choisissez **Developer** et acceptez les conditions d'utilisation.
4. Remplissez le formulaire : type d'usage **Personnel**, nom de l'application **Kastideo**, URL **https://github.com/jihemezes/kastideo**, un court résumé (« Lecteur IPTV personnel, affichage des fiches de films »), puis vos coordonnées.
5. Validez : la page affiche une **Clé d'API** (32 caractères) et un **Jeton d'accès en lecture** (long, commence par « eyJ »). Kastideo accepte l'un ou l'autre ; la clé d'API est la plus simple à copier.
6. Dans Kastideo : **Réglages (⌘,) > Général > Fiches des films et séries**, collez la clé puis cliquez sur **Enregistrer et vérifier**. « Clé valide ✓ » confirme la saisie.
7. Rouvrez une fiche (ou cliquez sur **Actualiser** en bas de la fiche) : elle est complétée par TMDB.

La clé est conservée dans le trousseau du Mac. **Retirer la clé** revient aux seules informations du fournisseur IPTV.

## Dépannage

- **Changement de chaîne lent ou refusé (« HTTP 404 », « 403 », « 401 » ou « 520 » dans le journal de lecture)** : avec un abonnement à une connexion, le fournisseur met un instant à libérer la chaîne précédente. Kastideo attend 1,5 s avant d'ouvrir la nouvelle chaîne puis réessaie deux fois si elle est refusée (« Attente… » et « nouvel essai » dans le journal). Si le refus persiste, patientez une minute puis réessayez.

Kastideo s'identifie auprès des serveurs comme le lecteur **VLC** : beaucoup de fournisseurs IPTV ne répondent qu'aux lecteurs qu'ils reconnaissent.

- **« Le serveur n'a pas répondu à temps »** : le serveur est surchargé ou indisponible. Réessayez plus tard ; si votre adresse est de type `get.php?username=…`, vérifiez qu'elle a bien été convertie en Xtream Codes (type affiché dans les réglages des sources).

- **« Identifiant ou mot de passe refusé »** : vérifiez vos identifiants avec **Tester la connexion**.
- **« Compte non actif »** : l'abonnement a expiré ou est suspendu chez votre fournisseur.
- **Aucun programme dans le guide** : la chaîne n'a pas d'identifiant de guide TV, ou le guide de votre source n'en contient pas pour elle.
- **« App Transport Security »** : ce message apparaissait en version 0.1.0 et 0.2.0 avec les sources en http://. Il est corrigé depuis la version 0.2.1.
- **Lecture impossible** : le serveur n'a pas fourni le flux. Vérifiez qu'aucun autre appareil n'utilise votre abonnement (une seule connexion autorisée), puis cliquez sur **Réessayer**. Essayez aussi la mémoire tampon **Stable**.

## Confidentialité

Kastideo fonctionne dans le bac à sable de macOS. Il n'accède qu'au réseau et aux fichiers que vous choisissez. Vos mots de passe restent dans le trousseau. Aucune donnée n'est envoyée ailleurs qu'à vos propres sources.

## Licences

Kastideo utilise **VLCKit** (moteur de VLC, © VideoLAN, licence LGPL 2.1 ou ultérieure, https://www.videolan.org/vlc/libvlc.html) et **Sparkle** (licence MIT, https://sparkle-project.org). VLCKit est intégré sous forme de bibliothèque dynamique non modifiée.
