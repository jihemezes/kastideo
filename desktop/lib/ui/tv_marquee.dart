import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Texte d'une seule ligne pour la télécommande : s'il est trop long pour son bouton, il est tronqué (…) tant que le
/// bouton n'est pas sélectionné, puis défile doucement dans le bouton une fois sélectionné, pour pouvoir le lire en entier.
class TvMarquee extends StatefulWidget {
  const TvMarquee(this.text, {super.key, required this.style, required this.active, this.textAlign = TextAlign.start});
  final String text;
  final TextStyle style;

  /// Vrai quand le bouton est sélectionné : le texte défile alors s'il dépasse.
  final bool active;
  final TextAlign textAlign;

  @override
  State<TvMarquee> createState() => _TvMarqueeState();
}

class _TvMarqueeState extends State<TvMarquee> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  double _overflow = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Cycle : pause, défilement jusqu'à la fin, pause, retour au début.
  void _sync() {
    if (widget.active && _overflow > 0) {
      if (!_controller.isAnimating) {
        final scroll = (_overflow / 45 * 1000).round().clamp(900, 12000);
        _controller
          ..duration = Duration(milliseconds: 700 + scroll + 900 + 350)
          ..repeat();
      }
    } else if (_controller.isAnimating || _controller.value != 0) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didUpdateWidget(TvMarquee old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active || old.text != widget.text) {
      if (!widget.active) _controller.stop();
      _controller.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sync();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plain = Text(widget.text, style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: widget.textAlign);
    return LayoutBuilder(builder: (context, box) {
      if (!box.hasBoundedWidth) return plain;
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      final overflow = painter.width - box.maxWidth;
      painter.dispose();
      final newOverflow = overflow > 1 ? overflow + 6 : 0.0;
      if (newOverflow != _overflow) {
        _overflow = newOverflow;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _sync();
        });
      }
      if (!widget.active || _overflow <= 0) return plain;
      final total = _controller.duration?.inMilliseconds ?? 1;
      final scroll = total - 700 - 900 - 350;
      return ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * total;
            double offset;
            if (t < 700) {
              offset = 0;
            } else if (t < 700 + scroll) {
              offset = _overflow * Curves.easeInOut.transform((t - 700) / scroll);
            } else if (t < 700 + scroll + 900) {
              offset = _overflow;
            } else {
              offset = _overflow * (1 - Curves.easeInOut.transform(math.min(1, (t - 700 - scroll - 900) / 350)));
            }
            return OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(-offset, 0),
                child: Text(widget.text, style: widget.style, maxLines: 1, softWrap: false),
              ),
            );
          },
        ),
      );
    });
  }
}
