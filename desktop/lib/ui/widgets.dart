import 'package:flutter/material.dart';

import '../core/text.dart';
import '../theme.dart';

/// Construit un widget différent au survol de la souris.
class Hover extends StatefulWidget {
  const Hover({super.key, required this.builder, this.onTap, this.cursor = SystemMouseCursors.click});
  final Widget Function(BuildContext context, bool hovering) builder;
  final VoidCallback? onTap;
  final MouseCursor cursor;

  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : widget.cursor,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _hovering),
      ),
    );
  }
}

/// Logo de chaîne (image du fournisseur, sinon initiales sur fond dégradé).
class LogoView extends StatelessWidget {
  const LogoView({super.key, required this.url, required this.name, this.size = 36});
  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: name, size: size);
    final radius = BorderRadius.circular(size * 0.22);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: Colors.white.withValues(alpha: 0.06),
        child: url == null
            ? fallback
            : Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.contain,
                cacheWidth: (size * 2).round(),
                filterQuality: FilterQuality.medium,
                headers: const {'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20'},
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
              ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hue = (name.hashCode % 360).abs().toDouble();
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [HSLColor.fromAHSL(1, hue, 0.45, 0.32).toColor(), HSLColor.fromAHSL(1, (hue + 40) % 360, 0.5, 0.22).toColor()],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(initials(name), style: kRounded(size * 0.36, FontWeight.w800)),
    );
  }
}

/// Fond dégradé de l'accueil (mêmes dégradés que la version Mac).
class KastideoBackground extends StatelessWidget {
  const KastideoBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [KPalette.night, Color.fromRGBO(87, 26, 140, 0.9), KPalette.night],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomRight,
            radius: 1.1,
            colors: [KPalette.magenta.withValues(alpha: 0.45), Colors.transparent],
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 0.8,
            colors: [KPalette.orange.withValues(alpha: 0.18), Colors.transparent],
          ),
        ),
      ),
    ]);
  }
}
