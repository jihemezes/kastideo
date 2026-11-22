import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/library.dart';
import '../l10n.dart';
import '../theme.dart';

/// Code PIN facultatif (4 chiffres) protégeant le réglage « Afficher les contenus adultes ».

/// Demande le code actuel ; vrai si aucun code n'est défini ou s'il est correct.
Future<bool> verifyAdultPin(BuildContext context, LibraryStore library) async {
  if (!library.hasAdultPin) return true;
  final pin = await _askPin(context, tr('Code PIN'));
  if (pin == null) return false;
  if (library.checkAdultPin(pin)) return true;
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Code PIN incorrect'))));
  return false;
}

/// Change l'affichage adulte, après vérification du code s'il existe.
Future<void> setAdultVisible(BuildContext context, bool value) async {
  final library = context.library;
  if (await verifyAdultPin(context, library)) library.setShowAdult(value);
}

/// Définit, modifie ou supprime le code (le code actuel est d'abord demandé).
Future<void> editAdultPin(BuildContext context) async {
  final library = context.library;
  if (!await verifyAdultPin(context, library) || !context.mounted) return;
  if (library.hasAdultPin) {
    final remove = await showDialog<bool>(
      context: context,
      builder: (c) => SimpleDialog(title: Text(tr('Code PIN')), children: [
        SimpleDialogOption(onPressed: () => Navigator.pop(c, false), child: Text(tr('Modifier le code'))),
        SimpleDialogOption(onPressed: () => Navigator.pop(c, true), child: Text(tr('Supprimer le code'))),
      ]),
    );
    if (remove == null || !context.mounted) return;
    if (remove) {
      library.setAdultPin(null);
      return;
    }
  }
  final first = await _askPin(context, tr('Nouveau code PIN (4 chiffres)'));
  if (first == null || !context.mounted) return;
  final again = await _askPin(context, tr('Confirmez le code PIN'));
  if (again == null || !context.mounted) return;
  if (first != again) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Les deux codes sont différents'))));
    return;
  }
  library.setAdultPin(first);
}

Future<String?> _askPin(BuildContext context, String title) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: kText(22),
        onSubmitted: (v) => v.length == 4 ? Navigator.pop(c, v) : null,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Annuler'))),
        FilledButton(onPressed: () => controller.text.length == 4 ? Navigator.pop(c, controller.text) : null, child: Text(tr('Valider'))),
      ],
    ),
  );
}
