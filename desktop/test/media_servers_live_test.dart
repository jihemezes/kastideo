// Test manuel contre les serveurs simulés (KASTIDEO_MOCK=1).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/discovery.dart';
import 'package:kastideo/core/media_servers.dart';
import 'package:kastideo/core/models.dart';

void main() {
  final skip = Platform.environment['KASTIDEO_MOCK'] != '1';
  test('jellyfin', () async {
    final s = MediaServerClient.normalizeFor(SourceKind.jellyfin, '127.0.0.1:8796');
    expect(s, 'http://127.0.0.1:8796');
    expect(await JellyfinClient.publicInfo(s), contains('Salon'));
    await expectLater(JellyfinClient.signIn(s, 'jm', 'bad'), throwsA(isA<MediaServerException>()));
    final session = await JellyfinClient.signIn(s, 'jm', 'secret');
    final c = JellyfinClient(s, 'S', session: session);
    final lib = await c.fetchLibrary();
    expect(lib.items.where((i) => i.kind == MediaKind.movie).length, 4);
    final show = lib.items.firstWhere((i) => i.kind == MediaKind.series);
    final (seasons, _) = await c.episodes(show);
    expect(seasons.map((s) => s.number), [1, 2]);
    final dune = lib.items.firstWhere((i) => i.name.startsWith('Dune'));
    expect(dune.name, 'Dune (2021)');
    await c.report(dune, 600, 1800, PlaybackEvent.progress);
    expect((await c.fetchLibrary()).progress[dune.id]!.$1, 600);
    await c.setPlayed(dune, true);
    expect((await c.fetchLibrary()).progress[dune.id]!.$1, 1800);
    await c.setPlayed(dune, false);
    final d = await c.details(dune);
    expect(d!.directors, ['Denis Villeneuve']);
  }, skip: skip);

  test('emby et adresses', () async {
    // Adresse copiée depuis le navigateur.
    expect(MediaServerClient.normalizeFor(SourceKind.emby, 'http://127.0.0.1:8798/web/index.html#!/home'), 'http://127.0.0.1:8798');
    final s = MediaServerClient.normalizeFor(SourceKind.emby, '127.0.0.1:8798');
    final session = await JellyfinClient.signIn(s, 'jm', 'secret', emby: true);
    final c = JellyfinClient(s, 'E', session: session, emby: true);
    expect((await c.fetchLibrary()).items, isNotEmpty);
    // Utilisateur sans mot de passe.
    final guest = await JellyfinClient.signIn(MediaServerClient.normalizeFor(SourceKind.jellyfin, '127.0.0.1:8796'), 'guest', '');
    expect(guest.token, isNotEmpty);
    expect(KastideoDevice.asciiOnly('Mac mini de Jérôme’s "x"'), "Mac mini de Jerome's x");
  }, skip: skip);

  test('plex', () async {
    final s = MediaServerClient.normalizeFor(SourceKind.plex, 'localhost');
    expect(s, 'http://localhost:32400');
    const addr = 'http://127.0.0.1:8797';
    final c = PlexClient(addr, 'P', token: 'ptok');
    expect(await c.identity(), 'Bureau');
    final lib = await c.fetchLibrary();
    expect(lib.items.where((i) => i.kind == MediaKind.movie).length, 3);
    final movie = lib.items.first;
    await c.setPlayed(movie, false);
    expect(movie.stream, contains('/library/parts/'));
    final show = lib.items.firstWhere((i) => i.kind == MediaKind.series);
    expect((await c.seasons(show)).first.episodes.length, 3);
    await c.report(movie, 120, 1800, PlaybackEvent.pause);
    expect((await c.fetchLibrary()).progress[movie.id]!.$1, 120);
    await c.setPlayed(movie, true);
    expect((await c.fetchLibrary()).progress[movie.id]!.$1, 1800);
    expect((await c.details(movie))!.tmdbId, '438631');
  }, skip: skip);

  test('discovery', () async {
    final found = await ServerDiscovery.scan(wait: const Duration(seconds: 2));
    // ignore: avoid_print
    print(found.map((f) => '${f.kind} ${f.name} ${f.address}').toList());
    expect(found.any((f) => f.kind == SourceKind.jellyfin), isTrue);
    expect(found.any((f) => f.kind == SourceKind.plex), isTrue);
  }, skip: skip);
}
