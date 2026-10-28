import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/log.dart';
import '../l10n.dart';
import '../theme.dart';
import '../version.dart';

/// Fenêtre « Journal » (Ctrl+Alt+L) : messages classés par sujet, avec recherche, niveaux de détail et copie du filtre.
Future<void> showLogDialog(BuildContext context, {LogTopic? topic}) =>
    showKDialog(
      context: context,
      builder: (_) => DarkZone(child: _LogDialog(topic: topic)),
    );

class _LogDialog extends StatefulWidget {
  const _LogDialog({this.topic});

  /// Sujet pré-sélectionné (par exemple « Guide TV » depuis les réglages).
  final LogTopic? topic;

  @override
  State<_LogDialog> createState() => _LogDialogState();
}

class _LogDialogState extends State<_LogDialog> {
  final log = PlaybackLog.shared;
  final Set<LogTopic> topics = {};
  final search = TextEditingController();
  bool errorsOnly = false;
  bool previous = false;
  List<LogLine> previousLines = [];
  bool copied = false;
  final scroll = ScrollController();
  bool _stick = true;

  @override
  void initState() {
    super.initState();
    if (widget.topic != null) topics.add(widget.topic!);
  }

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  List<LogLine> _shown() => previous ? previousLines : log.lines;

  List<LogLine> _filtered(List<LogLine> source) {
    final needle = search.text.trim().toLowerCase();
    return [
      for (final l in source)
        if ((topics.isEmpty || topics.contains(l.topic)) &&
            (!errorsOnly || l.level <= 1) &&
            (needle.isEmpty || l.text.toLowerCase().contains(needle)))
          l,
    ];
  }

  String _filterText() {
    final parts = <String>[
      previous ? 'session précédente' : 'session en cours',
    ];
    if (topics.isNotEmpty) {
      parts.add('sujets : ${LogTopic.values.where(topics.contains).map((t) => t.title).join(', ')}');
    }
    if (errorsOnly) parts.add('erreurs et alertes');
    if (search.text.trim().isNotEmpty) {
      parts.add('recherche « ${search.text.trim()} »');
    }
    return parts.join(' · ');
  }

  Future<void> _setPrevious(bool value) async {
    final lines = value ? await log.previousSession() : <LogLine>[];
    if (!mounted) return;
    setState(() {
      previous = value;
      previousLines = lines;
    });
  }

  Future<void> _copy(List<LogLine> filtered) async {
    await Clipboard.setData(
      ClipboardData(
        text: log.export(kVersion, selection: filtered, filter: _filterText()),
      ),
    );
    if (!mounted) return;
    setState(() => copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ListenableBuilder(
            listenable: log,
            builder: (context, _) {
              final shown = _shown();
              final filtered = _filtered(shown);
              final counts = <LogTopic, int>{};
              for (final l in shown) {
                counts[l.topic] = (counts[l.topic] ?? 0) + 1;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tr('Journal'),
                        style: kRoundedD(22, FontWeight.w800),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _copy(filtered),
                        icon: Icon(
                          copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 18,
                        ),
                        label: Text(
                          copied ? tr('Copié ✓') : tr("Copier l'affichage"),
                        ),
                      ),
                      TextButton(
                        onPressed: previous ? null : log.clear,
                        child: Text(tr('Effacer')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('Fermer')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        tr('Sujets'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      for (final t in LogTopic.values)
                        FilterChip(
                          label: Text(
                            '${t.title} ${counts[t] ?? 0}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: topics.contains(t),
                          visualDensity: VisualDensity.compact,
                          onSelected: (on) => setState(
                            () => on ? topics.add(t) : topics.remove(t),
                          ),
                        ),
                      if (topics.isNotEmpty)
                        IconButton(
                          onPressed: () => setState(topics.clear),
                          tooltip: tr('Tous'),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SegmentedButton<bool>(
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(
                              tr('Session en cours'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(
                              tr('Session précédente'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        selected: {previous},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => _setPrevious(s.first),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: search,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: tr('Rechercher dans le journal'),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: errorsOnly,
                        onChanged: (v) =>
                            setState(() => errorsOnly = v ?? false),
                      ),
                      Text(
                        tr('Erreurs et alertes'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => _showDetailDialog(context),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: Text(tr('Niveau de détail')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.axis == Axis.vertical) {
                            _stick = n.metrics.pixels >= n.metrics.maxScrollExtent - 30;
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.all(10),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            if (i == filtered.length - 1 &&
                                !previous &&
                                _stick) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (scroll.hasClients) {
                                  scroll.jumpTo(scroll.position.maxScrollExtent);
                                }
                              });
                            }
                            final l = filtered[i];
                            final t = l.date;
                            String two(int v) => v.toString().padLeft(2, '0');
                            final day = previous
                                ? '${two(t.day)}/${two(t.month)} '
                                : '';
                            final color = switch (l.level) {
                              0 => Colors.redAccent,
                              1 => Colors.orangeAccent,
                              _ => Colors.white70,
                            };
                            return SelectableText(
                              '$day${two(t.hour)}:${two(t.minute)}:${two(t.second)}  ${l.levelLabel.padRight(6)} ${l.topic.title.padRight(22)} ${l.text}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: color,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${filtered.length} ${tr('ligne(s) affichée(s) sur')} ${shown.length}. '
                    '${tr('Identifiants et mots de passe masqués : le journal peut être copié pour être partagé.')}'
                    '${log.logsPath == null ? '' : '  ${tr('Dossier du journal :')} ${log.logsPath}'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Niveau de détail enregistré par sujet : s'applique aux lignes écrites à partir de maintenant.
  Future<void> _showDetailDialog(BuildContext context) {
    return showKDialog(
      context: context,
      builder: (_) => DarkZone(
        child: Dialog(
          backgroundColor: const Color(0xFF1C1C1E),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ListenableBuilder(
                listenable: log,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Niveau de détail'),
                      style: kRoundedD(20, FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        '« Débogage » écrit davantage de lignes : à réserver à la recherche d\'un problème. Les erreurs et alertes sont toujours gardées.',
                      ),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final t in LogTopic.values)
                      Row(
                        children: [
                          Expanded(child: Text(t.title)),
                          DropdownButton<LogDetail>(
                            value: log.detail(t),
                            dropdownColor: const Color(0xFF2A2A2D),
                            items: [
                              for (final d in LogDetail.values)
                                DropdownMenuItem(
                                  value: d,
                                  child: Text(d.title),
                                ),
                            ],
                            onChanged: (d) {
                              if (d != null) log.setDetail(t, d);
                            },
                          ),
                        ],
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('Fermer')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
