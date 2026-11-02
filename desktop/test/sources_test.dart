import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/library.dart';
import 'package:kastideo/core/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Source src(String id) => Source(id: id, name: 'Compte $id', kind: SourceKind.xtream, address: 'http://x');
  MediaItem item(String source, String id, MediaKind kind, String name, {String group = 'Cat'}) =>
      MediaItem(id: '$source:$id', sourceId: source, kind: kind, name: name, group: group);

  Future<LibraryStore> make() async {
    SharedPreferences.setMockInitialValues({});
    final lib = LibraryStore();
    await lib.debugLoad([src('a'), src('b')], {
      'a': [
        item('a', '1', MediaKind.live, 'TF1'),
        item('a', '2', MediaKind.movie, 'Sintel (2010)'),
        item('a', '3', MediaKind.movie, 'Only A'),
      ],
      'b': [
        item('b', '1', MediaKind.live, 'TF1'),
        item('b', '2', MediaKind.movie, 'Sintel (2010)'),
        item('b', '4', MediaKind.movie, 'Only B'),
        item('b', '5', MediaKind.series, 'Série B'),
      ],
    });
    return lib;
  }

  test('toutes les sources : les doublons de films sont fusionnés, pas les chaînes', () async {
    final lib = await make();
    expect(lib.items(MediaKind.movie).map((i) => i.name).toList()..sort(), ['Only A', 'Only B', 'Sintel (2010)']);
    expect(lib.items(MediaKind.live).length, 2);
    expect(lib.items(MediaKind.series).length, 1);
  });

  test('sans fusion, tout est listé', () async {
    final lib = await make();
    lib.setDedupe(false);
    expect(lib.items(MediaKind.movie).length, 4);
  });

  test('source active : un seul compte', () async {
    final lib = await make();
    lib.setActiveSource('b');
    expect(lib.items(MediaKind.movie).every((i) => i.sourceId == 'b'), isTrue);
    expect(lib.items(MediaKind.movie).length, 2);
    expect(lib.items(MediaKind.live).length, 1);
    lib.setActiveSource(null);
    expect(lib.items(MediaKind.live).length, 2);
  });

  test('compteurs bruts par source', () async {
    final lib = await make();
    final b = lib.rawCounts(lib.sources[1]);
    expect((b.live, b.movies, b.series), (1, 2, 1));
  });
}
