import 'library.dart';
import 'log.dart';
import 'media_servers.dart';
import 'models.dart';
import 'settings.dart';

/// Partage la lecture avec les serveurs Jellyfin, Emby et Plex : positions reçues (reprise sur cet ordinateur)
/// et envoyées (reprise sur les autres appareils, « vu » à la fin).
class MediaSync {
  MediaSync(this.library, this.watch);
  final LibraryStore library;
  final WatchProgressStore watch;

  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  final Set<String> _reported = {};

  /// Positions connues du serveur : la plus récente des deux l'emporte (le serveur, puisqu'il vient d'être lu).
  void receive(Map<String, (double, double)> progress) {
    progress.forEach((id, value) => watch.update(id, value.$1, value.$2));
    watch.flush();
  }

  Future<void> report(MediaItem item, double position, double duration, PlaybackEvent event) async {
    final source = library.sourceOf(item);
    if (source == null || !source.kind.isMediaServer || duration <= 0) return;
    // Progression : toutes les 15 s au plus.
    if (event == PlaybackEvent.progress || event == PlaybackEvent.pause) {
      if (DateTime.now().difference(_lastSent) < const Duration(seconds: 15)) return;
    }
    if (event == PlaybackEvent.start) _reported.add(item.id);
    _lastSent = DateTime.now();
    try {
      final client = await library.serverClient(source);
      if (client == null) return;
      await client.report(item, position, duration, event);
      if (event == PlaybackEvent.stop) {
        _reported.remove(item.id);
        if (position / duration >= 0.92) await client.setPlayed(item, true);
      }
    } catch (e) {
      PlaybackLog.shared.note('Synchronisation avec ${source.kind.label} impossible : $e');
    }
  }

  /// « Marquer comme vu / non vu » (clic droit).
  Future<void> setPlayed(MediaItem item, bool played) async {
    final source = library.sourceOf(item);
    if (source == null) return;
    if (played) {
      final known = watch.fractionRaw(item.id);
      final duration = known?.$2 ?? 1;
      watch.update(item.id, duration, duration);
    } else {
      watch.clear(item.id);
    }
    await watch.flush();
    if (!source.kind.isMediaServer) return;
    try {
      final client = await library.serverClient(source);
      await client?.setPlayed(item, played);
    } catch (e) {
      PlaybackLog.shared.note('Synchronisation avec ${source.kind.label} impossible : $e');
    }
  }
}
