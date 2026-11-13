import SwiftUI
import KastideoCore

/// Lecteur plein écran piloté à la télécommande :
/// ↑ / ↓ changent de chaîne (direct), ← / → reculent de 10 s / avancent de 30 s (films), lecture/pause, Menu pour quitter.
struct TVPlayerView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(TVUI.self) private var ui
    @State private var showInfo = true
    @State private var infoTask: Task<Void, Never>?
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VLCVideoRepresentable(player: playback.player)
                .ignoresSafeArea()
            if playback.isLoading { ProgressView().scaleEffect(2) }
            if let message = playback.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .padding(24)
                    .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
            }
            if showInfo, let item = playback.current ?? ui.playing {
                VStack {
                    Spacer()
                    infoBar(item)
                }
                .transition(.opacity)
            }
        }
        .focusable()
        .focused($focused)
        .onAppear {
            focused = true
            flashInfo()
        }
        .onMoveCommand { direction in
            switch direction {
            case .up: zap(-1)
            case .down: zap(1)
            case .left: if !(playback.current?.kind == .live) { playback.jump(seconds: -10) }; flashInfo()
            case .right: if !(playback.current?.kind == .live) { playback.jump(seconds: 30) }; flashInfo()
            @unknown default: break
            }
        }
        .onTapGesture { flashInfo() }
        .onPlayPauseCommand {
            playback.togglePause()
            flashInfo()
        }
        .onExitCommand { ui.stop(playback: playback) }
    }

    private func flashInfo() {
        infoTask?.cancel()
        withAnimation { showInfo = true }
        infoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { withAnimation { showInfo = false } }
        }
    }

    private func zap(_ step: Int) {
        guard playback.current?.kind == .live || ui.playing?.kind == .live else { flashInfo(); return }
        let list = ui.zapList
        guard list.count > 1, let current = ui.playing, let index = list.firstIndex(where: { $0.id == current.id }) else {
            flashInfo()
            return
        }
        let next = list[(index + step + list.count) % list.count]
        ui.playing = next
        playback.play(next)
        flashInfo()
    }

    private func infoBar(_ item: MediaItem) -> some View {
        let programme = item.kind == .live ? store.epg.current(for: item.epgID) : nil
        let upcoming = item.kind == .live ? store.epg.upcoming(for: item.epgID, limit: 1).first : nil
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 24) {
                ArtworkView(url: item.logoURL, name: item.name)
                    .frame(width: 130, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 6) {
                    Text(programme?.title ?? TMDB.cleanTitle(item.name).title).font(.title2.bold()).lineLimit(1)
                    if programme != nil {
                        Text(TMDB.cleanTitle(item.name).title).font(.callout).foregroundStyle(.secondary)
                    }
                    if let programme {
                        ProgressView(value: programme.progress()).tint(TVPalette.orange).frame(maxWidth: 700)
                        if let upcoming {
                            Text("Ensuite · \(upcoming.title)").font(.callout).foregroundStyle(.secondary).lineLimit(1)
                        }
                    } else if item.kind != .live, playback.duration > 0 {
                        ProgressView(value: playback.position).tint(TVPalette.orange).frame(maxWidth: 700)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(playback.health.label).font(.callout).foregroundStyle(.secondary)
                    if !playback.isPlaying && !playback.isLoading { Image(systemName: "pause.fill").font(.title) }
                }
            }
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom))
    }
}
