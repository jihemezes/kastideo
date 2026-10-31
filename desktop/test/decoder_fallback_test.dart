import 'package:flutter_test/flutter_test.dart';
import 'package:kastideo/core/decoder_fallback.dart';

void main() {
  test('image qui avance : jamais figée', () {
    final d = FreezeDetector();
    for (var i = 0; i < 10; i++) {
      expect(d.update(frame: i * 50, playing: true, dataArriving: true), isFalse);
    }
  });

  test('image figée après trois mesures identiques', () {
    final d = FreezeDetector();
    expect(d.update(frame: 10, playing: true, dataArriving: true), isFalse);
    expect(d.update(frame: 10, playing: true, dataArriving: true), isFalse);
    expect(d.update(frame: 10, playing: true, dataArriving: true), isFalse);
    expect(d.update(frame: 10, playing: true, dataArriving: true), isTrue);
  });

  test('pause ou absence de données : pas de fausse alerte', () {
    final d = FreezeDetector();
    for (var i = 0; i < 6; i++) {
      expect(d.update(frame: 5, playing: false, dataArriving: true), isFalse);
    }
    for (var i = 0; i < 6; i++) {
      expect(d.update(frame: 5, playing: true, dataArriving: false), isFalse);
    }
  });

  test('une image qui repart remet le compteur à zéro', () {
    final d = FreezeDetector();
    d.update(frame: 1, playing: true, dataArriving: true);
    d.update(frame: 1, playing: true, dataArriving: true);
    d.update(frame: 1, playing: true, dataArriving: true);
    expect(d.update(frame: 2, playing: true, dataArriving: true), isFalse);
    expect(d.update(frame: 2, playing: true, dataArriving: true), isFalse);
  });

  test('erreurs de décodeur matériel reconnues', () {
    expect(FreezeDetector.isHardwareDecoderError('[ffmpeg/video] hevc: hwdec: failed to map frame'), isTrue);
    expect(FreezeDetector.isHardwareDecoderError('Error decoding via vaapi'), isTrue);
    expect(FreezeDetector.isHardwareDecoderError('Audio device underrun'), isFalse);
  });
}
