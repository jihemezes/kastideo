import SwiftUI

extension View {
    /// Titre de rubrique des Réglages : sur Mac, en couleur d'accent et en gras pour bien se repérer dans la fenêtre.
    @ViewBuilder
    func settingsHeader() -> some View {
        #if os(macOS)
        self.font(.headline).foregroundStyle(Color.accentColor)
        #else
        self
        #endif
    }
}

/// Section de formulaire dont le titre est mis en valeur (couleur d'accent sur Mac) ; identique à `Section("Titre")` ailleurs.
struct AccentSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        Section {
            content()
        } header: {
            Text(title).settingsHeader()
        }
    }
}
