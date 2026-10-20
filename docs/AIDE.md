# Aide de Kastideo

Kastideo est un lecteur multimédia qui réunit vos chaînes en direct, films et séries IPTV dans une interface simple et rapide. Kastideo ne fournit aucun contenu : vous ajoutez vos propres sources (abonnement Xtream Codes ou playlist M3U).

> Version 0.8.3 — plein écran corrigé, enregistrement du direct fiabilisé ; écran d'accueil, suppression dans les Récents, application disponible en français et en anglais ; Guide TV en grille, reprise de lecture, indicateur de téléchargement ; nouvelle icône (monogramme K) ; interface TV pour le direct (panneau de chaînes, bandeau d'information, zapping par numéro), en plus des interfaces Classique et Cinéma.

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

Chaque source peut avoir une adresse de guide TV au format XMLTV (`.xml` ou `.xml.gz`). Si vous la laissez vide, Kastideo utilise celle du serveur Xtream ou celle annoncée dans la playlist (`url-tvg`). Le guide est conservé de 6 h en arrière à 48 h en avant.

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
- **Cinéma** : un grand bandeau « à la une » (ce que vous regardiez en dernier, sinon vos favoris), puis des **rangées horizontales** : reprise, favoris et une rangée par catégorie. Les films et séries s'affichent en affiches, les chaînes en vignettes avec le programme en cours. Un clic ouvre le lecteur en plein cadre ; **Retour** (ou Échap) revient au catalogue. En haut de la fenêtre, les onglets **Direct / Films / Séries / Guide TV / Favoris / Récents / Enregistrements** remplacent la barre latérale ; la recherche fonctionne comme en Classique. « Tout voir » ouvre une catégorie complète en grille.

Pour changer d'interface :

- le bouton **Interface** de la barre d'outils (il s'applique au type de contenu affiché),
- menu **Présentation** : **⌥⌘1** Classique, **⌥⌘2** Cinéma, **⌥⌘3** TV (direct),
- ou **Réglages > Apparence**.

Par exemple : TV pour le direct et Cinéma pour les films et séries. La section **Enregistrements** s'affiche toujours en interface Classique. Le choix par défaut est Classique partout.

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

## Lecture

Kastideo lit tous les contenus avec le moteur **VLC** : direct au format MPEG-TS (.ts), HLS (.m3u8), MP4, MKV, AVI…

- La lecture démarre dès que vous sélectionnez une chaîne, un film ou un épisode.
- Pendant l'ouverture, le logo et le nom de la chaîne s'affichent. Le badge **« Prête en x s »** indique ensuite le temps de démarrage (désactivable dans les réglages).
- Les contrôles apparaissent au survol de la vidéo : lecture / pause, recul de 10 s et avance de 30 s pour les films et épisodes, barre de progression, volume (jusqu'à 200 %) et mode cinéma.
- Un clic sur la vidéo met en pause ; un **double-clic** active le **mode cinéma** : la fenêtre passe en plein écran et seule la **vidéo** reste affichée (ni colonnes ni barre d'outils ; le bouton vert de la fenêtre et **⌃⌘F** ont le même effet pendant une lecture). **Échap** ou **⌘↩** pour en sortir.
- **Reprise de la lecture** : pour les films et épisodes, Kastideo mémorise votre position. À la réouverture, la lecture reprend là où vous vous étiez arrêté, avec un message proposant de **recommencer au début**. Des barres de progression apparaissent dans les listes, les affiches et les épisodes. Désactivable, ou positions effaçables, dans les réglages.
- Pour les sources Xtream, le direct est lu au format MPEG-TS (.ts), comme le lecteur de référence Xtream ; si le flux échoue, Kastideo essaie automatiquement la variante .m3u8 (et inversement).

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
- À la fin, l'enregistrement est **converti en MP4** sans perte de qualité (lisible par QuickTime, l'iPhone, l'iPad). Désactivable dans les réglages.

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

- Kastideo vérifie une fois par jour si une nouvelle version est disponible sur GitHub.
- Une fenêtre présente les nouveautés, puis propose **Installer la mise à jour**. Kastideo se ferme, s'installe et se relance.
- Vous pouvez vérifier à tout moment avec **Kastideo > Rechercher les mises à jour…**.
- Chaque mise à jour est signée : Kastideo refuse d'installer un fichier qui ne vient pas de son éditeur.

Dans **Réglages > Mises à jour** :

- **Rechercher automatiquement** : active ou désactive la vérification quotidienne.
- **Télécharger et installer automatiquement** : les mises à jour s'installent sans rien demander, à la fermeture de l'application.
- **Recevoir les versions de test (bêta)** : propose aussi les versions bêta, qui apportent les nouveautés plus tôt mais peuvent être moins stables. Désactivez l'option pour revenir aux versions stables à la prochaine mise à jour.

> Les versions 0.1.0 et antérieures ne savent pas se mettre à jour : installez la 0.2.0 une fois à la main, les suivantes arriveront toutes seules.

## Nouveautés

Après chaque mise à jour, la fenêtre **Nouveautés** résume les changements de la version installée. Vous pouvez la rouvrir avec **Aide > Nouveautés de cette version** et y consulter les versions précédentes.

## Réglages généraux

- **Langue** (onglet **Général**) : Kastideo existe en **français** et en **anglais**. La langue se choisit au premier lancement, puis peut être changée dans **Réglages > Général > Langue** (ou « Système » pour suivre la langue du Mac). Le changement s'applique après un redémarrage de l'application, que Kastideo propose de faire pour vous. L'aide et les menus suivent la langue choisie ; les notes de version restent en français.
- **Apparence** (onglet **Apparence**) : thème sombre (par défaut), clair ou comme le système ; **couleur d'accent** (Système, bleu, violet, rose, rouge, orange, vert, turquoise) ; **interface** Classique ou Cinéma pour chaque type de contenu ; **densité des listes** (compacte, standard, aérée) pour l'interface Classique ; **taille des vignettes** (petites, moyennes, grandes) pour l'interface Cinéma.
- **Actualiser au démarrage** : recharge les sources dont la dernière actualisation date de plus de 6 heures.
- **Cache** : Kastideo garde une copie locale des listes et du guide TV pour démarrer instantanément. **Vider et recharger** efface cette copie et relance le chargement.

## Dépannage

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
