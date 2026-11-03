import 'dart:async';
import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Position de la fenêtre : mémorisée, et toujours ramenée sur un écran visible
/// (écran débranché, résolution ou mise à l'échelle modifiée, plusieurs écrans).
class WindowPlacement with WindowListener {
  WindowPlacement._(this._prefs);
  final SharedPreferences _prefs;
  Timer? _save;

  static const _key = 'window.bounds';
  static const _titleBar = 48.0;

  static Future<WindowPlacement> start(SharedPreferences prefs) async {
    final placement = WindowPlacement._(prefs);
    windowManager.addListener(placement);
    return placement;
  }

  /// Zones visibles de tous les écrans.
  static Future<List<Rect>> visibleAreas() async {
    final areas = <Rect>[];
    try {
      for (final d in await screenRetriever.getAllDisplays()) {
        final pos = d.visiblePosition ?? Offset.zero;
        final size = d.visibleSize ?? d.size;
        areas.add(pos & size);
      }
    } catch (_) {}
    return areas;
  }

  /// Vrai si la barre de titre est assez visible sur un écran pour attraper la fenêtre à la souris.
  static bool isReachable(Rect bounds, List<Rect> areas) {
    if (areas.isEmpty) return true;
    final strip = Rect.fromLTWH(bounds.left, bounds.top, bounds.width, _titleBar);
    for (final area in areas) {
      final overlap = strip.intersect(area);
      if (overlap.width >= 160 && overlap.height >= _titleBar - 4) return true;
    }
    return false;
  }

  /// Rectangle centré sur l'écran principal, ramené à sa taille si besoin.
  static Future<Rect> centered(Size wanted) async {
    try {
      final d = await screenRetriever.getPrimaryDisplay();
      final pos = d.visiblePosition ?? Offset.zero;
      final area = pos & (d.visibleSize ?? d.size);
      final w = wanted.width.clamp(0, area.width).toDouble();
      final h = wanted.height.clamp(0, area.height).toDouble();
      return Rect.fromLTWH(area.left + (area.width - w) / 2, area.top + (area.height - h) / 2, w, h);
    } catch (_) {
      return Offset.zero & wanted;
    }
  }

  Rect? saved() {
    final parts = (_prefs.getString(_key) ?? '').split(',').map(double.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) return null;
    return Rect.fromLTWH(parts[0]!, parts[1]!, parts[2]!, parts[3]!);
  }

  /// Au démarrage : retrouve la position mémorisée si elle est encore atteignable, sinon centre sur l'écran principal.
  Future<void> restore(Size defaultSize, Size minimum) async {
    final areas = await visibleAreas();
    var target = saved();
    if (target == null || target.width < minimum.width || target.height < minimum.height || !isReachable(target, areas)) {
      target = await centered(defaultSize);
    }
    try {
      await windowManager.setBounds(target);
    } catch (_) {}
  }

  /// Après l'affichage : si le système a placé la fenêtre à moitié hors écran, elle est recentrée.
  Future<void> verify(Size defaultSize) async {
    try {
      final current = await windowManager.getBounds();
      if (!isReachable(current, await visibleAreas())) {
        await windowManager.setBounds(await centered(Size(current.width, current.height).isEmpty ? defaultSize : current.size));
      }
    } catch (_) {}
  }

  void _schedule() {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 600), () async {
      try {
        if (await windowManager.isMinimized() || await windowManager.isMaximized() || await windowManager.isFullScreen()) return;
        final b = await windowManager.getBounds();
        if (!isReachable(b, await visibleAreas())) return;
        await _prefs.setString(_key, '${b.left},${b.top},${b.width},${b.height}');
      } catch (_) {}
    });
  }

  @override
  void onWindowMoved() => _schedule();

  @override
  void onWindowResized() => _schedule();
}
