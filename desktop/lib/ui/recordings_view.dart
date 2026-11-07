import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.video_file_outlined, size: 64, color: KPalette.ink.withValues(alpha: 0.35)),
        const SizedBox(height: 12),
        Text(tr('Choisissez un fichier à regarder'), style: kText(15, color: KPalette.secondaryText)),
      ]),
    );
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([context.navigation, context.playback]),
        builder: (context, _) {
          if (context.navigation.theater) return PlayerPane(placeholder: placeholder);
          final compact = MediaQuery.sizeOf(context).width < SidebarShell.wide;
          final Widget body = compact
              // Téléphone : le fichier en cours en haut, la liste dessous.
              ? Column(children: [
                  if (context.playback.current != null) AspectRatio(aspectRatio: 16 / 9, child: PlayerPane(placeholder: placeholder)),
                  const Expanded(child: RecordingsList()),
                ])
              : Row(children: [
                  const SizedBox(width: 470, child: RecordingsList()),
                  VerticalDivider(width: 1, color: KPalette.separator),
                  Expanded(child: PlayerPane(placeholder: placeholder)),
                ]);
          return SidebarShell(title: tr('Enregistrements'), sidebar: const Sidebar(kind: MediaKind.live, recordings: true), child: body);
        },
      ),
    );
  }
}

class RecordingsList extends StatefulWidget {
  const RecordingsList({super.key});

  @override
  State<RecordingsList> createState() => _RecordingsListState();
}

class _RecordingsListState extends State<RecordingsList> {
  bool _selecting = false;
  final Set<String> _selected = {};

  Future<void> _remove(List<RecordedFile> list, {bool clear = false}) async {
    if (list.isEmpty) return;
    final done = await showRemovalDialog(context, list, clear: clear);
    if (done && mounted) {
      setState(() {
        _selected.clear();
        _selecting = false;
      });
    }
  }

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
                IconButton(
                  tooltip: tr('Sélectionner'),
                  isSelected: _selecting,
                  onPressed: recordings.files.isEmpty
                      ? null
                      : () => setState(() {
                            _selecting = !_selecting;
                            _selected.clear();
                          }),
                  icon: const Icon(Icons.checklist_rounded),
                ),
                IconButton(
                  tooltip: tr('Vider la liste…'),
                  onPressed: recordings.files.isEmpty ? null : () => _remove(List.of(recordings.files), clear: true),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
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
            _header('${tr('FICHIERS')} (${recordings.files.length})', actions: [
              if (recordings.files.isNotEmpty) ...[
                TextButton(
                  onPressed: () => setState(() {
                    _selecting = !_selecting;
                    _selected.clear();
                  }),
                  child: Text(_selecting ? tr('Terminer la sélection') : tr('Sélectionner')),
                ),
                TextButton(onPressed: () => _remove(List.of(recordings.files), clear: true), child: Text(tr('Vider la liste…'))),
              ],
              if (_selecting) ...[
                TextButton(onPressed: () => setState(() => _selected.addAll(recordings.files.map((f) => f.path))), child: Text(tr('Tout sélectionner'))),
                TextButton(
                  onPressed: _selected.isEmpty ? null : () => _remove([for (final f in recordings.files) if (_selected.contains(f.path)) f]),
                  child: Text('${tr('Retirer la sélection')} (${_selected.length})…'),
                ),
              ],
            ]),
            if (recordings.removalUndo != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Expanded(child: Text(tr('Retiré de la liste.'), style: kText(12))),
                  TextButton(onPressed: recordings.undoRemoval, child: Text(tr('Annuler'))),
                ]),
              ),
            if (recordings.files.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(tr('Aucun fichier pour l\'instant.'), style: kText(12, color: KPalette.ink38)),
              ),
            for (final f in recordings.files)
              _FileRow(
                file: f,
                playing: playingPath == f.path,
                date: _date(f.modified),
                selecting: _selecting,
                selected: _selected.contains(f.path),
                onToggle: () => setState(() => _selected.contains(f.path) ? _selected.remove(f.path) : _selected.add(f.path)),
                onRemove: () => _remove([f]),
              ),
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
              '${active.stopS != null ? ' · ${tr('jusqu\'à')} ${hm(DateTime.fromMillisecondsSinceEpoch(active.stopS! * 1000))} (${tr('reste')} ${durationText(DateTime.fromMillisecondsSinceEpoch(active.stopS! * 1000).difference(DateTime.now()))})' : ' · ${tr('sans limite de durée')}'}',
              style: kText(12, color: KPalette.secondaryText),
            ),
          ]),
        ),
        const StopDurationButton(),
        const SizedBox(width: 6),
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
  const _FileRow({
    required this.file,
    required this.playing,
    required this.date,
    required this.selecting,
    required this.selected,
    required this.onToggle,
    required this.onRemove,
  });
  final RecordedFile file;
  final bool playing;
  final String date;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return MenuTap(
      onMenu: (d) => _menu(context, d.globalPosition),
      child: Hover(
        onTap: selecting ? onToggle : () => playLocalFile(context, file.path),
        builder: (context, hovering) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: playing ? KPalette.accent.withValues(alpha: 0.85) : (hovering ? KPalette.ink.withValues(alpha: 0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            if (selecting)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 20, color: selected ? KPalette.accent : KPalette.ink54),
              ),
            Icon(Icons.movie_outlined, size: 18, color: playing ? KPalette.ink : KPalette.ink54),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(file.name, style: kText(13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${sizeText(file.size)} · $date', style: kText(11, color: KPalette.ink.withValues(alpha: playing ? 0.8 : 0.45))),
              ]),
            ),
            if (!selecting && hovering)
              IconButton(
                tooltip: tr('Retirer de la liste…'),
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
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
        PopupMenuItem(value: 'remove', child: Text(tr('Retirer de la liste…'), style: kText(13))),
        PopupMenuItem(value: 'delete', child: Text(tr('Supprimer le fichier'), style: kText(13, color: KPalette.orange))),
      ],
    );
    if (!context.mounted) return;
    if (choice == 'play') playLocalFile(context, file.path);
    if (choice == 'folder') openFolder(File(file.path).parent.path);
    if (choice == 'remove') onRemove();
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

/// Boîte de retrait de la liste : par défaut les fichiers restent dans le stockage ; renvoie true si le retrait a eu lieu.
Future<bool> showRemovalDialog(BuildContext context, List<RecordedFile> list, {bool clear = false}) async {
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return false;
  var deleteFiles = prefs.getBool('recordings.remove.deleteFiles') ?? false;
  var remember = false;
  final total = list.fold<int>(0, (a, f) => a + f.size);
  final go = await showKDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setS) => AlertDialog(
        title: Text(clear
            ? '${tr('Vider la liste')} (${list.length})'
            : list.length == 1
                ? tr('Retirer l\'enregistrement de la liste')
                : '${tr('Retirer de la liste')} : ${list.length}'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (list.length <= 8)
              for (final f in list) Text('• ${f.name}', style: kText(12), maxLines: 1, overflow: TextOverflow.ellipsis)
            else
              Text('${list.length} ${tr('enregistrements terminés (programmations et téléchargements ne sont pas concernés).')}', style: kText(12)),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: deleteFiles,
              onChanged: (v) => setS(() => deleteFiles = v ?? false),
              title: Text(tr('Supprimer aussi le(s) fichier(s) du stockage'), style: kText(13)),
              subtitle: Text(
                deleteFiles
                    ? '${tr('Espace libéré')} : ${sizeText(total)}'
                    : tr('Les fichiers restent dans le dossier ; ils ne réapparaîtront pas dans la liste. Annulation possible juste après.'),
                style: kText(11, color: KPalette.ink54),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: remember,
              onChanged: (v) => setS(() => remember = v ?? false),
              title: Text(tr('Mémoriser ce choix'), style: kText(12)),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Annuler'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(deleteFiles ? tr('Retirer et supprimer') : tr('Retirer de la liste'))),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return false;
  final recs = context.recordings;
  final playback = context.playback;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (remember) await prefs.setBool('recordings.remove.deleteFiles', deleteFiles);
  for (final f in list) {
    if (deleteFiles && playback.current?.stream == f.path) await playback.stop();
  }
  final warnings = await recs.remove(list, deleteFiles: deleteFiles);
  if (warnings.length == 1) {
    messenger?.showSnackBar(SnackBar(content: Text(warnings.first)));
  } else if (warnings.length > 1 && context.mounted) {
    await showKDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${warnings.length} ${tr('avertissements')}'),
        content: SizedBox(
          width: 460,
          height: 200,
          child: ListView(children: [for (final w in warnings) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(w, style: kText(12)))]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('OK')))],
      ),
    );
  }
  return true;
}

/// Menu « Durée » : change à tout moment l'arrêt programmé de l'enregistrement en cours.
class StopDurationButton extends StatelessWidget {
  const StopDurationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final box = context.findRenderObject() as RenderBox;
        final p = box.localToGlobal(Offset(0, box.size.height));
        final recordings = context.recordings;
        final choice = await showMenu<int>(
          context: context,
          position: RelativeRect.fromLTRB(p.dx, p.dy, p.dx, p.dy),
          color: KPalette.menu,
          items: [
            for (final m in [15, 30, 60, 90, 120, 180, 240])
              PopupMenuItem(
                value: m,
                child: Text('${tr('Arrêter dans')} ${m < 60 ? '$m min' : (m % 60 == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${m % 60}')}', style: kText(13)),
              ),
            PopupMenuItem(value: -1, child: Text(tr('À une heure précise…'), style: kText(13))),
            PopupMenuItem(value: -2, child: Text(tr('Sans limite de durée'), style: kText(13))),
          ],
        );
        if (choice == null) return;
        if (choice == -2) return recordings.setStopAfter(null);
        if (choice == -1) {
          if (!context.mounted) return;
          final t = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
          );
          if (t == null) return;
          final now = DateTime.now();
          return recordings.setStopAt(DateTime(now.year, now.month, now.day, t.hour, t.minute));
        }
        recordings.setStopAfter(choice);
      },
      icon: const Icon(Icons.timer_outlined, size: 16),
      label: Text(tr('Durée')),
    );
  }
}

/// Bandeau affiché juste après le démarrage d'un enregistrement : il a déjà commencé et ne l'attend pas.
class RecordingDurationBanner extends StatelessWidget {
  const RecordingDurationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final recordings = context.recordings;
    return ListenableBuilder(
      listenable: recordings,
      builder: (context, _) {
        final a = recordings.active;
        if (!recordings.durationPrompt || a == null) return const SizedBox.shrink();
        final end = a.stopS == null ? null : DateTime.fromMillisecondsSinceEpoch(a.stopS! * 1000);
        return Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          decoration: BoxDecoration(
            color: KPalette.menuDark,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fiber_manual_record, size: 16, color: Colors.red),
            const SizedBox(width: 10),
            Flexible(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Enregistrement démarré'), style: kText(13, weight: FontWeight.w600, color: Colors.white)),
                Text(end == null ? tr('Sans limite de durée') : '${tr('Arrêt automatique à')} ${hm(end)}',
                    style: kText(12, color: Colors.white70)),
              ]),
            ),
            const SizedBox(width: 10),
            const StopDurationButton(),
            IconButton(onPressed: recordings.dismissDurationPrompt, icon: const Icon(Icons.close_rounded, size: 18)),
          ]),
        );
      },
    );
  }
}
