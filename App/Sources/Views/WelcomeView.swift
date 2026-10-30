import SwiftUI
import AppKit

/// Écran d'accueil affiché tant qu'aucune source n'est configurée.
struct WelcomeView: View {
    @Binding var showAddSource: Bool
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.07, green: 0.06, blue: 0.13), Color(red: 0.16, green: 0.07, blue: 0.20)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .shadow(color: .black.opacity(0.4), radius: 18, y: 8)

                VStack(spacing: 8) {
                    Text("Bienvenue dans Kastideo")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Réunissez vos chaînes, films et séries IPTV dans une seule interface, simple et rapide.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }

                HStack(spacing: 14) {
                    Button {
                        showAddSource = true
                    } label: {
                        Label("Ajouter une source", systemImage: "plus.circle.fill")
                            .padding(.horizontal, 8)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)

                    Button {
                        HelpCenter.shared.requested = "bienvenue"
                        openWindow(id: "help")
                    } label: {
                        Label("Lire l'aide", systemImage: "questionmark.circle")
                    }
                    .controlSize(.large)
                }

                Text("Kastideo est un lecteur : il ne fournit aucun contenu. Ajoutez votre abonnement Xtream Codes ou votre playlist M3U.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
            }
            .padding(40)
        }
        .foregroundStyle(.white)
    }
}
