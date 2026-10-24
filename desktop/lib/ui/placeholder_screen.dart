import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';
import 'widgets.dart';

/// Écran pas encore porté (Films, Séries) : annonce l'étape où il arrivera.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: KastideoBackground()),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 84, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(height: 14),
            Text(tr(title), style: kRounded(40, FontWeight.w900)),
            const SizedBox(height: 8),
            Text(tr('Arrive à l\'étape 2 de la version Windows / Linux.'),
                style: kText(15, color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: KPalette.magenta),
              onPressed: () => context.navigation.go(Screen.home),
              icon: const Icon(Icons.home_rounded),
              label: Text(tr('Accueil')),
            ),
          ]),
        ),
      ]),
    );
  }
}
