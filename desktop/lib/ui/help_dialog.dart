import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../theme.dart';

/// Aide intégrée (fichier Markdown simple, en français ou en anglais).
Future<void> showHelpDialog(BuildContext context) => showDialog(context: context, builder: (_) => const _HelpDialog());

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF242426),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
        child: FutureBuilder<String>(
          future: rootBundle.loadString(L10n.english ? 'assets/help/AIDE.en.md' : 'assets/help/AIDE.md'),
          builder: (context, snapshot) => Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(tr('Aide'), style: kRounded(24, FontWeight.w800)),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer'))),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final line in (snapshot.data ?? '').split('\n')) _line(line)],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Rendu Markdown minimal : titres, puces, citations, paragraphes (le gras ** est retiré).
  Widget _line(String raw) {
    final text = raw.replaceAll('**', '').replaceAll('`', '');
    if (text.startsWith('# ')) {
      return Padding(padding: const EdgeInsets.only(top: 6, bottom: 8), child: Text(text.substring(2), style: kRounded(26, FontWeight.w900)));
    }
    if (text.startsWith('## ')) {
      return Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(text.substring(3), style: kRounded(19, FontWeight.w800)));
    }
    if (text.startsWith('### ')) {
      return Padding(padding: const EdgeInsets.only(top: 10, bottom: 4), child: Text(text.substring(4), style: kText(15, weight: FontWeight.w700)));
    }
    if (text.startsWith('> ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text.substring(2), style: kText(13, color: KPalette.secondaryText)),
      );
    }
    if (text.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('•  ', style: kText(14, color: KPalette.orange)),
          Expanded(child: Text(text.substring(2), style: kText(14))),
        ]),
      );
    }
    if (text.trim().isEmpty) return const SizedBox(height: 6);
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(text, style: kText(14)));
  }
}
