import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/downloads.dart';
import '../core/log.dart';
import '../core/models.dart';
import '../core/paths.dart';
import '../core/recording.dart';
import '../l10n.dart';
import 'player_pane.dart';
import 'tv_shell.dart';
import '../theme.dart' show DarkZone;

/// Écran Enregistrements de la télévision : en cours, programmés, terminés (lecture, suppression).
void openTvRecordings(BuildContext context) {
  context.recordings.scanFiles();
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _TvRecordingsPage()));
}

class _TvRecordingsPage extends StatelessWidget {
  const _TvRecordingsPage();

  @override
  Widget build(BuildContext context) {
    final recordings = context.recordings;
    return ListenableBuilder(
      listenable: Listenable.merge([recordings, context.downloads]),
      builder: (context, _) {
        final active = recordings.active;
        final planned = recordings.schedules.where((s) => s.status == ScheduleStatus.scheduled || s.status == ScheduleStatus.recording).toList()
          ..sort((a, b) => a.startS.compareTo(b.startS));
        final files = recordings.files;
        final downloads = context.downloads.tasks;
        return TvMenuPage(
          title: tr('Enregistrements'),
          footer: '${tr('Dossier')} : ${recordings.folder}',
          entries: (c) => [
            if (active != null)
              TvEntry('● ${tr('En cours')} : ${active.channel.displayName}', (c) => recordings.stop(), detail: tr('Arrêter'), icon: Icons.stop_circle_rounded),
            for (final s in planned)
              TvEntry('${s.channelName} · ${s.title}', (c) => _scheduledMenu(c, s), detail: _when(s.start), icon: Icons.schedule_rounded),
            for (final t in downloads)
              TvEntry('↓ ${t.name}', (c) => _downloadMenu(c, t), detail: _downloadState(t), icon: Icons.download_rounded),
            for (final f in files) TvEntry(f.name.replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), ''), (c) => _fileMenu(c, f), detail: '${sizeText(f.size)} · ${_when(f.modified)}', icon: Icons.play_circle_outline_rounded),
            if (active == null && planned.isEmpty && files.isEmpty && downloads.isEmpty)
              TvEntry(tr('Aucun enregistrement. Pendant un direct, la touche Menu propose « Enregistrer ».'), null, icon: Icons.info_outline_rounded),
          ],
        );
      },
    );
  }

  static String _downloadState(DownloadTask t) => switch (t.status) {
        DownloadStatus.running => '${((t.fraction ?? 0) * 100).round()} %',
        DownloadStatus.queued => tr('En attente'),
        DownloadStatus.paused => tr('En pause'),
        DownloadStatus.failed => tr('Échec'),
        DownloadStatus.done => tr('Terminé'),
      };

  void _downloadMenu(BuildContext context, DownloadTask t) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: t.name,
        footer: t.path,
        entries: (c) => [
          if (t.status == DownloadStatus.done)
            TvEntry(tr('Lire'), (c) {
              Navigator.of(c).pop();
              playTvFile(c, t.path);
            }, icon: Icons.play_arrow_rounded),
          if (t.status == DownloadStatus.running || t.status == DownloadStatus.queued)
            TvEntry(tr('Mettre en pause'), (c) {
              c.downloads.pause(t);
              Navigator.of(c).pop();
            }, icon: Icons.pause_rounded),
          if (t.status == DownloadStatus.paused || t.status == DownloadStatus.failed)
            TvEntry(tr('Reprendre'), (c) {
              c.downloads.resume(t);
              Navigator.of(c).pop();
            }, icon: Icons.play_arrow_rounded),
          TvEntry(t.status == DownloadStatus.done ? tr('Supprimer le fichier') : tr('Annuler le téléchargement'), (c) {
            c.downloads.remove(t, deleteFile: true);
            Navigator.of(c).pop();
          }, icon: Icons.delete_outline_rounded),
        ],
      ),
    ));
  }

  static String _when(DateTime d) => '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';

  void _scheduledMenu(BuildContext context, ScheduledRecording s) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: s.title,
        footer: s.channelName,
        entries: (_) => [
          TvEntry(tr('Annuler cet enregistrement'), (c) {
            c.recordings.cancel(s);
            Navigator.of(c).pop();
          }, icon: Icons.cancel_outlined),
        ],
      ),
    ));
  }

  void _fileMenu(BuildContext context, RecordedFile f) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TvMenuPage(
        title: f.name,
        footer: '${sizeText(f.size)} · ${_when(f.modified)}',
        entries: (_) => [
          TvEntry(tr('Lire'), (c) {
            Navigator.of(c).pop();
            playTvFile(c, f.path);
          }, icon: Icons.play_arrow_rounded),
          TvEntry(tr('Supprimer le fichier'), (c) async {
            await c.recordings.remove([f], deleteFiles: true);
            if (c.mounted) Navigator.of(c).pop();
          }, icon: Icons.delete_outline_rounded),
        ],
      ),
    ));
  }
}

/// Lit un fichier enregistré en plein écran ; Retour arrête la lecture.
void playTvFile(BuildContext context, String path) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _TvFilePlayer(path: path)));
}

class _TvFilePlayer extends StatefulWidget {
  const _TvFilePlayer({required this.path});
  final String path;

  @override
  State<_TvFilePlayer> createState() => _TvFilePlayerState();
}

class _TvFilePlayerState extends State<_TvFilePlayer> {
  late final _playback = context.playback;

  @override
  void initState() {
    super.initState();
    final name = widget.path.split('/').last;
    PlaybackLog.shared.note('Lecture d\'un enregistrement : ${widget.path}');
    _playback.play(MediaItem(
      id: 'file:${widget.path}',
      sourceId: 'local',
      kind: MediaKind.movie,
      name: name.replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), ''),
      group: tr('Enregistrements'),
      stream: widget.path,
    ));
  }

  @override
  void dispose() {
    unawaited(_playback.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const DarkZone(child: PlayerPane());
}
