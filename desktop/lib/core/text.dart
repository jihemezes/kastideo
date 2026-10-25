/// Outils de texte partagés : clé de recherche sans accents, nettoyage des noms de chaînes et de films.
library;

const Map<String, String> _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i',
  'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o',
  'ö': 'o', 'ø': 'o', 'œ': 'oe', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y', 'ß': 'ss',
};

extension KastideoText on String {
  /// Clé de recherche : minuscules, sans accents, espaces aux extrémités retirés.
  String get searchKey {
    final lower = toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }
}

final RegExp _prefixBrackets = RegExp(r'^\s*(\|[^|]{1,12}\||\[[^\]]{1,12}\])\s*');
final RegExp _prefixCodes = RegExp(
    r'^\s*(FR|FRA|FRENCH|EN|ENG|US|UK|VF|VFF|VFQ|VO|VOST|VOSTFR|MULTI|4K|UHD|FHD|HD|NF|AMZ|DSNP|DE|ES|IT|PT|AR|TR|BE|CA|QC|CH)\s*[-:|]\s*',
    caseSensitive: false);
final RegExp _yearBrackets = RegExp(r'[\(\[]\s*((19|20)\d{2})\s*[\)\]]');
final RegExp _yearEnd = RegExp(r'\s((19|20)\d{2})\s*$');
final RegExp _otherBrackets = RegExp(r'[\[\(][^\]\)]*[\]\)]');
final RegExp _tags = RegExp(
    r'\b(4K|UHD|FHD|HD|SD|HDR|HEVC|H265|x265|1080p|720p|2160p|MULTI|VOSTFR|VOST|VF|VFF|VFQ|VO|TRUEFRENCH|FRENCH)\b',
    caseSensitive: false);
final RegExp _spaces = RegExp(r'\s{2,}');

/// Titre lisible (même règles que la version Mac) : sans préfixe de pays, sans balises de qualité.
({String title, int? year}) cleanTitle(String raw) {
  var text = raw.replaceFirst(_prefixBrackets, '').replaceFirst(_prefixCodes, '');
  int? year;
  final bracket = _yearBrackets.firstMatch(text);
  if (bracket != null) {
    year = int.tryParse(bracket.group(1)!);
    text = text.replaceRange(bracket.start, bracket.end, '');
  } else {
    final end = _yearEnd.firstMatch(text);
    if (end != null) {
      year = int.tryParse(end.group(1)!);
      text = text.replaceRange(end.start, end.end, '');
    }
  }
  text = text.replaceAll(_otherBrackets, ' ').replaceAll(_tags, ' ').replaceAll(_spaces, ' ');
  text = text.trim();
  while (text.isNotEmpty && '-:|'.contains(text[0])) {
    text = text.substring(1).trim();
  }
  while (text.isNotEmpty && '-:|'.contains(text[text.length - 1])) {
    text = text.substring(0, text.length - 1).trim();
  }
  return (title: text.isEmpty ? raw : text, year: year);
}

/// Initiales d'un nom (logo de remplacement).
String initials(String name) {
  final words = cleanTitle(name).title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, words.first.length.clamp(0, 2)).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

final RegExp _nonAlnum = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Clé de comparaison d'un titre (catalogue IPTV ou TMDB) : sans étiquettes, accents ni ponctuation.
String titleKey(String raw) => cleanTitle(raw).title.searchKey.split(_nonAlnum).where((w) => w.isNotEmpty).join();
