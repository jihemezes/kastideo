import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/epg.dart';
import '../core/models.dart';
import '../core/paths.dart';
import '../core/recording.dart';
import '../core/text.dart';
import '../l10n.dart';
import '../theme.dart';
import 'themes_view.dart';
import 'widgets.dart';

/// « Programmer un enregistrement… » : un programme à venir du guide TV, ou une plage horaire choisie à la main,
/// répétée ou non (tous les jours, du lundi au vendredi, chaque semaine).
Future<void> showScheduleDialog(BuildContext context, {MediaItem? channel}) =>
    showKDialog(context: context, builder: (_) => _ScheduleDialog(initial: channel));

String repeatLabel(ScheduleRepeat r) => switch (r) {
      ScheduleRepeat.none => tr('Une seule fois'),
      ScheduleRepeat.daily => tr('Tous les jours'),
      ScheduleRepeat.weekdays => tr('Du lundi au vendredi'),
      ScheduleRepeat.weekly => tr('Chaque semaine'),
    };

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({this.initial});
  final MediaItem? initial;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late MediaItem? _channel = widget.initial;
  String _query = '';
  bool _manual = false;
  ScheduleRepeat _repeat = ScheduleRepeat.none;

  // Plage horaire.
  late DateTime _day = DateTime.now();
  late TimeOfDay _from = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 5)));
  late TimeOfDay _to = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 65)));
  final _title = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sans programme dans le guide pour cette chaîne : plage horaire directement.
      final c = _channel;
      if (c != null && _upcoming(c).isEmpty && mounted) setState(() => _manual = true);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  List<Programme> _upcoming(MediaItem channel) {
    final now = nowSeconds();
    return context.guide.programmesOf(channel).where((p) => p.stopS > now).take(60).toList();
  }

  String _dayLabel(DateTime d) {
    final today = DateTime.now();
    final date = DateTime(d.year, d.month, d.day);
    final diff = date.difference(DateTime(today.year, today.month, today.day)).inDays;
    if (diff == 0) return tr('Aujourd\'hui');
    if (diff == 1) return tr('Demain');
    const daysFr = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    const daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final name = (L10n.english ? daysEn : daysFr)[d.weekday - 1];
    return '$name ${two(d.day)}/${two(d.month)}';
  }

  void _scheduleProgramme(MediaItem channel, Programme p) {
    final recordings = context.recordings;
    if (_repeat == ScheduleRepeat.none) {
      recordings.schedule(channel, p);
    } else {
      recordings.scheduleManual(channel, start: p.start, stop: p.stop, title: p.title, repeat: _repeat);
    }
    setState(() => _message = '${tr('Programmé')} : ${p.title} (${_dayLabel(p.start)} ${hm(p.start)})');
  }

  void _scheduleManual(MediaItem channel) {
    final start = DateTime(_day.year, _day.month, _day.day, _from.hour, _from.minute);
    var stop = DateTime(_day.year, _day.month, _day.day, _to.hour, _to.minute);
    // Fin après minuit : le lendemain (constructeur de date, et non +24 h, à cause des changements d'heure).
    if (!stop.isAfter(start)) stop = DateTime(_day.year, _day.month, _day.day + 1, _to.hour, _to.minute);
    if (stop.isBefore(DateTime.now())) {
      setState(() => _message = tr('Cette plage horaire est déjà passée.'));
      return;
    }
    context.recordings.scheduleManual(channel, start: start, stop: stop, title: _title.text, repeat: _repeat);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final channel = _channel;
    return AlertDialog(
      title: Row(children: [
        Icon(Icons.schedule_rounded, color: KPalette.accent),
        const SizedBox(width: 10),
        Expanded(child: Text(tr('Programmer un enregistrement'), style: kRounded(20, FontWeight.w800))),
      ]),
      content: SizedBox(
        width: 620,
        height: 500,
        child: channel == null ? _channelPicker() : _form(channel),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Fermer'))),
        if (channel != null && _manual)
          FilledButton.icon(
            onPressed: () => _scheduleManual(channel),
            icon: const Icon(Icons.fiber_manual_record_rounded, size: 16),
            label: Text(tr('Programmer')),
          ),
      ],
    );
  }

  Widget _channelPicker() {
    final library = context.library;
    final q = _query.searchKey;
    final items = q.length < 2
        ? [...library.favoritesOf(MediaKind.live), ...library.recentsOf(MediaKind.live)].fold<List<MediaItem>>([], (l, i) => l.any((x) => x.id == i.id) ? l : (l..add(i)))
        : library.items(MediaKind.live).where((i) => i.name.searchKey.contains(q)).take(100).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('Chaîne à enregistrer'), style: kText(13, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        autofocus: true,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          hintText: tr('Rechercher une chaîne'),
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
      const SizedBox(height: 6),
      if (q.length < 2) Text(tr('Favoris et récents — tapez un nom pour chercher parmi toutes les chaînes.'), style: kText(11, color: KPalette.secondaryText)),
      Expanded(
        child: ListView(children: [
          for (final item in items)
            ListTile(
              dense: true,
              leading: LogoView(url: item.logo, name: item.name, size: 30),
              title: Text(item.displayName, style: kText(13, weight: FontWeight.w500)),
              subtitle: Text(context.guide.current(item)?.title ?? item.group, style: kText(11, color: KPalette.secondaryText), maxLines: 1),
              onTap: () => setState(() {
                _channel = item;
                _manual = _upcoming(item).isEmpty;
                _title.text = '';
              }),
            ),
        ]),
      ),
    ]);
  }

  Widget _form(MediaItem channel) {
    final upcoming = _upcoming(channel);
    final recordings = context.recordings;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        LogoView(url: channel.logo, name: channel.name, size: 34),
        const SizedBox(width: 10),
        Expanded(child: Text(channel.displayName, style: kText(15, weight: FontWeight.w600))),
        if (widget.initial == null)
          TextButton(onPressed: () => setState(() => _channel = null), child: Text(tr('Changer de chaîne'))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(tr('Programmes du guide')), icon: const Icon(Icons.calendar_month_rounded, size: 16)),
            ButtonSegment(value: true, label: Text(tr('Plage horaire')), icon: const Icon(Icons.timer_outlined, size: 16)),
          ],
          selected: {_manual},
          onSelectionChanged: (v) => setState(() => _manual = v.first),
        ),
        const Spacer(),
        DropdownButton<ScheduleRepeat>(
          value: _repeat,
          items: [for (final r in ScheduleRepeat.values) DropdownMenuItem(value: r, child: Text(repeatLabel(r), style: kText(13)))],
          onChanged: (v) => setState(() => _repeat = v ?? ScheduleRepeat.none),
        ),
      ]),
      const SizedBox(height: 10),
      if (_message != null) ...[
        Text(_message!, style: kText(12, color: KPalette.accent)),
        const SizedBox(height: 6),
      ],
      Expanded(
        child: _manual
            ? _manualForm()
            : upcoming.isEmpty
                ? Center(
                    child: Text(tr('Pas de programme dans le guide TV pour cette chaîne : choisissez une plage horaire.'),
                        textAlign: TextAlign.center, style: kText(13, color: KPalette.secondaryText)),
                  )
                : ListenableBuilder(
                    listenable: recordings,
                    builder: (context, _) => ListView(children: [
                      for (final p in upcoming)
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: SizedBox(
                            width: 108,
                            child: Text('${_dayLabel(p.start)}\n${hm(p.start)} – ${hm(p.stop)}', style: kText(11, color: KPalette.secondaryText)),
                          ),
                          title: Text(p.title, style: kText(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: p.desc == null ? null : Text(p.desc!, style: kText(11, color: KPalette.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: recordings.isScheduled(channel, p) || recordings.schedules.any((s) => s.channelId == channel.id && s.startS == p.startS && s.status == ScheduleStatus.scheduled)
                              ? Icon(Icons.check_circle_rounded, color: KPalette.accent)
                              : OutlinedButton(
                                  onPressed: () => _scheduleProgramme(channel, p),
                                  child: Text(p.startS <= nowSeconds() ? tr('Enregistrer') : tr('Programmer')),
                                ),
                        ),
                    ]),
                  ),
      ),
    ]);
  }

  Widget _manualForm() {
    Widget field(String label, String value, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(width: 120, child: Text(label, style: kText(13))),
            OutlinedButton(onPressed: onTap, child: Text(value)),
          ]),
        );
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        field(tr('Jour'), _dayLabel(_day), () async {
          final d = await showDatePicker(
            context: context,
            initialDate: _day,
            firstDate: DateTime.now().subtract(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 60)),
          );
          if (d != null) setState(() => _day = d);
        }),
        field(tr('Début'), _from.format(context), () async {
          final t = await showTimePicker(context: context, initialTime: _from);
          if (t != null) setState(() => _from = t);
        }),
        field(tr('Fin'), _to.format(context), () async {
          final t = await showTimePicker(context: context, initialTime: _to);
          if (t != null) setState(() => _to = t);
        }),
        TextField(
          controller: _title,
          decoration: InputDecoration(labelText: tr('Titre (facultatif)'), isDense: true, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        Text(
          tr('Les marges avant et après (Réglages > Enregistrements) s\'ajoutent. Une fin plus tôt que le début se termine le lendemain. '
              'Kastideo doit être ouvert à l\'heure prévue (Réglages > Général > Lancer Kastideo à l\'ouverture de session).'),
          style: kText(11, color: KPalette.secondaryText),
        ),
      ]),
    );
  }
}
