import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/log.dart';
import '../l10n.dart';
import '../theme.dart';
import '../version.dart';

/// Fenêtre « Journal de lecture » (Ctrl+Alt+L), avec bouton Copier.
Future<void> showLogDialog(BuildContext context) => showDialog(context: context, builder: (_) => const _LogDialog());

class _LogDialog extends StatelessWidget {
  const _LogDialog();

  @override
  Widget build(BuildContext context) {
    final log = PlaybackLog.shared;
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(tr('Journal de lecture'), style: kRounded(22, FontWeight.w800)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: log.export(kVersion))),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(tr('Copier')),
              ),
              TextButton(onPressed: log.clear, child: Text(tr('Effacer'))),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer'))),
            ]),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
                child: ListenableBuilder(
                  listenable: log,
                  builder: (context, _) {
                    final lines = log.lines.reversed.toList();
                    return ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: lines.length,
                      itemBuilder: (context, i) {
                        final l = lines[i];
                        final t = l.date;
                        String two(int v) => v.toString().padLeft(2, '0');
                        final color = switch (l.level) { 0 => Colors.redAccent, 1 => Colors.orangeAccent, _ => KPalette.ink70 };
                        return SelectableText(
                          '${two(t.hour)}:${two(t.minute)}:${two(t.second)}  ${l.levelLabel.padRight(6)} ${l.text}',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
