import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/youtube.dart';
import '../l10n.dart';
import '../theme.dart';
import 'catalog_screen.dart';
import 'help_dialog.dart';
import 'settings_dialog.dart';

YouTubePlayerLabels youTubeLabels() => YouTubePlayerLabels(
      previous: tr('Précédente'),
      next: tr('Suivante'),
      chain: tr('Enchaîner'),
      loop: tr('Boucle'),
      mute: tr('Muet'),
      open: tr('Ouvrir sur YouTube'),
      unavailable: tr('Vidéo indisponible, passage à la suivante…'),
    );

/// Section YouTube : navigateur (chaînes suivies, recherche, favoris, historique) puis, au clic sur une vidéo, bascule
/// sur le lecteur officiel (mode confidentialité avancée) ouvert dans sa propre fenêtre.
class YouTubeScreen extends StatelessWidget {
  const YouTubeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Row(children: [
          const SizedBox(width: 236, child: Sidebar(kind: MediaKind.live, youtube: true)),
          VerticalDivider(width: 1, color: KPalette.separator),
          const Expanded(child: YouTubeBrowser()),
        ]),
      );
}

enum _Tab { channels, search, later, favorites, history }

class YouTubeBrowser extends StatefulWidget {
  const YouTubeBrowser({super.key});

  @override
  State<YouTubeBrowser> createState() => _YouTubeBrowserState();
}

class _YouTubeBrowserState extends State<YouTubeBrowser> {
  final _store = YouTubeStore.shared;
  final _field = TextEditingController();
  _Tab _tab = _Tab.channels;
  String _query = '';
  YouTubeOrder _order = YouTubeOrder.relevance;
  List<YouTubeVideo> _results = [];
  String? _next, _previous;
  bool _searching = false;
  bool _working = false;
  String? _message;
  YouTubeVideo? _nowPlaying;

  @override
  void initState() {
    super.initState();
    YouTubePlayerHost.shared.onVideo = (v) {
      _store.record(v);
      if (mounted) setState(() => _nowPlaying = v);
    };
    YouTubePlayerHost.shared.onProgress = _store.didProgress;
    _store.load().then((_) => _store.refreshFeeds());
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// Lit `videos` à partir de `index` : la liste affichée devient la file. La lecture IPTV s'arrête (une seule source sonore).
  Future<void> _play(List<YouTubeVideo> videos, int index) async {
    final playback = context.playback;
    final recording = context.recordings.active?.viaPlayer == true;
    if (playback.current != null && !recording) await playback.stop();
    setState(() => _nowPlaying = videos[index]);
    await YouTubePlayerHost.shared.play(videos, index, _store, youTubeLabels());
  }

  void _submit() {
    final text = _field.text.trim();
    if (text.isEmpty) return;
    setState(() => _message = null);
    final source = parseYouTubeSource(text);
    if (source != null && (text.contains('.') || text.startsWith('@'))) {
      _open(source);
    } else {
      _query = text;
      setState(() => _tab = _Tab.search);
      _search(null);
    }
  }

  /// Lien collé : une vidéo se lit, une playlist devient la file, une chaîne est suivie.
  Future<void> _open(YouTubeSource source) async {
    setState(() => _working = true);
    try {
      switch (source.kind) {
        case YouTubeSourceKind.video:
          final video = await _store.client.describe(source.id);
          await _play([video], 0);
        case YouTubeSourceKind.playlist:
          final feed = await _store.client.playlistFeed(source.id);
          if (feed.videos.isEmpty) {
            setState(() => _message = tr('Playlist vide ou privée.'));
          } else {
            await _play(feed.videos, 0);
          }
        case YouTubeSourceKind.channel || YouTubeSourceKind.handle:
          final channel = await _store.follow(source);
          _field.clear();
          setState(() {
            _tab = _Tab.channels;
            _message = '${tr('Chaîne suivie :')} ${channel.title}';
          });
          await _store.refreshFeeds(force: true);
      }
    } catch (_) {
      setState(() => _message = tr('Adresse non reconnue ou introuvable (une chaîne privée ou une playlist supprimée ne se lit pas).'));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _search(String? token) async {
    if (_query.isEmpty) return;
    setState(() {
      _searching = true;
      _message = null;
    });
    try {
      final page = await _store.client.search(_query, order: _order, pageToken: token);
      setState(() {
        _results = page.videos;
        _next = page.next;
        _previous = page.previous;
      });
    } on YouTubeNoKey {
      setState(() => _message = tr('Clé API manquante.'));
    } on YouTubeApiError catch (e) {
      setState(() => _message = e.code == 403 ? '${tr('Quota ou clé refusés par Google :')} ${e.message}' : '${tr('Erreur de l\'API YouTube :')} ${e.message}');
    } catch (e) {
      setState(() => _message = '${tr('Recherche impossible :')} $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _header(context),
        Divider(height: 1, color: KPalette.separator),
        if (_nowPlaying != null) _nowPlayingBar(),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: KPalette.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_message!, style: kText(13, color: KPalette.orange))),
                ]),
              ),
            switch (_tab) {
              _Tab.channels => _channelsTab(),
              _Tab.search => _searchTab(),
              _Tab.later => _laterTab(),
              _Tab.favorites => _grid(_store.favorites, tr('Ajoutez des vidéos en favoris avec l\'étoile ou le clic droit.')),
              _Tab.history => _historyTab(),
            },
          ]),
        ),
      ]),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.smart_display_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _field,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: tr('Rechercher sur YouTube ou coller un lien (vidéo, playlist, chaîne, @pseudo)'),
                  suffixIcon: IconButton(
                    tooltip: tr('Coller'),
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) _field.text = data!.text!.trim();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: KPalette.accent), onPressed: _working ? null : _submit, child: const Text('OK')),
            if (_working || _store.loadingFeeds) const Padding(padding: EdgeInsets.only(left: 10), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          ]),
          const SizedBox(height: 10),
          SegmentedButton<_Tab>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _Tab.channels, label: Text(tr('Mes chaînes'))),
              ButtonSegment(value: _Tab.search, label: Text(tr('Recherche'))),
              ButtonSegment(value: _Tab.later, label: Text(tr('À regarder'))),
              ButtonSegment(value: _Tab.favorites, label: Text(tr('Favoris'))),
              ButtonSegment(value: _Tab.history, label: Text(tr('Historique'))),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
        ]),
      );

  Widget _nowPlayingBar() => Container(
        color: KPalette.accent.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Icon(Icons.play_circle_fill_rounded, color: KPalette.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('${tr('Lecture dans la fenêtre YouTube :')} ${_nowPlaying!.title}', style: kText(13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          TextButton(onPressed: () => _play([_nowPlaying!], 0), child: Text(tr('Rouvrir la fenêtre'))),
        ]),
      );

  // Mes chaînes

  Widget _channelsTab() {
    if (_store.channels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(children: [
          Icon(Icons.live_tv_rounded, size: 52, color: KPalette.ink.withValues(alpha: 0.35)),
          const SizedBox(height: 12),
          Text(tr('Aucune chaîne suivie'), style: kRounded(18, FontWeight.w700)),
          const SizedBox(height: 6),
          Text(tr('Collez le lien d\'une chaîne ou son @pseudo dans le champ ci-dessus : ses dernières vidéos s\'afficheront ici, sans clé ni compte.'),
              textAlign: TextAlign.center, style: kText(13, color: KPalette.secondaryText)),
          const SizedBox(height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton.icon(
              onPressed: _importSubscriptions,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(tr('Importer mes abonnements…')),
            ),
            const SizedBox(width: 12),
            HelpLink(label: tr('Comment obtenir mon fichier ?'), page: 'youtube-import'),
          ]),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        TextButton.icon(
          onPressed: _importSubscriptions,
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: Text(tr('Importer mes abonnements…')),
        ),
        HelpLink(label: tr('Comment obtenir mon fichier ?'), page: 'youtube-import'),
        const Spacer(),
        TextButton.icon(
          onPressed: _store.loadingFeeds ? null : () => _store.refreshFeeds(force: true),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(tr('Actualiser')),
        ),
      ]),
      for (final channel in _store.channels) ...[
        Row(children: [
          Expanded(child: Text(channel.title, style: kRounded(17, FontWeight.w700))),
          if (_store.feedErrors[channel.id] != null)
            Flexible(child: Text(_store.feedErrors[channel.id]!, style: kText(11, color: KPalette.orange), maxLines: 1, overflow: TextOverflow.ellipsis)),
          TextButton(onPressed: () => _store.unfollow(channel), child: Text(tr('Ne plus suivre'))),
        ]),
        const SizedBox(height: 6),
        SizedBox(
          height: 190,
          child: Builder(builder: (context) {
            final videos = _store.feeds[channel.id] ?? const <YouTubeVideo>[];
            if (videos.isEmpty) return Text(_store.loadingFeeds ? tr('Chargement…') : tr('Aucune vidéo récente.'), style: kText(13, color: KPalette.secondaryText));
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) => SizedBox(width: 230, child: _VideoCard(video: videos[i], onTap: () => _play(videos, i))),
            );
          }),
        ),
        const SizedBox(height: 22),
      ],
    ]);
  }

  // Recherche

  Widget _searchTab() {
    if (!_store.hasKey) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('La recherche nécessite votre propre clé API Google (gratuite).'), style: kText(15, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(tr('Ouvrez Réglages > Général > YouTube : la marche à suivre y est expliquée en quelques étapes. Sans clé, vous pouvez suivre des chaînes et coller des liens de vidéos ou de playlists.'),
              style: kText(13, color: KPalette.secondaryText)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => showSettingsDialog(context), child: Text(tr('Ouvrir les Réglages'))),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (_query.isNotEmpty) Expanded(child: Text('${tr('Résultats pour')} « $_query »', style: kRounded(16, FontWeight.w700))) else const Spacer(),
        SegmentedButton<YouTubeOrder>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: YouTubeOrder.relevance, label: Text(tr('Pertinence'))),
            ButtonSegment(value: YouTubeOrder.date, label: Text(tr('Date'))),
            ButtonSegment(value: YouTubeOrder.viewCount, label: Text(tr('Vues'))),
          ],
          selected: {_order},
          onSelectionChanged: (s) {
            setState(() => _order = s.first);
            if (_query.isNotEmpty) _search(null);
          },
        ),
      ]),
      const SizedBox(height: 14),
      if (_searching) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      _grid(_results, _query.isEmpty ? tr('Tapez votre recherche dans le champ ci-dessus.') : tr('Aucun résultat.')),
      if (_previous != null || _next != null)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            OutlinedButton(onPressed: _previous == null ? null : () => _search(_previous), child: Text(tr('Précédent'))),
            const SizedBox(width: 10),
            OutlinedButton(onPressed: _next == null ? null : () => _search(_next), child: Text(tr('Suivant'))),
          ]),
        ),
    ]);
  }

  Widget _laterTab() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Mettez des vidéos de côté avec le clic droit. Une vidéo entamée reprend là où vous l\'avez laissée ; elle quitte cette liste quand vous l\'avez vue jusqu\'au bout.'),
            style: kText(12, color: KPalette.secondaryText)),
        const SizedBox(height: 10),
        _grid(_store.watchLater, tr('Aucune vidéo mise de côté.')),
      ]);

  /// Import des abonnements d'un export Google Takeout (abonnements.csv).
  Future<void> _importSubscriptions() async {
    final file = await openFile(acceptedTypeGroups: [
      XTypeGroup(label: 'Takeout', extensions: const ['csv', 'json', 'txt']),
    ]);
    if (file == null) return;
    final added = _store.importSubscriptions(await file.readAsString());
    setState(() => _message = added > 0 ? '${tr('Chaînes importées :')} $added' : tr('Aucune nouvelle chaîne trouvée dans ce fichier.'));
    _store.refreshFeeds(force: true);
  }

  Widget _historyTab() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_store.history.isNotEmpty)
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _store.clearHistory, child: Text(tr('Effacer l\'historique')))),
        _grid(_store.history, tr('Les vidéos que vous regardez apparaîtront ici.')),
      ]);

  Widget _grid(List<YouTubeVideo> videos, String empty) {
    if (videos.isEmpty) {
      return _searching ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.symmetric(vertical: 50), child: Center(child: Text(empty, style: kText(13, color: KPalette.secondaryText))));
    }
    return LayoutBuilder(builder: (context, c) {
      final columns = (c.maxWidth / 250).floor().clamp(1, 6);
      final width = (c.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(spacing: 16, runSpacing: 18, children: [
        for (var i = 0; i < videos.length; i++) SizedBox(width: width, child: _VideoCard(video: videos[i], onTap: () => _play(videos, i))),
      ]);
    });
  }
}

/// Vignette d'une vidéo : clic = lecture (la liste affichée devient la file), clic droit = favori, copie du lien.
class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video, required this.onTap});
  final YouTubeVideo video;
  final VoidCallback onTap;

  String? _date() {
    final d = video.date;
    if (d == null) return null;
    final days = DateTime.now().difference(d).inDays;
    if (days < 1) return tr('aujourd\'hui');
    if (days < 30) return L10n.english ? '$days d ago' : 'il y a $days j';
    if (days < 365) return L10n.english ? '${days ~/ 30} mo ago' : 'il y a ${days ~/ 30} mois';
    return L10n.english ? '${days ~/ 365} y ago' : 'il y a ${days ~/ 365} an(s)';
  }

  @override
  Widget build(BuildContext context) {
    final store = YouTubeStore.shared;
    final date = _date();
    return GestureDetector(
      onSecondaryTapDown: (d) => _menu(context, d.globalPosition),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(fit: StackFit.expand, children: [
                Image.network(video.thumbnail, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: KPalette.ink.withValues(alpha: 0.08))),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (store.isLater(video)) const Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
                    if (store.isFavorite(video)) const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  ]),
                ),
                if (store.fractionOf(video) > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(value: store.fractionOf(video), minHeight: 3, color: Colors.red, backgroundColor: Colors.black54),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(video.title, style: kText(13, weight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          Text([video.channel, ?date].where((s) => s.isNotEmpty).join(' · '),
              style: kText(11, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  void _menu(BuildContext context, Offset position) {
    final store = YouTubeStore.shared;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(value: 'later', child: Text(store.isLater(video) ? tr('Retirer de « À regarder »') : tr('À regarder plus tard'))),
        PopupMenuItem(value: 'fav', child: Text(store.isFavorite(video) ? tr('Retirer des favoris') : tr('Ajouter aux favoris'))),
        PopupMenuItem(value: 'open', child: Text(tr('Ouvrir sur YouTube'))),
        PopupMenuItem(value: 'copy', child: Text(tr('Copier le lien'))),
      ],
    ).then((v) {
      switch (v) {
        case 'later':
          store.toggleLater(video);
        case 'fav':
          store.toggleFavorite(video);
        case 'open':
          launchUrl(video.watchUrl);
        case 'copy':
          Clipboard.setData(ClipboardData(text: video.watchUrl.toString()));
      }
    });
  }
}
