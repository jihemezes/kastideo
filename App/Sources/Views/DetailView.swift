import SwiftUI
import AVKit
import KastideoCore

/// Colonne de droite : lecteur ou fiche de série.
struct DetailView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback

    var body: some View {
        if let id = navigation.selectedItemID, let item = store.item(id: id) {
            if item.needsEpisodes {
                SeriesDetailView(series: item)
                    .id(item.id)
            } else {
                PlayerPane(item: item)
            }
        } else {
            ContentUnavailableView("Choisissez un programme",
                                   systemImage: "play.tv",
                                   description: Text("Sélectionnez une chaîne, un film ou une série dans la liste."))
                .onAppear { playback.stop() }
        }
    }
}

/// Lecteur + informations (guide TV, résumé).
struct PlayerPane: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    let item: MediaItem

    var body: some View {
        VStack(spacing: 0) {
            VideoSurface()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            InfoPanel(item: item)
                .frame(height: 190)
        }
        .task(id: item.id) {
            playback.play(item)
            store.recordPlay(item)
        }
    }
}

/// Surface vidéo avec états de chargement et d'erreur.
struct VideoSurface: View {
    @Environment(PlaybackController.self) private var playback

    var body: some View {
        ZStack {
            Color.black
            PlayerView(player: playback.player)
            if playback.isLoading && playback.errorMessage == nil {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
            if let message = playback.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                    Button("Réessayer") { playback.retry() }
                }
                .foregroundStyle(.white)
                .padding(24)
                .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

/// Vue AVKit native (contrôles, plein écran, image dans l'image).
struct PlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .floating
        view.allowsPictureInPicturePlayback = true
        view.showsFullScreenToggleButton = true
        view.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ view: AVPlayerView, context: Context) {
        if view.player !== player { view.player = player }
    }
}

/// Panneau d'informations sous le lecteur.
struct InfoPanel: View {
    @Environment(LibraryStore.self) private var store
    let item: MediaItem

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            LogoView(url: item.logoURL, name: item.name, size: 64)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.title2.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Button {
                        store.toggleFavorite(item.id)
                    } label: {
                        Image(systemName: store.isFavorite(item.id) ? "star.fill" : "star")
                            .foregroundStyle(store.isFavorite(item.id) ? .yellow : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Ajouter ou retirer des favoris (⌘D)")
                }
                Text(item.group)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if item.kind == .live {
                    GuideStrip(epgID: item.epgID)
                } else if let info = item.info {
                    ScrollView {
                        Text(info)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.background)
    }
}

/// Programme en cours + programmes à venir.
struct GuideStrip: View {
    @Environment(LibraryStore.self) private var store
    let epgID: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = context.date
            if let current = store.epg.current(for: epgID, at: now) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("EN COURS")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundStyle(.white)
                        Text(current.title).font(.headline).lineLimit(1)
                        Spacer()
                        Text("\(current.start.formatted(date: .omitted, time: .shortened)) – \(current.stop.formatted(date: .omitted, time: .shortened))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: current.progress(at: now))
                        .progressViewStyle(.linear)
                    if let desc = current.desc {
                        Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.epg.upcoming(for: epgID, after: now)) { programme in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(programme.start.formatted(date: .omitted, time: .shortened))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Text(programme.title).font(.caption).lineLimit(1)
                                }
                                .padding(8)
                                .frame(width: 150, alignment: .leading)
                                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                                .help(programme.desc ?? programme.title)
                            }
                        }
                    }
                }
            } else {
                Text(epgID == nil ? "Pas d'identifiant de guide TV pour cette chaîne." : "Aucun programme disponible pour le moment.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
