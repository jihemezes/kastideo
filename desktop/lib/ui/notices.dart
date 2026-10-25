import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../app_state.dart';
import '../core/alerts.dart';
import '../l10n.dart';
import '../theme.dart';
import 'themes_view.dart';
import 'widgets.dart';

/// Messages en haut à droite : alertes de programme (« ça commence ») et informations d'enregistrement.
class NoticeOverlay extends StatefulWidget {
  const NoticeOverlay({super.key});

  @override
  State<NoticeOverlay> createState() => _NoticeOverlayState();
}

class _NoticeOverlayState extends State<NoticeOverlay> {
  int _seen = 0;

  @override
  Widget build(BuildContext context) => DarkZone(child: Builder(builder: _buildDark));

  Widget _buildDark(BuildContext context) {
    final alerts = context.alerts;
    final recordings = context.recordings;
    return ListenableBuilder(
      listenable: Listenable.merge([alerts, recordings]),
      builder: (context, _) {
        if (alerts.pending.length > _seen) {
          // Nouvelle alerte : la fenêtre revient au premier plan si elle était réduite.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              if (await windowManager.isMinimized()) await windowManager.restore();
            } catch (_) {}
          });
        }
        _seen = alerts.pending.length;
        final notice = recordings.notice;
        return Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final a in alerts.pending.reversed.take(3)) _AlertCard(alert: a),
                if (notice != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xF02C2C2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record_rounded, size: 14, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Flexible(child: Text(notice, style: kTextD(13))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final FiredAlert alert;

  @override
  Widget build(BuildContext context) {
    final p = alert.programme;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xF22C2C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KPalette.orange.withValues(alpha: 0.6)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18)],
        ),
        child: Row(
          children: [
            LogoView(url: alert.channel.logo, name: alert.channel.name, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, size: 14, color: KPalette.orange),
                      const SizedBox(width: 5),
                      Text(
                        p.start.isAfter(DateTime.now()) ? '${tr('À')} ${hm(p.start)}' : tr('Ça commence'),
                        style: kTextD(11, weight: FontWeight.w700, color: KPalette.orange),
                      ),
                    ],
                  ),
                  Text(
                    p.title,
                    style: kTextD(14, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(alert.channel.displayName, style: kTextD(12, color: KPalette.secondaryDark), maxLines: 1),
                ],
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: KPalette.accentDark, visualDensity: VisualDensity.compact),
              onPressed: () {
                context.alerts.dismiss(alert);
                openItem(context, alert.channel);
              },
              child: Text(tr('Regarder')),
            ),
            IconButton(
              tooltip: tr('Fermer'),
              visualDensity: VisualDensity.compact,
              onPressed: () => context.alerts.dismiss(alert),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
