import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/help.dart';

const sample = '''
Texte avant les rubriques (ignoré).

# Démarrer

## Bienvenue {#bienvenue}

Raccourci <!--mac-->**⌘9**<!--/mac--><!--pc-->**Ctrl+9**<!--/pc--> partout.

<!--mac-->
1. Ouvrez les Réglages.
<!--/mac-->
<!--pc-->
1. Ouvrez la roue dentée.
<!--/pc-->

## Réservé Mac {#mac-seul}

<!--mac-->
Contenu pour Mac.
<!--/mac-->

# Sources

## Xtream {#xtream}

### Étape
- Un
  - Sous-point
> Une note
> sur deux lignes
![Schéma](img:home)
Voir [la clé](help:youtube-cle).
''';

void main() {
  test('filtre de plateforme : les blocs Mac disparaissent', () {
    final groups = parseHelp(sample);
    expect(groups.map((g) => g.title), ['Démarrer', 'Sources']);
    expect(groups[0].pages.map((p) => p.id), ['bienvenue']);
    final body = groups[0].pages[0].body;
    expect(body, contains('Ctrl+9'));
    expect(body, isNot(contains('⌘')));
    expect(body, contains('roue dentée'));
    expect(body, isNot(contains('<!--')));
  });

  test('blocs de contenu', () {
    final blocks = parseHelpBlocks(parseHelp(sample)[1].pages[0].body);
    expect(blocks[0].type, HelpBlockType.heading);
    expect(blocks[1].type, HelpBlockType.bullet);
    expect(blocks[1].level, 0);
    expect(blocks[2].level, 1);
    expect(blocks[3].type, HelpBlockType.note);
    expect(blocks[3].text, 'Une note sur deux lignes');
    expect(blocks[4].type, HelpBlockType.image);
    expect(blocks[4].name, 'home');
    expect(blocks[5].text, 'Voir [la clé](help:youtube-cle).');
    final numbered = parseHelpBlocks('1. Un\n2. Deux');
    expect(numbered.map((b) => b.number), [1, 2]);
  });

  test('recherche sans accents ni majuscules', () {
    final groups = parseHelp(sample);
    expect(searchHelp(groups, 'ROUE dentee').map((p) => p.id), ['bienvenue']);
    expect(searchHelp(groups, 'etape sous').map((p) => p.id), ['xtream']);
    expect(searchHelp(groups, 'a'), isEmpty);
    expect(searchHelp(groups, 'introuvable'), isEmpty);
    expect(helpSnippet(groups[0].pages[0], 'roue'), contains('roue'));
  });

  for (final lang in ['fr', 'en']) {
    test('aide embarquée ($lang) : liens internes valides, pas de marqueur, copie identique à docs/help', () {
      final source = File('assets/help/aide.$lang.md').readAsStringSync();
      final groups = parseHelp(source);
      final pages = [for (final g in groups) ...g.pages];
      final ids = pages.map((p) => p.id).toSet();
      expect(ids.length, greaterThan(40));
      expect(ids.length, pages.length, reason: 'identifiants uniques');
      for (final page in pages) {
        expect(page.body, isNot(contains('<!--')), reason: page.id);
        for (final m in RegExp(r'\]\(help:([^)]+)\)').allMatches(page.body)) {
          expect(ids, contains(m.group(1)), reason: '${page.id} → ${m.group(1)}');
        }
        for (final m in RegExp(r'\(img:([^)]+)\)').allMatches(page.body)) {
          expect(File('assets/help/img/help-${m.group(1)}-$lang.png').existsSync(), isTrue, reason: '${page.id} image ${m.group(1)}');
        }
      }
      final shared = File('../docs/help/aide.$lang.md');
      if (shared.existsSync()) {
        expect(shared.readAsStringSync(), source, reason: 'lancez scripts/sync-help.sh');
      }
    });
  }
}
