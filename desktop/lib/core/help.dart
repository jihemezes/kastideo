/// Aide intégrée : source Markdown unique, partagée avec l'application Mac (voir docs/DEVELOPPEMENT.md).
///
/// Format : `# Rubrique`, puis `## Titre de la page {#identifiant}`. Les blocs `<!--mac-->…<!--/mac-->`
/// sont retirés ici, ceux de `<!--pc-->…<!--/pc-->` sont gardés. `[texte](help:id)` renvoie à une page,
/// `![texte](img:nom)` insère un schéma.
library;

import 'text.dart';

class HelpPage {
  const HelpPage(this.id, this.title, this.group, this.body);
  final String id;
  final String title;
  final String group;
  final String body;
}

class HelpGroup {
  const HelpGroup(this.title, this.pages);
  final String title;
  final List<HelpPage> pages;
}

enum HelpBlockType { heading, paragraph, bullet, numbered, note, image, rule }

class HelpBlock {
  const HelpBlock(this.type, {this.text = '', this.level = 0, this.number = 0, this.name = ''});
  final HelpBlockType type;
  final String text;
  final int level;
  final int number;
  final String name;
}

String _filterPlatform(String source) {
  var text = source.replaceAll(RegExp(r'<!--mac-->.*?<!--/mac-->', dotAll: true), '');
  text = text.replaceAll('<!--pc-->', '').replaceAll('<!--/pc-->', '');
  return text;
}

/// Découpe l'aide en rubriques et pages (les pages vides pour cette plateforme sont masquées).
List<HelpGroup> parseHelp(String source) {
  final groups = <HelpGroup>[];
  var groupTitle = '';
  var pages = <HelpPage>[];
  String? id;
  String title = '';
  var lines = <String>[];

  void closePage() {
    if (id == null) return;
    final body = lines.join('\n').trim();
    if (body.isNotEmpty) pages.add(HelpPage(id!, title, groupTitle, body));
    id = null;
    lines = [];
  }

  void closeGroup() {
    closePage();
    if (pages.isNotEmpty) groups.add(HelpGroup(groupTitle, pages));
    pages = [];
  }

  for (final line in _filterPlatform(source).split('\n')) {
    if (line.startsWith('## ')) {
      closePage();
      var t = line.substring(3).trim();
      var pid = t;
      final match = RegExp(r'^(.*)\{#([^}]+)\}$').firstMatch(t);
      if (match != null) {
        t = match.group(1)!.trim();
        pid = match.group(2)!;
      }
      id = pid;
      title = t;
    } else if (line.startsWith('# ')) {
      closeGroup();
      groupTitle = line.substring(2).trim();
    } else if (id != null) {
      lines.add(line);
    }
  }
  closeGroup();
  return groups;
}

/// Contenu d'une page : titres, paragraphes, puces (avec niveau), listes numérotées, encadrés, schémas.
List<HelpBlock> parseHelpBlocks(String body) {
  final result = <HelpBlock>[];
  final paragraph = <String>[];
  final note = <String>[];
  void flushParagraph() {
    if (paragraph.isNotEmpty) result.add(HelpBlock(HelpBlockType.paragraph, text: paragraph.join(' ')));
    paragraph.clear();
  }

  void flushNote() {
    if (note.isNotEmpty) result.add(HelpBlock(HelpBlockType.note, text: note.join(' ')));
    note.clear();
  }

  final image = RegExp(r'^!\[(.*)\]\(img:([^)]+)\)$');
  final numbered = RegExp(r'^(\d+)\. (.*)$');
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      flushParagraph();
      flushNote();
      continue;
    }
    if (line.startsWith('> ')) {
      flushParagraph();
      note.add(line.substring(2));
      continue;
    }
    flushNote();
    final img = image.firstMatch(line);
    final num = numbered.firstMatch(line);
    if (line.startsWith('### ')) {
      flushParagraph();
      result.add(HelpBlock(HelpBlockType.heading, text: line.substring(4)));
    } else if (img != null) {
      flushParagraph();
      result.add(HelpBlock(HelpBlockType.image, text: img.group(1)!, name: img.group(2)!));
    } else if (line == '---') {
      flushParagraph();
      result.add(const HelpBlock(HelpBlockType.rule));
    } else if (line.startsWith('- ') || line.startsWith('* ')) {
      flushParagraph();
      final indent = raw.length - raw.trimLeft().length;
      result.add(HelpBlock(HelpBlockType.bullet, text: line.substring(2), level: indent ~/ 2));
    } else if (num != null) {
      flushParagraph();
      result.add(HelpBlock(HelpBlockType.numbered, text: num.group(2)!, number: int.parse(num.group(1)!)));
    } else {
      paragraph.add(line);
    }
  }
  flushParagraph();
  flushNote();
  return result;
}

List<String> _terms(String query) => query.searchKey.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

/// Termes de recherche valides (au moins 2 lettres au total), sinon liste vide.
List<String> helpTerms(String query) {
  final terms = _terms(query);
  return terms.join().length >= 2 ? terms : const [];
}

/// Pages contenant tous les mots saisis : titre d'abord, puis nombre d'occurrences.
List<HelpPage> searchHelp(List<HelpGroup> groups, String query) {
  final terms = helpTerms(query);
  if (terms.isEmpty) return const [];
  final scored = <(HelpPage, int)>[];
  for (final page in groups.expand((g) => g.pages)) {
    final title = page.title.searchKey;
    final body = page.body.searchKey;
    var score = 0;
    var all = true;
    for (final term in terms) {
      final inTitle = title.contains(term);
      final count = term.allMatches(body).length;
      if (!inTitle && count == 0) {
        all = false;
        break;
      }
      score += (inTitle ? 50 : 0) + (count > 20 ? 20 : count);
    }
    if (all) scored.add((page, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final s in scored) s.$1];
}

/// Extrait du texte autour du premier mot trouvé (liste des résultats).
String helpSnippet(HelpPage page, String query, {int length = 90}) {
  final plain = page.body
      .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'[*`>#!]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
  final terms = helpTerms(query);
  var start = 0;
  if (terms.isNotEmpty) {
    final at = plain.searchKey.indexOf(terms.first);
    if (at > 0) start = at > 30 ? at - 30 : 0;
    if (start > 0) {
      final space = plain.indexOf(' ', start);
      if (space >= 0 && space < start + 15) start = space + 1;
    }
  }
  final end = start + length > plain.length ? plain.length : start + length;
  return '${start > 0 ? '…' : ''}${plain.substring(start, end).trim()}${end < plain.length ? '…' : ''}';
}
