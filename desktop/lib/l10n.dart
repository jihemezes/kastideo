import 'dart:io';

/// Traduction minimale : le texte français sert de clé (comme les Localizable.strings de la version Mac).
class L10n {
  static final bool english = !Platform.localeName.toLowerCase().startsWith('fr');

  static const Map<String, String> _en = {
    'Accueil': 'Home',
    'Direct': 'Live',
    'Films': 'Movies',
    'Séries': 'Series',
    'Favoris': 'Favorites',
    'Récents': 'Recents',
    'Guide TV': 'TV Guide',
    'Enregistrements': 'Recordings',
    'Toutes les chaînes': 'All channels',
    'Catégories': 'Categories',
    'Sources': 'Sources',
    'Rechercher': 'Search',
    'Rechercher une chaîne, un film ou une série': 'Search for a channel, movie or series',
    'Vos chaînes, vos films et vos séries au même endroit': 'Your channels, movies and series in one place',
    'Chargement…': 'Loading…',
    'En cours de lecture': 'Now playing',
    'Retourner à la lecture': 'Back to playback',
    'Arrêter': 'Stop',
    'Choisissez une chaîne': 'Choose a channel',
    'Ajouter une source': 'Add a source',
    'Aucune source': 'No source',
    'Ajoutez votre abonnement IPTV (Xtream Codes ou playlist M3U) pour commencer.':
        'Add your IPTV subscription (Xtream Codes or M3U playlist) to get started.',
    'Réessayer': 'Retry',
    'Journal de lecture': 'Playback log',
    'Copier': 'Copy',
    'Effacer': 'Clear',
    'Fermer': 'Close',
    'Annuler': 'Cancel',
    'Ajouter': 'Add',
    'Supprimer': 'Delete',
    'Actualiser': 'Refresh',
    'Nom': 'Name',
    'Serveur': 'Server',
    'Identifiant': 'Username',
    'Mot de passe': 'Password',
    'Adresse de la playlist ou chemin du fichier': 'Playlist address or file path',
    'Aperçu Windows / Linux': 'Windows / Linux preview',
    'Arrive à l\'étape 2 de la version Windows / Linux.': 'Coming in step 2 of the Windows / Linux version.',
    'Aucune chaîne': 'No channel',
    'Aucun résultat': 'No results',
    'EN DIRECT': 'LIVE',
    'Mode cinéma': 'Theater mode',
    'Plein écran': 'Full screen',
    'Couper / rétablir le son': 'Mute / unmute',
    'Lecture / pause (Espace)': 'Play / pause (Space)',
    'Excellent': 'Excellent',
    'Correct': 'Fair',
    'Instable': 'Unstable',
    'Aide': 'Help',
    'Ajouter aux favoris': 'Add to favorites',
    'Retirer des favoris': 'Remove from favorites',
    'chaînes': 'channels',
    'chaîne': 'channel',
    'film': 'movie',
    'série': 'series',
    'films': 'movies',
    'séries': 'series',
    'Prête en': 'Ready in',
    'Copier le nom': 'Copy name',
    'Quitter le plein écran': 'Exit full screen',
  };

  static String tr(String french) => english ? (_en[french] ?? french) : french;
}

String tr(String french) => L10n.tr(french);
