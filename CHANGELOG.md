# Journal des versions

Toutes les évolutions notables de Kastideo sont consignées ici.
Les notes de chaque version sont reprises automatiquement dans la GitHub Release correspondante.

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
