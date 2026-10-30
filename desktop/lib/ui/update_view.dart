import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/updater.dart';
import '../l10n.dart';
import '../main.dart' show appShutdown;
import '../theme.dart';
import '../version.dart';
import 'support_button.dart';

/// Bandeau « Nouvelle version » en haut à droite (proposé hors visionnage, comme sur Mac).
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final updates = context.updates;
    final playback = context.playback;
    final multiview = context.multiview;
    return ListenableBuilder(
      listenable: Listenable.merge([updates, playback, multiview]),
      builder: (context, _) {
        final watching = playback.current != null || multiview.isRunning;
        if (!updates.shouldPropose || watching) return const SizedBox.shrink();
        final release = updates.latest!;
        return Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: KPalette.menuDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: KPalette.accentDark.withValues(alpha: 0.6)),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.system_update_alt_rounded, size: 20, color: KPalette.accentDark),
            const SizedBox(width: 10),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('${tr('Kastideo')} ${release.version} ${tr('est disponible')}', style: kTextD(13, weight: FontWeight.w600)),
                Text('${tr('Version installée')} : $kVersion', style: kTextD(11, color: Colors.white60)),
              ]),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: () => showUpdateDialog(context), child: Text(tr('Voir'))),
            IconButton(
              tooltip: tr('Plus tard'),
              iconSize: 16,
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
              onPressed: () {
                updates.dismiss();
              },
            ),
          ]),
        );
      },
    );
  }
}

/// Fenêtre de mise à jour : nouveautés de la version, Installer, Ignorer cette version, Plus tard.
Future<void> showUpdateDialog(BuildContext context) => showKDialog(context: context, barrierDismissible: false, builder: (_) => const _UpdateDialog());

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog();

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  String? _message;

  String _kindLabel() => switch (UpdateService.installKind) {
        InstallKind.windowsSetup => tr('Kastideo téléchargera le nouvel installateur, se fermera, s\'installera puis se relancera tout seul.'),
        InstallKind.windowsPortable => tr('Version portable : Kastideo téléchargera la nouvelle archive, se fermera, remplacera ses fichiers puis se relancera.'),
        InstallKind.appImage => tr('AppImage : Kastideo téléchargera le nouveau fichier à côté de l\'actuel, supprimera l\'ancien puis se relancera.'),
        InstallKind.deb => tr('Paquet .deb : Kastideo téléchargera le paquet et l\'installera (votre mot de passe vous sera demandé), puis se relancera.'),
        InstallKind.other => tr('Cette copie de Kastideo ne peut pas se mettre à jour seule : téléchargez la nouvelle version sur GitHub.'),
      };

  Future<void> _install(UpdateService updates, ReleaseInfo release) async {
    setState(() => _message = null);
    final result = await updates.install(release, beforeExit: appShutdown.run);
    if (!mounted || result == null) return;
    if (result == 'no-asset') {
      await launchUrl(Uri.parse(release.url));
      return;
    }
    if (result.startsWith('deb:')) {
      final path = result.substring(4);
      setState(() => _message = '${tr('L\'installation automatique a échoué. Installez le paquet téléchargé avec cette commande dans un terminal :')}\n'
          'sudo apt install "$path"');
      return;
    }
    setState(() => _message = '${tr('Mise à jour impossible')} : $result');
  }

  @override
  Widget build(BuildContext context) {
    final updates = context.updates;
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        final release = updates.latest;
        if (release == null) return const SizedBox.shrink();
        final busy = updates.state == UpdateState.downloading || updates.state == UpdateState.installing;
        final asset = updates.assetFor(release);
        return AlertDialog(
          title: Row(children: [
            Icon(Icons.system_update_alt_rounded, color: KPalette.accent),
            const SizedBox(width: 10),
            Expanded(child: Text('Kastideo ${release.version}', style: kRounded(22, FontWeight.w800))),
          ]),
          content: SizedBox(
            width: 600,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${tr('Version installée')} : $kVersion', style: kText(13, color: KPalette.secondaryText)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                  child: SingleChildScrollView(child: MarkdownText(release.notes.trim().isEmpty ? tr('Pas de notes de version.') : release.notes)),
                ),
              ),
              const SizedBox(height: 12),
              Text(_kindLabel(), style: kText(12, color: KPalette.secondaryText)),
              if (asset != null) Text('${tr('Fichier')} : $asset', style: kText(11, color: KPalette.ink38)),
              if (busy) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: updates.state == UpdateState.installing ? null : updates.progress),
                const SizedBox(height: 6),
                Text(
                  updates.state == UpdateState.installing
                      ? tr('Installation… Kastideo va se fermer puis se relancer.')
                      : '${tr('Téléchargement')} ${((updates.progress ?? 0) * 100).round()} %',
                  style: kText(12),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                SelectableText(_message!, style: kText(12, color: KPalette.orange)),
              ],
            ]),
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      updates.skip(release);
                      Navigator.pop(context);
                    },
              child: Text(tr('Ignorer cette version')),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      updates.dismiss();
                      Navigator.pop(context);
                    },
              child: Text(tr('Plus tard')),
            ),
            FilledButton.icon(
              onPressed: busy ? null : () => _install(updates, release),
              icon: Icon(asset == null ? Icons.open_in_new_rounded : Icons.download_rounded, size: 18),
              label: Text(asset == null ? tr('Ouvrir la page GitHub') : tr('Installer et relancer')),
            ),
          ],
        );
      },
    );
  }
}

/// Markdown simple (titres, puces, gras) pour les notes de version et les nouveautés.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.text, {super.key});
  final String text;

  InlineSpan _spans(String line, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    var last = 0;
    for (final m in pattern.allMatches(line)) {
      if (m.start > last) spans.add(TextSpan(text: line.substring(last, m.start)));
      spans.add(TextSpan(
        text: m.group(1) ?? m.group(2),
        style: m.group(1) != null ? const TextStyle(fontWeight: FontWeight.w700, fontVariations: [FontVariation('wght', 700)]) : const TextStyle(fontFamily: 'monospace'),
      ));
      last = m.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    return TextSpan(style: base, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
      } else if (line.startsWith('#')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(line.replaceFirst(RegExp(r'^#+\s*'), ''), style: kText(15, weight: FontWeight.w700)),
        ));
      } else if (RegExp(r'^\s*[-*] ').hasMatch(line)) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('•  ', style: kText(13, color: KPalette.accent)),
            Expanded(child: Text.rich(_spans(line.replaceFirst(RegExp(r'^\s*[-*] '), ''), kText(13)))),
          ]),
        ));
      } else {
        children.add(Padding(padding: const EdgeInsets.only(bottom: 4), child: Text.rich(_spans(line, kText(13)))));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

// MARK: Nouveautés après une mise à jour

/// Au premier lancement d'une nouvelle version : ce qui a changé depuis la version précédente (journal des versions).
Future<void> showWhatsNewIfUpdated(BuildContext context) async {
  if (!kVersion.contains('.')) return;
  final prefs = await SharedPreferences.getInstance();
  final last = prefs.getString('whatsnew.lastVersion');
  await prefs.setString('whatsnew.lastVersion', kVersion);
  if (last == null || compareVersions(kVersion, last) <= 0 || !context.mounted) return;
  await showWhatsNew(context, since: last);
}

/// Sections du journal des versions plus récentes que [since] (toutes les récentes si null).
Future<void> showWhatsNew(BuildContext context, {String? since}) async {
  String changelog;
  try {
    changelog = await rootBundle.loadString('CHANGELOG.md');
  } catch (_) {
    return;
  }
  final sections = <(String, String)>[];
  String? version;
  final buffer = StringBuffer();
  void flush() {
    if (version != null) sections.add((version, buffer.toString().trim()));
    buffer.clear();
  }

  for (final line in changelog.split('\n')) {
    final m = RegExp(r'^## \[([^\]]+)\]').firstMatch(line);
    if (m != null) {
      flush();
      version = m.group(1);
    } else if (version != null) {
      buffer.writeln(line);
    }
  }
  flush();
  final shown = [
    for (final s in sections)
      if (compareVersions(s.$1, kVersion.contains('.') ? kVersion : '9.9.9') <= 0 && (since == null || compareVersions(s.$1, since) > 0)) s,
  ].take(since == null ? 3 : 6).toList();
  if (shown.isEmpty || !context.mounted) return;
  await showKDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Row(children: [
        Icon(Icons.auto_awesome_rounded, color: KPalette.accent),
        const SizedBox(width: 10),
        Text(tr('Nouveautés'), style: kRounded(22, FontWeight.w800)),
      ]),
      content: SizedBox(
        width: 640,
        height: 440,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (v, body) in shown) ...[
              Text(v, style: kText(16, weight: FontWeight.w700, color: KPalette.accent)),
              const SizedBox(height: 6),
              MarkdownText(body),
              const SizedBox(height: 14),
            ],
          ]),
        ),
      ),
      actions: [
        const SupportButton(),
        FilledButton(onPressed: () => Navigator.pop(c), child: Text(tr('Continuer'))),
      ],
    ),
  );
}
