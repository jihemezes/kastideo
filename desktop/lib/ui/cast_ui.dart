import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/cast.dart';
import '../core/youtube.dart';
import '../l10n.dart';
import '../theme.dart';
import 'help_dialog.dart';
import 'settings_dialog.dart';

/// Choix de l'appareil : liste des téléviseurs trouvés, recherche, ajout par adresse IP, arrêt de la diffusion.
Future<void> showCastDialog(BuildContext context) {
  final cast = context.cast;
  cast.clearMessage();
  cast.refresh();
  return showKDialog<void>(context: context, builder: (_) => const DarkZone(child: _CastDialog()));
}

class _CastDialog extends StatelessWidget {
  const _CastDialog();

  @override
  Widget build(BuildContext context) {
    final cast = context.cast;
    final playback = context.playback;
    return Dialog(
      backgroundColor: const Color(0xFF232327),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: ListenableBuilder(
          listenable: cast,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.cast_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(tr('Diffuser sur un téléviseur'), style: kTextD(18, weight: FontWeight.w700))),
                IconButton(
                  tooltip: tr('Chercher à nouveau'),
                  onPressed: cast.searching ? null : cast.refresh,
                  icon: cast.searching
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
                IconButton(
                  tooltip: tr('Aide'),
                  onPressed: () => showHelpDialog(context, page: 'cast'),
                  icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
                ),
              ]),
              const SizedBox(height: 6),
              if (cast.isCasting) ...[
                _Notice(
                  icon: Icons.cast_connected_rounded,
                  text: '${tr('Diffusion en cours sur')} ${cast.active?.name ?? ''}',
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: KPalette.magenta),
                  onPressed: () {
                    cast.stopCasting();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.cancel_presentation_rounded),
                  label: Text(tr('Arrêter la diffusion et reprendre ici')),
                ),
                const SizedBox(height: 14),
              ] else if (playback.current == null) ...[
                _Notice(icon: Icons.info_outline_rounded, text: tr('Lancez d\'abord une chaîne, un film ou une vidéo : elle partira sur le téléviseur choisi.')),
                const SizedBox(height: 10),
              ],
              if (cast.message != null) ...[
                _Notice(icon: Icons.error_outline_rounded, text: cast.message!, warning: true),
                const SizedBox(height: 10),
              ],
              Flexible(
                child: cast.devices.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          cast.searching
                              ? tr('Recherche des téléviseurs…')
                              : tr('Aucun appareil trouvé. Le téléviseur doit être allumé et sur le même réseau que cet ordinateur. Vous pouvez aussi ajouter son adresse IP dans Réglages › Cast.'),
                          style: kTextD(13, color: Colors.white70),
                        ),
                      )
                    : ListView(shrinkWrap: true, children: [
                        for (final d in cast.devices)
                          ListTile(
                            dense: true,
                            leading: Icon(d.canCastVideo ? Icons.tv_rounded : Icons.ondemand_video_rounded, color: Colors.white),
                            title: Text(d.name, style: kTextD(14, weight: FontWeight.w600)),
                            subtitle: Text(
                              d.canCastVideo ? '${d.host} · ${tr('Chromecast / Google TV')}' : '${d.host} · ${tr('YouTube seulement')}',
                              style: kTextD(12, color: Colors.white60),
                            ),
                            trailing: cast.active?.id == d.id ? const Icon(Icons.cast_connected_rounded, color: KPalette.orange) : null,
                            selected: cast.target?.id == d.id,
                            enabled: d.canCastVideo && playback.current != null && !cast.isCasting,
                            onTap: () {
                              Navigator.of(context).pop();
                              cast.start(d);
                            },
                          ),
                      ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSettingsDialog(context, tab: SettingsTab.general);
                  },
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(tr('Réglages Cast')),
                ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('Fermer'))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.warning = false});
  final IconData icon;
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (warning ? Colors.redAccent : KPalette.orange).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: warning ? Colors.redAccent : KPalette.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: kTextD(13))),
        ]),
      );
}

/// Bouton de la barre de lecture : ouvre le choix du téléviseur ; orange pendant une diffusion.
class CastBarButton extends StatelessWidget {
  const CastBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cast = context.cast;
    return ListenableBuilder(
      listenable: cast,
      builder: (context, _) {
        final on = cast.isCasting;
        return Tooltip(
          message: on ? '${tr('Diffusion sur')} ${cast.active?.name ?? ''}' : tr('Diffuser sur un téléviseur (Chromecast, Google TV…)'),
          child: InkResponse(
            onTap: () => showCastDialog(context),
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(on ? Icons.cast_connected_rounded : Icons.cast_rounded, size: 22, color: on ? KPalette.orange : Colors.white),
            ),
          ),
        );
      },
    );
  }
}

/// Remplace l'image pendant la diffusion : où l'on regarde et comment l'arrêter.
class CastPanel extends StatelessWidget {
  const CastPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cast = context.cast;
    final item = context.playback.current;
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cast_connected_rounded, size: 72, color: KPalette.orange),
        const SizedBox(height: 14),
        Text('${tr('Diffusion sur')} ${cast.active?.name ?? tr('le téléviseur')}', style: kTextD(20, weight: FontWeight.w700)),
        if (item != null) ...[
          const SizedBox(height: 6),
          Text(item.name, style: kTextD(14, color: Colors.white70), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 18),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
          onPressed: cast.stopCasting,
          icon: const Icon(Icons.computer_rounded),
          label: Text(tr('Reprendre sur l\'ordinateur')),
        ),
      ]),
    );
  }
}

/// Bandeau d'erreur du Cast quand rien ne joue (message laissé par la dernière tentative).
class CastErrorNotice extends StatelessWidget {
  const CastErrorNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final cast = context.cast;
    return ListenableBuilder(
      listenable: cast,
      builder: (context, _) => cast.message == null || cast.isCasting
          ? const SizedBox.shrink()
          : Positioned(
              top: 60,
              left: 24,
              right: 24,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: GestureDetector(onTap: cast.clearMessage, child: _Notice(icon: Icons.error_outline_rounded, text: cast.message!, warning: true)),
                ),
              ),
            ),
    );
  }
}

/// Appareil pour YouTube : choix rapide parmi les appareils trouvés (menu).
Future<void> castYouTubeFlow(BuildContext context, {required YouTubeVideo video}) async {
  final cast = context.cast;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (cast.settings.castYouTubeMode == 'browser') {
    final error = await cast.castYouTube(video, cast.target ?? const CastDevice(id: 'none', name: '', host: ''));
    if (error != null) messenger?.showSnackBar(SnackBar(content: Text(error)));
    return;
  }
  if (cast.devices.isEmpty) await cast.refresh();
  if (!context.mounted) return;
  final choices = cast.devices.where((d) => d.canCastYouTube).toList();
  if (choices.isEmpty) {
    messenger?.showSnackBar(SnackBar(content: Text(tr('Aucun téléviseur compatible trouvé sur le réseau. Vérifiez qu\'il est allumé, ou utilisez le mode « navigateur » dans Réglages › Cast.'))));
    return;
  }
  CastDevice? chosen = choices.length == 1 ? choices.first : null;
  chosen ??= await showKDialog<CastDevice>(
    context: context,
    builder: (ctx) => DarkZone(
      child: SimpleDialog(
        backgroundColor: const Color(0xFF232327),
        title: Text(tr('Lire YouTube sur…'), style: kTextD(17, weight: FontWeight.w700)),
        children: [
          for (final d in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(d),
              child: Row(children: [const Icon(Icons.tv_rounded, color: Colors.white), const SizedBox(width: 10), Text(d.name, style: kTextD(14))]),
            ),
        ],
      ),
    ),
  );
  if (chosen == null) return;
  cast.choose(chosen);
  final error = await cast.castYouTube(video, chosen);
  messenger?.showSnackBar(SnackBar(content: Text(error ?? '${tr('YouTube lancé sur')} ${chosen.name}')));
}
