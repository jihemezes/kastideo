# Journal des versions

Toutes les évolutions notables de Kastideo sont consignées ici.
Les notes de chaque version sont reprises automatiquement dans la GitHub Release correspondante.

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
