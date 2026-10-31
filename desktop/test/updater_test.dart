import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/updater.dart';

void main() {
  test('Comparaison des versions des aperçus', () {
    expect(compareVersions('1.2.0-desktop8', '1.2.0-desktop7'), greaterThan(0));
    expect(compareVersions('1.2.0-desktop10', '1.2.0-desktop9'), greaterThan(0));
    expect(compareVersions('1.2.1-desktop1', '1.2.0-desktop9'), greaterThan(0));
    expect(compareVersions('1.2.0-desktop7', '1.2.0-desktop7'), 0);
    expect(compareVersions('dev', '1.2.0-desktop7'), lessThan(0));
  });

  test('Comparaison des versions Android', () {
    expect(compareVersions('1.9.0-android2', '1.9.0-android1'), greaterThan(0));
    expect(compareVersions('1.9.1-android1', '1.9.0-android9'), greaterThan(0));
    expect(compareVersions('1.9.0-android1', '1.9.0-android1'), 0);
    expect(versionParts('1.9.0-android3'), [1, 9, 0, 3]);
  });
}
