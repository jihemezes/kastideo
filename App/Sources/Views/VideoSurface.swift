import SwiftUI
import AppKit
import VLCKitSPM
import KastideoCore

/// Surface vidéo VLC avec contrôles, chargement, erreurs et temps de démarrage.
struct VideoSurface: View {
    @Environment(PlaybackController.self) private var playback
    @Environment(NavigationModel.self) private var navigation
    @AppStorage(PlaybackKeys.showStartupTime) private var showStartupTime = true

    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?
    @State private var showStartupBadge = false
    @State private var scrubbing: Double?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack {
            Color.black
            VLCVideoRepresentable(player: playback.player)

            // Calque transparent : capte le survol et le double-clic au-dessus de la vue VLC.
            Color.clear
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    if case .active = phase { revealControls() }
                }
                .onTapGesture(count: 2) { navigation.isTheater.toggle() }
                .onTapGesture { playback.togglePause() }

            if playback.isLoading && playback.errorMessage == nil {
                LoadingCard(item: playback.current)
            }

            if let message = playback.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                    HStack {
                        Button("Réessayer") { playback.retry() }
                        Button("Journal de lecture") { openWindow(id: "playbackLog") }
                    }
                }
                .foregroundStyle(.white)
                .padding(24)
                .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
            }

            VStack {
                HStack {
                    Spacer()
                    if showStartupTime, showStartupBadge, let time = playback.startupTime {
                        Label(String(format: "Prête en %.1f s", time), systemImage: "bolt.fill")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.opacity)
                    }
                }
                Spacer()
                if controlsVisible && playback.current != nil && playback.errorMessage == nil {
                    ControlsBar(scrubbing: $scrubbing)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(14)
        }
        .clipped()
        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
        .animation(.easeInOut(duration: 0.3), value: showStartupBadge)
        .onChange(of: playback.startupTime) { _, time in
            guard time != nil else { return }
            showStartupBadge = true
            Task {
                try? await Task.sleep(for: .seconds(4))
                showStartupBadge = false
            }
        }
        .onChange(of: playback.current?.id) { _, _ in revealControls() }
        .onExitCommand { if navigation.isTheater { navigation.isTheater = false } }
    }

    private func revealControls() {
        controlsVisible = true
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, scrubbing == nil else { return }
            controlsVisible = false
        }
    }
}

/// Barre de contrôles : lecture, avance / recul, progression, volume, mode cinéma.
struct ControlsBar: View {
    @Environment(PlaybackController.self) private var playback
    @Environment(NavigationModel.self) private var navigation
    @Binding var scrubbing: Double?

    var body: some View {
        @Bindable var playback = playback
        HStack(spacing: 14) {
            Button { playback.togglePause() } label: {
                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 22)
            }
            .help("Lecture / pause (⌘K)")

            if playback.isSeekable {
                Button { playback.jump(seconds: -10) } label: { Image(systemName: "gobackward.10") }
                    .help("Reculer de 10 s")
                Button { playback.jump(seconds: 30) } label: { Image(systemName: "goforward.30") }
                    .help("Avancer de 30 s")
                Text((scrubbing.map { $0 * playback.duration } ?? playback.elapsed).clockString)
                    .monospacedDigit()
                Slider(value: Binding(get: { scrubbing ?? playback.position },
                                      set: { scrubbing = $0 }),
                       in: 0...1,
                       onEditingChanged: { editing in
                    if !editing, let value = scrubbing {
                        playback.seek(to: value)
                        scrubbing = nil
                    }
                })
                .controlSize(.small)
                Text(playback.duration.clockString)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("EN DIRECT").font(.caption.weight(.bold))
                }
                Spacer()
            }

            Button { playback.isMuted.toggle() } label: {
                Image(systemName: playback.isMuted || playback.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .frame(width: 22)
            }
            .help("Couper / rétablir le son")
            Slider(value: $playback.volume, in: 0...200)
                .controlSize(.small)
                .frame(width: 90)
                .help("Volume (100 = normal, jusqu'à 200 %)")

            Button { navigation.isTheater.toggle() } label: {
                Image(systemName: navigation.isTheater ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            }
            .help("Mode cinéma (⌘↩ ou double-clic)")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.white)
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .environment(\.colorScheme, .dark)
    }
}

/// Carte affichée pendant l'ouverture du flux.
struct LoadingCard: View {
    let item: MediaItem?

    var body: some View {
        VStack(spacing: 12) {
            if let item {
                LogoView(url: item.logoURL, name: item.name, size: 72)
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            ProgressView()
                .controlSize(.regular)
                .tint(.white)
        }
        .padding(24)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Vue vidéo VLC (VLCVideoView) intégrée dans SwiftUI.
struct VLCVideoRepresentable: NSViewRepresentable {
    let player: VLCMediaPlayer

    func makeNSView(context: Context) -> VLCVideoView {
        let view = VLCVideoView(frame: .zero)
        view.backColor = .black
        view.fillScreen = false
        player.drawable = view
        return view
    }

    func updateNSView(_ view: VLCVideoView, context: Context) {
        if (player.drawable as? VLCVideoView) !== view {
            player.drawable = view
        }
    }
}
