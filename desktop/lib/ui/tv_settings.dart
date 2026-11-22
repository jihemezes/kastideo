import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/models.dart';
import '../core/settings.dart' show InterfaceStyle;
import '../l10n.dart';
import '../theme.dart';
import '../version.dart';
import 'tv_home.dart';
import 'tv_shell.dart';

/// Réglages de l'Android TV, à la télécommande : sources, catégories, langue, lecture, guide, TMDB, aide.
void openTvSettings(BuildContext context) {
  _push(
    context,
    TvMenuPage(
      title: tr('Réglages'),
      footer: 'Kastideo $kVersion',
      entries: (context) {
        final s = context.settings;
        return [
          TvEntry(tr('Ajouter une source avec mon téléphone'), (c) => openTvQr(c), icon: Icons.qr_code_2_rounded),
          TvEntry(tr('Sources'), (c) => _openSources(c), detail: '${context.library.sources.length}'),
          TvEntry(tr('Catégories'), (c) => _openCategoryKinds(c)),
          TvEntry(tr('Style d\'affichage'), (c) => _openStyles(c)),
          TvEntry(tr('Langue'), (c) => _openLanguage(c), detail: s.language == 'system' ? tr('Langue du système') : L10n.names[s.language]),
          TvEntry(tr('Lecture'), (c) => _openPlayback(c)),
          TvEntry(tr('Guide TV'), (c) => _openGuide(c)),
          TvEntry(tr('Clé TMDB'), (c) => _editTmdb(c), detail: s.usesTMDB ? tr('Oui') : tr('Non')),
          TvEntry(tr('Actualiser les catalogues'), (c) => _refreshAll(c), icon: Icons.refresh_rounded),
          TvEntry(tr('Aide'), (c) => _push(c, const TvHelpPage()), icon: Icons.help_outline_rounded),
          TvEntry(tr('Journal de lecture'), (c) => openTvLog(c), icon: Icons.receipt_long_rounded),
        ];
      },
    ),
  );
}

void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

String _yes(bool v) => v ? tr('Oui') : tr('Non');

void _refreshAll(BuildContext context) {
  context.library.refreshAll();
  _toast(context, tr('Actualisation en cours…'));
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text, style: kTextD(20)), duration: const Duration(seconds: 2)));
}

/// Choix dans une liste ; le choix actuel est marqué ✓ et la page se ferme après la sélection.
void _choose(BuildContext context, String title, List<(String value, String label)> options, String current, void Function(String) pick) {
  _push(
    context,
    TvMenuPage(
      title: title,
      entries: (_) => [
        for (final o in options)
          TvEntry(o.$2, (c) {
            pick(o.$1);
            Navigator.of(c).pop();
          }, icon: o.$1 == current ? Icons.check_circle_rounded : Icons.circle_outlined),
      ],
    ),
  );
}

// MARK: Sources

void _openSources(BuildContext context) {
  _push(
    context,
    TvMenuPage(
      title: tr('Sources'),
      footer: tr('OK ouvre les actions de la source.'),
      entries: (context) {
        final sources = context.library.sources;
        if (sources.isEmpty) return [TvEntry(tr('Aucune source'), null)];
        return [
          for (final s in List.of(sources))
            TvEntry(s.name, (c) => _openSource(c, s), detail: s.enabled ? null : tr('Désactivée')),
        ];
      },
    ),
  );
}

void _openSource(BuildContext context, Source source) {
  _push(
    context,
    TvMenuPage(
      title: source.name,
      entries: (context) => [
        TvEntry(source.enabled ? tr('Désactiver') : tr('Activer'), (c) => c.library.setSourceEnabled(source, !source.enabled), detail: _yes(source.enabled)),
        TvEntry(tr('Actualiser'), (c) {
          c.library.refresh(source);
          _toast(c, tr('Actualisation en cours…'));
        }, icon: Icons.refresh_rounded),
        TvEntry(tr('Monter'), (c) => c.library.moveSource(source, -1), icon: Icons.arrow_upward_rounded),
        TvEntry(tr('Descendre'), (c) => c.library.moveSource(source, 1), icon: Icons.arrow_downward_rounded),
        TvEntry(tr('Retirer'), (c) async {
          await c.library.removeSource(source);
          if (c.mounted) Navigator.of(c).pop();
        }, icon: Icons.delete_outline_rounded),
      ],
    ),
  );
}

// MARK: Catégories

void _openCategoryKinds(BuildContext context) {
  _push(
    context,
    TvMenuPage(
      title: tr('Catégories'),
      entries: (context) => [
        for (final (kind, label) in [(MediaKind.live, tr('Direct')), (MediaKind.movie, tr('Films')), (MediaKind.series, tr('Séries'))])
          TvEntry(label, (c) => _openCategories(c, kind, label), detail: '${context.library.allCategories(kind).length}'),
      ],
    ),
  );
}

void _openCategories(BuildContext context, MediaKind kind, String label) {
  _push(
    context,
    TvMenuPage(
      title: label,
      footer: tr('OK : afficher, masquer, monter ou descendre la catégorie.'),
      entries: (context) {
        final library = context.library;
        final prefs = library.prefs(kind);
        return [
          TvEntry(tr('Tout afficher'), (c) {
            final names = c.library.allCategories(kind);
            final before = names.where((n) => c.library.prefs(kind).isHidden(n)).length;
            c.library.updateCategories(kind, (p) {
              p.hidden = <String>{};
              p.keywords = <String>[];
            });
            _toast(c, before == 0 ? tr('Toutes les catégories sont déjà affichées.') : '$before ${tr('catégories affichées')}');
          }, icon: Icons.visibility_rounded),
          TvEntry(tr('Tout masquer'), (c) {
            c.library.updateCategories(kind, (p) => p.hidden = {...c.library.allCategories(kind)});
            _toast(c, tr('Toutes les catégories sont masquées.'));
          }, icon: Icons.visibility_off_rounded),
          TvEntry(tr('Trier de A à Z'), (c) => c.library.updateCategories(kind, (p) {
                p.order = List.of(c.library.allCategories(kind))..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
              }), icon: Icons.sort_by_alpha_rounded),
          TvEntry(tr('Ordre du fournisseur'), (c) => c.library.updateCategories(kind, (p) => p.order = []), icon: Icons.restart_alt_rounded),
          for (final name in library.allCategories(kind))
            TvEntry(prefs.displayName(name), (c) => _openCategory(c, kind, name),
                detail: prefs.hidden.contains(name) ? tr('Masquée') : (prefs.isHidden(name) ? tr('Masquée (mot-clé)') : null)),
        ];
      },
    ),
  );
}

void _openCategory(BuildContext context, MediaKind kind, String name) {
  void move(BuildContext c, int delta) {
    final list = List.of(c.library.allCategories(kind));
    final from = list.indexOf(name);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= list.length) return;
    list.insert(to, list.removeAt(from));
    c.library.updateCategories(kind, (p) => p.order = list);
  }

  _push(
    context,
    TvMenuPage(
      title: context.library.prefs(kind).displayName(name),
      entries: (context) {
        final hidden = context.library.prefs(kind).isHidden(name);
        return [
          TvEntry(hidden ? tr('Afficher') : tr('Masquer'), (c) => c.library.updateCategories(kind, (p) {
                if (hidden) {
                  p.hidden.remove(name);
                  final lower = name.toLowerCase();
                  p.keywords.removeWhere((k) => k.trim().isNotEmpty && lower.contains(k.trim().toLowerCase()));
                } else {
                  p.hidden.add(name);
                }
              }), icon: hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded),
          TvEntry(tr('Monter'), (c) => move(c, -1), icon: Icons.arrow_upward_rounded),
          TvEntry(tr('Descendre'), (c) => move(c, 1), icon: Icons.arrow_downward_rounded),
        ];
      },
    ),
  );
}

// MARK: Styles d'affichage

String _styleName(InterfaceStyle s) => switch (s) {
      InterfaceStyle.classic => tr('Classique'),
      InterfaceStyle.cinema => tr('Cinéma'),
      InterfaceStyle.tv => tr('TV'),
    };

void _openStyles(BuildContext context) {
  _push(
    context,
    TvMenuPage(
      title: tr('Style d\'affichage'),
      footer: tr('Classique : grille. Cinéma : bannière et rangées. TV : chaîne en plein écran (Direct).'),
      entries: (context) => [
        for (final (kind, label) in [(MediaKind.live, tr('Direct')), (MediaKind.movie, tr('Films')), (MediaKind.series, tr('Séries'))])
          TvEntry(label, (c) {
            final options = [InterfaceStyle.classic, InterfaceStyle.cinema, if (kind == MediaKind.live) InterfaceStyle.tv];
            _choose(c, label, [for (final o in options) (o.name, _styleName(o))], c.settings.interfaceFor(kind).name,
                (v) => c.settings.setInterface(kind, InterfaceStyle.values.firstWhere((x) => x.name == v)));
          }, detail: _styleName(context.settings.interfaceFor(kind))),
      ],
    ),
  );
}

// MARK: Langue, lecture, guide

void _openLanguage(BuildContext context) {
  _choose(
    context,
    tr('Langue'),
    [('system', tr('Langue du système')), for (final c in L10n.codes) (c, L10n.names[c]!)],
    context.settings.language,
    (v) {
      context.settings.setLanguage(v);
      _toast(context, tr('Le changement s\'applique au prochain lancement de Kastideo.'));
    },
  );
}

void _openPlayback(BuildContext context) {
  _push(
    context,
    TvMenuPage(
      title: tr('Lecture'),
      entries: (context) {
        final s = context.settings;
        return [
          TvEntry(tr('Enchaîner automatiquement l\'épisode suivant d\'une série'), (c) => c.settings.setBool('player.autoNext', !s.autoNextEpisode), detail: _yes(s.autoNextEpisode)),
          TvEntry(tr('Rendu vidéo direct (recommandé)'), (c) => c.settings.setTvDirectRender(!s.tvDirectRender),
              detail: s.tvDirectRender ? tr('Oui · au prochain lancement') : tr('Non')),
          TvEntry(tr('Revoir une émission (replay)'), (c) => c.settings.setBool('replay.enabled', !s.replayEnabled), detail: _yes(s.replayEnabled)),
          TvEntry(tr('Revenir au direct à la fin d\'un replay'), (c) => c.settings.setBool('replay.returnToLive', !s.replayReturnToLive), detail: _yes(s.replayReturnToLive)),
          TvEntry(tr('Toujours en décodage logiciel'), (c) => c.settings.setSoftwareAlways(!s.softwareAlways), detail: _yes(s.softwareAlways)),
          TvEntry(tr('Relais de flux'), (c) => c.settings.setRelay(!s.relayEnabled), detail: _yes(s.relayEnabled)),
          TvEntry(tr('Mise à jour automatique des catalogues'), (c) => c.settings.setAutoRefresh(!s.autoRefresh), detail: _yes(s.autoRefresh)),
        ];
      },
    ),
  );
}

void _openGuide(BuildContext context) {
  _push(
    context,
    TvMenuPage(
      title: tr('Guide TV'),
      entries: (context) {
        final s = context.settings;
        final guide = context.guide;
        return [
          TvEntry(tr('À l\'ouverture du guide'), (c) => _choose(c, tr('À l\'ouverture du guide'), [('now', tr('Maintenant')), ('last', tr('Dernière position'))], s.guideStart,
              (v) => c.settings.setString('guide.start', v)), detail: s.guideStart == 'last' ? tr('Dernière position') : tr('Maintenant')),
          TvEntry(tr('Guide TV de secours'), (c) => c.guide.setFallbackEnabled(!guide.fallbackEnabled), detail: _yes(guide.fallbackEnabled)),
          TvEntry(tr('Recharger le guide TV'), (c) {
            c.guide.refreshAll();
            _toast(c, tr('Actualisation en cours…'));
          }, icon: Icons.refresh_rounded),
        ];
      },
    ),
  );
}

// MARK: Clé TMDB

void _editTmdb(BuildContext context) {
  _push(
    context,
    TvTextPage(
      title: tr('Clé TMDB'),
      hint: tr('Collez ou saisissez la clé API TMDB'),
      initial: context.settings.tmdbKey,
      onSave: (text) async {
        await context.settings.setTMDBKey(text);
      },
    ),
  );
}

/// Saisie d'un texte avec le clavier de la télévision : OK sur le champ saisit, puis OK sur Enregistrer.
class TvTextPage extends StatefulWidget {
  const TvTextPage({super.key, required this.title, required this.hint, required this.initial, required this.onSave});
  final String title;
  final String hint;
  final String initial;
  final Future<void> Function(String text) onSave;

  @override
  State<TvTextPage> createState() => _TvTextPageState();
}

class _TvTextPageState extends State<TvTextPage> with TvKeys<TvTextPage> {
  late final _controller = TextEditingController(text: widget.initial);
  final _field = FocusNode();
  int _index = 0; // 0 champ, 1 enregistrer

  @override
  void initState() {
    super.initState();
    startTvKeys();
  }

  @override
  void dispose() {
    stopTvKeys();
    _controller.dispose();
    _field.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.onSave(_controller.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  bool onTvKey(TvKey key) {
    if (_field.hasFocus) return false;
    setState(() {
      switch (key) {
        case TvKey.up:
          _index = 0;
        case TvKey.down:
          _index = 1;
        case TvKey.ok:
          if (_index == 0) {
            _field.requestFocus();
          } else {
            _save();
          }
        default:
          break;
      }
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return TvBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(120, 50, 120, 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: kTextD(42, weight: FontWeight.w800)),
          const SizedBox(height: 28),
          TvFocusBox(
            selected: _index == 0,
            radius: 18,
            child: Container(
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              color: Colors.white.withValues(alpha: 0.13),
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _field.unfocus();
                    setState(() => _index = 1);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _controller,
                  focusNode: _field,
                  style: kTextD(24),
                  cursorColor: KPalette.orange,
                  decoration: InputDecoration(border: InputBorder.none, hintText: widget.hint, hintStyle: kTextD(22, color: Colors.white38)),
                  onSubmitted: (_) {
                    _field.unfocus();
                    setState(() => _index = 1);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TvFocusBox(
            selected: _index == 1,
            radius: 18,
            child: Container(
              height: 82,
              alignment: Alignment.center,
              color: Colors.white.withValues(alpha: 0.13),
              child: Text(tr('Enregistrer'), style: kTextD(24, weight: FontWeight.w700)),
            ),
          ),
          const Spacer(),
          const TvHints(items: [('OK', 'Choisir'), ('▲ ▼', 'Se déplacer'), ('Retour', 'Revenir')]),
        ]),
      ),
    );
  }
}
