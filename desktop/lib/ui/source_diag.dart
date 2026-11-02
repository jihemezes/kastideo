import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../core/models.dart';
import '../core/themes.dart';
import '../l10n.dart';
import '../theme.dart';

/// « Diagnostic » d'une source : ce que le fournisseur renvoie et ce que Kastideo en affiche (comparer deux comptes).
Future<void> showSourceDiagnostic(BuildContext context, Source source) =>
    showKDialog<void>(context: context, builder: (_) => _SourceDiagDialog(source: source));

class _SourceDiagDialog extends StatefulWidget {
  const _SourceDiagDialog({required this.source});
  final Source source;

  @override
  State<_SourceDiagDialog> createState() => _SourceDiagDialogState();
}

class _SourceDiagDialogState extends State<_SourceDiagDialog> {
  String _report = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  Future<void> _build() async {
    final library = context.library;
    final source = widget.source;
    final b = StringBuffer();
    b.writeln('${source.name} · ${tr(source.kind.label)}');
    final host = Uri.tryParse(source.address)?.host ?? '';
    if (host.isNotEmpty) b.writeln('${tr('Serveur')} : $host');
    if (source.kind == SourceKind.xtream) {
      try {
        final client = await library.xtreamClient(source.id);
        final info = await client?.accountInfo() ?? const {};
        if (info.isNotEmpty) {
          b.writeln('${tr('Compte')} : ${info.entries.map((e) => '${e.key}=${e.value}').join(' · ')}');
        }
      } catch (e) {
        b.writeln('${tr('Compte')} : ${tr('illisible')} ($e)');
      }
    }
    b.writeln();
    final showAdult = library.showAdult;
    final raw = library.contentOf(source.id);
    for (final kind in [MediaKind.live, MediaKind.movie, MediaKind.series]) {
      final all = raw.where((i) => i.kind == kind).toList();
      if (all.isEmpty && !source.kind.isIptv) continue;
      final prefs = library.prefs(kind);
      final categories = all.map((i) => i.group).toSet();
      final inHidden = all.where((i) => prefs.isHidden(i.group)).length;
      final adult = showAdult ? 0 : all.where((i) => !prefs.isHidden(i.group) && ThemeClassifier.isAdult(i.name, group: i.group)).length;
      final visible = library.items(kind).where((i) => i.sourceId == source.id).length;
      final other = all.length - inHidden - adult - visible;
      final label = switch (kind) { MediaKind.live => tr('Chaînes'), MediaKind.movie => tr('Films'), _ => tr('Séries') };
      b.writeln('$label : ${all.length} ${tr('renvoyés par le fournisseur')} (${categories.length} ${tr('catégories')})');
      b.writeln('   ${tr('Affichés')} : $visible');
      if (inHidden > 0) b.writeln('   ${tr('Dans des catégories masquées')} : $inHidden');
      if (adult > 0) b.writeln('   ${tr('Contenus adultes masqués')} : $adult');
      if (other > 0) b.writeln('   ${tr('Autres (doublons fusionnés avec un autre compte, source non affichée)')} : $other');
    }
    if (mounted) {
      setState(() {
        _report = b.toString().trimRight();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(tr('Diagnostic de la source')),
        content: SizedBox(
          width: 520,
          child: _loading
              ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
              : SingleChildScrollView(child: SelectableText(_report, style: kText(13))),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Clipboard.setData(ClipboardData(text: _report)),
            child: Text(tr('Copier')),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer'))),
        ],
      );
}
