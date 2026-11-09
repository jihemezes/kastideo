import 'dart:io';

import 'device.dart';
import 'package:local_notifier/local_notifier.dart';
import 'desk.dart';

import 'log.dart';

/// Notifications du système (Windows : centre de notifications ; Linux : libnotify), comme sur Mac.
/// Un clic sur la notification ramène la fenêtre de Kastideo au premier plan.
class SystemNotifier {
  SystemNotifier._();

  static bool enabled = true;
  static bool _ready = false;

  static Future<void> setup() async {
    if (Platform.isAndroid) {
      _ready = true;
      await Device.requestNotifications();
      return;
    }
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;
    try {
      await localNotifier.setup(appName: 'Kastideo', shortcutPolicy: ShortcutPolicy.requireCreate);
      _ready = true;
    } catch (e) {
      PlaybackLog.shared.note('Notifications du système indisponibles : $e');
    }
  }

  static Future<void> show(String title, String body) async {
    if (!enabled || !_ready) return;
    if (Platform.isAndroid) {
      await Device.notify(title, body);
      return;
    }
    try {
      final n = LocalNotification(title: title, body: body);
      n.onClick = () async {
        try {
          await windowManager.show();
          if (await windowManager.isMinimized()) await windowManager.restore();
          await windowManager.focus();
        } catch (_) {}
      };
      await n.show();
    } catch (e) {
      PlaybackLog.shared.note('Notification impossible : $e');
    }
  }
}
