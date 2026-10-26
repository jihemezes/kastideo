import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/recording.dart';

ScheduledRecording _at(DateTime start, ScheduleRepeat repeat) {
  final s = start.millisecondsSinceEpoch ~/ 1000;
  return ScheduledRecording(id: 'c|$s', channelId: 'c', channelName: 'TF1', title: 'JT', startS: s, stopS: s + 1800, repeat: repeat);
}

void main() {
  test('Prochaine occurrence d\'un enregistrement répété', () {
    final now = DateTime.now();
    // Un vendredi à venir, 20 h.
    var friday = DateTime(now.year, now.month, now.day + 7, 20);
    while (friday.weekday != DateTime.friday) {
      friday = friday.add(const Duration(days: 1));
    }
    expect(_at(friday, ScheduleRepeat.weekdays).next()!.start.weekday, DateTime.monday);
    expect(_at(friday, ScheduleRepeat.daily).next()!.start.weekday, DateTime.saturday);
    expect(_at(friday, ScheduleRepeat.weekly).next()!.start.difference(friday).inDays, 7);
    expect(_at(friday, ScheduleRepeat.weekly).next()!.start.hour, 20);
    expect(_at(friday, ScheduleRepeat.none).next(), isNull);
    // Occurrence passée depuis longtemps : la suivante est dans le futur.
    final old = _at(DateTime(now.year, now.month, now.day - 10, 20), ScheduleRepeat.daily).next()!;
    expect(old.stop.isAfter(now), isTrue);
  });
}
