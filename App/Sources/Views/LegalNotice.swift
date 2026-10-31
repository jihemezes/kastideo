import SwiftUI
import AppKit

/// Avertissement légal affiché au premier lancement et après chaque mise à jour (texte français et anglais).
/// Le texte est le même dans l'aide (page « Avertissement ») et dans le README.
enum LegalNotice {
    static let acceptedKey = "legal.acceptedVersion"

    struct Content {
        let title: String
        let subtitle: String
        let intro: String
        let points: [(lead: String, body: String)]
        let closing: String
        let accept: String
        let quit: String
        let close: String
    }

    /// Vrai tant que l'utilisateur n'a pas accepté l'avertissement pour cette version.
    static var needsAcceptance: Bool {
        UserDefaults.standard.string(forKey: acceptedKey) != ReleaseNotes.currentVersion
    }

    static func accept() {
        UserDefaults.standard.set(ReleaseNotes.currentVersion, forKey: acceptedKey)
    }

    static func content(for code: String) -> Content {
        code == "en" ? english : french
    }

    static let french = Content(
            title: "Avertissement", subtitle: "À lire avant d'utiliser Kastideo",
            intro: "Merci d'utiliser Kastideo. Kastideo est un lecteur multimédia : il lit les listes de lecture (M3U), les comptes IPTV (Xtream Codes), vos serveurs personnels (Jellyfin, Emby, Plex), les vidéos de vos disques et YouTube.",
            points: [
            ("Aucun contenu fourni.", "Kastideo ne fournit, n'héberge ni ne vend aucune chaîne, aucun film, aucune liste de lecture ni aucun abonnement."),
            ("Aucune affiliation.", "Kastideo n'est affilié à aucun fournisseur de contenus ou d'abonnements IPTV, ni à YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple ou Microsoft. Les marques citées appartiennent à leurs propriétaires. Ce produit utilise l'API TMDB mais n'est ni approuvé ni certifié par TMDB."),
            ("Vos propres contenus.", "Vous devez fournir vos propres sources et contenus. Vous êtes seul responsable de vérifier qu'ils sont légaux et que vous avez tous les droits nécessaires pour les regarder, les enregistrer, les télécharger et les diffuser."),
            ("Droit d'auteur.", "Kastideo n'encourage pas la diffusion de contenus protégés par le droit d'auteur sans l'autorisation de leurs titulaires. Les enregistrements, les téléchargements et la diffusion vers un téléviseur (Cast) sont réservés à un usage privé, dans les limites de la loi de votre pays."),
            ("Responsabilité.", "L'auteur de Kastideo n'est pas responsable de l'usage que vous faites du logiciel, ni du contenu, de la disponibilité ou de la légalité des services tiers auxquels vous le connectez. Kastideo est fourni gratuitement, « tel quel », sans garantie."),
            ("Vos données.", "Vos identifiants sont conservés sur votre appareil et ne sont transmis qu'aux services que vous configurez.")
            ],
            closing: "En cliquant sur « J'ai compris et j'accepte », vous reconnaissez avoir lu ces conditions et vous les acceptez. Dans le cas contraire, quittez l'application.",
            accept: "J'ai compris et j'accepte", quit: "Quitter", close: "Fermer")

    static let english = Content(
            title: "Disclaimer", subtitle: "Please read before using Kastideo",
            intro: "Thank you for using Kastideo. Kastideo is a media player: it plays playlists (M3U), IPTV accounts (Xtream Codes), your own servers (Jellyfin, Emby, Plex), the videos on your drives and YouTube.",
            points: [
            ("No content provided.", "Kastideo does not provide, host or sell any channel, movie, playlist or subscription."),
            ("No affiliation.", "Kastideo is not affiliated with any content or IPTV subscription provider, nor with YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple or Microsoft. Trademarks mentioned belong to their respective owners. This product uses the TMDB API but is not endorsed or certified by TMDB."),
            ("Your own content.", "You must supply your own sources and content. You are solely responsible for checking that they are legal and that you have all the rights needed to watch, record, download and stream them."),
            ("Copyright.", "Kastideo does not encourage the streaming of copyright-protected material without the permission of the copyright holder. Recordings, downloads and casting to a TV are for private use only, within the limits of the law in your country."),
            ("Liability.", "The author of Kastideo is not responsible for how you use the software, nor for the content, availability or legality of the third-party services you connect it to. Kastideo is provided free of charge, “as is”, without warranty."),
            ("Your data.", "Your credentials are kept on your device and are only sent to the services you configure.")
            ],
            closing: "By clicking “I understand and accept”, you confirm that you have read and accept these terms. Otherwise, please quit the application.",
            accept: "I understand and accept", quit: "Quit", close: "Close")
}

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
