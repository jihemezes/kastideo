import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../app_state.dart';
import '../core/playback.dart' show VideoFormat;
import '../l10n.dart';
import 'tv_shell.dart';

/// Options du lecteur à la télécommande (touche Menu pendant la lecture) : pistes audio, sous-titres, vitesse, format
/// de l'image, épisode suivant, liste des épisodes, enchaînement automatique, journal.
/// [extra] : lignes propres à l'écran appelant (favori, chaîne précédente…), placées en tête.
void openTvPlayerOptions(BuildContext context, {List<TvEntry> extra = const []}) {
  final playback = context.playback;
  final library = context.library;
  final info = context.info;
  final settings = context.settings;
  final current = playback.current;
  final isEpisode = current != null && library.seriesOf(current) != null;

  String trackName(String? title, String? language, int index) {
    final parts = [if (title != null && title.isNotEmpty) title, if (language != null && language.isNotEmpty) language];
    return parts.isEmpty ? '${tr('Piste')} ${index + 1}' : parts.join(' · ');
  }

  /// Page de choix : OK applique puis revient au lecteur.
  void choice(BuildContext c, String title, List<(String, bool, VoidCallback)> rows) {
    Navigator.of(c).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: title,
        entries: (_) => [
          for (final r in rows)
            TvEntry(r.$1, (cc) {
              r.$3();
              Navigator.of(cc)
                ..pop()
                ..pop();
            }, icon: r.$2 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
        ],
      ),
    ));
  }

  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => TvMenuPage(
      title: tr('Options du lecteur'),
      footer: current?.displayName,
      entries: (c) {
        final audio = playback.audioTracks;
        final subs = playback.subtitleTracks;
        final rate = playback.rate;
        final format = switch (playback.videoFormat) {
          VideoFormat.fit => tr('Ajuster'),
          VideoFormat.fill => tr('Remplir l\'écran'),
          VideoFormat.wide => '16:9',
          VideoFormat.standard => '4:3',
        };
        return [
          ...extra,
          if (audio.length > 1)
            TvEntry(tr('Audio'), (c) {
              final selected = playback.selectedAudio.id;
              choice(c, tr('Audio'), [
                for (var i = 0; i < audio.length; i++)
                  (trackName(audio[i].title, audio[i].language, i), audio[i].id == selected, () => playback.selectAudioTrack(audio[i])),
              ]);
            }, detail: trackName(playback.selectedAudio.title, playback.selectedAudio.language, 0)),
          if (subs.isNotEmpty)
            if (playback.directRender)
              TvEntry(tr('Sous-titres'), null, detail: tr('Indisponible en rendu direct'), icon: Icons.block_rounded)
            else
              TvEntry(tr('Sous-titres'), (c) {
                final selected = playback.selectedSubtitle.id;
                choice(c, tr('Sous-titres'), [
                  (tr('Aucun'), selected == 'no', () => playback.selectSubtitleTrack(SubtitleTrack.no())),
                  for (var i = 0; i < subs.length; i++)
                    (trackName(subs[i].title, subs[i].language, i), subs[i].id == selected, () => playback.selectSubtitleTrack(subs[i])),
                ]);
              }, detail: playback.selectedSubtitle.id == 'no' ? tr('Aucun') : null),
          if (!playback.isLive && playback.isSeekable)
            TvEntry(tr('Vitesse de lecture'), (c) {
              choice(c, tr('Vitesse de lecture'), [
                for (final r in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0])
                  ('×${r.toString().replaceAll('.0', '').replaceAll('.', ',')}', rate == r, () => playback.setRate(r)),
              ]);
            }, detail: '×${rate.toString().replaceAll('.0', '').replaceAll('.', ',')}'),
          TvEntry(tr('Format de l\'image'), (c) {
            choice(c, tr('Format de l\'image'), [
              (tr('Ajuster'), playback.videoFormat == VideoFormat.fit, () => playback.setVideoFormat(VideoFormat.fit)),
              (tr('Remplir l\'écran'), playback.videoFormat == VideoFormat.fill, () => playback.setVideoFormat(VideoFormat.fill)),
              ('16:9', playback.videoFormat == VideoFormat.wide, () => playback.setVideoFormat(VideoFormat.wide)),
              ('4:3', playback.videoFormat == VideoFormat.standard, () => playback.setVideoFormat(VideoFormat.standard)),
            ]);
          }, detail: format),
          if (isEpisode) ...[
            TvEntry(tr('Épisode suivant'), (c) async {
              final next = await nextEpisodeOf(library, info, current);
              if (!c.mounted) return;
              if (next == null) {
                _toast(c, tr('Dernier épisode de la série.'));
                return;
              }
              playback.play(next);
              library.noteRecent(next);
              Navigator.of(c).pop();
            }, icon: Icons.skip_next_rounded),
            TvEntry(tr('Épisodes'), (c) async {
              final seasons = await seasonsOfEpisode(library, info, current);
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
                          Navigator.of(cc)
                            ..pop()
                            ..pop();
                        }, icon: e.id == current.id ? Icons.play_circle_rounded : Icons.chevron_right_rounded),
                  ],
                ),
              ));
            }),
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
