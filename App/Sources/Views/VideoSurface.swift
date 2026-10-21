import SwiftUI
import AppKit
import VLCKitSPM
import KastideoCore

/// Surface vidéo VLC avec contrôles, chargement, erreurs et temps de démarrage.
struct VideoSurface: View {
    @Environment(PlaybackController.self) private var playback
    @Environment(NavigationModel.self) private var navigation
    @Environment(RecordingCenter.self) private var recordings
    @AppStorage(PlaybackKeys.showStartupTime) private var showStartupTime = true

    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?
    @State private var showStartupBadge = false
    @State private var scrubbing: Double?
    @State private var hoveringBar = false
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
                    if let live = recordings.activeLive {
                        RecordingBadge(live: live)
                    }
                    Spacer()
                    if showStartupTime, showStartupBadge, let time = playback.startupTime {
                        Label(String(format: String(localized: "Prête en %.1f s"), time), systemImage: "bolt.fill")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.opacity)
                    }
                }
                Spacer()
                if controlsVisible && playback.current != nil && playback.errorMessage == nil {
                    ControlsBar(scrubbing: $scrubbing)
                        .frame(maxWidth: 860)
                        .onHover { inside in
                            hoveringBar = inside
                            if !inside { revealControls() }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(14)

            if navigation.showContextPanel, playback.current != nil {
                HStack {
                    Spacer()
                    PlayerContextPanel()
                        .frame(width: 330)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                .padding(14)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: navigation.showContextPanel)
        .overlay(alignment: .top) {
            if let resumed = playback.resumedAt {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Reprise à \(resumed.clockString)")
                        .font(.callout.weight(.medium).monospacedDigit())
                    Button("Recommencer") { playback.restartFromBeginning() }
                        .buttonStyle(.borderless)
                        .font(.callout.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.black.opacity(0.7), in: Capsule())
                .padding(.top, 54)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipped()
        .animation(.easeInOut(duration: 0.25), value: playback.resumedAt)
        .onChange(of: playback.resumedAt) { _, value in
            guard let value else { return }
            Task {
                try? await Task.sleep(for: .seconds(8))
                if playback.resumedAt == value { playback.dismissResumeNotice() }
            }
        }
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
        .onExitCommand {
            if navigation.showContextPanel { navigation.showContextPanel = false }
            else if navigation.isTheater { navigation.isTheater = false }
        }
    }

    /// Barre rétractable : visible au moindre mouvement, masquée (avec le pointeur) après 3 s d'inactivité,
    /// sauf pendant un déplacement dans la timeline, au survol de la barre ou quand le panneau est ouvert.
    private func revealControls() {
        controlsVisible = true
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, scrubbing == nil, !hoveringBar, !navigation.showContextPanel,
                  playback.isPlaying else { return }
            controlsVisible = false
            NSCursor.setHiddenUntilMouseMoves(true)
        }
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
/// VLC reste attaché à la vue où la vidéo a démarré : changer de vue en cours de lecture donne un écran noir
/// (retour depuis l'accueil, plein écran…). On garde donc une seule VLCVideoView par lecteur, déplacée dans
/// le conteneur affiché le plus récent. Pendant une transition (plein écran), l'ancien et le nouveau conteneur
/// coexistent : seul le plus récent présent dans une fenêtre reçoit la vidéo.
struct VLCVideoRepresentable: NSViewRepresentable {
    let player: VLCMediaPlayer

    func makeNSView(context: Context) -> VideoContainerView {
        let container = VideoContainerView(player: player)
        VideoContainerView.register(container)
        return container
    }

    func updateNSView(_ container: VideoContainerView, context: Context) {
        VideoContainerView.reassign(for: player)
    }

    static func dismantleNSView(_ container: VideoContainerView, coordinator: ()) {
        VideoContainerView.unregister(container)
    }
}

/// Conteneur de la vidéo VLC partagée.
final class VideoContainerView: NSView {
    let player: VLCMediaPlayer
    private let order: Int

    private static var counter = 0
    private static var containers: [WeakContainer] = []
    private static var videoViews: [ObjectIdentifier: VLCVideoView] = [:]

    private struct WeakContainer { weak var view: VideoContainerView? }

    init(player: VLCMediaPlayer) {
        self.player = player
        Self.counter += 1
        order = Self.counter
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) non pris en charge") }

    static func videoView(for player: VLCMediaPlayer) -> VLCVideoView {
        let key = ObjectIdentifier(player)
        if let view = videoViews[key] { return view }
        let view = VLCVideoView(frame: .zero)
        view.backColor = .black
        view.fillScreen = false
        view.autoresizingMask = [.width, .height]
        videoViews[key] = view
        player.drawable = view
        return view
    }

    static func register(_ container: VideoContainerView) {
        containers.removeAll { $0.view == nil }
        containers.append(WeakContainer(view: container))
    }

    static func unregister(_ container: VideoContainerView) {
        containers.removeAll { $0.view == nil || $0.view === container }
        reassign(for: container.player)
    }

    /// Fenêtre invisible qui héberge la vidéo quand aucun écran ne l'affiche : le moteur VLC a besoin que sa vue
    /// reste dans une fenêtre, sinon l'arrêt de la lecture peut bloquer l'application (roue multicolore).
    private static let parking: NSWindow = {
        let window = NSWindow(contentRect: NSRect(x: -10_000, y: -10_000, width: 320, height: 180),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 180))
        return window
    }()

    /// Garantit que la vue vidéo est dans une fenêtre (écran affiché, sinon fenêtre invisible).
    static func ensureHosted(for player: VLCMediaPlayer) {
        reassign(for: player)
        let view = videoView(for: player)
        if view.window == nil, let holder = parking.contentView {
            view.removeFromSuperview()
            view.frame = holder.bounds
            holder.addSubview(view)
        }
    }

    /// Place la vidéo dans le conteneur le plus récent qui est affiché dans une fenêtre.
    static func reassign(for player: VLCMediaPlayer) {
        let candidates = containers.compactMap(\.view).filter { $0.player === player && $0.window != nil }
        guard let target = candidates.max(by: { $0.order < $1.order }) else {
            // Aucun écran : la vidéo part dans la fenêtre invisible.
            let view = videoView(for: player)
            if view.window == nil || view.superview?.window == nil, let holder = parking.contentView, view.superview !== holder {
                view.removeFromSuperview()
                view.frame = holder.bounds
                holder.addSubview(view)
            }
            return
        }
        let view = videoView(for: player)
        if view.superview !== target {
            view.removeFromSuperview()
            view.frame = target.bounds
            target.addSubview(view)
        }
        if (player.drawable as? VLCVideoView) !== view {
            player.drawable = view
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Arrivée (nouvel écran) ou départ (ancien écran retiré) : la vidéo va au bon conteneur.
        let player = player
        Task { @MainActor in VideoContainerView.reassign(for: player) }
    }
}
