import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import '../theme.dart';
import '../version.dart';

/// Avertissement légal affiché au premier lancement et après chaque mise à jour (texte français et anglais).
/// Le texte est le même dans l'aide (page « Avertissement ») et dans le README.
class _LegalText {
  const _LegalText({
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.points,
    required this.closing,
    required this.accept,
    required this.quit,
    required this.close,
  });
  final String title, subtitle, intro, closing, accept, quit, close;
  final List<(String, String)> points;
}

const _french = _LegalText(
  title: 'Avertissement',
  subtitle: 'À lire avant d\'utiliser Kastideo',
  intro: 'Merci d\'utiliser Kastideo. Kastideo est un lecteur multimédia : il lit les listes de lecture (M3U), les comptes IPTV (Xtream Codes), vos serveurs personnels (Jellyfin, Emby, Plex), les vidéos de vos disques et YouTube.',
  points: [
    (
      'Aucun contenu fourni.',
      'Kastideo ne fournit, n\'héberge ni ne vend aucune chaîne, aucun film, aucune liste de lecture ni aucun abonnement.',
    ),
    (
      'Aucune affiliation.',
      'Kastideo n\'est affilié à aucun fournisseur de contenus ou d\'abonnements IPTV, ni à YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple ou Microsoft. Les marques citées appartiennent à leurs propriétaires. Ce produit utilise l\'API TMDB mais n\'est ni approuvé ni certifié par TMDB.',
    ),
    (
      'Vos propres contenus.',
      'Vous devez fournir vos propres sources et contenus. Vous êtes seul responsable de vérifier qu\'ils sont légaux et que vous avez tous les droits nécessaires pour les regarder, les enregistrer, les télécharger et les diffuser.',
    ),
    (
      'Droit d\'auteur.',
      'Kastideo n\'encourage pas la diffusion de contenus protégés par le droit d\'auteur sans l\'autorisation de leurs titulaires. Les enregistrements, les téléchargements et la diffusion vers un téléviseur (Cast) sont réservés à un usage privé, dans les limites de la loi de votre pays.',
    ),
    (
      'Responsabilité.',
      'L\'auteur de Kastideo n\'est pas responsable de l\'usage que vous faites du logiciel, ni du contenu, de la disponibilité ou de la légalité des services tiers auxquels vous le connectez. Kastideo est fourni gratuitement, « tel quel », sans garantie.',
    ),
    (
      'Vos données.',
      'Vos identifiants sont conservés sur votre appareil et ne sont transmis qu\'aux services que vous configurez.',
    ),
  ],
  closing: 'En cliquant sur « J\'ai compris et j\'accepte », vous reconnaissez avoir lu ces conditions et vous les acceptez. Dans le cas contraire, quittez l\'application.',
  accept: 'J\'ai compris et j\'accepte',
  quit: 'Quitter',
  close: 'Fermer',
);

const _english = _LegalText(
  title: 'Disclaimer',
  subtitle: 'Please read before using Kastideo',
  intro: 'Thank you for using Kastideo. Kastideo is a media player: it plays playlists (M3U), IPTV accounts (Xtream Codes), your own servers (Jellyfin, Emby, Plex), the videos on your drives and YouTube.',
  points: [
    (
      'No content provided.',
      'Kastideo does not provide, host or sell any channel, movie, playlist or subscription.',
    ),
    (
      'No affiliation.',
      'Kastideo is not affiliated with any content or IPTV subscription provider, nor with YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple or Microsoft. Trademarks mentioned belong to their respective owners. This product uses the TMDB API but is not endorsed or certified by TMDB.',
    ),
    (
      'Your own content.',
      'You must supply your own sources and content. You are solely responsible for checking that they are legal and that you have all the rights needed to watch, record, download and stream them.',
    ),
    (
      'Copyright.',
      'Kastideo does not encourage the streaming of copyright-protected material without the permission of the copyright holder. Recordings, downloads and casting to a TV are for private use only, within the limits of the law in your country.',
    ),
    (
      'Liability.',
      'The author of Kastideo is not responsible for how you use the software, nor for the content, availability or legality of the third-party services you connect it to. Kastideo is provided free of charge, “as is”, without warranty.',
    ),
    (
      'Your data.',
      'Your credentials are kept on your device and are only sent to the services you configure.',
    ),
  ],
  closing: 'By clicking “I understand and accept”, you confirm that you have read and accept these terms. Otherwise, please quit the application.',
  accept: 'I understand and accept',
  quit: 'Quit',
  close: 'Close',
);

class LegalNotice {
  static const acceptedKey = 'legal.acceptedVersion';

  /// Affiche l'avertissement tant qu'il n'a pas été accepté pour cette version (quitte l'application en cas de refus).
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(acceptedKey) == kVersion || !context.mounted) return;
    final accepted = await show(context, requireAcceptance: true);
    if (accepted == true) {
      await prefs.setString(acceptedKey, kVersion);
    } else {
      exit(0);
    }
  }

  /// Fenêtre de l'avertissement. Avec [requireAcceptance] : « J'ai compris et j'accepte » ou « Quitter » ; sinon relecture simple.
  static Future<bool?> show(
    BuildContext context, {
    bool requireAcceptance = false,
  }) {
    final text = L10n.english ? _english : _french;
    return showKDialog<bool>(
      context: context,
      barrierDismissible: !requireAcceptance,
      builder: (c) => PopScope(
        canPop: !requireAcceptance,
        child: AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text.title, style: kText(20, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                text.subtitle,
                style: kText(13, color: KPalette.secondaryText),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text.intro, style: kText(14)),
                  for (final point in text.points) ...[
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: point.$1,
                            style: kText(14, weight: FontWeight.w700),
                          ),
                          TextSpan(text: ' ${point.$2}', style: kText(14)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(text.closing, style: kText(14, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          actions: requireAcceptance
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(text.quit),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(text.accept),
                  ),
                ]
              : [
                  FilledButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text(text.close),
                  ),
                ],
        ),
      ),
    );
  }
}
