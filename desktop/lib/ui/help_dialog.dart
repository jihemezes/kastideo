import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';

/// Aide intégrée (fichier Markdown simple, en français ou en anglais) : sommaire à gauche, recherche, texte à droite.
Future<void> showHelpDialog(BuildContext context) => showKDialog(context: context, builder: (_) => const _HelpDialog());

/// Section de l'aide (titre de niveau 2 et ses lignes).
class _Section {
  _Section(this.title);
  final String title;
  final List<String> lines = [];
  final key = GlobalKey();
}

class _HelpDialog extends StatefulWidget {
  const _HelpDialog();

  @override
  State<_HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<_HelpDialog> {
  List<String> _intro = const [];
  List<_Section> _sections = const [];
  String _query = '';
  int _current = 0;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    rootBundle.loadString(L10n.english ? 'assets/help/AIDE.en.md' : 'assets/help/AIDE.md').then((text) {
      final intro = <String>[];
      final sections = <_Section>[];
      for (final line in text.split('\n')) {
        if (line.startsWith('## ')) {
          sections.add(_Section(line.substring(3).trim()));
        } else if (sections.isEmpty) {
          intro.add(line);
        } else {
          sections.last.lines.add(line);
        }
      }
      if (mounted) {
        setState(() {
          _intro = intro;
          _sections = sections;
        });
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _matches(_Section s) {
    final q = _query.trim();
    if (q.length < 2) return true;
    final key = q.searchKey;
    return s.title.searchKey.contains(key) || s.lines.any((l) => l.searchKey.contains(key));
  }

  void _jump(int index) {
    setState(() => _current = index);
    final ctx = _sections[index].key.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final visible = [for (var i = 0; i < _sections.length; i++) if (_matches(_sections[i])) i];
    return Dialog(
      backgroundColor: KPalette.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 740),
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
                    onChanged: (v) => setState(() => _query = v),
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
                // Sommaire.
                SizedBox(
                  width: 230,
                  child: ListView(children: [
                    for (final i in visible)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _jump(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _current == i ? KPalette.accent.withValues(alpha: 0.16) : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_sections[i].title,
                              style: kText(13, weight: _current == i ? FontWeight.w600 : FontWeight.w400, color: _current == i ? KPalette.accent : null)),
                        ),
                      ),
                  ]),
                ),
                VerticalDivider(width: 24, color: KPalette.separator),
                Expanded(
                  child: Scrollbar(
                    controller: _scroll,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.only(right: 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (_query.trim().length < 2) for (final line in _intro) _line(line),
                        for (final i in visible) ...[
                          Padding(
                            key: _sections[i].key,
                            padding: const EdgeInsets.only(top: 16, bottom: 6),
                            child: Text(_sections[i].title, style: kRounded(20, FontWeight.w800)),
                          ),
                          for (final line in _sections[i].lines) _line(line),
                        ],
                        if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(tr('Aucun résultat'), style: kText(14, color: KPalette.secondaryText)),
                          ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// Texte avec **gras** et `code`, et les mots recherchés surlignés.
  Widget _rich(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) spans.addAll(_highlight(text.substring(last, m.start), base));
      if (m.group(1) != null) {
        spans.addAll(_highlight(m.group(1)!, base.copyWith(fontWeight: FontWeight.w700, fontVariations: const [FontVariation('wght', 700)])));
      } else {
        spans.addAll(_highlight(m.group(2)!, base.copyWith(fontFamily: 'monospace', backgroundColor: KPalette.ink.withValues(alpha: 0.08))));
      }
      last = m.end;
    }
    if (last < text.length) spans.addAll(_highlight(text.substring(last), base));
    return Text.rich(TextSpan(children: spans));
  }

  List<InlineSpan> _highlight(String text, TextStyle style) {
    final q = _query.trim();
    if (q.length < 2) return [TextSpan(text: text, style: style)];
    final lower = text.toLowerCase();
    final needle = q.toLowerCase();
    final result = <InlineSpan>[];
    var i = 0;
    while (true) {
      final j = lower.indexOf(needle, i);
      if (j < 0) break;
      if (j > i) result.add(TextSpan(text: text.substring(i, j), style: style));
      result.add(TextSpan(text: text.substring(j, j + needle.length), style: style.copyWith(backgroundColor: KPalette.orange.withValues(alpha: 0.35))));
      i = j + needle.length;
    }
    if (i < text.length) result.add(TextSpan(text: text.substring(i), style: style));
    return result;
  }

  /// Rendu Markdown simple : titres, puces (et sous-puces), listes numérotées, encadrés « > », paragraphes.
  Widget _line(String raw) {
    final text = raw.trimRight();
    if (text.startsWith('# ')) {
      return Padding(padding: const EdgeInsets.only(top: 2, bottom: 8), child: Text(text.substring(2), style: kRounded(26, FontWeight.w900)));
    }
    if (text.startsWith('### ')) {
      return Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(text.substring(4), style: kText(15, weight: FontWeight.w700)));
    }
    if (text.startsWith('> ')) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: KPalette.accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: KPalette.accent),
          const SizedBox(width: 8),
          Expanded(child: _rich(text.substring(2), kText(13, color: KPalette.ink70))),
        ]),
      );
    }
    final bullet = RegExp(r'^(\s*)- (.*)$').firstMatch(text);
    if (bullet != null) {
      final level = bullet.group(1)!.length ~/ 2;
      return Padding(
        padding: EdgeInsets.only(left: 6.0 + level * 18, bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(level == 0 ? '•  ' : '◦  ', style: kText(14, color: KPalette.accent)),
          Expanded(child: _rich(bullet.group(2)!, kText(14))),
        ]),
      );
    }
    final numbered = RegExp(r'^(\d+)\. (.*)$').firstMatch(text);
    if (numbered != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 22, child: Text('${numbered.group(1)}.', style: kText(14, weight: FontWeight.w600, color: KPalette.accent))),
          Expanded(child: _rich(numbered.group(2)!, kText(14))),
        ]),
      );
    }
    if (text.trim().isEmpty) return const SizedBox(height: 6);
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: _rich(text, kText(14)));
  }
}
