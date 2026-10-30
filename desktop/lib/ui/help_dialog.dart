import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/help.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';

/// Aide intégrée : sommaire par rubriques à gauche, recherche, page à droite. [page] ouvre l'aide à une page précise.
Future<void> showHelpDialog(BuildContext context, {String? page}) =>
    showKDialog(context: context, builder: (_) => _HelpDialog(page: page));

/// Page d'aide qui correspond à l'écran affiché.
String helpPageFor(Screen screen) => switch (screen) {
      Screen.home => 'accueil',
      Screen.live => 'interfaces',
      Screen.movies || Screen.series => 'colonnes',
      Screen.guide => 'guide-grille',
      Screen.recordings => 'enregistrer',
      Screen.multiview => 'multivue',
      Screen.library => 'mes-videos',
      Screen.youtube => 'youtube',
    };

/// Lien discret « Comment faire ? » qui ouvre l'aide à une page précise.
class HelpLink extends StatelessWidget {
  const HelpLink({super.key, required this.label, required this.page});
  final String label;
  final String page;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => showHelpDialog(context, page: page),
        icon: const Icon(Icons.help_outline_rounded, size: 18),
        label: Text(label),
      );
}

class _HelpDialog extends StatefulWidget {
  const _HelpDialog({this.page});
  final String? page;

  @override
  State<_HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<_HelpDialog> {
  List<HelpGroup> _groups = const [];
  String _selected = '';
  String _query = '';
  final _scroll = ScrollController();
  final _recognizers = <TapGestureRecognizer>[];

  List<HelpPage> get _pages => [for (final g in _groups) ...g.pages];
  List<String> get _terms => helpTerms(_query);

  @override
  void initState() {
    super.initState();
    rootBundle.loadString(L10n.english ? 'assets/help/aide.en.md' : 'assets/help/aide.fr.md').then((text) {
      if (!mounted) return;
      final groups = parseHelp(text);
      final pages = [for (final g in groups) ...g.pages];
      setState(() {
        _groups = groups;
        _selected = pages.any((p) => p.id == widget.page) ? widget.page! : (pages.isEmpty ? '' : pages.first.id);
      });
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _select(String id) {
    if (!_pages.any((p) => p.id == id)) return;
    setState(() => _selected = id);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final results = searchHelp(_groups, _query);
    final searching = _terms.isNotEmpty;
    return Dialog(
      backgroundColor: KPalette.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(tr('Aide'), style: kRounded(24, FontWeight.w800)),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    style: kText(13),
                    onChanged: (v) => setState(() {
                      _query = v;
                      final found = searchHelp(_groups, v);
                      if (found.isNotEmpty && !found.any((p) => p.id == _selected)) {
                        _selected = found.first.id;
                        if (_scroll.hasClients) _scroll.jumpTo(0);
                      }
                    }),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: KPalette.ink.withValues(alpha: 0.07),
                      prefixIcon: Icon(Icons.search_rounded, size: 16, color: KPalette.ink54),
                      hintText: tr('Rechercher dans l\'aide'),
                      hintStyle: kText(13, color: KPalette.ink38),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer'))),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 260, child: searching ? _results(results) : _toc()),
                VerticalDivider(width: 24, color: KPalette.separator),
                Expanded(child: _content()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // Sommaire par rubriques.
  Widget _toc() => ListView(children: [
        for (final group in _groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            child: Text(group.title.toUpperCase(), style: kText(11, weight: FontWeight.w700, color: KPalette.ink54)),
          ),
          for (final page in group.pages) _tocRow(page, page.title),
        ],
      ]);

  Widget _tocRow(HelpPage page, String label, {String? subtitle}) {
    final current = page.id == _selected;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _select(page.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: current ? KPalette.accent.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: kText(13, weight: current ? FontWeight.w600 : FontWeight.w400, color: current ? KPalette.accent : null)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: kText(11, color: KPalette.secondaryText)),
          ],
        ]),
      ),
    );
  }

  // Résultats de recherche.
  Widget _results(List<HelpPage> results) {
    if (results.isEmpty) {
      return Center(child: Text(tr('Aucun résultat'), style: kText(14, color: KPalette.secondaryText)));
    }
    return ListView(children: [
      for (final page in results) _tocRow(page, page.title, subtitle: '${page.group} · ${helpSnippet(page, _query)}'),
    ]);
  }

  // Page affichée.
  Widget _content() {
    final pages = _pages;
    final index = pages.indexWhere((p) => p.id == _selected);
    if (index < 0) return const SizedBox.shrink();
    final page = pages[index];
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.only(right: 18, bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(page.group.toUpperCase(), style: kText(11, weight: FontWeight.w700, color: KPalette.accent)),
          const SizedBox(height: 4),
          Text(page.title, style: kRounded(28, FontWeight.w900)),
          const SizedBox(height: 10),
          for (final block in parseHelpBlocks(page.body)) _block(block),
          const SizedBox(height: 18),
          Divider(color: KPalette.separator),
          Row(children: [
            if (index > 0)
              TextButton.icon(
                onPressed: () => _select(pages[index - 1].id),
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: Text(pages[index - 1].title),
              ),
            const Spacer(),
            if (index + 1 < pages.length)
              TextButton(
                onPressed: () => _select(pages[index + 1].id),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(pages[index + 1].title),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ]),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _block(HelpBlock block) {
    switch (block.type) {
      case HelpBlockType.heading:
        return Padding(padding: const EdgeInsets.only(top: 14, bottom: 4), child: _rich(block.text, kText(17, weight: FontWeight.w700)));
      case HelpBlockType.paragraph:
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: _rich(block.text, kText(14)));
      case HelpBlockType.bullet:
        return Padding(
          padding: EdgeInsets.only(left: 6.0 + block.level * 18, bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(block.level == 0 ? '•  ' : '◦  ', style: kText(14, color: KPalette.accent)),
            Expanded(child: _rich(block.text, kText(14))),
          ]),
        );
      case HelpBlockType.numbered:
        return Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 24, child: Text('${block.number}.', style: kText(14, weight: FontWeight.w600, color: KPalette.accent))),
            Expanded(child: _rich(block.text, kText(14))),
          ]),
        );
      case HelpBlockType.note:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: KPalette.accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_outline_rounded, size: 16, color: KPalette.accent),
            const SizedBox(width: 8),
            Expanded(child: _rich(block.text, kText(13, color: KPalette.ink70))),
          ]),
        );
      case HelpBlockType.image:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/help/img/help-${block.name}-${L10n.english ? 'en' : 'fr'}.png',
                  semanticLabel: block.text,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      case HelpBlockType.rule:
        return Divider(color: KPalette.separator);
    }
  }

  /// Texte avec **gras**, `code` et [liens](help:page) ou (https://…), les mots recherchés surlignés.
  Widget _rich(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`|\[([^\]]+)\]\(([^)]+)\)');
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) spans.addAll(_highlight(text.substring(last, m.start), base));
      if (m.group(1) != null) {
        spans.addAll(_highlight(m.group(1)!, base.copyWith(fontWeight: FontWeight.w700, fontVariations: const [FontVariation('wght', 700)])));
      } else if (m.group(2) != null) {
        spans.addAll(_highlight(m.group(2)!, base.copyWith(fontFamily: 'monospace', backgroundColor: KPalette.ink.withValues(alpha: 0.08))));
      } else {
        final target = m.group(4)!;
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (target.startsWith('help:')) {
              _select(target.substring(5));
            } else {
              launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
            }
          };
        _recognizers.add(recognizer);
        spans.add(TextSpan(
          text: m.group(3)!,
          style: base.copyWith(color: KPalette.accent, decoration: TextDecoration.underline, decorationColor: KPalette.accent),
          recognizer: recognizer,
          mouseCursor: SystemMouseCursors.click,
        ));
      }
      last = m.end;
    }
    if (last < text.length) spans.addAll(_highlight(text.substring(last), base));
    return Text.rich(TextSpan(children: spans));
  }

  List<InlineSpan> _highlight(String text, TextStyle style) {
    final terms = _terms;
    if (terms.isEmpty) return [TextSpan(text: text, style: style)];
    // Repère chaque occurrence de chaque mot (comparaison sans accents ni majuscules, longueurs conservées).
    final lower = _fold1(text);
    final marked = List<bool>.filled(text.length, false);
    for (final term in terms) {
      var from = 0;
      while (true) {
        final at = lower.indexOf(term, from);
        if (at < 0) break;
        for (var i = at; i < at + term.length && i < marked.length; i++) {
          marked[i] = true;
        }
        from = at + term.length;
      }
    }
    final result = <InlineSpan>[];
    var i = 0;
    while (i < text.length) {
      var j = i;
      while (j < text.length && marked[j] == marked[i]) {
        j++;
      }
      final style2 = marked[i] ? style.copyWith(backgroundColor: KPalette.orange.withValues(alpha: 0.35)) : style;
      result.add(TextSpan(text: text.substring(i, j), style: style2));
      i = j;
    }
    return result;
  }
}

/// Minuscules et sans accents, caractère par caractère (la longueur du texte est conservée).
String _fold1(String text) {
  final b = StringBuffer();
  for (final rune in text.runes) {
    final c = String.fromCharCode(rune);
    final k = c.searchKey;
    b.write(k.length == c.length ? k : c);
  }
  return b.toString();
}
