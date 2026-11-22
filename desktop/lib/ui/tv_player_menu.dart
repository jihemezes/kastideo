import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../app_state.dart';
import '../core/log.dart';
import '../core/models.dart';
import '../core/playback.dart' show VideoFormat;
import '../l10n.dart';
import 'player_pane.dart' show toggleRecording;
import 'tv_multiview.dart';
import 'tv_settings.dart' show openTvSubtitleStyle;
import 'tv_shell.dart';

/// Options du lecteur à la télécommande (touche Menu pendant la lecture) : pistes audio, sous-titres, vitesse, format
/// de l'image, épisode suivant, liste des épisodes, enchaînement automatique, journal.
/// [extra] : lignes propres à l'écran appelant (favori, chaîne précédente…), placées en tête.
/// Page de choix : OK applique, puis ferme [pops] pages (1 depuis la barre du lecteur, 2 depuis le menu d'options).
void tvChoice(BuildContext c, String title, List<(String, bool, VoidCallback)> rows, {int pops = 2}) {
  Navigator.of(c).push(MaterialPageRoute<void>(
    builder: (_) => TvMenuPage(
      title: title,
      entries: (_) => [
        for (final r in rows)
          TvEntry(r.$1, (cc) {
            r.$3();
            final nav = Navigator.of(cc);
            for (var i = 0; i < pops; i++) {
              nav.pop();
            }
          }, icon: r.$2 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
      ],
    ),
  ));
}

String _trackName(String? title, String? language, int index) {
  final parts = [if (title != null && title.isNotEmpty) title, if (language != null && language.isNotEmpty) language];
  return parts.isEmpty ? '${tr('Piste')} ${index + 1}' : parts.join(' · ');
}

void tvChooseAudio(BuildContext c, {int pops = 2}) {
  final playback = c.playback;
  final audio = playback.audioTracks;
  final selected = playback.selectedAudio.id;
  tvChoice(c, tr('Audio'), [
    for (var i = 0; i < audio.length; i++) (_trackName(audio[i].title, audio[i].language, i), audio[i].id == selected, () => playback.selectAudioTrack(audio[i])),
  ], pops: pops);
}

/// Sous-titres : en rendu vidéo direct ils sont impossibles ; la page propose de passer en rendu classique (redémarrage de Kastideo).
void tvChooseSubtitles(BuildContext c, {int pops = 2}) {
  final playback = c.playback;
  if (playback.directRender) {
    Navigator.of(c).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: tr('Sous-titres'),
        footer: tr('Le rendu vidéo direct, très fluide en 4K, ne peut pas afficher de sous-titres.'),
        entries: (_) => [
          TvEntry(tr('Passer en rendu classique et fermer Kastideo'), (cc) async {
            cc.settings.setTvDirectRender(false);
            PlaybackLog.shared.note('Rendu classique demandé pour les sous-titres : fermeture de Kastideo.');
            await Future<void>.delayed(const Duration(milliseconds: 900));
            exit(0);
          }, icon: Icons.subtitles_rounded),
          TvEntry(tr('Annuler'), (cc) => Navigator.of(cc).pop(), icon: Icons.close_rounded),
        ],
      ),
    ));
    return;
  }
  final selected = playback.selectedSubtitle.id;
  final subs = playback.subtitleTracks;
  tvChoice(c, tr('Sous-titres'), [
    (tr('Aucun'), selected == 'no', () => playback.selectSubtitleTrack(SubtitleTrack.no())),
    for (var i = 0; i < subs.length; i++) (_trackName(subs[i].title, subs[i].language, i), subs[i].id == selected, () => playback.selectSubtitleTrack(subs[i])),
  ], pops: pops);
}

String _rateText(double r) => '×${r.toString().replaceAll('.0', '').replaceAll('.', ',')}';

void tvChooseRate(BuildContext c, {int pops = 2}) {
  final playback = c.playback;
  tvChoice(c, tr('Vitesse de lecture'), [for (final r in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]) (_rateText(r), playback.rate == r, () => playback.setRate(r))], pops: pops);
}

String tvFormatName(VideoFormat f) => switch (f) {
      VideoFormat.fit => tr('Ajuster'),
      VideoFormat.fill => tr('Remplir l\'écran'),
      VideoFormat.wide => '16:9',
      VideoFormat.standard => '4:3',
    };

void tvChooseFormat(BuildContext c, {int pops = 2}) {
  final playback = c.playback;
  tvChoice(c, tr('Format de l\'image'), [for (final f in VideoFormat.values) (tvFormatName(f), playback.videoFormat == f, () => playback.setVideoFormat(f))], pops: pops);
}

Future<void> tvNextEpisode(BuildContext c) async {
  final playback = c.playback;
  final library = c.library;
  final current = playback.current;
  if (current == null) return;
  final next = await nextEpisodeOf(library, c.info, current);
  if (!c.mounted) return;
  if (next == null) {
    _toast(c, tr('Dernier épisode de la série.'));
    return;
  }
  playback.play(next);
  library.noteRecent(next);
}

Future<void> tvEpisodeList(BuildContext c, {int pops = 2}) async {
  final playback = c.playback;
  final library = c.library;
  final current = playback.current;
  if (current == null) return;
  final seasons = await seasonsOfEpisode(library, c.info, current);
  if (!c.mounted || seasons.isEmpty) return;
  Navigator.of(c).push(MaterialPageRoute<void>(
    builder: (_) => TvMenuPage(
      title: tr('Épisodes'),
      entries: (_) => [
        for (final s in seasons)
          for (final e in s.episodes)
            TvEntry(e.displayName, (cc) {
              playback.play(e);
              library.noteRecent(e);
              final nav = Navigator.of(cc);
              for (var i = 0; i < pops; i++) {
                nav.pop();
              }
            }, icon: e.id == current.id ? Icons.play_circle_rounded : Icons.chevron_right_rounded),
      ],
    ),
  ));
}

/// Options du lecteur à la télécommande (touche Menu pendant la lecture) : pistes audio, sous-titres, vitesse, format
/// de l'image, épisode suivant, liste des épisodes, enchaînement automatique, enregistrement, MultiVue, journal.
/// [extra] : lignes propres à l'écran appelant (favori, chaîne précédente…), placées en tête.
void openTvPlayerOptions(BuildContext context, {List<TvEntry> extra = const []}) {
  final playback = context.playback;
  final library = context.library;
  final settings = context.settings;
  final current = playback.current;
  final isEpisode = current != null && library.seriesOf(current) != null;
  final isLive = current != null && current.kind == MediaKind.live;

  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => TvMenuPage(
      title: tr('Options du lecteur'),
      footer: current?.displayName,
      entries: (c) {
        final audio = playback.audioTracks;
        final subs = playback.subtitleTracks;
        final rate = playback.rate;
        final recordings = c.recordings;
        final recording = current != null && recordings.isRecording(current);
        return [
          ...extra,
          if (isLive)
            TvEntry(recording ? tr('Arrêter l\'enregistrement') : tr('Enregistrer cette chaîne'), (c) {
              toggleRecording(c);
              Navigator.of(c).pop();
            }, icon: recording ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded),
          if (isLive && c.settings.multiviewAvailableFor(library.selectableSources))
            TvEntry(tr('MultiVue'), (c) {
              Navigator.of(c).pop();
              openTvMultiView(c, add: current);
            }, icon: Icons.grid_view_rounded),
          if (audio.length > 1) TvEntry(tr('Audio'), (c) => tvChooseAudio(c), detail: _trackName(playback.selectedAudio.title, playback.selectedAudio.language, 0)),
          if (subs.isNotEmpty)
            TvEntry(tr('Sous-titres'), (c) => tvChooseSubtitles(c), detail: playback.directRender ? tr('Rendu classique requis') : (playback.selectedSubtitle.id == 'no' ? tr('Aucun') : null)),
          if (subs.isNotEmpty && !playback.directRender) TvEntry(tr('Réglage des sous-titres'), (c) => openTvSubtitleStyle(c)),
          if (!playback.isLive && playback.isSeekable) TvEntry(tr('Vitesse de lecture'), (c) => tvChooseRate(c), detail: _rateText(rate)),
          TvEntry(tr('Format de l\'image'), (c) => tvChooseFormat(c), detail: tvFormatName(playback.videoFormat)),
          if (isEpisode) ...[
            TvEntry(tr('Épisode suivant'), (c) async {
              await tvNextEpisode(c);
              if (c.mounted) Navigator.of(c).pop();
            }, icon: Icons.skip_next_rounded),
            TvEntry(tr('Épisodes'), (c) => tvEpisodeList(c)),
            TvEntry(tr('Enchaîner automatiquement l\'épisode suivant d\'une série'), (c) => settings.setBool('player.autoNext', !settings.autoNextEpisode),
                icon: settings.autoNextEpisode ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
          ],
          TvEntry(tr('Journal de lecture'), (c) => openTvLog(c), icon: Icons.receipt_long_rounded),
        ];
      },
    ),
  ));
}

void _toast(BuildContext context, String text) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      right: 0,
      bottom: 90,
      child: Center(
        child: Material(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(14),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14), child: Text(text, style: const TextStyle(fontSize: 22, color: Colors.white))),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2), entry.remove);
}
