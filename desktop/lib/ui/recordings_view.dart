import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/downloads.dart';
import '../core/models.dart';
import '../core/paths.dart';
import '../core/recording.dart';
import '../l10n.dart';
import '../theme.dart';
import 'catalog_screen.dart';
import 'player_pane.dart';
import 'themes_view.dart';
import 'schedule_dialog.dart';
import 'widgets.dart';

/// Ouvre un dossier dans l'explorateur de fichiers.
Future<void> openFolder(String path) async {
  try {
    await Directory(path).create(recursive: true);
  } catch (_) {}
  await launchUrl(Uri.file(path));
}

/// Écran « Enregistrements » : en cours, téléchargements, programmés, fichiers (lecture à droite).
class RecordingsScreen extends StatelessWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListenableBuilder(
          listenable: context.navigation,
          builder: (context, _) => Row(children: [
            if (!context.navigation.theater) ...[
              const SizedBox(width: 236, child: Sidebar(kind: MediaKind.live, recordings: true)),
              VerticalDivider(width: 1, color: KPalette.separator),
              const SizedBox(width: 470, child: RecordingsList()),
              VerticalDivider(width: 1, color: KPalette.separator),
            ],
            Expanded(
              child: PlayerPane(
                placeholder: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.video_file_outlined, size: 64, color: KPalette.ink.withValues(alpha: 0.35)),
                    const SizedBox(height: 12),
                    Text(tr('Choisissez un fichier à regarder'), style: kText(15, color: KPalette.secondaryText)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
}

class RecordingsList extends StatefulWidget {
  const RecordingsList({super.key});

  @override
  State<RecordingsList> createState() => _RecordingsListState();
}

class _RecordingsListState extends State<RecordingsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.recordings.scanFiles());
  }

  String _date(DateTime d) => '${two(d.day)}/${two(d.month)} ${hm(d)}';

  Widget _header(String text, {List<Widget> actions = const []}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 10, 6),
        child: Row(children: [
          Expanded(child: Text(text, style: kText(12, weight: FontWeight.w700, color: KPalette.ink54))),
          ...actions,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final recordings = context.recordings;
    final downloads = context.downloads;
    return Container(
      color: KPalette.list,
      child: ListenableBuilder(
        listenable: Listenable.merge([recordings, downloads, context.playback]),
        builder: (context, _) {
          final active = recordings.active;
          final scheduled = recordings.schedules;
          final playingPath = context.playback.current?.stream;
          return ListView(padding: const EdgeInsets.only(bottom: 20), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 0),
              child: Row(children: [
                Expanded(child: Text(tr('Enregistrements'), style: kRounded(22, FontWeight.w800))),
                FilledButton.icon(
                  onPressed: () => showScheduleDialog(context),
                  icon: const Icon(Icons.add_alarm_rounded, size: 16),
                  label: Text(tr('Programmer…')),
                ),
                IconButton(
                  tooltip: tr('Ouvrir le dossier'),
                  onPressed: () => openFolder(recordings.folder),
                  icon: const Icon(Icons.folder_open_rounded),
                ),
                IconButton(tooltip: tr('Actualiser'), onPressed: recordings.scanFiles, icon: const Icon(Icons.refresh_rounded)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(recordings.folder, style: kText(11, color: KPalette.ink38), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (active != null) ...[
              _header(tr('EN COURS')),
              _ActiveCard(active: active),
            ],
            if (downloads.tasks.isNotEmpty) ...[
              _header(tr('TÉLÉCHARGEMENTS'), actions: [
                if (downloads.tasks.any((t) => t.status == DownloadStatus.done))
                  TextButton(onPressed: downloads.clearFinished, child: Text(tr('Effacer les terminés'))),
              ]),
              if (downloads.waitingReason != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Text(
                      downloads.waitingReason == 'night'
                          ? '${tr('Prévu cette nuit, à partir de')} ${context.settings.nightHour} h'
                          : tr('En pause pendant la lecture (Réglages > Enregistrements)'),
                      style: kText(12, color: KPalette.orange)),
                ),
              for (final t in downloads.tasks) _DownloadRow(task: t),
            ],
            _header(tr('PROGRAMMÉS'), actions: [
              if (scheduled.any((s) => s.status != ScheduleStatus.scheduled && s.status != ScheduleStatus.recording))
                TextButton(onPressed: recordings.clearFinishedSchedules, child: Text(tr('Effacer l\'historique'))),
            ]),
            if (scheduled.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(tr('Programmez un enregistrement avec « Programmer… », un clic droit sur une chaîne du direct, ou depuis le guide TV et les thèmes.'),
                    style: kText(12, color: KPalette.ink38)),
              ),
            for (final s in scheduled) _ScheduleRow(schedule: s, date: _date(s.start)),
            _header('${tr('FICHIERS')} (${recordings.files.length})'),
            if (recordings.files.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(tr('Aucun fichier pour l\'instant.'), style: kText(12, color: KPalette.ink38)),
              ),
            for (final f in recordings.files)
              _FileRow(file: f, playing: playingPath == f.path, date: _date(f.modified)),
          ]);
        },
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.active});
  final ActiveRecording active;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(active.startedAt);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        LogoView(url: active.channel.logo, name: active.channel.name, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.fiber_manual_record, size: 12, color: Colors.red),
              const SizedBox(width: 6),
              Flexible(
                child: Text(active.title.isEmpty ? active.channel.displayName : active.title,
                    style: kText(14, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            Text(
              '${active.channel.displayName} · ${durationText(elapsed)} · ${sizeText(active.bytes)}'
              '${active.stopS != null ? ' · ${tr('jusqu\'à')} ${hm(DateTime.fromMillisecondsSinceEpoch(active.stopS! * 1000))}' : ''}',
              style: kText(12, color: KPalette.secondaryText),
            ),
          ]),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: context.recordings.stop,
          icon: const Icon(Icons.stop_rounded),
          label: Text(tr('Arrêter')),
        ),
      ]),
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.task});
  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final downloads = context.downloads;
    final t = task;
    final String status = switch (t.status) {
      DownloadStatus.running => [
          if (t.total != null) '${sizeText(t.received)} / ${sizeText(t.total!)}' else sizeText(t.received),
          if (t.speed > 0) '${sizeText(t.speed.round())}/s',
          if (t.remaining != null) '${tr('reste')} ${durationText(t.remaining!)}',
        ].join(' · '),
      DownloadStatus.queued => t.nightOnly ? tr('Cette nuit') : tr('En attente'),
      DownloadStatus.paused => tr('En pause'),
      DownloadStatus.done => '${tr('Terminé')}${t.total != null ? ' · ${sizeText(t.total!)}' : ''}',
      DownloadStatus.failed => '${tr('Échec')} : ${t.error ?? ''}',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Icon(
          t.status == DownloadStatus.done ? Icons.check_circle_rounded : Icons.download_rounded,
          size: 20,
          color: t.status == DownloadStatus.done ? Colors.greenAccent : (t.status == DownloadStatus.failed ? KPalette.orange : KPalette.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.group.isNotEmpty && t.group != t.name ? '${t.group} — ${t.name}' : t.name,
                style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (t.status == DownloadStatus.running || (t.fraction != null && t.status != DownloadStatus.done))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: LinearProgressIndicator(value: t.fraction, minHeight: 3, color: KPalette.accent, backgroundColor: KPalette.ink12),
              ),
            Text(status, style: kText(11, color: t.status == DownloadStatus.failed ? KPalette.orange : KPalette.ink54), maxLines: 2),
          ]),
        ),
        if (t.status == DownloadStatus.running || t.status == DownloadStatus.queued)
          IconButton(tooltip: tr('Mettre en pause'), onPressed: () => downloads.pause(t), icon: const Icon(Icons.pause_rounded, size: 18)),
        if (t.status == DownloadStatus.paused || t.status == DownloadStatus.failed || (t.status == DownloadStatus.queued && t.nightOnly))
          IconButton(tooltip: tr('Télécharger maintenant'), onPressed: () => downloads.resume(t), icon: const Icon(Icons.play_arrow_rounded, size: 18)),
        IconButton(
          tooltip: t.status == DownloadStatus.done ? tr('Retirer de la liste') : tr('Annuler'),
          onPressed: () => downloads.remove(t),
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ]),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule, required this.date});
  final ScheduledRecording schedule;
  final String date;

  @override
  Widget build(BuildContext context) {
    final s = schedule;
    final (icon, color, label) = switch (s.status) {
      ScheduleStatus.scheduled => (Icons.schedule_rounded, KPalette.accent, tr('Programmé')),
      ScheduleStatus.recording => (Icons.fiber_manual_record, Colors.red, tr('En cours')),
      ScheduleStatus.done => (Icons.check_circle_rounded, Colors.greenAccent, tr('Terminé')),
      ScheduleStatus.failed => (Icons.error_outline_rounded, KPalette.orange, tr('Échec')),
      ScheduleStatus.missed => (Icons.event_busy_rounded, KPalette.ink38, tr('Manqué')),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$date – ${hm(s.stop)} · ${s.channelName} · $label${s.repeat != ScheduleRepeat.none ? ' · ${repeatLabel(s.repeat)}' : ''}${s.error != null ? ' · ${s.error}' : ''}',
                style: kText(11, color: KPalette.ink54), maxLines: 2),
          ]),
        ),
        if (s.path != null && File(s.path!).existsSync())
          IconButton(tooltip: tr('Regarder'), onPressed: () => playLocalFile(context, s.path!), icon: const Icon(Icons.play_arrow_rounded, size: 18)),
        if (s.repeat != ScheduleRepeat.none && s.status == ScheduleStatus.scheduled)
          IconButton(
            tooltip: tr('Arrêter la répétition'),
            onPressed: () => context.recordings.stopRepeating(s),
            icon: const Icon(Icons.repeat_one_rounded, size: 18),
          ),
        IconButton(
          tooltip: s.status == ScheduleStatus.scheduled || s.status == ScheduleStatus.recording ? tr('Annuler') : tr('Retirer de la liste'),
          onPressed: () => context.recordings.cancel(s),
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ]),
    );
  }
}

/// Lit un fichier du disque dans le lecteur de l'écran Enregistrements.
void playLocalFile(BuildContext context, String path) {
  final name = path.split(Platform.pathSeparator).last;
  context.playback.play(MediaItem(
    id: 'file:$path',
    sourceId: 'local',
    kind: MediaKind.movie,
    name: name.replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), ''),
    group: tr('Enregistrements'),
    stream: path,
  ));
  if (context.navigation.screen != Screen.recordings) context.navigation.go(Screen.recordings);
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.playing, required this.date});
  final RecordedFile file;
  final bool playing;
  final String date;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (d) => _menu(context, d.globalPosition),
      child: Hover(
        onTap: () => playLocalFile(context, file.path),
        builder: (context, hovering) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: playing ? KPalette.accent.withValues(alpha: 0.85) : (hovering ? KPalette.ink.withValues(alpha: 0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            Icon(Icons.movie_outlined, size: 18, color: playing ? KPalette.ink : KPalette.ink54),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(file.name, style: kText(13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${sizeText(file.size)} · $date', style: kText(11, color: KPalette.ink.withValues(alpha: playing ? 0.8 : 0.45))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, Offset position) async {
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: KPalette.menu,
      items: [
        PopupMenuItem(value: 'play', child: Text(tr('Regarder'), style: kText(13))),
        PopupMenuItem(value: 'folder', child: Text(tr('Afficher dans le dossier'), style: kText(13))),
        PopupMenuItem(value: 'delete', child: Text(tr('Supprimer le fichier'), style: kText(13, color: KPalette.orange))),
      ],
    );
    if (!context.mounted) return;
    if (choice == 'play') playLocalFile(context, file.path);
    if (choice == 'folder') openFolder(File(file.path).parent.path);
    if (choice == 'delete') {
      final ok = await showKDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('Supprimer ce fichier ?')),
          content: Text(file.name),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Annuler'))),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Supprimer'))),
          ],
        ),
      );
      if (ok == true && context.mounted) {
        if (context.playback.current?.stream == file.path) await context.playback.stop();
        if (context.mounted) await context.recordings.deleteFile(file);
      }
    }
  }
}
