import SwiftUI
import ObjectiveC

/// Langue de l'application sur Apple TV : « Système » (par défaut) ou un choix manuel, appliqué tout de suite.
/// Les textes viennent des fichiers .lproj ; la recherche de traduction de `Bundle.main` est redirigée vers la langue choisie.
@Observable
final class TVLanguage {
    static let shared = TVLanguage()
    static let storageKey = "appLanguage"

    struct Option: Identifiable {
        let value: String
        let label: String
        var id: String { value }
    }

    /// Noms laissés dans chaque langue pour être compris quelle que soit la langue affichée.
    static let options: [Option] = [
        Option(value: "system", label: "Système / System"),
        Option(value: "fr", label: "Français"),
        Option(value: "en", label: "English"),
        Option(value: "es", label: "Español"),
        Option(value: "de", label: "Deutsch"),
        Option(value: "it", label: "Italiano"),
        Option(value: "pt-PT", label: "Português (Portugal)"),
        Option(value: "pt-BR", label: "Português (Brasil)")
    ]

    /// Langue du système parmi celles gérées (lue avant toute redirection).
    private static let systemCode: String = Bundle.main.preferredLocalizations.first ?? "en"

    /// Choix de l'utilisateur : `system` ou un code de langue.
    private(set) var choice: String

    /// Compteur qui change à chaque choix : sert à reconstruire l'interface.
    private(set) var revision = 0

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? "system"
        choice = Self.options.contains { $0.value == stored } ? stored : "system"
        Self.redirect(to: choice)
    }

    /// Code de langue effectivement affiché : fr, en, es, de, it, pt-PT ou pt-BR.
    var code: String { choice == "system" ? Self.systemCode : choice }

    /// Langue de l'aide : fr, en, es, de, it ou pt (pt-PT et pt-BR partagent l'aide portugaise ; repli : anglais).
    var helpLanguage: String {
        let base = String(code.lowercased().prefix(2))
        return ["fr", "es", "de", "it", "pt"].contains(base) ? base : "en"
    }

    /// Change la langue : mémorisée, appliquée à l'écran tout de suite.
    func select(_ value: String) {
        guard Self.options.contains(where: { $0.value == value }), value != choice else { return }
        choice = value
        UserDefaults.standard.set(value, forKey: Self.storageKey)
        if value == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([value], forKey: "AppleLanguages")
        }
        Self.redirect(to: value)
        revision += 1
    }

    // MARK: Redirection des traductions

    private static func redirect(to value: String) {
        object_setClass(Bundle.main, TVLanguageBundle.self)
        let path = value == "system" ? nil : Bundle.main.path(forResource: value, ofType: "lproj")
        objc_setAssociatedObject(Bundle.main, &TVLanguageBundle.key, path.flatMap(Bundle.init(path:)), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/// `Bundle.main` redirigé vers le dossier .lproj de la langue choisie.
private final class TVLanguageBundle: Bundle, @unchecked Sendable {
    nonisolated(unsafe) static var key: UInt8 = 0

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &Self.key) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
