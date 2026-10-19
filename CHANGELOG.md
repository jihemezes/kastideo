# Journal des versions

Toutes les évolutions notables de Kastideo sont consignées ici.
Les notes de chaque version sont reprises automatiquement dans la GitHub Release correspondante.

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
