# Fiche App Store — Français (fr-FR)

> Préparée pour plus tard (objectif actuel : TestFlight). Limites Apple entre parenthèses.

**Nom (30)** : Kastideo
**Sous-titre (30)** : Lecteur IPTV, films et séries
**Texte promotionnel (170)** : Vos chaînes, films et séries au même endroit : guide TV, replay, enregistrement, favoris et synchronisation iCloud. Un lecteur sans contenu fourni.
**Mots-clés (100)** : iptv,m3u,xtream,lecteur,guide tv,epg,jellyfin,emby,plex,replay,streaming,vlc,chromecast,airplay
**Catégorie** : Divertissement (secondaire : Photo et vidéo)
**URL d'assistance** : https://kastideo.com — **URL marketing** : https://kastideo.com — **Confidentialité** : https://github.com/jihemezes/kastideo/blob/main/docs/PRIVACY.md
**Classification d'âge** : répondre « Aucun » aux contenus sensibles ; l'app lit des sources choisies par l'utilisateur (prévoir 17+ si Apple l'exige pour les contenus non filtrés).

## Description (4000)

Kastideo est un lecteur : il centralise vos chaînes, séries, films et vidéos dans une interface simple, rapide et personnalisable. **Kastideo ne fournit, ne vend et n'héberge aucun contenu** : vous ajoutez vos propres sources et vous êtes responsable de leur légalité.

SOURCES COMPATIBLES
• Listes M3U / M3U8 et abonnements Xtream Codes
• Serveurs Jellyfin, Emby et Plex (reprise de lecture synchronisée)
• Dossiers, partages réseau et vidéos de votre galerie
• Vidéos YouTube via l'API officielle

DIRECT ET GUIDE TV
• Guide TV en grille, avec zoom, filtres par catégorie, favoris et thèmes
• Thèmes (sport, info, cinéma…), « ce soir », replay des programmes passés si votre fournisseur le permet
• Alertes de programmes, enregistrement et décalage du direct (timeshift)
• Zapping dans le lecteur, changement de chaîne par glissement

FILMS ET SÉRIES
• Affichage Cinéma avec bandeau « à la une », rangées par catégorie et fiches détaillées (affiche, résumé, distribution, bande-annonce avec votre clé TMDB gratuite)
• Reprise là où vous vous êtes arrêté, épisode suivant automatique

LECTEUR
• Vitesse de lecture, format d'image, volume et luminosité par geste, AirPlay
• Son en arrière-plan
• Informations techniques du flux

PERSONNALISATION
• Catégories : ordre, masquage, renommage, masquage par mot-clé
• Page de départ, thème clair/sombre, couleur d'accent, taille des affiches
• Synchronisation par iCloud Drive entre vos appareils (Mac, iPhone, iPad)
• Aucun compte, aucune publicité, aucun traceur

IMPORTANT : Kastideo ne contient ni chaînes ni films. Utilisez-le uniquement avec des contenus dont vous avez le droit d'accès.

## Notes pour l'équipe de revue

Kastideo est un lecteur multimédia générique (comme un lecteur de playlists). Il ne contient, ne propose et ne recommande aucun contenu ni aucun fournisseur. Au premier lancement, un avertissement légal s'affiche (à accepter) ; l'utilisateur ajoute ensuite sa propre source.
Pas de compte à créer. Pour tester : Réglages > Ajouter une source > « Liste M3U (URL) », et coller :
https://raw.githubusercontent.com/jihemezes/kastideo/main/docs/store/demo.m3u
Cette liste ne contient que des flux de test publics (Apple, vidéos libres de droits Blender).
Aucune connexion ni donnée personnelle n'est exigée ; aucun achat intégré, aucune publicité.
