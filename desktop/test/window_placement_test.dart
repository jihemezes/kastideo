import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/window_placement.dart';

void main() {
  const screens = [Rect.fromLTWH(0, 0, 1920, 1040), Rect.fromLTWH(1920, 0, 1280, 1024)];

  test('fenêtre entièrement visible : atteignable', () {
    expect(WindowPlacement.isReachable(const Rect.fromLTWH(100, 100, 1280, 820), screens), isTrue);
    expect(WindowPlacement.isReachable(const Rect.fromLTWH(2000, 50, 1000, 700), screens), isTrue);
  });

  test('barre de titre hors écran : à recentrer', () {
    expect(WindowPlacement.isReachable(const Rect.fromLTWH(100, -60, 1280, 820), screens), isFalse);
    expect(WindowPlacement.isReachable(const Rect.fromLTWH(3100, 100, 1280, 820), screens), isFalse);
    // Écran débranché : l'ancienne position sur le second écran n'est plus visible.
    expect(WindowPlacement.isReachable(const Rect.fromLTWH(2000, 50, 1000, 700), [screens.first]), isFalse);
  });
}
