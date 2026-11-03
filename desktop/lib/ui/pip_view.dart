import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/multiview.dart';
import '../l10n.dart';
import '../theme.dart';
import 'multiview_view.dart';

/// Miniature flottante dans le coin du lecteur : un clic l'échange avec la lecture principale.
class PipOverlay extends StatefulWidget {
  const PipOverlay({super.key});

  @override
  State<PipOverlay> createState() => _PipOverlayState();
}

class _PipOverlayState extends State<PipOverlay> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final pip = PipController.shared;
    return ListenableBuilder(
      listenable: pip,
      builder: (context, _) {
        final slot = pip.slot;
        if (slot == null) return const SizedBox.shrink();
        return Positioned(
          right: 16,
          bottom: 96,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: () => pip.swap(context.playback),
              child: Container(
                width: 260,
                height: 146,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white54, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                ),
                clipBehavior: Clip.antiAlias,
                child: ListenableBuilder(
                  listenable: slot,
                  builder: (context, _) => Stack(fit: StackFit.expand, children: [
                    if (slot.item != null) Video(controller: slot.video, controls: NoVideoControls, fill: Colors.black),
                    if (slot.loading) const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    if (slot.failed)
                      Center(child: Text(tr('Flux refusé'), style: kTextD(12, color: KPalette.orange))),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 4, 4, 14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xBF000000), Colors.transparent]),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(slot.item?.displayName ?? '', style: kTextD(12, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (_hover) ...[
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              tooltip: tr('Échanger avec la lecture principale'),
                              onPressed: () => pip.swap(context.playback),
                              icon: const Icon(Icons.open_in_full_rounded, color: Colors.white),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              tooltip: tr('Fermer la miniature'),
                              onPressed: pip.close,
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bouton « Image dans l'image » (chaînes en direct) : choix de la seconde chaîne, ou fermeture de la miniature.
class PipButton extends StatelessWidget {
  const PipButton({super.key});

  @override
  Widget build(BuildContext context) {
    final pip = PipController.shared;
    return ListenableBuilder(
      listenable: pip,
      builder: (context, _) => Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: pip.isOpen ? tr('Fermer la miniature') : tr('Image dans l\'image : une seconde chaîne en miniature'),
          icon: Icon(pip.isOpen ? Icons.picture_in_picture_rounded : Icons.picture_in_picture_alt_rounded, color: Colors.white),
          onPressed: () async {
            if (pip.isOpen) {
              await pip.close();
              return;
            }
            final playback = context.playback;
            final library = context.library;
            final settings = context.settings;
            final item = await pickMultiViewChannel(context, canPick: (i) => pip.canOpen(i, playback, library, settings));
            if (item != null) await pip.open(item, playback, library, settings);
            if (pip.message != null && context.mounted) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(pip.message!)));
            }
          },
        ),
      ),
    );
  }
}

/// Vrai si le bouton PIP peut être proposé : chaîne en direct et au moins deux flux possibles en tout.
bool pipAvailable(BuildContext context, MediaItem? current) =>
    current != null && current.kind == MediaKind.live && context.settings.multiviewAvailableFor(context.library.selectableSources);
