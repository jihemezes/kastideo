import SwiftUI
import KastideoCore

/// Lecteur plein écran piloté à la télécommande :
/// ↑ / ↓ changent de chaîne (direct), ← / → reculent de 10 s / avancent de 30 s (films), lecture/pause,
/// appui central = options (audio, sous-titres, vitesse, dernière chaîne, numéro de chaîne), Menu pour quitter.
struct TVPlayerView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(TVUI.self) private var ui
    @State private var showInfo = true
    @State private var infoTask: Task<Void, Never>?
    @State private var dialog: PlayerDialog?
    @State private var numberText = ""
    @State private var askNumber = false
    @FocusState private var focused: Bool
    @AppStorage("tv.zapMode") private var zapMode = "confirm"
    @State private var browsing = false
    @State private var browseIndex = 0
    @State private var lastMove = Date.distantPast
    @State private var browseTask: Task<Void, Never>?

    enum PlayerDialog: Identifiable {
        case options, audio, subtitles, speed, sleep
        var id: Int { hashValue }
    }

    private var current: MediaItem? { ui.playing ?? playback.current }
    private var isLive: Bool { current?.kind == .live }

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
            if browsing { channelList }
            if showInfo, !browsing, let item = current {
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
            // Le pavé tactile de la télécommande déclenche facilement ces gestes : on les espace.
            switch direction {
            case .up: vertical(-1)
            case .down: vertical(1)
            case .left: horizontal(-10)
            case .right: horizontal(30)
            @unknown default: break
            }
        }
        .onTapGesture {
            if browsing {
                validateBrowse()
            } else {
                flashInfo()
                dialog = .options
            }
        }
        .onPlayPauseCommand {
            playback.togglePause()
            flashInfo()
        }
        .onExitCommand {
            if browsing { browsing = false } else { ui.stop(playback: playback) }
        }
        .confirmationDialog("Options", isPresented: Binding(get: { dialog == .options }, set: { if !$0 { dialog = nil } }), titleVisibility: .visible) {
            if let current {
                Button(store.isFavorite(current.id) ? "Retirer des favoris" : "Ajouter aux favoris") { store.toggleFavorite(current.id) }
            }
            Button(ui.sleepAt == nil ? "Minuterie de veille…" : "Minuterie de veille (active)…") { dialog = .sleep }
            Button("Pistes audio…") { dialog = .audio }
            Button("Sous-titres…") { dialog = .subtitles }
            if !isLive { Button("Vitesse de lecture…") { dialog = .speed } }
            if isLive, let previous = ui.previousChannel {
                Button("Dernière chaîne : \(previous.name)") { ui.play(previous, playback: playback) }
            }
            if isLive { Button("Aller à la chaîne n°…") { numberText = ""; askNumber = true } }
            if let current, current.kind == .episode, let next = ui.nextEpisode(after: current) {
                Button("Épisode suivant") { ui.play(next, playback: playback) }
            }
            Button("Fermer", role: .cancel) {}
        }
        .confirmationDialog("Minuterie de veille", isPresented: Binding(get: { dialog == .sleep }, set: { if !$0 { dialog = nil } }), titleVisibility: .visible) {
            ForEach([30, 60, 90, 120], id: \.self) { minutes in
                Button("Arrêter dans \(minutes) min") { ui.setSleep(minutes: minutes, playback: playback) }
            }
            if ui.sleepAt != nil { Button("Désactiver la minuterie", role: .destructive) { ui.setSleep(minutes: nil, playback: playback) } }
            Button("Fermer", role: .cancel) {}
        }
        .confirmationDialog("Pistes audio", isPresented: Binding(get: { dialog == .audio }, set: { if !$0 { dialog = nil } }), titleVisibility: .visible) {
            ForEach(playback.audioTracks.filter { $0.id >= 0 }) { track in
                Button(track.name + (track.id == playback.currentAudioTrack ? " ✓" : "")) { playback.selectAudioTrack(track.id) }
            }
            Button("Fermer", role: .cancel) {}
        }
        .confirmationDialog("Sous-titres", isPresented: Binding(get: { dialog == .subtitles }, set: { if !$0 { dialog = nil } }), titleVisibility: .visible) {
            Button("Désactivés") { playback.selectSubtitleTrack(-1) }
            ForEach(playback.subtitleTracks.filter { $0.id >= 0 }) { track in
                Button(track.name + (track.id == playback.currentSubtitleTrack ? " ✓" : "")) { playback.selectSubtitleTrack(track.id) }
            }
            Button("Fermer", role: .cancel) {}
        }
        .confirmationDialog("Vitesse de lecture", isPresented: Binding(get: { dialog == .speed }, set: { if !$0 { dialog = nil } }), titleVisibility: .visible) {
            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { value in
                Button(String(format: "%g×", value) + (abs(Double(playback.player.rate) - value) < 0.01 ? " ✓" : "")) { playback.player.rate = Float(value) }
            }
            Button("Fermer", role: .cancel) {}
        }
        .alert("Numéro de chaîne", isPresented: $askNumber) {
            TextField("Numéro", text: $numberText)
            Button("OK") { goToNumber() }
            Button("Annuler", role: .cancel) {}
        }
    }

    private func flashInfo() {
        infoTask?.cancel()
        withAnimation { showInfo = true }
        infoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { withAnimation { showInfo = false } }
        }
    }

    private func vertical(_ step: Int) {
        guard isLive else { flashInfo(); return }
        if zapMode == "direct" {
            guard Date().timeIntervalSince(lastMove) > 0.8 else { return }
            lastMove = Date()
            zap(step)
            return
        }
        let list = ui.zapList
        guard list.count > 1 else { flashInfo(); return }
        if !browsing {
            browseIndex = current.flatMap { c in list.firstIndex(where: { $0.id == c.id }) } ?? 0
            browsing = true
        } else {
            guard Date().timeIntervalSince(lastMove) > 0.18 else { return }
            lastMove = Date()
            browseIndex = (browseIndex + step + list.count) % list.count
        }
        browseTask?.cancel()
        browseTask = Task {
            try? await Task.sleep(for: .seconds(7))
            if !Task.isCancelled { browsing = false }
        }
    }

    private func horizontal(_ seconds: Int) {
        if !isLive, Date().timeIntervalSince(lastMove) > 0.5 {
            lastMove = Date()
            playback.jump(seconds: seconds)
        }
        flashInfo()
    }

    private func validateBrowse() {
        browseTask?.cancel()
        browsing = false
        let list = ui.zapList
        guard list.indices.contains(browseIndex) else { return }
        let target = list[browseIndex]
        if target.id != current?.id { ui.play(target, playback: playback) }
        flashInfo()
    }

    /// Liste de chaînes (↑ / ↓ puis clic pour valider).
    private var channelList: some View {
        let list = ui.zapList
        let indices = (-4...4).map { (browseIndex + $0 + list.count * 10) % max(list.count, 1) }
        return HStack {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(indices.enumerated()), id: \.offset) { position, index in
                    if list.indices.contains(index) {
                        let item = list[index]
                        HStack(spacing: 14) {
                            ArtworkView(url: item.logoURL, name: item.name).frame(width: 70, height: 44)
                            Text(item.number.map { "\($0)  " } ?? "").foregroundStyle(.secondary)
                            Text(TMDB.cleanTitle(item.name).title).lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .font(position == 4 ? .title3.bold() : .callout)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .frame(width: 520, alignment: .leading)
                        .background(position == 4 ? TVPalette.orange.opacity(0.55) : Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                Text("↑ ↓ pour parcourir · clic pour valider · Menu pour annuler").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.leading, 60)
            Spacer()
        }
    }

    private func zap(_ step: Int) {
        guard isLive else { flashInfo(); return }
        let list = ui.zapList
        guard list.count > 1, let current, let index = list.firstIndex(where: { $0.id == current.id }) else {
            flashInfo()
            return
        }
        ui.play(list[(index + step + list.count) % list.count], playback: playback)
        flashInfo()
    }

    private func goToNumber() {
        guard let number = Int(numberText.trimmingCharacters(in: .whitespaces)) else { return }
        let all = store.items(for: .all(.live))
        if let target = ui.zapList.first(where: { $0.number == number }) ?? all.first(where: { $0.number == number }) {
            ui.play(target, playback: playback)
            flashInfo()
        }
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
                        Text(TMDB.cleanTitle(item.name).title + (item.number.map { " · n°\($0)" } ?? "")).font(.callout).foregroundStyle(.secondary)
                    }
                    if let programme {
                        ProgressView(value: programme.progress()).tint(TVPalette.orange).frame(maxWidth: 700)
                        if let upcoming {
                            Text("Ensuite · \(upcoming.title)").font(.callout).foregroundStyle(.secondary).lineLimit(1)
                        }
                    } else if item.kind != .live, playback.duration > 0 {
                        ProgressView(value: playback.position).tint(TVPalette.orange).frame(maxWidth: 700)
                        Text("Reste \(remaining)").font(.callout).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(playback.health.qualityLabel ?? playback.health.label).font(.callout).foregroundStyle(.secondary)
                    if !playback.isPlaying && !playback.isLoading { Image(systemName: "pause.fill").font(.title) }
                }
            }
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom))
    }

    private var remaining: String {
        let left = max(playback.duration * (1 - playback.position), 0)
        let minutes = Int(left / 60)
        return minutes >= 60 ? String(format: "%d h %02d", minutes / 60, minutes % 60) : "\(minutes) min"
    }
}
