import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/updater.dart';
import '../core/device.dart';
import '../l10n.dart';
import '../main.dart' show appShutdown;
import '../version.dart';
import 'tv_shell.dart';

/// Mise à jour à la télécommande : une page à part (le fond de l'accueil ne reçoit plus les touches).
void openTvUpdate(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _TvUpdatePage()));
}

/// Propose la mise à jour d'office sur téléviseur (une fois par version et par lancement), quand rien n'est en lecture.
class TvUpdatePrompt extends StatefulWidget {
  const TvUpdatePrompt({super.key});

  @override
  State<TvUpdatePrompt> createState() => _TvUpdatePromptState();
}

class _TvUpdatePromptState extends State<TvUpdatePrompt> {
  String? _shownFor;

  void _check() {
    if (!mounted || !Device.isTv) return;
    final updates = context.updates;
    if (!updates.shouldPropose || context.playback.current != null) return;
    final version = updates.latest!.version;
    if (_shownFor == version) return;
    _shownFor = version;
    openTvUpdate(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!Device.isTv) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: context.updates,
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _check());
        return const SizedBox.shrink();
      },
    );
  }
}

class _TvUpdatePage extends StatefulWidget {
  const _TvUpdatePage();

  @override
  State<_TvUpdatePage> createState() => _TvUpdatePageState();
}

class _TvUpdatePageState extends State<_TvUpdatePage> {
  String? _message;

  /// Notes de version sans la mise en forme Markdown, limitées à quelques lignes.
  String _notes(ReleaseInfo r) {
    final lines = r.notes.split('\n').map((l) => l.replaceAll(RegExp(r'^\s*[-*#]+\s*'), '').replaceAll('**', '').replaceAll('`', '').trim()).where((l) => l.isNotEmpty).take(6);
    return lines.join('\n');
  }

  Future<void> _install(UpdateService updates, ReleaseInfo release) async {
    setState(() => _message = null);
    final result = await updates.install(release, beforeExit: appShutdown.run);
    if (!mounted || result == null) return;
    if (result == 'no-asset') {
      await launchUrl(Uri.parse(release.url));
      return;
    }
    setState(() => _message = result == 'android-permission'
        ? tr('Autorisez Kastideo à installer des applications (réglage qui vient de s\'ouvrir), puis revenez ici et réessayez.')
        : '${tr('Mise à jour impossible')} : $result');
  }

  @override
  Widget build(BuildContext context) {
    final updates = context.updates;
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        final release = updates.latest;
        if (release == null) return const TvMenuPage(title: 'Kastideo', entries: _none);
        final busy = updates.state == UpdateState.downloading || updates.state == UpdateState.installing;
        final progress = updates.state == UpdateState.installing
            ? tr('Installation…')
            : (busy ? '${tr('Téléchargement')} ${((updates.progress ?? 0) * 100).round()} %' : null);
        return TvMenuPage(
          title: '${tr('Kastideo')} ${release.version} ${tr('est disponible')}',
          footer: [
            '${tr('Version installée')} : $kVersion',
            if (progress != null) progress else _notes(release),
            ?_message,
          ].join('\n'),
          entries: (c) => [
            TvEntry(updates.assetFor(release) == null ? tr('Ouvrir la page GitHub') : tr('Installer et relancer'), busy ? null : (c) => _install(updates, release),
                icon: Icons.download_rounded, detail: progress),
            TvEntry(tr('Plus tard'), busy ? null : (c) {
              updates.dismiss();
              Navigator.of(c).pop();
            }, icon: Icons.schedule_rounded),
            TvEntry(tr('Ignorer cette version'), busy ? null : (c) {
              updates.skip(release);
              Navigator.of(c).pop();
            }, icon: Icons.block_rounded),
          ],
        );
      },
    );
  }
}

List<TvEntry> _none(BuildContext context) => const [];
