import 'package:flutter/material.dart';

/// Couleurs de Kastideo (mêmes valeurs que KastideoPalette sur Mac).
class KPalette {
  static const night = Color.fromRGBO(15, 5, 36, 1); // 0.06, 0.02, 0.14
  static const indigo = Color.fromRGBO(43, 33, 148, 1); // 0.17, 0.13, 0.58
  static const violet = Color.fromRGBO(87, 26, 140, 1); // 0.34, 0.10, 0.55
  static const magenta = Color.fromRGBO(204, 41, 133, 1); // 0.80, 0.16, 0.52
  static const orange = Color.fromRGBO(255, 153, 51, 1); // 1.00, 0.60, 0.20

  // Interface sombre façon macOS.
  static const window = Color(0xFF1E1E1E);
  static const sidebar = Color(0xFF262328);
  static const list = Color(0xFF1B1B1D);
  static const separator = Color(0x22FFFFFF);
  static const accent = Color(0xFF0A84FF); // accent système de macOS (sombre)
  static const secondaryText = Color(0x99FFFFFF);
}

/// Styles de texte : Nunito (arrondie, comme SF Pro Rounded) pour les titres, Inter pour le reste.
TextStyle kRounded(double size, FontWeight weight, {Color color = Colors.white}) => TextStyle(
      fontFamily: 'Nunito',
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: 1.1,
    );

TextStyle kText(double size, {FontWeight weight = FontWeight.w400, Color color = Colors.white}) => TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
    );

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(seedColor: KPalette.accent, brightness: Brightness.dark)
        .copyWith(primary: KPalette.accent, secondary: KPalette.orange, surface: KPalette.window),
    scaffoldBackgroundColor: KPalette.window,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.white.withValues(alpha: 0.06),
    tooltipTheme: TooltipThemeData(
      textStyle: kText(12),
      decoration: BoxDecoration(color: const Color(0xEE2C2C2E), borderRadius: BorderRadius.circular(6)),
      waitDuration: const Duration(milliseconds: 600),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 3,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(foregroundColor: Colors.white, textStyle: kText(13, weight: FontWeight.w600)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? KPalette.accent : Colors.white24),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    chipTheme: ChipThemeData(
      selectedColor: Colors.white.withValues(alpha: 0.18),
      backgroundColor: Colors.transparent,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      labelStyle: kText(13),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white.withValues(alpha: 0.18) : null),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? Colors.white30 : Colors.white),
      ),
    ),
    dividerColor: KPalette.separator,
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(3),
      thumbColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.25)),
    ),
  );
  return base;
}
