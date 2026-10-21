# Journal des versions

Toutes les évolutions notables de Kastideo sont consignées ici.
Les notes de chaque version sont reprises automatiquement dans la GitHub Release correspondante.

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
