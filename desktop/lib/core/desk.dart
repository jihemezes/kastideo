import 'dart:io';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart' as wm;

export 'package:window_manager/window_manager.dart' show WindowOptions, WindowListener;

/// Fenêtre de l'application : pilotée par window_manager sur Windows et Linux, sans effet (ou plein écran
/// immersif) sur Android, où il n'y a pas de fenêtre à gérer.
class DeskWindow {
  bool get _desktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  bool _fullScreen = false;

  Future<void> ensureInitialized() async {
    if (_desktop) await wm.windowManager.ensureInitialized();
  }

  Future<void> waitUntilReadyToShow(wm.WindowOptions options, Future<void> Function() ready) async {
    if (_desktop) {
      await wm.windowManager.waitUntilReadyToShow(options, ready);
    }
  }

  Future<void> show() async {
    if (_desktop) await wm.windowManager.show();
  }

  Future<void> hide() async {
    if (_desktop) await wm.windowManager.hide();
  }

  Future<void> focus() async {
    if (_desktop) await wm.windowManager.focus();
  }

  Future<void> restore() async {
    if (_desktop) await wm.windowManager.restore();
  }

  Future<void> minimize() async {
    if (_desktop) await wm.windowManager.minimize();
  }

  Future<bool> isMinimized() async => _desktop ? await wm.windowManager.isMinimized() : false;

  Future<bool> isFullScreen() async => _desktop ? await wm.windowManager.isFullScreen() : _fullScreen;

  /// Plein écran : fenêtre sur le bureau, barres système masquées sur Android.
  Future<void> setFullScreen(bool value) async {
    if (_desktop) {
      await wm.windowManager.setFullScreen(value);
      return;
    }
    _fullScreen = value;
    await SystemChrome.setEnabledSystemUIMode(value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  Future<void> setPreventClose(bool value) async {
    if (_desktop) await wm.windowManager.setPreventClose(value);
  }

  void addListener(wm.WindowListener listener) {
    if (_desktop) wm.windowManager.addListener(listener);
  }

  Future<void> setBackgroundColor(Color color) async {
    if (_desktop) await wm.windowManager.setBackgroundColor(color);
  }
}

final DeskWindow windowManager = DeskWindow();
