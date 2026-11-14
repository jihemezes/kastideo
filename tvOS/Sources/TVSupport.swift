import SwiftUI
import UIKit
import VLCKitSPM
import KastideoCore

// MARK: - Pont avec le code partagé (mêmes noms que sur Mac et iPhone)

/// Surface vidéo VLC conservée tant que l'app tourne.
@MainActor
enum TVVideoHost {
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

enum VideoContainerView {
    @MainActor
    static func ensureHosted(for player: VLCMediaPlayer) {
        TVVideoHost.attach(player)
    }
}

/// La diffusion vers un téléviseur n'a pas de sens sur Apple TV.
@MainActor
final class CastCenter {
    static let shared = CastCenter()
    func castEnded(by controller: PlaybackController) {}
}

struct VLCVideoRepresentable: UIViewRepresentable {
    let player: VLCMediaPlayer

    func makeUIView(context: Context) -> UIView {
        let host = UIView(frame: .zero)
        host.backgroundColor = .black
        let video = TVVideoHost.attach(player)
        video.removeFromSuperview()
        video.frame = host.bounds
        video.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(video)
        return host
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
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

enum TVPalette {
    static let orange = Color(red: 1.0, green: 0.53, blue: 0.16)
    static let magenta = Color(red: 0.78, green: 0.2, blue: 0.62)
}

// MARK: - État de l'interface

@MainActor
@Observable
final class TVUI {
    /// Contenu en cours de lecture plein écran.
    var playing: MediaItem?
    /// Chaînes parmi lesquelles on change avec haut / bas.
    var zapList: [MediaItem] = []
    /// Fiche détaillée ouverte (film ou série).
    var detail: MediaItem?
    var showDisclaimer = LegalNotice.needsAcceptance
    /// Onglet affiché (0 Accueil, 1 Direct, 2 Films, 3 Séries, 4 Guide TV, 5 Réglages).
    var tab = 0
    /// Chaîne regardée juste avant (« Dernière chaîne »).
    var previousChannel: MediaItem?
    /// Épisodes de la série en cours (épisode suivant automatique).
    var episodeContext: [MediaItem] = []

    func play(_ item: MediaItem, list: [MediaItem] = [], playback: PlaybackController) {
        if item.kind == .live, let current = playing ?? playback.current, current.kind == .live, current.id != item.id {
            previousChannel = current
        }
        if item.kind == .live { zapList = list.isEmpty ? zapList : list } else { zapList = [] }
        if item.kind != .episode { episodeContext = [] }
        playing = item
        playback.play(item)
    }

    func nextEpisode(after item: MediaItem) -> MediaItem? {
        guard let index = episodeContext.firstIndex(where: { $0.id == item.id }), index + 1 < episodeContext.count else { return nil }
        return episodeContext[index + 1]
    }

    /// Fin d'un épisode : lance le suivant.
    func playNext(after item: MediaItem, playback: PlaybackController) {
        guard let next = nextEpisode(after: item) else { return }
        play(next, playback: playback)
    }

    func stop(playback: PlaybackController) {
        playback.stopByUser()
        playing = nil
    }
}

// MARK: - Vignette

struct ArtworkView: View {
    let url: URL?
    let name: String
    var contentMode: ContentMode = .fit

    var body: some View {
        ZStack {
            Color.white.opacity(0.07)
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
            .font(.system(size: 54, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

/// Fond dégradé de l'accueil Kastideo.
struct TVBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.04, blue: 0.1), Color(red: 0.18, green: 0.05, blue: 0.22)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [TVPalette.magenta.opacity(0.35), .clear], center: .bottomTrailing, startRadius: 20, endRadius: 900)
            RadialGradient(colors: [TVPalette.orange.opacity(0.15), .clear], center: .topTrailing, startRadius: 10, endRadius: 600)
        }
        .ignoresSafeArea()
    }
}

extension Programme {
    /// « 20:55 – 22:30 »
    func timeRange() -> String {
        "\(start.formatted(date: .omitted, time: .shortened)) – \(stop.formatted(date: .omitted, time: .shortened))"
    }
}

extension SourceKind {
    var title: String {
        switch self {
        case .m3uURL: return String(localized: "Playlist M3U (URL)")
        case .m3uFile: return String(localized: "Playlist M3U (fichier)")
        case .xtream: return String(localized: "Xtream Codes")
        case .folders: return String(localized: "Dossiers")
        case .mediaServer(let type, _, _): return type.label
        case .gallery: return String(localized: "Galerie")
        }
    }
}

// TVVLCKit n'a pas l'API de diffusion vers un téléviseur (Cast) : substituts inertes pour que le code partagé compile.
final class VLCRendererItem: NSObject {
    var name: String { "" }
}

extension VLCMediaPlayer {
    func setRendererItem(_ item: VLCRendererItem?) -> Bool { true }
}
