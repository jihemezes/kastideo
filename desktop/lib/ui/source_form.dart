import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/discovery.dart';
import '../core/library.dart';
import '../core/media_servers.dart';
import '../core/models.dart';
import '../l10n.dart';
import '../theme.dart';

/// Icône de chaque type de source.
IconData sourceIcon(SourceKind kind) => switch (kind) {
  SourceKind.xtream => Icons.dns_rounded,
  SourceKind.m3uUrl || SourceKind.m3uFile => Icons.playlist_play_rounded,
  SourceKind.folder => Icons.folder_rounded,
  SourceKind.jellyfin || SourceKind.emby => Icons.video_library_rounded,
  SourceKind.plex => Icons.play_circle_outline_rounded,
};

/// Formulaire d'ajout ou de modification d'une source : IPTV (Xtream, M3U), dossiers (disque, clé USB, NAS) ou
/// serveur multimédia (Jellyfin, Emby, Plex), avec recherche des serveurs de la maison.
class SourceForm extends StatefulWidget {
  const SourceForm({super.key, this.source, required this.onDone});

  /// Source modifiée (null : nouvelle source).
  final Source? source;
  final VoidCallback onDone;

  @override
  State<SourceForm> createState() => _SourceFormState();
}

class _SourceFormState extends State<SourceForm> {
  late SourceKind _kind = widget.source?.kind == SourceKind.m3uFile ? SourceKind.m3uUrl : (widget.source?.kind ?? SourceKind.xtream);
  final _name = TextEditingController();
  final _server = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _address = TextEditingController();
  final _epg = TextEditingController();
  final _token = TextEditingController();
  final _networkPath = TextEditingController();
  final List<String> _folders = [];
  bool _showPassword = false;
  bool _saving = false;
  String? _error;
  String? _info;

  // Recherche sur le réseau.
  bool _scanning = false;
  List<DiscoveredServer>? _found;

  // Connexion Plex (plex.tv/link).
  PlexPin? _pin;
  Timer? _pinTimer;
  List<(String, List<String>, String)> _plexServers = const [];

  bool get _editing => widget.source != null;

  @override
  void initState() {
    super.initState();
    final s = widget.source;
    if (s != null) _load(s);
  }

  Future<void> _load(Source s) async {
    final library = context.library;
    _name.text = s.name;
    _epg.text = s.epgUrl ?? '';
    _user.text = s.username ?? '';
    switch (s.kind) {
      case SourceKind.xtream:
        _server.text = s.address;
        _pass.text = await library.password(s.id) ?? '';
      case SourceKind.m3uUrl || SourceKind.m3uFile:
        _address.text = s.address;
      case SourceKind.folder:
        _folders.addAll(LibraryStore.folderPaths(s));
      case SourceKind.jellyfin || SourceKind.emby:
        _server.text = s.address;
        _pass.text = await library.password(s.id) ?? '';
      case SourceKind.plex:
        _server.text = s.address;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pinTimer?.cancel();
    for (final c in [_name, _server, _user, _pass, _address, _epg, _token, _networkPath]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _field(String label, {String? hint, Widget? suffix}) =>
      InputDecoration(labelText: label, hintText: hint, isDense: true, border: const OutlineInputBorder(), suffixIcon: suffix);

  Widget get _eye => IconButton(
    tooltip: _showPassword ? tr('Masquer') : tr('Afficher'),
    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
    onPressed: () => setState(() => _showPassword = !_showPassword),
  );

  // MARK: Actions

  Future<void> _save() async {
    // Chemin saisi sans avoir cliqué sur « + » : ajouté quand même.
    if (_networkPath.text.trim().isNotEmpty) _addNetworkPath();
    setState(() {
      _saving = true;
      _error = null;
    });
    final library = context.library;
    try {
      final editing = widget.source;
      if (editing != null) {
        await library.updateSource(
          editing,
          name: _name.text,
          address: switch (editing.kind) {
            SourceKind.xtream || SourceKind.jellyfin || SourceKind.emby || SourceKind.plex => _server.text,
            SourceKind.folder => _folders.join('\n'),
            _ => _address.text,
          },
          username: editing.kind == SourceKind.xtream || editing.kind == SourceKind.jellyfin || editing.kind == SourceKind.emby ? _user.text : null,
          password: editing.kind == SourceKind.xtream || editing.kind == SourceKind.jellyfin || editing.kind == SourceKind.emby ? _pass.text : null,
          token: editing.kind == SourceKind.plex && _token.text.trim().isNotEmpty ? _token.text : null,
          epgUrl: _epg.text,
        );
      } else {
        switch (_kind) {
          case SourceKind.xtream:
            await library.addXtream(name: _name.text, server: _server.text, username: _user.text, password: _pass.text, epgUrl: _epg.text);
          case SourceKind.m3uUrl || SourceKind.m3uFile:
            await library.addM3U(name: _name.text, address: _address.text, epgUrl: _epg.text);
          case SourceKind.folder:
            await library.addFolders(name: _name.text, paths: _folders);
          case SourceKind.jellyfin || SourceKind.emby:
            await library.addMediaServer(kind: _kind, name: _name.text, address: _server.text, username: _user.text, password: _pass.text);
          case SourceKind.plex:
            await library.addMediaServer(kind: _kind, name: _name.text, address: _server.text, token: _token.text);
        }
      }
      if (library.lastError != null) {
        setState(() => _error = library.lastError);
      } else {
        widget.onDone();
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'M3U', extensions: ['m3u', 'm3u8', 'txt']),
      ],
    );
    if (file != null) setState(() => _address.text = file.path);
  }

  Future<void> _addFolder() async {
    final dir = await getDirectoryPath(confirmButtonText: tr('Choisir'));
    if (dir != null && !_folders.contains(dir)) setState(() => _folders.add(dir));
  }

  void _addNetworkPath() {
    final p = _networkPath.text.trim();
    if (p.isEmpty || _folders.contains(p)) return;
    setState(() {
      _folders.add(p);
      _networkPath.clear();
    });
  }

  Future<void> _discover() async {
    setState(() {
      _scanning = true;
      _found = null;
    });
    final found = await ServerDiscovery.scan();
    if (mounted) {
      setState(() {
        _scanning = false;
        _found = found;
      });
    }
  }

  Future<void> _test() async {
    setState(() {
      _info = tr('Vérification…');
      _error = null;
    });
    try {
      final server = MediaServerClient.normalizeFor(_kind, _server.text);
      final String? name;
      if (_kind == SourceKind.plex) {
        name = _token.text.trim().isEmpty ? null : await PlexClient(server, '', token: _token.text.trim()).identity();
      } else {
        name = await JellyfinClient.publicInfo(server);
      }
      setState(() => _info = name == null ? tr('Le serveur répond.') : '${tr('Serveur trouvé')} : $name');
    } catch (e) {
      setState(() {
        _info = null;
        _error = '$e';
      });
    }
  }

  Future<void> _plexSignIn() async {
    setState(() {
      _error = null;
      _info = tr('Ouverture de plex.tv…');
    });
    try {
      final pin = await PlexClient.createPin();
      setState(() {
        _pin = pin;
        _info = tr('Autorisez Kastideo dans la page plex.tv qui vient de s\'ouvrir, puis revenez ici.');
      });
      await launchUrl(Uri.parse(pin.url));
      var tries = 0;
      _pinTimer?.cancel();
      _pinTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
        tries++;
        if (tries > 150 || !mounted) {
          t.cancel();
          return;
        }
        final token = await pin.poll().catchError((_) => null);
        if (token == null) return;
        t.cancel();
        _token.text = token;
        final servers = await PlexClient.accountServers(token).catchError((_) => <(String, List<String>, String)>[]);
        if (!mounted) return;
        setState(() {
          _pin = null;
          _plexServers = servers;
          _info = servers.isEmpty ? tr('Connecté à Plex. Indiquez l\'adresse du serveur.') : tr('Connecté à Plex : choisissez le serveur.');
          if (servers.length == 1 && servers.first.$2.isNotEmpty) _choosePlex(servers.first);
        });
      });
    } catch (e) {
      setState(() {
        _info = null;
        _error = '$e';
      });
    }
  }

  void _choosePlex((String, List<String>, String) server) {
    setState(() {
      _server.text = server.$2.first;
      _token.text = server.$3;
      if (_name.text.trim().isEmpty) _name.text = server.$1;
    });
  }

  // MARK: Affichage

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_editing)
          Text('${tr('Modifier la source')} « ${widget.source!.name} »', style: kText(16, weight: FontWeight.w700))
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (kind, label) in [
                (SourceKind.xtream, 'Xtream Codes'),
                (SourceKind.m3uUrl, tr('Playlist M3U')),
                (SourceKind.folder, tr('Dossiers')),
                (SourceKind.jellyfin, 'Jellyfin'),
                (SourceKind.emby, 'Emby'),
                (SourceKind.plex, 'Plex'),
              ])
                ChoiceChip(
                  avatar: Icon(sourceIcon(kind), size: 16),
                  label: Text(label),
                  selected: _kind == kind,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _kind = kind;
                    _error = null;
                    _info = null;
                  }),
                ),
            ],
          ),
          if (_kind.isMediaServer) ...[const SizedBox(height: 10), _discovery()],
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _name,
          decoration: _field(tr('Nom'), hint: _kind == SourceKind.folder ? tr('Mon disque') : tr('Mon abonnement')),
        ),
        const SizedBox(height: 12),
        ...switch (_kind) {
          SourceKind.xtream => _xtream(),
          SourceKind.m3uUrl || SourceKind.m3uFile => _m3u(),
          SourceKind.folder => _folderForm(),
          SourceKind.jellyfin || SourceKind.emby => _jellyfin(),
          SourceKind.plex => _plex(),
        },
        if (_info != null) ...[const SizedBox(height: 10), Text(_info!, style: kText(13, color: KPalette.accent))],
        if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: kText(13, color: KPalette.orange))],
        const SizedBox(height: 18),
        Row(
          children: [
            if (_saving) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            if (_saving && (_kind == SourceKind.folder || _kind.isMediaServer)) ...[
              const SizedBox(width: 8),
              Text(
                _kind == SourceKind.folder ? tr('Examen des dossiers…') : tr('Chargement des bibliothèques…'),
                style: kText(12, color: KPalette.secondaryText),
              ),
            ],
            const Spacer(),
            TextButton(onPressed: _saving ? null : widget.onDone, child: Text(tr('Annuler'))),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: KPalette.magenta),
              onPressed: _saving ? null : _save,
              child: Text(_editing ? tr('Enregistrer') : tr('Ajouter')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _discovery() {
    final found = _found;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tr('Serveurs Jellyfin, Emby ou Plex de la maison'), style: kText(13, weight: FontWeight.w600)),
              ),
              OutlinedButton.icon(
                onPressed: _scanning ? null : _discover,
                icon: _scanning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_find_rounded, size: 18),
                label: Text(_scanning ? tr('Recherche…') : tr('Rechercher sur le réseau')),
              ),
            ],
          ),
          if (found != null && found.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                tr('Aucun serveur trouvé. Saisissez son adresse (ex. http://192.168.1.10:8096), ou vérifiez qu\'il est allumé et sur le même réseau.'),
                style: kText(12, color: KPalette.secondaryText),
              ),
            ),
          if (found != null && found.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in found)
                    ActionChip(
                      avatar: Icon(sourceIcon(s.kind), size: 16),
                      label: Text('${s.name} · ${s.kind.label} · ${Uri.tryParse(s.address)?.authority ?? s.address}'),
                      onPressed: () => setState(() {
                        _kind = s.kind;
                        _server.text = s.address;
                        if (_name.text.trim().isEmpty) _name.text = s.name;
                        _error = null;
                        _info = '${s.kind.label} : ${s.address}';
                      }),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _xtream() => [
    TextField(
      controller: _server,
      decoration: _field(tr('Serveur'), hint: 'http://exemple.com:8080'),
    ),
    const SizedBox(height: 12),
    TextField(controller: _user, decoration: _field(tr('Identifiant'))),
    const SizedBox(height: 12),
    TextField(
      controller: _pass,
      obscureText: !_showPassword,
      decoration: _field(tr('Mot de passe'), suffix: _eye),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _epg,
      decoration: _field(tr('Guide TV (XMLTV) — facultatif'), hint: tr('Laisser vide : guide indiqué par le fournisseur')),
    ),
  ];

  List<Widget> _m3u() => [
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _address,
            decoration: _field(tr('Adresse de la playlist ou chemin du fichier'), hint: 'http://…/get.php?username=…&password=…'),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _pickFile, child: Text(tr('Choisir un fichier…'))),
      ],
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _epg,
      decoration: _field(tr('Guide TV (XMLTV) — facultatif'), hint: tr('Laisser vide : guide indiqué par le fournisseur')),
    ),
  ];

  List<Widget> _folderForm() => [
    Text(tr('Dossiers à examiner'), style: kText(13, weight: FontWeight.w600)),
    const SizedBox(height: 6),
    if (_folders.isEmpty)
      Text(tr('Aucun dossier pour l\'instant.'), style: kText(12, color: KPalette.secondaryText))
    else
      for (final f in _folders)
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
          child: Row(
            children: [
              Icon(Icons.folder_outlined, size: 18, color: KPalette.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(f, style: kText(13), overflow: TextOverflow.ellipsis),
              ),
              IconButton(tooltip: tr('Retirer'), iconSize: 18, onPressed: () => setState(() => _folders.remove(f)), icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ),
    const SizedBox(height: 8),
    Row(
      children: [
        OutlinedButton.icon(onPressed: _addFolder, icon: const Icon(Icons.create_new_folder_outlined, size: 18), label: Text(tr('Ajouter un dossier…'))),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _networkPath,
            decoration: _field(tr('ou chemin réseau'), hint: r'\\NAS\Vidéos  —  /mnt/nas/videos'),
            onSubmitted: (_) => _addNetworkPath(),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(tooltip: tr('Ajouter'), onPressed: _addNetworkPath, icon: const Icon(Icons.add_rounded)),
      ],
    ),
    const SizedBox(height: 8),
    Text(
      tr(
        'Disque interne, clé ou disque USB, ou partage d\'un NAS déjà connecté à l\'ordinateur (lecteur réseau sous Windows, partage monté sous Linux). '
        'Les films (« Titre (2020).mkv »), les séries (« Série S01E02 ») et les autres vidéos sont reconnus d\'après leur nom ; '
        'avec une clé TMDB, ils reçoivent affiches et fiches. Les sous-titres .srt placés à côté sont chargés à la lecture.',
      ),
      style: kText(12, color: KPalette.secondaryText),
    ),
  ];

  List<Widget> _jellyfin() => [
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _server,
            decoration: _field(tr('Adresse du serveur'), hint: 'http://192.168.1.10:8096'),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _test, child: Text(tr('Tester'))),
      ],
    ),
    const SizedBox(height: 12),
    TextField(controller: _user, decoration: _field(tr('Identifiant'))),
    const SizedBox(height: 12),
    TextField(
      controller: _pass,
      obscureText: !_showPassword,
      decoration: _field(tr('Mot de passe (ou clé d\'API)'), suffix: _eye),
    ),
    const SizedBox(height: 8),
    Text(
      tr(
        'Les bibliothèques de films, de séries et de vidéos du serveur apparaissent dans Films et Séries. La lecture est directe (sans conversion) '
        'et la reprise de lecture ainsi que les contenus vus sont partagés avec le serveur et ses autres appareils.',
      ),
      style: kText(12, color: KPalette.secondaryText),
    ),
  ];

  List<Widget> _plex() => [
    Row(
      children: [
        FilledButton.icon(
          onPressed: _pin != null ? null : _plexSignIn,
          icon: const Icon(Icons.login_rounded, size: 18),
          label: Text(_pin != null ? '${tr('En attente de plex.tv')} (${_pin!.code})' : tr('Se connecter avec Plex')),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(tr('ou saisissez le jeton du serveur ci-dessous.'), style: kText(12, color: KPalette.secondaryText)),
        ),
      ],
    ),
    if (_plexServers.isNotEmpty) ...[
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in _plexServers)
            ChoiceChip(
              label: Text('${s.$1} · ${s.$2.isEmpty ? '?' : Uri.tryParse(s.$2.first)?.authority ?? s.$2.first}'),
              selected: s.$2.contains(_server.text),
              onSelected: s.$2.isEmpty ? null : (_) => _choosePlex(s),
            ),
        ],
      ),
    ],
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _server,
            decoration: _field(tr('Adresse du serveur'), hint: 'http://192.168.1.10:32400'),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _test, child: Text(tr('Tester'))),
      ],
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _token,
      obscureText: !_showPassword,
      decoration: _field(_editing ? tr('Jeton Plex (laisser vide : inchangé)') : tr('Jeton Plex (X-Plex-Token)'), suffix: _eye),
    ),
    const SizedBox(height: 8),
    Text(
      tr(
        '« Se connecter avec Plex » ouvre plex.tv dans le navigateur : autorisez Kastideo, et les serveurs de votre compte sont proposés. '
        'Les bibliothèques de films et de séries apparaissent dans Films et Séries, avec la reprise de lecture partagée.',
      ),
      style: kText(12, color: KPalette.secondaryText),
    ),
  ];
}
