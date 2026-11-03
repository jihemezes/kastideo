import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import 'library.dart';
import 'log.dart';
import 'models.dart';
import 'playback.dart';
import 'settings.dart';
import 'xtream.dart';

/// Disposition des vignettes de la MultiVue.
enum MultiLayout {
  /// Selon le nombre de chaînes : 1 en plein cadre, 2 côte à côte, 3 ou 4 en grille.
  auto,

  /// Grille 2 × 2.
  grid,

  /// Une grande image et les autres en petit à droite.
  focus,

  /// Toutes côte à côte sur une ligne.
  row,

  /// Toutes empilées en colonne.
  column,
}

/// Groupe de chaînes mémorisé (ex. « Multiplex foot »).
class MultiViewGroup {
  MultiViewGroup(this.name, this.ids, {this.layout = MultiLayout.auto});
  final String name;
  final List<String> ids;
  final MultiLayout layout;

  Map<String, dynamic> toJson() => {'name': name, 'ids': ids, 'layout': layout.name};

  static MultiViewGroup fromJson(Map<String, dynamic> j) => MultiViewGroup(
        j['name'] as String? ?? '',
        List<String>.from(j['ids'] as List? ?? const []),
        layout: MultiLayout.values.where((l) => l.name == j['layout']).firstOrNull ?? MultiLayout.auto,
      );
}

/// Un flux de la MultiVue : son propre lecteur mpv (une connexion au fournisseur).
class MultiSlot extends ChangeNotifier {
  MultiSlot() {
    player = Player(
      configuration: const PlayerConfiguration(title: 'Kastideo', logLevel: MPVLogLevel.warn, bufferSize: 32 * 1024 * 1024),
    );
    video = VideoController(player);
    _subscriptions.addAll([
      player.stream.height.listen((h) {
        if (h != null && h > 0 && (loading || failed)) {
          loading = false;
          failed = false;
          _retries = 0;
          notifyListeners();
        }
      }),
      player.stream.error.listen((e) {
        if (item == null) return;
        PlaybackLog.shared.note('MultiVue : ${item!.name} — $e');
        // Seules les erreurs d'ouverture comptent (une sortie audio absente, par exemple, n'empêche pas l'image).
        if (PlaybackController.isOpenFailure(e)) _retryOrFail();
      }),
      player.stream.completed.listen((done) {
        // Flux coupé par le serveur : on le rouvre (deux essais), comme le lecteur principal.
        if (done && item != null) _retryOrFail();
      }),
    ]);
    _ready = _prepare();
  }

  late final Player player;
  late final VideoController video;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  late final Future<void> _ready;

  MediaItem? item;

  /// Source réservée à cet écran (ses chaînes seules sont proposées).
  String? sourceId;
  bool loading = false;
  bool failed = false;
  Timer? _timeout;
  int _retries = 0;
  double _volume = 0;

  void _retryOrFail() {
    final channel = item;
    if (channel == null) return;
    if (_retries < 2) {
      _retries++;
      PlaybackLog.shared.note('MultiVue : nouvel essai pour ${channel.name} ($_retries/2)');
      Timer(const Duration(seconds: 2), () {
        if (item?.id == channel.id) play(channel, volume: _volume, retry: true);
      });
      return;
    }
    loading = false;
    failed = true;
    notifyListeners();
  }

  Future<void> _prepare() async {
    final native = player.platform;
    if (native is NativePlayer) {
      await native.setProperty('user-agent', kUserAgent);
      await native.setProperty('network-timeout', '20');
      await native.setProperty('cache', 'yes');
      await native.setProperty('demuxer-readahead-secs', '2');
      await native.setProperty('hwdec', 'auto-safe');
      await native.setProperty('ytdl', 'no');
      await native.setProperty('stream-lavf-o', 'reconnect=1,reconnect_streamed=1,reconnect_delay_max=5');
    }
  }

  Future<void> play(MediaItem channel, {required double volume, bool retry = false}) async {
    final url = channel.stream;
    if (url == null) return;
    await _ready;
    if (!retry) _retries = 0;
    _volume = volume;
    item = channel;
    loading = true;
    failed = false;
    notifyListeners();
    PlaybackLog.shared.note('MultiVue : ouverture de ${channel.name}');
    await player.setVolume(volume);
    await player.open(Media(url));
    _timeout?.cancel();
    _timeout = Timer(PlaybackController.startTimeout, () {
      if (loading && item?.id == channel.id) {
        loading = false;
        failed = true;
        notifyListeners();
      }
    });
  }

  Future<void> setVolume(double v) {
    _volume = v;
    return player.setVolume(v);
  }

  Future<void> stop() async {
    _timeout?.cancel();
    item = null;
    loading = false;
    failed = false;
    notifyListeners();
    await player.stop();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    player.dispose();
    super.dispose();
  }
}

/// MultiVue : jusqu'à 4 chaînes en direct, le son suit la vignette active (comme MultiViewModel sur Mac).
class MultiViewController extends ChangeNotifier {
  MultiViewController(this.settings, this.playback) {
    _load();
  }

  final AppSettings settings;
  final PlaybackController playback;
  LibraryStore? library;
  SharedPreferences? _prefs;

  final List<MultiSlot> slots = [];
  int active = 0;

  /// Vignette affichée en grand (disposition « une grande »).
  int big = 0;
  MultiLayout layout = MultiLayout.auto;
  final List<MultiViewGroup> groups = [];

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    layout = MultiLayout.values.where((l) => l.name == _prefs!.getString('multiview.layout')).firstOrNull ?? MultiLayout.auto;
    final raw = _prefs!.getString('multiview.groups.v1');
    if (raw != null) {
      try {
        groups.addAll([for (final e in jsonDecode(raw) as List) MultiViewGroup.fromJson(Map<String, dynamic>.from(e as Map))]);
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Cases de la grille : 4 au plus.
  int get capacity => 4;

  bool get isRunning => slots.any((s) => s.item != null);
  List<MediaItem> get channels => [for (final s in slots) ?s.item];
  bool contains(MediaItem item) => slots.any((s) => s.item?.id == item.id);

  double get _volume => playback.muted ? 0 : playback.volume;

  /// Nom + identifiant du compte (deux abonnements peuvent porter le même nom).
  static String accountLabel(Source s) {
    var user = s.username ?? '';
    if (user.isEmpty && s.kind == SourceKind.m3uUrl) user = Uri.tryParse(s.address)?.queryParameters['username'] ?? '';
    return user.isEmpty ? s.name : '${s.name} · $user';
  }

  List<Source> get liveSources => library?.selectableSources ?? const [];

  /// Nombre d'écrans possible : somme des connexions des sources, 4 au plus.
  int get maxScreens => liveSources.fold<int>(0, (n, s) => n + settings.multiviewLimit(s)).clamp(1, 4);

  int get screenCount => (_prefs?.getInt('multiview.screens') ?? 2).clamp(1, 4);

  /// Écrans déjà réservés à une source (hors l'écran indiqué).
  int assignedCount(String sourceId, {int? excluding}) {
    var n = 0;
    for (var i = 0; i < slots.length; i++) {
      if (i != excluding && slots[i].sourceId == sourceId) n++;
    }
    return n;
  }

  /// Première source de direct qui a encore une connexion à réserver.
  String? freeSource({int? excluding}) {
    for (final s in liveSources) {
      if (assignedCount(s.id, excluding: excluding) < settings.multiviewLimit(s)) return s.id;
    }
    return null;
  }

  /// Prépare les écrans à l'ouverture de la MultiVue.
  void ensureScreens() => setScreenCount(slots.length > screenCount ? slots.length : screenCount);

  /// Fixe le nombre d'écrans (les nouveaux sont réservés à la première source disponible).
  Future<void> setScreenCount(int wanted) async {
    final target = wanted.clamp(1, maxScreens);
    while (slots.length > target) {
      await remove(slots.length - 1);
    }
    while (slots.length < target) {
      slots.add(MultiSlot()..sourceId = freeSource());
    }
    _prefs?.setInt('multiview.screens', target);
    notifyListeners();
  }

  /// Réserve un écran à une source ; faux si toutes ses connexions sont déjà réservées.
  Future<bool> assign(int index, String sourceId) async {
    if (index < 0 || index >= slots.length) return false;
    final source = liveSources.where((s) => s.id == sourceId).firstOrNull;
    if (source == null) return false;
    if (slots[index].sourceId != sourceId && assignedCount(sourceId, excluding: index) >= settings.multiviewLimit(source)) return false;
    slots[index].sourceId = sourceId;
    if (slots[index].item != null && slots[index].item!.sourceId != sourceId) await slots[index].stop();
    notifyListeners();
    return true;
  }

  /// Vrai si la chaîne peut être lue sur cet écran (celui-ci est réservé à sa source).
  bool canPlay(MediaItem item, {int? replacing}) {
    if (replacing != null && replacing >= 0 && replacing < slots.length) return slots[replacing].sourceId == item.sourceId;
    return true;
  }

  /// Ajoute une chaîne : dans un écran libre de sa source, sinon dans un écran vide réaffecté, sinon dans un nouvel écran.
  Future<bool> add(MediaItem item) async {
    if (contains(item)) return true;
    final source = library?.sourceOf(item);
    if (source == null) return false;
    var index = slots.indexWhere((s) => s.item == null && s.sourceId == item.sourceId);
    if (index < 0) {
      if (assignedCount(item.sourceId) >= settings.multiviewLimit(source)) return false;
      index = slots.indexWhere((s) => s.item == null);
      if (index < 0) {
        if (slots.length >= maxScreens) return false;
        slots.add(MultiSlot());
        index = slots.length - 1;
        _prefs?.setInt('multiview.screens', slots.length);
      }
      slots[index].sourceId = item.sourceId;
    }
    if (!isRunning) active = index;
    notifyListeners();
    await slots[index].play(item, volume: index == active ? _volume : 0);
    notifyListeners();
    return true;
  }

  /// Remplace la chaîne d'une case (même source seulement).
  Future<void> replace(int index, MediaItem item) async {
    if (index < 0 || index >= slots.length) return;
    final existing = slots.indexWhere((s) => s.item?.id == item.id);
    if (existing >= 0 && existing != index) {
      setActive(existing);
      return;
    }
    if (!canPlay(item, replacing: index)) return;
    await slots[index].play(item, volume: index == active ? _volume : 0);
    notifyListeners();
  }

  /// Redessine après l'arrêt d'une chaîne d'un écran.
  void refresh() => notifyListeners();

  /// Ajoute une case vide (le choix de la chaîne suit).
  int? addEmptySlot() {
    if (slots.length >= capacity) return null;
    slots.add(MultiSlot());
    notifyListeners();
    return slots.length - 1;
  }

  Future<void> remove(int index) async {
    if (index < 0 || index >= slots.length) return;
    final slot = slots.removeAt(index);
    await slot.stop();
    slot.dispose();
    if (index < active) {
      active--;
    } else if (index == active) {
      active = slots.indexWhere((s) => s.item != null);
      if (active < 0) active = 0;
    }
    if (index < big) {
      big--;
    } else if (index == big) {
      big = 0;
    }
    await _applyVolumes();
    notifyListeners();
  }

  /// Le son suit la vignette active.
  void setActive(int index) {
    if (index < 0 || index >= slots.length) return;
    active = index;
    _applyVolumes();
    notifyListeners();
  }

  /// Passe une vignette en grand (et lui donne le son).
  void makeBig(int index) {
    if (index < 0 || index >= slots.length) return;
    if (layout == MultiLayout.auto || layout == MultiLayout.grid || layout == MultiLayout.row) {
      layout = MultiLayout.focus;
      _prefs?.setString('multiview.layout', layout.name);
    } else if (big == index) {
      // Déjà en grand : double-clic de nouveau → retour à la grille.
      layout = MultiLayout.auto;
      _prefs?.setString('multiview.layout', layout.name);
    }
    big = index;
    setActive(index);
  }

  void setLayout(MultiLayout value) {
    layout = value;
    _prefs?.setString('multiview.layout', value.name);
    notifyListeners();
  }

  /// Volume du lecteur principal appliqué à la vignette active (les autres sont muettes).
  Future<void> _applyVolumes() async {
    for (var i = 0; i < slots.length; i++) {
      await slots[i].setVolume(i == active ? _volume : 0);
    }
  }

  Future<void> refreshVolume() => _applyVolumes();

  Future<void> stopAll() async {
    final all = List.of(slots);
    slots.clear();
    active = 0;
    big = 0;
    notifyListeners();
    for (final s in all) {
      try {
        await s.stop();
      } catch (_) {}
      s.dispose();
    }
  }

  // MARK: Groupes mémorisés

  void _saveGroups() => _prefs?.setString('multiview.groups.v1', jsonEncode([for (final g in groups) g.toJson()]));

  void saveGroup(String name) {
    final ids = [for (final c in channels) c.id];
    if (ids.isEmpty || name.trim().isEmpty) return;
    groups.removeWhere((g) => g.name == name.trim());
    groups.add(MultiViewGroup(name.trim(), ids, layout: layout));
    _saveGroups();
    notifyListeners();
  }

  void deleteGroup(MultiViewGroup group) {
    groups.remove(group);
    _saveGroups();
    notifyListeners();
  }

  /// Ouvre un groupe : les chaînes en cours sont remplacées. Renvoie le nombre de chaînes introuvables.
  Future<int> openGroup(MultiViewGroup group, MediaItem? Function(String id) resolve) async {
    await stopAll();
    layout = group.layout;
    var missing = 0;
    for (final id in group.ids.take(capacity)) {
      final item = resolve(id);
      if (item == null) {
        missing++;
        continue;
      }
      await add(item);
    }
    notifyListeners();
    return missing;
  }
}

/// Image dans l'image : une seconde chaîne en miniature dans le lecteur (son coupé), échangeable en un clic.
class PipController extends ChangeNotifier {
  PipController._();
  static final PipController shared = PipController._();

  MultiSlot? slot;
  String? message;

  MediaItem? get item => slot?.item;
  bool get isOpen => slot != null;

  /// Vrai si la source de [candidate] a une connexion libre en plus de la lecture principale.
  bool canOpen(MediaItem candidate, PlaybackController playback, LibraryStore library, AppSettings settings) {
    final inUse = playback.current?.sourceId == candidate.sourceId ? 1 : 0;
    return inUse + 1 <= settings.multiviewLimit(library.sourceOf(candidate));
  }

  Future<void> open(MediaItem candidate, PlaybackController playback, LibraryStore library, AppSettings settings) async {
    if (candidate.id == playback.current?.id) return;
    if (!canOpen(candidate, playback, library, settings)) {
      message = tr('Cette source n\'autorise pas de second flux. Choisissez une chaîne d\'une autre source.');
      notifyListeners();
      return;
    }
    message = null;
    final pip = slot ??= MultiSlot();
    notifyListeners();
    await pip.play(candidate, volume: 0);
    notifyListeners();
  }

  /// La miniature prend la place de la lecture principale, et inversement.
  Future<void> swap(PlaybackController playback) async {
    final pip = slot;
    final small = pip?.item;
    final big = playback.current;
    if (pip == null || small == null || big == null) return;
    await pip.stop();
    playback.play(small);
    // Le flux principal précédent passe en miniature une fois l'ancien fermé.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (slot == pip) await pip.play(big, volume: 0);
    notifyListeners();
  }

  Future<void> close() async {
    final pip = slot;
    if (pip == null) return;
    slot = null;
    message = null;
    notifyListeners();
    try {
      await pip.stop();
    } catch (_) {}
    pip.dispose();
  }
}
