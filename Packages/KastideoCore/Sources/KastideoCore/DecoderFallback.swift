import Foundation

/// Détection d'une image figée : des données arrivent, la lecture est en cours, mais plus aucune image n'est affichée.
/// Appelé à intervalle régulier (toutes les 2 s dans l'application). Sert à basculer en décodage logiciel.
public struct FreezeDetector: Sendable {
    /// Nombre de mesures consécutives sans nouvelle image avant de conclure à une image figée.
    public let limit: Int
    private var lastShown: Int?
    private var frozen = 0

    public init(limit: Int = 3) {
        self.limit = max(limit, 1)
    }

    public mutating func reset() {
        lastShown = nil
        frozen = 0
    }

    /// Retourne vrai quand l'image est figée depuis [limit] mesures de suite.
    /// Pause, mise en mémoire tampon ou absence de données ne comptent pas comme une image figée.
    public mutating func update(displayedPictures: Int, playing: Bool, dataArriving: Bool) -> Bool {
        defer { lastShown = displayedPictures }
        guard playing, dataArriving, let last = lastShown else {
            frozen = 0
            return false
        }
        if displayedPictures == last { frozen += 1 } else { frozen = 0 }
        return frozen >= limit
    }
}
