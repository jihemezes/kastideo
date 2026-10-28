// Replay : relecture d'un programme déjà diffusé depuis l'archive du fournisseur
// (« timeshift » Xtream Codes), portage de Replay.swift de la version Mac.

/// Horloge du serveur Xtream : sert à écrire l'heure de début d'un replay dans le fuseau du serveur.
class ServerClock {
  const ServerClock({this.timezone, this.offset});

  /// Nom du fuseau (« Europe/Paris ») annoncé par le serveur.
  final String? timezone;

  /// Décalage actuel avec UTC en secondes, déduit de `time_now` et `timestamp_now`.
  final int? offset;

  /// Lit le bloc `server_info` de player_api.php.
  static ServerClock? parse(Object? info) {
    if (info is! Map) return null;
    String? text(String key) {
      final v = info[key];
      if (v == null) return null;
      final s = '$v'.trim();
      return s.isEmpty ? null : s;
    }

    int? offset;
    final local = text('time_now');
    final stamp = double.tryParse(text('timestamp_now') ?? '');
    if (local != null && stamp != null) {
      final asUtc = DateTime.tryParse('${local.replaceFirst(' ', 'T')}Z');
      if (asUtc != null) {
        final raw = asUtc.millisecondsSinceEpoch / 1000 - stamp;
        offset = (raw / 900).round() * 900; // arrondi au quart d'heure
      }
    }
    final zone = text('timezone');
    if (zone == null && offset == null) return null;
    return ServerClock(timezone: zone, offset: offset);
  }

  Map<String, dynamic> toJson() => {'tz': ?timezone, 'off': ?offset};

  static ServerClock? fromJson(Map<String, dynamic>? j) =>
      j == null || (j['tz'] == null && j['off'] == null)
      ? null
      : ServerClock(timezone: j['tz'] as String?, offset: j['off'] as int?);

  static const _noDst = {
    'Europe/Moscow',
    'Europe/Minsk',
    'Europe/Istanbul',
    'Europe/Kirov',
    'Europe/Samara',
    'Europe/Volgograd',
    'Europe/Simferopol',
  };
  static const _standard = {
    'Europe/Paris': 3600,
    'Europe/Brussels': 3600,
    'Europe/Berlin': 3600,
    'Europe/Madrid': 3600,
    'Europe/Rome': 3600,
    'Europe/Amsterdam': 3600,
    'Europe/Zurich': 3600,
    'Europe/Vienna': 3600,
    'Europe/Luxembourg': 3600,
    'Europe/London': 0,
    'Europe/Lisbon': 0,
    'Europe/Dublin': 0,
  };

  /// Heure d'été européenne à cet instant (dernier dimanche de mars à octobre, 01:00 UTC).
  static bool euDst(int utcSeconds) {
    final d = DateTime.fromMillisecondsSinceEpoch(
      utcSeconds * 1000,
      isUtc: true,
    );
    DateTime lastSunday(int month) {
      var day = DateTime.utc(d.year, month + 1, 0, 1);
      while (day.weekday != DateTime.sunday) {
        day = day.subtract(const Duration(days: 1));
      }
      return day;
    }

    return !d.isBefore(lastSunday(3)) && d.isBefore(lastSunday(10));
  }

  /// Décalage avec UTC (secondes) à un instant donné ; `fallback` : celui de l'appareil si le serveur ne dit rien.
  int offsetAt(int utcSeconds, {required int fallback, int? nowSeconds}) {
    final zone = timezone;
    final europe =
        zone != null && zone.startsWith('Europe/') && !_noDst.contains(zone);
    if (europe) {
      final now = nowSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final base = offset != null
          ? offset! - (euDst(now) ? 3600 : 0)
          : _standard[zone];
      if (base != null) return base + (euDst(utcSeconds) ? 3600 : 0);
    }
    return offset ?? (zone == null ? null : _standard[zone]) ?? fallback;
  }
}

class ReplayUrl {
  /// Préfixe des identifiants des éléments de replay.
  static const idPrefix = 'replay:';

  /// Marge avant le début annoncé du programme (le guide est rarement exact à la minute).
  static const marginBefore = 60;

  /// Marge après la fin annoncée (les programmes débordent).
  static const marginAfter = 5 * 60;

  /// Adresse du replay depuis l'adresse directe
  /// (`…/live/identifiant/mot-de-passe/ID.ts` → `…/timeshift/identifiant/mot-de-passe/durée/AAAA-MM-JJ:HH-MM/ID.ts`).
  static String? make(
    String live, {
    required int startS,
    required int stopS,
    ServerClock? clock,
    int extraOffsetMinutes = 0,
    int? deviceOffset,
  }) {
    final uri = Uri.tryParse(live);
    if (uri == null || !uri.hasAuthority) return null;
    final parts = uri.path.split('/').where((p) => p.isNotEmpty).toList();
    final liveIndex = parts.lastIndexOf('live');
    if (liveIndex < 0 || liveIndex + 3 != parts.length - 1) return null;
    final user = parts[liveIndex + 1],
        pass = parts[liveIndex + 2],
        file = parts[liveIndex + 3];
    final dot = file.lastIndexOf('.');
    final id = dot < 0 ? file : file.substring(0, dot);
    final begin = startS - marginBefore;
    final finish = stopS + marginAfter;
    final minutes = ((finish - begin) / 60).ceil().clamp(1, 100000);
    final device =
        deviceOffset ??
        DateTime.fromMillisecondsSinceEpoch(begin * 1000)
            .timeZoneOffset
            .inSeconds;
    final offset =
        (clock == null ? device : clock.offsetAt(begin, fallback: device)) +
        extraOffsetMinutes * 60;
    final t = DateTime.fromMillisecondsSinceEpoch(
      (begin + offset) * 1000,
      isUtc: true,
    );
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}:${two(t.hour)}-${two(t.minute)}';
    final prefix = parts.sublist(0, liveIndex).map((p) => '/$p').join();
    final origin =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    return '$origin$prefix/timeshift/$user/$pass/$minutes/$stamp/$id.ts';
  }
}
