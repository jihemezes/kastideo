import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';

/// Sélecteur de source de la barre latérale (au moins deux comptes IPTV) : « Toutes les sources » ou un seul compte.
class SourcePicker extends StatelessWidget {
  const SourcePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final sources = library.selectableSources;
    if (sources.length < 2) return const SizedBox.shrink();
    final active = library.activeSource;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showSourcePicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: KPalette.ink.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.dns_rounded, size: 16, color: KPalette.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(active?.name ?? tr('Toutes les sources'), style: kText(13, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.arrow_drop_down_rounded),
          ]),
        ),
      ),
    );
  }
}

Future<void> showSourcePicker(BuildContext context) =>
    showKDialog<void>(context: context, builder: (_) => const _SourcePickerDialog());

class _SourcePickerDialog extends StatelessWidget {
  const _SourcePickerDialog();

  @override
  Widget build(BuildContext context) {
    final library = context.library;
    final navigation = context.navigation;
    return ListenableBuilder(
      listenable: library,
      builder: (context, _) {
        final sources = library.selectableSources;
        void choose(String? id) {
          library.setActiveSource(id);
          navigation.resetFilters();
          Navigator.pop(context);
        }

        Widget tile({required String title, required String detail, required bool selected, required VoidCallback onTap}) => ListTile(
              selected: selected,
              leading: Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
              title: Text(title, style: kText(14, weight: FontWeight.w600)),
              subtitle: Text(detail, style: kText(12, color: KPalette.secondaryText)),
              onTap: onTap,
            );
        var live = 0, movies = 0, series = 0;
        for (final s in sources) {
          final c = library.rawCounts(s);
          live += c.live;
          movies += c.movies;
          series += c.series;
        }
        return AlertDialog(
          title: Text(tr('Source affichée')),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                tile(
                  title: tr('Toutes les sources'),
                  detail: library.dedupe ? tr('Les comptes sont réunis, doublons fusionnés') : tr('Les comptes sont réunis'),
                  selected: library.activeSourceId == null,
                  onTap: () => choose(null),
                ),
                for (final s in sources)
                  () {
                    final c = library.rawCounts(s);
                    return tile(
                      title: s.name,
                      detail: '${c.live} ${tr('chaînes')} · ${c.movies} ${tr('films')} · ${c.series} ${tr('séries')}',
                      selected: library.activeSourceId == s.id,
                      onTap: () => choose(s.id),
                    );
                  }(),
                const Divider(),
                SwitchListTile(
                  title: Text(tr('Fusionner les doublons entre comptes'), style: kText(13)),
                  subtitle: Text(tr('Un film ou une série fourni par plusieurs comptes n\'apparaît qu\'une fois dans « Toutes les sources ».'), style: kText(11, color: KPalette.secondaryText)),
                  value: library.dedupe,
                  onChanged: library.setDedupe,
                ),
                Text('${tr('Total')} : $live ${tr('chaînes')} · $movies ${tr('films')} · $series ${tr('séries')}', style: kText(11, color: KPalette.secondaryText)),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer')))],
        );
      },
    );
  }
}
