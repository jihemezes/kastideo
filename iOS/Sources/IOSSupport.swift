import SwiftUI
import Observation
import UIKit
import AVKit
import VLCKitSPM
import KastideoCore

// MARK: - Adaptations iOS du code partagé avec le Mac

/// Sur iOS, la vue vidéo VLC est créée une fois pour toutes par lecteur : elle reste attachée au lecteur
/// (le son continue) même quand l'écran de lecture est refermé.
@MainActor
enum IOSVideoHost {
    private static var views: [ObjectIdentifier: UIView] = [:]

    @discardableResult
    static func attach(_ player: VLCMediaPlayer) -> UIView {
        let key = ObjectIdentifier(player)
        if let view = views[key] { return view }
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        views[key] = view
        player.drawable = view
        return view
    }
}

/// Même nom que sur Mac (PlaybackController l'appelle avant d'arrêter un flux).
enum VideoContainerView {
    @MainActor
    static func ensureHosted(for player: VLCMediaPlayer) {
        IOSVideoHost.attach(player)
    }
}

/// La diffusion vers un téléviseur (Cast) n'existe pas encore sur iOS : AirPlay est proposé à la place.
@MainActor
final class CastCenter {
    static let shared = CastCenter()
    func castEnded(by controller: PlaybackController) {}
}

/// Surface vidéo VLC pour SwiftUI.
struct VLCVideoRepresentable: UIViewRepresentable {
    let player: VLCMediaPlayer

    func makeUIView(context: Context) -> UIView {
        let host = UIView(frame: .zero)
        host.backgroundColor = .black
        let video = IOSVideoHost.attach(player)
        video.removeFromSuperview()
        video.frame = host.bounds
        video.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(video)
        return host
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Bouton AirPlay du système (diffusion vers une Apple TV ou un HomePod ; la recopie d'écran fonctionne pour la vidéo).
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let picker = AVRoutePickerView(frame: .zero)
        picker.tintColor = .white
        picker.activeTintColor = UIColor(IOSPalette.orange)
        return picker
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Interface commune

/// État de l'interface iPhone / iPad.
@MainActor
@Observable
final class IOSUI {
    var showPlayer = false
    var detail: MediaItem?
    /// Programme dont la fiche est ouverte (guide, thèmes).
    var programme: ProgrammeRef?
    var tab: IOSTab = .home
    var showAddSource = false
    var showDisclaimer = LegalNotice.needsAcceptance
}

enum IOSTab: Hashable {
    case home, live, movies, series, settings
}

enum IOSPalette {
    static let orange = Color(red: 1.0, green: 0.62, blue: 0.2)
    static let background = Color(red: 0.07, green: 0.06, blue: 0.11)
    static let card = Color.white.opacity(0.08)
}

/// Pastille d'image (logo de chaîne ou affiche) avec une lettre de secours.
struct ArtworkView: View {
    let url: URL?
    let name: String
    var contentMode: ContentMode = .fit

    var body: some View {
        ZStack {
            Rectangle().fill(IOSPalette.card)
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: contentMode)
                    default:
                        initial
                    }
                }
            } else {
                initial
            }
        }
        .clipped()
    }

    private var initial: some View {
        Text(String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased())
            .font(.title2.weight(.bold))
            .foregroundStyle(.secondary)
    }
}

extension MediaKind {
    var title: String {
        switch self {
        case .live: return String(localized: "Direct")
        case .movie: return String(localized: "Films")
        case .series: return String(localized: "Séries")
        case .episode: return String(localized: "Épisodes")
        }
    }
}

enum Support {
    static let url = URL(string: "https://ko-fi.com/jihemezes")!
}

extension SourceKind {
    var title: String {
        switch self {
        case .m3uURL: return String(localized: "Playlist M3U (URL)")
        case .m3uFile: return String(localized: "Playlist M3U (fichier)")
        case .xtream: return String(localized: "Xtream Codes")
        case .folders: return String(localized: "Dossiers")
        case .mediaServer(let type, _, _): return type.label
        }
    }
}
