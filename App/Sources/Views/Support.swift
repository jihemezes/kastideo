import SwiftUI
import AppKit

/// Soutien volontaire au développeur (Ko-fi). L'application reste entièrement gratuite.
enum Support {
    static let url = URL(string: "https://ko-fi.com/jihemezes")!
    /// Réglage : masquer les boutons discrets (accueil, nouveautés). Ceux de Réglages > À propos et de l'aide restent.
    static let hideKey = "support.hide"
}

/// Petit bouton discret « Offrir un café » (ouvre la page Ko-fi dans le navigateur).
struct SupportButton: View {
    @AppStorage(Support.hideKey) private var hidden = false
    @Environment(\.openURL) private var openURL
    /// `true` : s'affiche même si l'utilisateur a masqué les boutons (page À propos).
    var always = false
    var onDark = false

    var body: some View {
        if always || !hidden {
            Button {
                openURL(Support.url)
            } label: {
                Label("Offrir un café", systemImage: "cup.and.saucer.fill")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(onDark ? Color.white.opacity(0.12) : Color.accentColor.opacity(0.12)))
                    .foregroundStyle(onDark ? Color.white.opacity(0.75) : Color.accentColor)
            }
            .buttonStyle(.plain)
            .help("Kastideo reste gratuit. Un café pour soutenir son développement ? (Ko-fi)")
        }
    }
}

/// Onglet Réglages > À propos.
struct AboutSettingsView: View {
    @AppStorage(Support.hideKey) private var hidden = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kastideo").font(.title2.weight(.bold))
                        Text("Version \(ReleaseNotes.currentVersion)").foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Text("Kastideo est gratuit et le restera. Si l'application vous plaît et que vous souhaitez encourager son développement, vous pouvez m'offrir un café : c'est facultatif, et chaque geste fait plaisir.")
                HStack {
                    SupportButton(always: true)
                    Spacer()
                }
                Toggle("Masquer les boutons « Offrir un café » (accueil, nouveautés)", isOn: $hidden)
            } header: {
                Text("Soutenir Kastideo")
            }

            Section {
                Button("Page du projet sur GitHub") {
                    openURL(URL(string: "https://github.com/jihemezes/kastideo")!)
                }
                Button("Signaler un problème ou proposer une idée") {
                    openURL(URL(string: "https://github.com/jihemezes/kastideo/issues")!)
                }
            } header: {
                Text("Liens")
            }
        }
        .formStyle(.grouped)
    }
}
