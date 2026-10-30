import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';

/// Page Ko-fi : soutien volontaire (Kastideo reste gratuit).
final Uri kKofiUrl = Uri.parse('https://ko-fi.com/jihemezes');

/// Petit bouton discret « Offrir un café ». `always` : visible même si l'utilisateur a masqué les boutons
/// (page À propos). `onDark` : sur un fond sombre fixe (accueil).
class SupportButton extends StatelessWidget {
  const SupportButton({super.key, this.always = false, this.onDark = false});
  final bool always;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        if (!always && settings.hideSupport) return const SizedBox.shrink();
        final fg = onDark ? Colors.white.withValues(alpha: 0.75) : KPalette.accent;
        return Tooltip(
          message: tr('Kastideo reste gratuit. Un café pour soutenir son développement ? (Ko-fi)'),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => launchUrl(kKofiUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: onDark ? Colors.white.withValues(alpha: 0.12) : KPalette.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.local_cafe_rounded, size: 14, color: fg),
                const SizedBox(width: 6),
                Text(tr('Offrir un café'), style: onDark ? kTextD(12, color: fg) : kText(12, color: fg)),
              ]),
            ),
          ),
        );
      },
    );
  }
}
