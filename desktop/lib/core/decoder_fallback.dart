/// Détecte une image figée : des données arrivent, la lecture est en cours, mais plus aucune image n'est
/// affichée depuis [limit] mesures consécutives (une mesure toutes les 2 s).
class FreezeDetector {
  FreezeDetector({int limit = 3}) : limit = limit < 1 ? 1 : limit;

  final int limit;
  int? _last;
  int _frozen = 0;

  void reset() {
    _last = null;
    _frozen = 0;
  }

  /// Renvoie vrai quand l'image est figée depuis assez longtemps.
  bool update({required int frame, required bool playing, required bool dataArriving}) {
    final last = _last;
    _last = frame;
    if (!playing || !dataArriving || last == null) {
      _frozen = 0;
      return false;
    }
    _frozen = frame == last ? _frozen + 1 : 0;
    return _frozen >= limit;
  }

  /// Message du moteur qui trahit un décodeur matériel défaillant.
  static bool isHardwareDecoderError(String message) {
    final m = message.toLowerCase();
    final hardware = m.contains('hwdec') ||
        m.contains('vaapi') ||
        m.contains('d3d11va') ||
        m.contains('dxva') ||
        m.contains('nvdec') ||
        m.contains('vdpau') ||
        m.contains('cuda');
    final failure = m.contains('fail') || m.contains('error') || m.contains('cannot') || m.contains('unable');
    return hardware && failure;
  }
}
