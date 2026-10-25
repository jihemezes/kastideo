import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../l10n.dart';
import '../theme.dart';
import 'catalog_screen.dart';
import 'guide_view.dart';
import 'player_pane.dart';
import 'settings_dialog.dart';
import 'themes_view.dart';
import 'widgets.dart';

/// Interface « TV » du direct (comme TVRootView sur Mac) : chaîne en plein cadre, panneau des chaînes,
/// bandeau d'information, zapping par numéro ou avec les flèches.
class TVView extends StatefulWidget {
  const TVView({super.key});

  @override
  State<TVView> createState() => _TVViewState();
}

class _TVViewState extends State<TVView> {
  ChannelFilter _filter = const AllChannels();
  final _query = TextEditingController();
  final _focus = FocusNode();
  final _searchFocus = FocusNode();
  final _listController = ScrollController();
  bool _panel = false;
  bool _banner = false;
  bool _topBar = true;
  String _typed = '';
  String? _notice;
  String? _previousId;
  Timer? _panelTimer, _bannerTimer, _typeTimer, _noticeTimer, _topTimer, _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWithLastChannel());
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => mounted && _banner ? setState(() {}) : null);
    _pokeTopBar();
    HardwareKeyboard.instance.addHandler(_hardwareKey);
  }

  /// Touches captées avant le système de focus (comme le moniteur clavier de la version Mac) :
  /// les flèches ne sont ainsi jamais prises par un autre contrôle (volume, listes…).
  bool _hardwareKey(KeyEvent event) {
    if (!mounted) return false;
    // Une fenêtre (réglages, fiche…) est ouverte par-dessus : on laisse faire.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final editing = focusContext != null &&
        (focusContext.widget is EditableText || focusContext.findAncestorWidgetOfExactType<EditableText>() != null);
    if (editing && !_searchFocus.hasFocus) return false;
    return _onKey(_focus, event) == KeyEventResult.handled;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hardwareKey);
    for (final t in [_panelTimer, _bannerTimer, _typeTimer, _noticeTimer, _topTimer, _clock]) {
      t?.cancel();
    }
    _query.dispose();
    _focus.dispose();
    _searchFocus.dispose();
    _listController.dispose();
    super.dispose();
  }

  MediaItem? get _current {
    final item = context.playback.current;
    return item?.kind == MediaKind.live ? item : null;
  }

  List<MediaItem> get _channels => channelsFor(context, _filter, _query.text);

  /// À l'ouverture : reprend la chaîne en cours ou la dernière regardée, sinon ouvre le panneau.
  void _startWithLastChannel() {
    if (!mounted) return;
    if (_current != null) {
      _flashBanner();
      return;
    }
    final last = context.library.recentsOf(MediaKind.live).firstOrNull;
    if (last != null) {
      _select(last);
    } else {
      _openPanel();
    }
  }

  // MARK: Actions

  Future<void> _select(MediaItem item) async {
    if (!await confirmConnection(context, item)) {
      if (mounted) _flashBanner();
      return;
    }
    if (!mounted) return;
    final current = _current;
    if (current != null && current.id != item.id) _previousId = current.id;
    context.playback.play(item);
    context.library.noteRecent(item);
    _flashBanner();
  }

  void _zap(int delta) {
    final list = _channels;
    if (list.isEmpty) return;
    final index = _current == null ? -1 : list.indexWhere((i) => i.id == _current!.id);
    final next = index < 0 ? (delta >= 0 ? 0 : list.length - 1) : (index + delta + list.length) % list.length;
    _select(list[next]);
  }

  void _goBack() {
    final id = _previousId;
    final item = id == null ? null : context.library.item(id);
    if (item != null) _select(item);
  }

  void _toggleFavorite() {
    final item = _current;
    if (item != null) context.library.toggleFavorite(item.id);
  }

  // MARK: Panneau, bandeau, barre du haut

  void _openPanel() {
    setState(() => _panel = true);
    _touchPanel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _closePanel() {
    _panelTimer?.cancel();
    if (_panel) setState(() => _panel = false);
    _focus.requestFocus();
  }

  void _togglePanel() => _panel ? _closePanel() : _openPanel();

  /// Le panneau se referme après 8 s sans activité.
  void _touchPanel() {
    _panelTimer?.cancel();
    _panelTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_searchFocus.hasFocus) _closePanel();
    });
  }

  void _scrollToCurrent() {
    final current = _current;
    if (current == null || !_listController.hasClients) return;
    final index = _channels.indexWhere((i) => i.id == current.id);
    if (index < 0) return;
    final target = (index * 56.0 - 200).clamp(0.0, _listController.position.maxScrollExtent);
    _listController.jumpTo(target);
  }

  void _flashBanner() {
    _bannerTimer?.cancel();
    setState(() => _banner = true);
    _bannerTimer = Timer(const Duration(seconds: 5), () => mounted ? setState(() => _banner = false) : null);
  }

  void _toggleBanner() {
    if (_banner) {
      _bannerTimer?.cancel();
      setState(() => _banner = false);
    } else {
      _flashBanner();
    }
  }

  void _pokeTopBar() {
    if (!_topBar) setState(() => _topBar = true);
    _topTimer?.cancel();
    _topTimer = Timer(const Duration(seconds: 3), () => mounted ? setState(() => _topBar = false) : null);
  }

  // MARK: Numéro de chaîne

  void _typeDigit(String digit) {
    if (_typed.length >= 4) return;
    setState(() => _typed += digit);
    _typeTimer?.cancel();
    if (_typed.length == 4) {
      _commitNumber();
      return;
    }
    _typeTimer = Timer(const Duration(milliseconds: 1600), _commitNumber);
  }

  void _cancelNumber() {
    _typeTimer?.cancel();
    setState(() => _typed = '');
  }

  void _commitNumber() {
    _typeTimer?.cancel();
    final number = int.tryParse(_typed);
    setState(() => _typed = '');
    if (number == null || !mounted) return;
    final item = _resolve(number);
    if (item != null) {
      _select(item);
    } else {
      _showNotice('${tr('Chaîne')} $number ${tr('introuvable')}');
    }
  }

  /// Chaîne portant ce numéro ; si la playlist ne numérote pas ses chaînes, position dans la liste affichée.
  MediaItem? _resolve(int number) {
    final all = context.library.items(MediaKind.live);
    if (all.any((i) => i.number != null)) return all.where((i) => i.number == number).firstOrNull;
    final list = _channels;
    return number >= 1 && number <= list.length ? list[number - 1] : null;
  }

  void _showNotice(String text) {
    _noticeTimer?.cancel();
    setState(() => _notice = text);
    _noticeTimer = Timer(const Duration(milliseconds: 2500), () => mounted ? setState(() => _notice = null) : null);
  }

  // MARK: Clavier

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    // Pas de raccourcis pendant la saisie dans la recherche du panneau.
    if (_searchFocus.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _closePanel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isAltPressed || keys.isMetaPressed) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _zap(-1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _zap(1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _openPanel();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _panel ? _closePanel() : _toggleBanner();
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _typed.isNotEmpty ? _commitNumber() : _togglePanel();
    } else if (key == LogicalKeyboardKey.escape) {
      if (_typed.isNotEmpty) {
        _cancelNumber();
      } else if (_panel) {
        _closePanel();
      } else if (context.navigation.theater) {
        context.navigation.exitTheater();
      } else {
        return KeyEventResult.ignored;
      }
    } else if (key == LogicalKeyboardKey.space) {
      context.playback.togglePause();
    } else if (key == LogicalKeyboardKey.keyM) {
      context.playback.toggleMute();
    } else if (key == LogicalKeyboardKey.keyF) {
      _toggleFavorite();
    } else if (key == LogicalKeyboardKey.keyR) {
      toggleRecording(context);
    } else if (key == LogicalKeyboardKey.keyI) {
      _toggleBanner();
    } else if (key == LogicalKeyboardKey.keyB) {
      _goBack();
    } else if (key == LogicalKeyboardKey.keyG) {
      context.navigation.go(Screen.guide);
    } else if (key == LogicalKeyboardKey.keyH) {
      context.navigation.go(Screen.home);
    } else {
      final label = event.character ?? '';
      final digit = _digit(key) ?? (RegExp(r'^[0-9]$').hasMatch(label) ? label : null);
      if (digit == null) return KeyEventResult.ignored;
      _typeDigit(digit);
    }
    return KeyEventResult.handled;
  }

  static String? _digit(LogicalKeyboardKey key) {
    const digits = [
      LogicalKeyboardKey.digit0, LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, //
      LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5, LogicalKeyboardKey.digit6, LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8, LogicalKeyboardKey.digit9,
    ];
    const numpad = [
      LogicalKeyboardKey.numpad0, LogicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad2, LogicalKeyboardKey.numpad3, //
      LogicalKeyboardKey.numpad4, LogicalKeyboardKey.numpad5, LogicalKeyboardKey.numpad6, LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8, LogicalKeyboardKey.numpad9,
    ];
    var i = digits.indexOf(key);
    if (i < 0) i = numpad.indexOf(key);
    return i < 0 ? null : '$i';
  }

  // MARK: Vue

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      autofocus: true,
      child: MouseRegion(
        onHover: (_) => _pokeTopBar(),
        child: ListenableBuilder(
          listenable: Listenable.merge([context.playback, context.library, context.guide, context.navigation]),
          builder: (context, _) {
            final current = _current;
            return Stack(children: [
              Positioned.fill(
                child: PlayerPane(
                  tvMode: true,
                  placeholder: _Welcome(onOpen: _openPanel),
                ),
              ),
              // Bord gauche : l'approche de la souris ouvre le panneau.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 14,
                child: MouseRegion(onEnter: (_) => _openPanel(), child: const SizedBox.expand()),
              ),
              if (!context.navigation.theater)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_topBar,
                    child: AnimatedOpacity(
                      opacity: _topBar && !_panel ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: _TopBar(onChannels: _togglePanel, title: current?.displayName),
                    ),
                  ),
                ),
              if (current != null)
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 84,
                  child: IgnorePointer(
                    child: AnimatedSlide(
                      offset: _banner ? Offset.zero : const Offset(0, 0.3),
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedOpacity(
                        opacity: _banner ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Center(child: _TVBanner(item: current)),
                      ),
                    ),
                  ),
                ),
              if (_typed.isNotEmpty)
                Positioned(
                  top: 24,
                  right: 24,
                  child: IgnorePointer(child: _NumberPad(typed: _typed, preview: _resolve(int.parse(_typed))?.displayName)),
                ),
              if (_notice != null)
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: _Glass(
                        radius: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Text(_notice!, style: kText(15, weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: _panel ? 0 : -380,
                top: 0,
                bottom: 0,
                width: 360,
                child: _panelView(context),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _panelView(BuildContext context) {
    final channels = _channels;
    final currentId = _current?.id;
    return MouseRegion(
      onHover: (_) => _touchPanel(),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xD0202024),
              border: Border(right: BorderSide(color: KPalette.separator)),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(children: [
                  Row(children: [
                    Builder(
                      builder: (context) => TextButton.icon(
                        onPressed: () async {
                          final box = context.findRenderObject() as RenderBox;
                          final f = await pickChannelFilter(context, box.localToGlobal(Offset(0, box.size.height)));
                          if (f != null) setState(() => _filter = f);
                          _touchPanel();
                        },
                        icon: const Icon(Icons.filter_list_rounded, size: 18),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(channelFilterTitle(context, _filter), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text('${channels.length}', style: kText(12, color: KPalette.secondaryText)),
                    IconButton(
                      tooltip: tr('Fermer'),
                      onPressed: _closePanel,
                      icon: const Icon(Icons.chevron_left_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ]),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    child: TextField(
                      controller: _query,
                      focusNode: _searchFocus,
                      onChanged: (_) {
                        setState(() {});
                        _touchPanel();
                      },
                      style: kText(13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        prefixIcon: Icon(Icons.search_rounded, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                        prefixIconConstraints: const BoxConstraints(minWidth: 32),
                        hintText: tr('Rechercher une chaîne'),
                        hintStyle: kText(13, color: Colors.white.withValues(alpha: 0.4)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ]),
              ),
              const Divider(height: 1, color: KPalette.separator),
              Expanded(
                child: channels.isEmpty
                    ? Center(
                        child: Text(_query.text.isEmpty ? tr('Aucune chaîne') : tr('Aucun résultat'),
                            style: kText(13, color: KPalette.secondaryText)),
                      )
                    : ListView.builder(
                        controller: _listController,
                        padding: const EdgeInsets.all(6),
                        itemCount: channels.length,
                        itemExtent: 56,
                        itemBuilder: (context, i) => _ChannelRow(
                          item: channels[i],
                          current: channels[i].id == currentId,
                          onTap: () {
                            _select(channels[i]);
                            _touchPanel();
                          },
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tv_rounded, size: 64, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(tr('Direct'), style: kRounded(24, FontWeight.w800)),
          const SizedBox(height: 6),
          Text(tr('Choisissez une chaîne dans le panneau (touche ←), tapez son numéro ou utilisez ↑ / ↓.'),
              style: kText(14, color: KPalette.secondaryText)),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: KPalette.accent),
            onPressed: onOpen,
            icon: const Icon(Icons.list_rounded),
            label: Text(tr('Ouvrir les chaînes')),
          ),
        ]),
      );
}

/// Barre du haut (se cache seule) : accueil, sections, chaînes, guide, réglages.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onChannels, this.title});
  final VoidCallback onChannels;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final navigation = context.navigation;
    Widget button(IconData icon, String tip, VoidCallback onTap) => Tooltip(
          message: tip,
          child: Hover(
            onTap: onTap,
            builder: (context, hovering) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: hovering ? 0.16 : 0.0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xCC000000), Colors.transparent]),
      ),
      child: Row(children: [
        button(Icons.home_rounded, tr('Accueil'), () => navigation.go(Screen.home)),
        button(Icons.list_rounded, '${tr('Chaînes')} (←)', onChannels),
        button(Icons.calendar_month_rounded, '${tr('Guide TV')} (G)', () => navigation.go(Screen.guide)),
        const SizedBox(width: 10),
        if (title != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(title!, style: kText(15, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        const Spacer(),
        SizedBox(width: 230, child: SectionPicker(current: MediaKind.live)),
        const SizedBox(width: 8),
        button(Icons.settings_rounded, tr('Réglages'), () => showSettingsDialog(context)),
      ]),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.item, required this.current, required this.onTap});
  final MediaItem item;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.guide.current(item);
    final favorite = context.library.isFavorite(item.id);
    return GestureDetector(
      onSecondaryTapUp: (d) => showItemMenu(context, item, d.globalPosition),
      child: Hover(
        onTap: onTap,
        builder: (context, hovering) => Container(
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: current
                ? KPalette.accent.withValues(alpha: 0.35)
                : hovering
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            if (item.number != null)
              SizedBox(
                width: 34,
                child: Text('${item.number}', textAlign: TextAlign.right, style: kText(13, color: KPalette.secondaryText)),
              ),
            const SizedBox(width: 8),
            LogoView(url: item.logo, name: item.name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.displayName, style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (p != null) ...[
                  Text(p.title, style: kText(11, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 20),
                    child: LinearProgressIndicator(value: p.progress(), minHeight: 2, color: KPalette.orange, backgroundColor: Colors.white12),
                  ),
                ],
              ]),
            ),
            if (favorite) const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
          ]),
        ),
      ),
    );
  }
}

/// Fond translucide flouté (équivalent de .ultraThinMaterial).
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 18, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xB0202024),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: child,
          ),
        ),
      );
}

/// Bandeau d'information affiché à chaque changement de chaîne.
class _TVBanner extends StatelessWidget {
  const _TVBanner({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final guide = context.guide;
    final current = guide.current(item);
    final next = guide.next(item);
    final now = DateTime.now();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: _Glass(
        child: Row(children: [
          LogoView(url: item.logo, name: item.name, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (item.number != null) ...[
                  Text('${item.number}', style: kText(19, weight: FontWeight.w800, color: KPalette.accent)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Row(children: [
                    Flexible(
                      child: Text(item.displayName, style: kText(19, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (context.library.isFavorite(item.id)) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    ],
                  ]),
                ),
                Text(hm(now), style: kText(19, color: KPalette.secondaryText)),
              ]),
              const SizedBox(height: 6),
              if (current != null) ...[
                Row(children: [
                  Expanded(child: Text(current.title, style: kText(15, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(timeRange(current), style: kText(12, color: KPalette.secondaryText)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: current.progress(), minHeight: 4, color: KPalette.orange, backgroundColor: Colors.white12),
                ),
                if (next != null) ...[
                  const SizedBox(height: 6),
                  Text('${tr('Ensuite')} : ${next.title} (${hm(next.start)})',
                      style: kText(12, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ] else
                Text(tr('Pas de programme disponible'), style: kText(13, color: KPalette.secondaryText)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Chiffres tapés au clavier, avec le nom de la chaîne correspondante.
class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.typed, this.preview});
  final String typed;
  final String? preview;

  @override
  Widget build(BuildContext context) => _Glass(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text(typed, style: kRounded(54, FontWeight.w800).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          Text(preview ?? '…', style: kText(13, color: KPalette.secondaryText)),
        ]),
      );
}
