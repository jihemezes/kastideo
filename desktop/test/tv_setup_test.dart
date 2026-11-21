import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/library.dart';
import 'package:kastideo/core/tv_setup.dart';
import 'package:kastideo/ui/tv_shell.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test('serveur d\'ajout depuis le téléphone : page et code incorrect', () async {
    SharedPreferences.setMockInitialValues({});
    final server = TvSetupServer(LibraryStore());
    await server.start();
    expect(server.running, isTrue);
    expect(server.code.length, 4);
    final port = Uri.parse(server.address ?? 'http://127.0.0.1:0/').port;
    final client = HttpClient();
    final get = await (await client.getUrl(Uri.parse('http://127.0.0.1:$port/'))).close();
    expect(get.statusCode, 200);
    final request = await client.postUrl(Uri.parse('http://127.0.0.1:$port/add'));
    request.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
    request.write('code=0000x&type=m3u&name=a&url=http%3A%2F%2Fx');
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();
    expect(body, contains('Code incorrect'));
    client.close();
    await server.stop();
  });

  test('touches de la télécommande reconnues', () {
    const down = KeyDownEvent(physicalKey: PhysicalKeyboardKey.arrowDown, logicalKey: LogicalKeyboardKey.arrowDown, timeStamp: Duration.zero);
    const ok = KeyDownEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: LogicalKeyboardKey.select, timeStamp: Duration.zero);
    expect(tvKeyOf(down), TvKey.down);
    expect(tvKeyOf(ok), TvKey.ok);
  });
}
