import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/details.dart';
import '../core/guide.dart';
import '../core/models.dart';
import '../core/settings.dart';
import '../l10n.dart';
import '../theme.dart';
import '../version.dart';

enum SettingsTab { general, appearance, sources, categories, backup }

/// Fenêtre Réglages (Ctrl+,) : Général, Apparence, Sources, Catégories, Sauvegarde.
Future<void> showSettingsDialog(BuildContext context,
        {SettingsTab tab = SettingsTab.general, MediaKind categoryKind = MediaKind.live, bool startAdding = false}) =>
    showDialog(
      context: context,
      builder: (_) => _SettingsDialog(initial: tab, categoryKind: categoryKind, startAdding: startAdding),
    );

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.initial, required this.categoryKind, required this.startAdding});
  final SettingsTab initial;
  final MediaKind categoryKind;
  final bool startAdding;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late SettingsTab _tab = widget.initial;

  static const _tabs = [
    (SettingsTab.general, Icons.tune_rounded, 'Général'),
    (SettingsTab.appearance, Icons.palette_outlined, 'Apparence'),
    (SettingsTab.sources, Icons.settings_input_antenna_rounded, 'Sources'),
    (SettingsTab.categories, Icons.folder_outlined, 'Catégories'),
    (SettingsTab.backup, Icons.import_export_rounded, 'Sauvegarde'),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF242426),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 660),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(children: [
              Text(tr('Réglages'), style: kRounded(24, FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer'))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              for (final (tab, icon, label) in _tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(icon, size: 16),
                    label: Text(tr(label)),
                    selected: _tab == tab,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _tab = tab),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: KPalette.separator),
          Expanded(
            child: switch (_tab) {
              SettingsTab.general => const _GeneralTab(),
              SettingsTab.appearance => const _AppearanceTab(),
              SettingsTab.sources => _SourcesTab(startAdding: widget.startAdding),
              SettingsTab.categories => CategoryManager(initialKind: widget.categoryKind),
              SettingsTab.backup => const _BackupTab(),
            },
          ),
        ]),
      ),
    );
  }
}

Widget _section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: kText(13, weight: FontWeight.w700, color: Colors.white60)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ]),
    );

Widget _caption(String text) =>
    Padding(padding: const EdgeInsets.only(top: 4), child: Text(text, style: kText(12, color: Colors.white54)));

class _GeneralTab extends StatefulWidget {
  const _GeneralTab();

  @override
  State<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<_GeneralTab> {
  late final TextEditingController _tmdb = TextEditingController(text: context.settings.tmdbKey);
  String? _tmdbStatus;

  @override
  void dispose() {
    _tmdb.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final settings = context.settings;
    final info = context.info;
    await settings.setTMDBKey(_tmdb.text);
    info.clear();
    if (!settings.usesTMDB) {
      setState(() => _tmdbStatus = tr('Clé retirée : les fiches utilisent seulement les informations du fournisseur.'));
      return;
    }
    setState(() => _tmdbStatus = tr('Vérification…'));
    final ok = await TMDBClient(settings.tmdbKey, 'fr-FR').check();
    if (mounted) setState(() => _tmdbStatus = ok ? tr('Clé valide : les fiches sont complétées par TMDB.') : tr('Clé refusée par TMDB.'));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => ListView(padding: const EdgeInsets.all(20), children: [
        _section(tr('Langue'), [
          DropdownButton<String>(
            value: settings.language,
            items: [
              DropdownMenuItem(value: 'system', child: Text(tr('Langue du système'))),
              const DropdownMenuItem(value: 'fr', child: Text('Français')),
              const DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (v) => settings.setLanguage(v ?? 'system'),
          ),
          _caption(tr('Le changement s\'applique au prochain lancement de Kastideo.')),
        ]),
        _section(tr('Lecture'), [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Reprendre les films et épisodes là où vous vous êtes arrêté'), style: kText(14)),
            value: settings.resumePlayback,
            onChanged: settings.setResume,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Relais de flux pour le direct (une seule connexion au fournisseur)'), style: kText(14)),
            value: settings.relayEnabled,
            onChanged: settings.setRelay,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Actualiser les sources au démarrage (si plus de 6 h)'), style: kText(14)),
            value: settings.autoRefresh,
            onChanged: settings.setAutoRefresh,
          ),
          Row(children: [
            OutlinedButton(onPressed: context.library.clearRecents, child: Text(tr('Effacer les récents'))),
          ]),
        ]),
        const _GuideSection(),
        _section(tr('Contenus adultes'), [
          ListenableBuilder(
            listenable: context.library,
            builder: (context, _) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Afficher les contenus adultes'), style: kText(14)),
              value: context.library.showAdult,
              onChanged: context.library.setShowAdult,
            ),
          ),
          _caption(tr('Chaînes et contenus dont le nom contient « |XX| » ou rangés dans une catégorie adulte : masqués partout (listes, recherche, thèmes) tant que l\'option est désactivée.')),
        ]),
        _section(tr('Fiches des films et séries (TMDB)'), [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _tmdb,
                obscureText: true,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  labelText: tr('Clé API TMDB (v3) ou jeton de lecture (v4)'),
                ),
                onSubmitted: (_) => _saveKey(),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: KPalette.accent), onPressed: _saveKey, child: Text(tr('Enregistrer'))),
          ]),
          if (_tmdbStatus != null) _caption(_tmdbStatus!),
          _caption(tr('Facultatif et gratuit : affiches, résumés, distribution et bandes-annonces plus complets. Créez un compte sur themoviedb.org, puis Paramètres > API.')),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://www.themoviedb.org/settings/api')),
            child: Text(tr('Obtenir une clé TMDB')),
          ),
        ]),
        _section(tr('À propos'), [
          Text('Kastideo $kVersion · ${Platform.operatingSystem}', style: kText(13, color: Colors.white70)),
        ]),
      ]),
    );
  }
}

class _AppearanceTab extends StatelessWidget {
  const _AppearanceTab();

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    Widget row(MediaKind kind, String label, {bool cinemaAvailable = true}) {
      final current = settings.interfaceFor(kind);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 120, child: Text(label, style: kText(14))),
          SegmentedButton<InterfaceStyle>(
            segments: [
              ButtonSegment(value: InterfaceStyle.classic, label: Text(tr('Classique')), icon: const Icon(Icons.view_list_rounded)),
              ButtonSegment(
                  value: InterfaceStyle.cinema, label: Text(tr('Cinéma')), icon: const Icon(Icons.view_module_rounded), enabled: cinemaAvailable),
              ButtonSegment(value: InterfaceStyle.tv, label: Text(tr('TV')), icon: const Icon(Icons.tv_rounded), enabled: kind == MediaKind.live),
            ],
            selected: {current},
            onSelectionChanged: (v) => settings.setInterface(kind, v.first),
          ),
        ]),
      );
    }

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => ListView(padding: const EdgeInsets.all(20), children: [
        _section(tr('Interface par type de contenu'), [
          row(MediaKind.live, tr('Direct')),
          row(MediaKind.movie, tr('Films')),
          row(MediaKind.series, tr('Séries')),
          _caption(tr('Classique : trois colonnes (catégories, liste, lecteur ou fiche). Cinéma : bandeau « à la une », affiches ou vignettes et rangées '
              '(ce qui passe par thème, ce soir, catégories). TV (direct seulement) : chaîne en plein cadre, zapping par numéro ou ↑ / ↓, panneau des chaînes (←) et bandeau d\'information.')),
        ]),
        const _HeroSection(),
      ]),
    );
  }
}

class _SourcesTab extends StatefulWidget {
  const _SourcesTab({required this.startAdding});
  final bool startAdding;

  @override
  State<_SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends State<_SourcesTab> {
  late bool _adding = widget.startAdding;
  bool _xtream = true;
  bool _saving = false;
  String? _error;
  final _name = TextEditingController();
  final _server = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _address = TextEditingController();
  final _epg = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _server, _user, _pass, _address, _epg]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final library = context.library;
    try {
      if (_xtream) {
        await library.addXtream(name: _name.text, server: _server.text, username: _user.text, password: _pass.text, epgUrl: _epg.text);
      } else {
        await library.addM3U(name: _name.text, address: _address.text, epgUrl: _epg.text);
      }
      setState(() {
        _error = library.lastError;
        if (_error == null) _adding = false;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFile() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'M3U', extensions: ['m3u', 'm3u8', 'txt']),
    ]);
    if (file != null) setState(() => _address.text = file.path);
  }

  InputDecoration _field(String label, {String? hint}) =>
      InputDecoration(labelText: label, hintText: hint, isDense: true, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) => ListView(padding: const EdgeInsets.all(20), children: [
        if (!_adding) ...[
          if (library.sources.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(tr('Ajoutez votre abonnement IPTV (Xtream Codes ou playlist M3U) pour commencer.'),
                  style: kText(13, color: KPalette.secondaryText)),
            ),
          for (final source in library.sources) _sourceRow(source),
          const SizedBox(height: 12),
          Row(children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: KPalette.magenta),
              onPressed: () => setState(() => _adding = true),
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('Ajouter une source')),
            ),
            const SizedBox(width: 10),
            if (library.sources.isNotEmpty)
              OutlinedButton.icon(
                onPressed: library.isBusy ? null : library.refreshAll,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(tr('Tout actualiser')),
              ),
          ]),
          if (library.lastError != null) _caption(library.lastError!),
        ] else
          _addForm(),
      ]),
    );
  }

  Widget _sourceRow(Source source) {
    final library = context.library;
    int count(MediaKind k) => library.items(k).where((i) => i.sourceId == source.id).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(source.kind == SourceKind.xtream ? Icons.dns_rounded : Icons.playlist_play_rounded, color: KPalette.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(source.name, style: kText(14, weight: FontWeight.w600)),
            Text(
              '${source.kind == SourceKind.xtream ? 'Xtream Codes' : 'Playlist M3U'} · ${count(MediaKind.live)} ${tr('chaînes')} · '
              '${count(MediaKind.movie)} ${tr('films')} · ${count(MediaKind.series)} ${tr('séries')}',
              style: kText(12, color: KPalette.secondaryText),
            ),
            _SourceGuideLine(source: source),
          ]),
        ),
        if (library.isBusy) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        IconButton(
          tooltip: tr('Actualiser'),
          onPressed: library.isBusy ? null : () => library.refresh(source),
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: tr('Supprimer'),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(tr('Supprimer cette source ?')),
                content: Text(source.name),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Annuler'))),
                  FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Supprimer'))),
                ],
              ),
            );
            if (ok == true) library.removeSource(source);
          },
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ]),
    );
  }

  Widget _addForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('Xtream Codes'), icon: Icon(Icons.dns_rounded)),
          ButtonSegment(value: false, label: Text('Playlist M3U'), icon: Icon(Icons.playlist_play_rounded)),
        ],
        selected: {_xtream},
        onSelectionChanged: (v) => setState(() => _xtream = v.first),
      ),
      const SizedBox(height: 16),
      TextField(controller: _name, decoration: _field(tr('Nom'), hint: tr('Mon abonnement'))),
      const SizedBox(height: 12),
      if (_xtream) ...[
        TextField(controller: _server, decoration: _field(tr('Serveur'), hint: 'http://exemple.com:8080')),
        const SizedBox(height: 12),
        TextField(controller: _user, decoration: _field(tr('Identifiant'))),
        const SizedBox(height: 12),
        TextField(controller: _pass, obscureText: true, decoration: _field(tr('Mot de passe'))),
      ] else
        Row(children: [
          Expanded(
            child: TextField(
              controller: _address,
              decoration: _field(tr('Adresse de la playlist ou chemin du fichier'), hint: 'http://…/get.php?username=…&password=…'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: _pickFile, child: Text(tr('Choisir un fichier…'))),
        ]),
      const SizedBox(height: 12),
      TextField(
        controller: _epg,
        decoration: _field(tr('Guide TV (XMLTV) — facultatif'), hint: tr('Laisser vide : guide indiqué par le fournisseur')),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: kText(13, color: KPalette.orange)),
      ],
      const SizedBox(height: 18),
      Row(children: [
        if (_saving) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        const Spacer(),
        TextButton(onPressed: _saving ? null : () => setState(() => _adding = false), child: Text(tr('Annuler'))),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: KPalette.magenta),
          onPressed: _saving ? null : _save,
          child: Text(tr('Ajouter')),
        ),
      ]),
    ]);
  }
}

/// Gestionnaire de catégories (comme sur Mac) : ordre par glisser-déposer, masquage, renommage, mots-clés.
class CategoryManager extends StatefulWidget {
  const CategoryManager({super.key, required this.initialKind});
  final MediaKind initialKind;

  @override
  State<CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends State<CategoryManager> {
  late MediaKind _kind = widget.initialKind == MediaKind.episode ? MediaKind.series : widget.initialKind;
  final _keyword = TextEditingController();

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _rename(String name) async {
    final library = context.library;
    final controller = TextEditingController(text: library.prefs(_kind).renames[name] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Renommer la catégorie')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: name, helperText: tr('Laisser vide pour revenir au nom du fournisseur')),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Annuler'))),
          FilledButton(onPressed: () => Navigator.pop(c, controller.text), child: Text(tr('Enregistrer'))),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    library.updateCategories(_kind, (p) {
      if (result.trim().isEmpty) {
        p.renames.remove(name);
      } else {
        p.renames[name] = result.trim();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        final prefs = library.prefs(_kind);
        final names = library.allCategories(_kind);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SegmentedButton<MediaKind>(
                segments: [
                  ButtonSegment(value: MediaKind.live, label: Text(tr('Direct'))),
                  ButtonSegment(value: MediaKind.movie, label: Text(tr('Films'))),
                  ButtonSegment(value: MediaKind.series, label: Text(tr('Séries'))),
                ],
                selected: {_kind},
                onSelectionChanged: (v) => setState(() => _kind = v.first),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => library.updateCategories(_kind, (p) => p.order = [...names]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))),
                child: Text(tr('Trier de A à Z')),
              ),
              TextButton(
                onPressed: () => library.updateCategories(_kind, (p) {
                  p.order = [];
                  p.hidden = {};
                  p.renames = {};
                  p.keywords = [];
                }),
                child: Text(tr('Rétablir')),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _keyword,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    labelText: tr('Masquer les catégories contenant… (ex. PAKISTAN, ARABIC)'),
                  ),
                  onSubmitted: (_) => _addKeyword(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _addKeyword, child: Text(tr('Ajouter'))),
            ]),
            if (prefs.keywords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final k in prefs.keywords)
                  InputChip(label: Text(k), onDeleted: () => library.updateCategories(_kind, (p) => p.keywords.remove(k))),
              ]),
            ],
            const SizedBox(height: 10),
            Text(tr('Glissez pour changer l\'ordre ; décochez pour masquer partout ; double-clic pour renommer.'),
                style: kText(12, color: Colors.white54)),
            const SizedBox(height: 6),
            Expanded(
              child: names.isEmpty
                  ? Center(child: Text(tr('Aucune catégorie'), style: kText(13, color: Colors.white54)))
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: names.length,
                      onReorderItem: (from, to) {
                        final list = [...names];
                        final moved = list.removeAt(from);
                        list.insert(to, moved);
                        library.updateCategories(_kind, (p) => p.order = list);
                      },
                      itemBuilder: (context, i) {
                        final name = names[i];
                        final byKeyword = prefs.isHiddenByKeyword(name);
                        final visible = !prefs.isHidden(name);
                        return Container(
                          key: ValueKey(name),
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(6)),
                          child: Row(children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_indicator_rounded, size: 18, color: Colors.white38)),
                            ),
                            Checkbox(
                              value: visible,
                              onChanged: byKeyword
                                  ? null
                                  : (v) => library.updateCategories(_kind, (p) => v == true ? p.hidden.remove(name) : p.hidden.add(name)),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onDoubleTap: () => _rename(name),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(prefs.displayName(name), style: kText(13, color: visible ? Colors.white : Colors.white38)),
                                  if (prefs.renames.containsKey(name)) Text(name, style: kText(11, color: Colors.white38)),
                                  if (byKeyword) Text(tr('Masquée par un mot-clé'), style: kText(11, color: KPalette.orange)),
                                ]),
                              ),
                            ),
                            Text('${library.itemsInCategory(_kind, name).length}', style: kText(12, color: Colors.white38)),
                            IconButton(
                              tooltip: tr('Renommer'),
                              onPressed: () => _rename(name),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                            ),
                            const SizedBox(width: 24),
                          ]),
                        );
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }

  void _addKeyword() {
    final word = _keyword.text.trim();
    if (word.isEmpty) return;
    context.library.updateCategories(_kind, (p) {
      if (!p.keywords.contains(word)) p.keywords.add(word);
    });
    _keyword.clear();
  }
}

class _BackupTab extends StatefulWidget {
  const _BackupTab();

  @override
  State<_BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<_BackupTab> {
  bool _includePasswords = true;
  String? _message;
  bool _busy = false;

  Future<void> _export() async {
    final location = await getSaveLocation(
      suggestedName: 'Kastideo-configuration.json',
      acceptedTypeGroups: [const XTypeGroup(label: 'JSON', extensions: ['json'])],
    );
    if (location == null || !mounted) return;
    final data = await context.library
        .makeExport(includePasswords: _includePasswords, settings: context.settings, app: Platform.isWindows ? 'windows' : 'linux');
    await File(location.path).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    setState(() => _message = '${tr('Configuration exportée')} : ${(data['sources'] as List).length} ${tr('source(s)')}, '
        '${(data['favorites'] as List).length} ${tr('favori(s)')}.');
  }

  Future<void> _import() async {
    final file = await openFile(acceptedTypeGroups: [const XTypeGroup(label: 'JSON', extensions: ['json'])]);
    if (file == null || !mounted) return;
    setState(() {
      _busy = true;
      _message = tr('Importation en cours…');
    });
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (!mounted) return;
      final result = await context.library.importConfig(data, context.settings);
      setState(() => _message = result);
    } catch (e) {
      setState(() => _message = '${tr('Fichier illisible')} : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        _section(tr('Sauvegarde et transfert'), [
          Text(
            tr('Le fichier de configuration permet de retrouver vos sources, favoris, récents, catégories et réglages '
                'sur un autre ordinateur : Mac, Windows ou Linux. Il est compatible avec Kastideo pour Mac (Réglages > Général > Sauvegarde et transfert).'),
            style: kText(13, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _includePasswords,
            onChanged: (v) => setState(() => _includePasswords = v ?? true),
            title: Text(tr('Inclure les mots de passe dans le fichier'), style: kText(14)),
          ),
          _caption(tr('S\'il contient les mots de passe, gardez-le en lieu sûr. Les playlists M3U enregistrées comme fichiers locaux ne sont pas exportées.')),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: KPalette.accent),
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(tr('Exporter la configuration…')),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_rounded),
              label: Text(tr('Importer une configuration…')),
            ),
          ]),
          if (_message != null) ...[const SizedBox(height: 10), Text(_message!, style: kText(13, color: Colors.white70))],
        ]),
      ]);
}

/// Guide TV d'une source (nombre de programmes ou erreur).
class _SourceGuideLine extends StatelessWidget {
  const _SourceGuideLine({required this.source});
  final Source source;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: context.guide,
        builder: (context, _) {
          final s = context.guide.status[source.id];
          final String text;
          if (s?.loading ?? false) {
            text = tr('Guide TV : chargement…');
          } else if (s?.error != null) {
            text = '${tr('Guide TV')} : ${s!.error}';
          } else if ((s?.programmes ?? 0) > 0) {
            text = '${tr('Guide TV')} : ${s!.programmes} ${tr('programmes')}';
          } else {
            text = tr('Guide TV : pas encore chargé');
          }
          return Text(text,
              style: kText(12, color: s?.error != null ? KPalette.orange : Colors.white38), maxLines: 2, overflow: TextOverflow.ellipsis);
        },
      );
}

/// Réglages : guide TV (fournisseurs et guide de secours).
class _GuideSection extends StatefulWidget {
  const _GuideSection();

  @override
  State<_GuideSection> createState() => _GuideSectionState();
}

class _GuideSectionState extends State<_GuideSection> {
  late final TextEditingController _url = TextEditingController(text: context.guide.fallbackUrlText);

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  String _ago(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inMinutes < 1) return tr('à l\'instant');
    final (n, unit) = d.inHours < 1 ? (d.inMinutes, 'min') : d.inDays < 1 ? (d.inHours, 'h') : (d.inDays, L10n.english ? 'd' : 'j');
    return L10n.english ? '$n $unit ago' : 'il y a $n $unit';
  }

  @override
  Widget build(BuildContext context) {
    final guide = context.guide;
    return ListenableBuilder(
      listenable: guide,
      builder: (context, _) {
        final f = guide.fallbackStatus;
        final String status;
        if (f.error != null) {
          status = f.error!;
        } else if (f.updated != null) {
          status = '${f.channelCount} ${tr('chaînes')}, ${f.matchedChannels} ${tr('reliées à vos chaînes')} · ${tr('mis à jour')} ${_ago(f.updated!)}';
        } else {
          status = f.loading ? tr('Chargement…') : tr('Pas encore chargé.');
        }
        return _section(tr('Guide TV'), [
          Row(children: [
            Expanded(
              child: Text('${guide.epg.channelCount} ${tr('chaînes ont un programme')} · ${guide.groups.length} ${tr('chaînes classées par thème')}',
                  style: kText(13, color: Colors.white70)),
            ),
            if (guide.isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: guide.isLoading ? null : guide.refreshAll,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr('Actualiser le guide')),
            ),
          ]),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Compléter le guide du fournisseur avec un guide de secours'), style: kText(14)),
            value: guide.fallbackEnabled,
            onChanged: guide.setFallbackEnabled,
          ),
          if (guide.fallbackEnabled) ...[
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _url,
                  style: kText(13),
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    labelText: tr('Adresse du guide (XMLTV, .xml ou .xml.gz)'),
                  ),
                  onSubmitted: guide.setFallbackUrl,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: tr('Choisir'),
                color: const Color(0xF02C2C2E),
                onSelected: (url) {
                  _url.text = url;
                  guide.setFallbackUrl(url);
                },
                itemBuilder: (_) => [
                  for (final p in GuideStore.presets) PopupMenuItem(value: p.url, child: Text(p.label, style: kText(13))),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(children: [Text(tr('Choisir'), style: kText(13)), const Icon(Icons.arrow_drop_down_rounded)]),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text(status, style: kText(12, color: f.error != null ? KPalette.orange : Colors.white54))),
              TextButton(
                onPressed: f.loading ? null : () => guide.setFallbackUrl(_url.text),
                child: Text(tr('Actualiser maintenant')),
              ),
            ]),
          ],
          _caption(tr('Les chaînes sans programme dans le guide de votre fournisseur sont complétées automatiquement, en les rapprochant '
              'par leur nom (« |FR| TF1 FHD » → TF1). Guide gratuit et communautaire de xmltvfr.fr, mis à jour chaque jour, rechargé toutes les 12 heures.')),
        ]);
      },
    );
  }
}

/// Réglages : bandeau « à la une » de l'interface Cinéma.
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([context.settings, context.library]),
        builder: (context, _) => _content(context),
      );

  Widget _content(BuildContext context) {
    final settings = context.settings;
    final library = context.library;
    Widget toggle(String label, bool value, ValueChanged<bool>? onChanged) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label, style: kText(14, color: onChanged == null ? Colors.white38 : Colors.white)),
          value: value,
          onChanged: onChanged,
        );
    Widget categoryPicker(String label, MediaKind kind) {
      final names = library.categories(kind);
      final current = settings.heroCategory(kind);
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          SizedBox(width: 190, child: Text(label, style: kText(13))),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: names.contains(current) ? current : '',
              items: [
                DropdownMenuItem(value: '', child: Text(tr('Tout le catalogue (au hasard)'), style: kText(13))),
                for (final n in names)
                  DropdownMenuItem(value: n, child: Text(library.categoryName(kind, n), style: kText(13), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => settings.setHeroCategory(kind, v ?? ''),
            ),
          ),
        ]),
      );
    }

    return _section(tr('Bandeau « à la une » (Cinéma)'), [
      toggle(tr('Afficher le bandeau « à la une »'), settings.heroEnabled, (v) => settings.setHero(enabled: v)),
      if (settings.heroEnabled) ...[
        Row(children: [
          SizedBox(width: 120, child: Text(tr('Hauteur'), style: kText(13))),
          SegmentedButton<HeroHeight>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: HeroHeight.compact, label: Text(tr('Compact'))),
              ButtonSegment(value: HeroHeight.normal, label: Text(tr('Normal'))),
              ButtonSegment(value: HeroHeight.large, label: Text(tr('Grand'))),
            ],
            selected: {settings.heroHeight},
            onSelectionChanged: (v) => settings.setHero(height: v.first),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          SizedBox(width: 120, child: Text(tr('Défilement'), style: kText(13))),
          DropdownButton<double>(
            value: const [6.0, 8.0, 12.0, 20.0].contains(settings.heroInterval) ? settings.heroInterval : 8.0,
            items: [
              for (final s in const [6.0, 8.0, 12.0, 20.0])
                DropdownMenuItem(value: s, child: Text('${tr('Toutes les')} ${s.round()} s', style: kText(13))),
            ],
            onChanged: (v) => settings.setHero(interval: v),
          ),
        ]),
        toggle(tr('Tendances de la semaine (TMDB) disponibles dans votre catalogue'), settings.heroUseTrending,
            settings.usesTMDB ? (v) => settings.setHero(trending: v) : null),
        toggle(tr('Derniers ajouts du fournisseur'), settings.heroUseRecent, (v) => settings.setHero(recent: v)),
        toggle(tr('Sélection d\'une catégorie'), settings.heroUseCategory, (v) => settings.setHero(category: v)),
        if (settings.heroUseCategory) ...[
          categoryPicker(tr('Catégorie des films'), MediaKind.movie),
          categoryPicker(tr('Catégorie des séries'), MediaKind.series),
        ],
      ],
      _caption(tr('Le bandeau fait défiler les films ou séries choisis, avec image de fond, résumé et note ; il s\'arrête quand la souris le survole. '
          'En Direct, il montre le programme en cours de vos chaînes favorites et récentes (à défaut, des grandes chaînes d\'info et de sport). '
          'Les tendances nécessitent une clé TMDB (Réglages > Général).')),
    ]);
  }
}
