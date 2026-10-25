import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log.dart';

/// Coffre des mots de passe : Gestionnaire d'identification (Windows), trousseau GNOME / KWallet (Linux).
/// Si le système n'a pas de coffre disponible (certains Raspberry Pi, sessions sans trousseau),
/// Kastideo se replie sur ses préférences locales, en le signalant dans le journal.
class Secrets {
  Secrets._();
  static final Secrets shared = Secrets._();
  static const _storage = FlutterSecureStorage();
  bool _warned = false;

  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final fallback = prefs.getString('secret.$key');
    return fallback == null ? null : utf8.decode(base64.decode(fallback));
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return;
    } catch (e) {
      if (!_warned) {
        _warned = true;
        PlaybackLog.shared.note('Coffre du système indisponible ($e) : mots de passe gardés dans les préférences de Kastideo');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secret.$key', base64.encode(utf8.encode(value)));
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('secret.$key');
  }
}
