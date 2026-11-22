import 'package:flutter/widgets.dart';

import '../app_state.dart';
import '../core/youtube.dart';
import '../l10n.dart';

/// Un historique que l'on peut vider : libellé, nombre d'éléments et action d'effacement.
class HistoryKind {
  const HistoryKind(this.title, this.detail, this.count, this.clear);
  final String title;

  /// Ce que l'effacement supprime, en une phrase.
  final String detail;
  final int count;
  final VoidCallback clear;
}

/// Historiques conservés par l'application. Les favoris, les sources et les réglages ne sont jamais touchés.
List<HistoryKind> historyKinds(BuildContext context) {
  final library = context.library;
  final watch = context.watch;
  final youtube = YouTubeStore.shared;
  return [
    HistoryKind(tr('Récents'), tr('Chaînes, films et épisodes ouverts récemment'), library.recentIds.length, library.clearRecents),
    HistoryKind(tr('Vus et reprise de lecture'), tr('Marques « vu » et positions de reprise des films et épisodes'), watch.count, watch.clearAll),
    HistoryKind(tr('Historique YouTube'), tr('Vidéos YouTube regardées'), youtube.history.length, youtube.clearHistory),
  ];
}

/// Vide tous les historiques d'un coup.
void clearAllHistories(BuildContext context) {
  for (final h in historyKinds(context)) {
    h.clear();
  }
}
