import 'dart:io';

import 'package:flutter/gestures.dart';
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
        color: KPalette.ink.withValues(alpha: 0.06),
        child: url == null
            ? fallback
            : url!.startsWith('file:')
                ? Image.file(File.fromUri(Uri.parse(url!)), width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback)
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

/// Affiche (film, série) : image du fournisseur ou de TMDB, sinon dégradé avec le titre.
class PosterImage extends StatelessWidget {
  const PosterImage({super.key, required this.url, required this.name, required this.width, required this.height, this.fit = BoxFit.cover});
  final String? url;
  final String name;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.08),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF383838), Color(0xFF1C1C1C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: width < 60
          ? Text(initials(name), style: kRounded(width * 0.32, FontWeight.w800, color: KPalette.ink70))
          : Text(cleanTitle(name).title,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: kRounded(width * 0.11, FontWeight.w800, color: KPalette.ink70)),
    );
    if (url == null) return fallback;
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: (width * 2).round(),
      filterQuality: FilterQuality.medium,
      headers: const {'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20'},
      errorBuilder: (_, _, _) => fallback,
      frameBuilder: (context, child, frame, sync) => frame == null && !sync ? fallback : child,
    );
  }
}

/// Défilement à la souris : les rangées horizontales se font aussi glisser avec la souris.
class KastideoScrollBehavior extends MaterialScrollBehavior {
  const KastideoScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices =>
      {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus};
}

/// Ligne horizontale qui défile aussi avec la molette verticale (pastilles de filtres).
class WheelRow extends StatefulWidget {
  const WheelRow({super.key, required this.children});
  final List<Widget> children;

  @override
  State<WheelRow> createState() => _WheelRowState();
}

class _WheelRowState extends State<WheelRow> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerSignal: (event) {
          if (event is! PointerScrollEvent || !_controller.hasClients) return;
          final delta = event.scrollDelta.dy.abs() > event.scrollDelta.dx.abs() ? event.scrollDelta.dy : event.scrollDelta.dx;
          final position = _controller.position;
          _controller.jumpTo((position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent));
        },
        child: SingleChildScrollView(controller: _controller, scrollDirection: Axis.horizontal, child: Row(children: widget.children)),
      );
}
