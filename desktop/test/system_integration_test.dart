import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/system_integration.dart';

void main() {
  test('association .m3u sous Linux : écrit et retire mimeapps.list', () async {
    final dir = await Directory.systemTemp.createTemp('kastideo-home');
    SystemIntegration.homeOverride = dir.path;
    try {
      final list = File('${dir.path}/.config/mimeapps.list');
      await list.parent.create(recursive: true);
      await list.writeAsString('[Default Applications]\naudio/x-mpegurl=vlc.desktop\nimage/png=eog.desktop\n\n[Added Associations]\nimage/png=eog.desktop;\n');
      expect(await SystemIntegration.m3uAssociated(), false);
      expect(await SystemIntegration.setM3uAssociation(true), isNull);
      final text = list.readAsStringSync();
      expect(text.contains('audio/x-mpegurl=fr.jmezes.kastideo-m3u.desktop'), true);
      expect(text.contains('vlc.desktop'), false);
      expect(text.contains('image/png=eog.desktop'), true);
      expect(await SystemIntegration.m3uAssociated(), true);
      expect(await SystemIntegration.setM3uAssociation(false), isNull);
      expect(list.readAsStringSync().contains('kastideo'), false);
      expect(await SystemIntegration.m3uAssociated(), false);
    } finally {
      SystemIntegration.homeOverride = null;
      await dir.delete(recursive: true);
    }
  }, skip: !Platform.isLinux);

  test('association .m3u sous Linux sans mimeapps.list', () async {
    final dir = await Directory.systemTemp.createTemp('kastideo-home');
    SystemIntegration.homeOverride = dir.path;
    try {
      expect(await SystemIntegration.setM3uAssociation(true), isNull);
      expect(File('${dir.path}/.config/mimeapps.list').readAsStringSync().startsWith('[Default Applications]'), true);
    } finally {
      SystemIntegration.homeOverride = null;
      await dir.delete(recursive: true);
    }
  }, skip: !Platform.isLinux);
}
