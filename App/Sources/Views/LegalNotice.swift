import SwiftUI
import AppKit

/// Fenêtre de l'avertissement : acceptation obligatoire (ou « Quitter ») au lancement, simple relecture dans les Réglages.
struct DisclaimerSheet: View {
    var requiresAcceptance = true
    var onAccept: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var language = ""

    private var content: LegalNotice.Content {
        LegalNotice.content(for: AppLanguage(rawValue: language)?.code ?? AppLanguage.effectiveCode)
    }

    var body: some View {
        let content = content
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title).font(.title2.weight(.bold))
                    Text(content.subtitle).foregroundStyle(.secondary)
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(content.intro)
                    ForEach(Array(content.points.enumerated()), id: \.offset) { _, point in
                        Text(point.lead).bold() + Text(" " + point.body)
                    }
                    Text(content.closing).fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(.trailing, 8)
            }
            HStack {
                Spacer()
                if requiresAcceptance {
                    Button(content.quit) { NSApp.terminate(nil) }
                    Button(content.accept) {
                        LegalNotice.accept()
                        onAccept()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button(content.close) { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(width: 580, height: 560)
        .interactiveDismissDisabled(requiresAcceptance)
    }
}
