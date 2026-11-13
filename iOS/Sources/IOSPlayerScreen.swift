import SwiftUI
import KastideoCore

/// Lecteur plein écran : tap pour afficher les commandes, glisser la barre pour se déplacer.
struct IOSPlayerScreen: View {
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @Environment(LibraryStore.self) private var store
    @Environment(IOSRecorder.self) private var recorder
    @Environment(MultiViewModel.self) private var multiView
    @AppStorage("ios.record.minutes") private var recordMinutes = 0
    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?
    @State private var scrubbing: Double?
    @State private var showInfo = false
    @State private var dragMode: DragMode?
    @State private var dragBase = 0.0
    @State private var seekTarget: Double?
    @State private var hud: IOSPlayerHUD?
    @State private var hudTask: Task<Void, Never>?
    @State private var vodRate: Float = 1
    @State private var aspect = "fit"
    @State private var showEpisodes = false

    private enum DragMode { case volume, brightness, seek, zap }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VLCVideoRepresentable(player: playback.player)
                .ignoresSafeArea()

            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(SpatialTapGesture(count: 2).onEnded { value in
                        doubleTap(x: value.location.x, width: geo.size.width)
                    })
                    .onTapGesture { toggleControls() }
                    .gesture(
                        DragGesture(minimumDistance: 14)
                            .onChanged { dragChanged($0, size: geo.size) }
                            .onEnded { dragEnded($0) }
                    )
            }
            .ignoresSafeArea()

            if playback.isLoading && playback.errorMessage == nil {
                VStack(spacing: 10) {
                    ProgressView().tint(.white).scaleEffect(1.4)
                    if let item = playback.current {
                        Text(item.name).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                    }
                }
                .allowsHitTesting(false)
            }

            if let message = playback.errorMessage {
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(IOSPalette.orange)
                    Text(message).multilineTextAlignment(.center).foregroundStyle(.white)
                    Button("Réessayer") { playback.retry() }.buttonStyle(.borderedProminent)
                }
                .padding(24)
                .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                .padding(30)
            }

            if let resumed = playback.resumedAt {
                VStack {
                    Spacer()
                    Text("Reprise à \(resumed.clockString)")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.black.opacity(0.7), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(.bottom, 90)
                }
                .allowsHitTesting(false)
                .task { try? await Task.sleep(for: .seconds(4)); playback.dismissResumeNotice() }
            }

            if let hud {
                hudView(hud).allowsHitTesting(false).transition(.opacity)
            }

            if controlsVisible {
                controls.transition(.opacity)
                if showInfo { infoPanel.transition(.opacity) }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            scheduleHide()
            let ui = ui, store = store, playback = playback
            playback.onEpisodeEnded = { item in
                ui.playNextEpisode(after: item, store: store, playback: playback)
            }
        }
        .sheet(isPresented: $showEpisodes) {
            if let context = ui.episodeContext {
                IOSEpisodeListSheet(context: context)
            }
        }
        .onChange(of: playback.current?.id) { _, id in
            if vodRate != 1 { vodRate = 1; playback.player.rate = 1 }
            // Le flux change : l'enregistrement en cours est clos.
            recorder.streamEnded()
            if id == nil { ui.showPlayer = false }
        }
    }

    // MARK: Commandes

    private var controls: some View {
        VStack {
            HStack(spacing: 16) {
                Button { ui.showPlayer = false } label: {
                    Image(systemName: "chevron.down").font(.title3.weight(.semibold))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(playback.current?.name ?? "").font(.headline).lineLimit(1)
                    if recorder.isRecording, let started = recorder.startedAt {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text("● Enregistrement \(context.date.timeIntervalSince(started).clockString)")
                                .font(.caption2.monospacedDigit()).foregroundStyle(.red)
                        }
                    } else if let startup = playback.startupTime {
                        Text("Prête en \(String(format: "%.1f", startup)) s").font(.caption2).foregroundStyle(.white.opacity(0.6))
                    }
                    if playback.isLive, let channel = playback.current, !channel.isReplay {
                        programmeLine(channel)
                    }
                }
                Spacer()
                infoChip
                optionsMenu
                if !playback.audioTracks.isEmpty || !playback.subtitleTracks.isEmpty {
                    Menu {
                        if playback.audioTracks.count > 1 {
                            Section("Audio") {
                                ForEach(playback.audioTracks) { track in
                                    Button { playback.selectAudioTrack(track.id) } label: {
                                        if track.id == playback.currentAudioTrack {
                                            Label(track.name, systemImage: "checkmark")
                                        } else {
                                            Text(track.name)
                                        }
                                    }
                                }
                            }
                        }
                        if !playback.subtitleTracks.isEmpty {
                            Section("Sous-titres") {
                                ForEach(playback.subtitleTracks) { track in
                                    Button { playback.selectSubtitleTrack(track.id) } label: {
                                        if track.id == playback.currentSubtitleTrack {
                                            Label(track.name, systemImage: "checkmark")
                                        } else {
                                            Text(track.name)
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "captions.bubble").font(.title3)
                    }
                }
                if playback.isLive, !(playback.current?.isReplay ?? false) {
                    Button {
                        if recorder.isRecording {
                            recorder.stop(playback: playback)
                        } else {
                            recorder.start(playback: playback, minutes: recordMinutes)
                        }
                        scheduleHide()
                    } label: {
                        Image(systemName: recorder.isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.title3)
                            .foregroundStyle(.red)
                    }
                }
                if playback.isLive, !(playback.current?.isReplay ?? false), MultiViewKeys.isAvailable(sources: store.sources) {
                    Button {
                        guard let item = playback.current else { return }
                        // La connexion de la lecture principale est rendue à la MultiVue (sauf enregistrement en cours).
                        if !recorder.isRecording { playback.stopByUser() }
                        multiView.add(item, store: store)
                        ui.showPlayer = false
                        Task {
                            try? await Task.sleep(for: .milliseconds(600))
                            ui.showMultiView = true
                        }
                    } label: {
                        Image(systemName: "rectangle.split.2x2").font(.title3)
                    }
                }
                AirPlayButton().frame(width: 34, height: 34)
                Button { playback.stopByUser(); ui.showPlayer = false } label: {
                    Image(systemName: "stop.fill").font(.title3)
                }
            }
            .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 24)
            .background(LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom))

            Spacer()

            HStack(spacing: 36) {
                if canZap {
                    Button { zap(-1); scheduleHide() } label: {
                        Image(systemName: "backward.end.fill").font(.system(size: 26))
                    }
                }
                if !playback.isLive || playback.timeshiftSeekable {
                    Button { playback.jump(seconds: -10); scheduleHide() } label: {
                        Image(systemName: "gobackward.10").font(.system(size: 30))
                    }
                }
                Button { playback.togglePause(); scheduleHide() } label: {
                    Image(systemName: playback.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 64))
                }
                if !playback.isLive || playback.isTimeshifted {
                    Button { playback.jump(seconds: 30); scheduleHide() } label: {
                        Image(systemName: "goforward.30").font(.system(size: 30))
                    }
                }
                if canZap {
                    Button { zap(1); scheduleHide() } label: {
                        Image(systemName: "forward.end.fill").font(.system(size: 26))
                    }
                }
                if let current = playback.current, let next = ui.nextEpisode(after: current) {
                    Button {
                        ui.play(next, store: store, playback: playback)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "forward.end.fill").font(.system(size: 26))
                            Text("Suivant").font(.caption2)
                        }
                    }
                }
            }

            Spacer()

            bottomBar
        }
        .foregroundStyle(.white)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 6) {
            volumeRow
            if playback.isLive {
                if playback.isTimeshifted { IOSTimeshiftBar().frame(height: 30) }
                HStack(spacing: 10) {
                    if playback.isTimeshifted {
                        Button { playback.goLive(); scheduleHide() } label: {
                            Label("Retour au direct", systemImage: "forward.end.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        Menu {
                            ForEach(TimeshiftSettings.speeds, id: \.self) { speed in
                                Button { playback.setRate(speed) } label: {
                                    if playback.rate == speed {
                                        Label(TimeshiftSettings.label(speed), systemImage: "checkmark")
                                    } else {
                                        Text(TimeshiftSettings.label(speed))
                                    }
                                }
                            }
                        } label: {
                            Text(TimeshiftSettings.label(playback.rate))
                                .font(.caption.weight(.bold).monospacedDigit())
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(.white.opacity(0.18), in: Capsule())
                        }
                    } else {
                        Text("DIRECT")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.red, in: Capsule())
                    }
                    Spacer()
                    Text(Date.now, style: .time).font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.8))
                }
                if let notice = playback.timeshiftNotice {
                    Text(notice).font(.caption).foregroundStyle(.yellow)
                }
            } else if playback.duration > 0 {
                Slider(value: Binding(get: { scrubbing ?? playback.position }, set: { scrubbing = $0 }),
                       in: 0...1, onEditingChanged: { editing in
                    if !editing, let value = scrubbing {
                        playback.seek(to: value)
                        scrubbing = nil
                    }
                    scheduleHide()
                })
                .tint(IOSPalette.orange)
                let shown = (scrubbing ?? playback.position) * playback.duration
                let remaining = max(playback.duration - shown, 0)
                HStack {
                    Text(shown.clockString)
                    Spacer()
                    if remaining > 0 {
                        Text("Reste \(remaining.clockString) · fin à \(Date.now.addingTimeInterval(remaining).formatted(date: .omitted, time: .shortened))")
                    }
                    Spacer()
                    Text(playback.duration.clockString)
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
            }
            if let item = playback.current, item.isReplay, let channel = store.replayChannel(of: item) {
                HStack {
                    Button {
                        playback.play(channel)
                    } label: {
                        Label("Retour au direct", systemImage: "dot.radiowaves.left.and.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 18).padding(.bottom, 14).padding(.top, 20)
        .background(LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
    }

    // MARK: Son

    private var volumeRow: some View {
        HStack(spacing: 12) {
            Button {
                playback.isMuted.toggle()
                scheduleHide()
            } label: {
                Image(systemName: speakerIcon).font(.title3).frame(width: 30)
            }
            Slider(value: Binding(get: { playback.isMuted ? 0 : min(playback.volume, 100) },
                                  set: { value in
                                      playback.volume = value
                                      playback.isMuted = value <= 0
                                  }),
                   in: 0...100, onEditingChanged: { _ in scheduleHide() })
                .tint(.white)
                .frame(maxWidth: 190)
            Spacer()
        }
    }

    private var speakerIcon: String {
        if playback.isMuted || playback.volume <= 0 { return "speaker.slash.fill" }
        if playback.volume < 34 { return "speaker.wave.1.fill" }
        if playback.volume < 67 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    // MARK: Infos du flux

    private var healthColor: Color {
        switch playback.health.level {
        case .good: return .green
        case .fair: return .orange
        case .poor: return .red
        case .unknown: return .gray
        }
    }

    private var qualityShort: String? {
        guard let resolution = playback.health.resolution else { return nil }
        let h = resolution.height
        if h >= 2000 { return "4K" }
        if h >= 700 { return "HD" }
        return "SD"
    }

    private var infoChip: some View {
        Button { showInfo.toggle(); scheduleHide() } label: {
            HStack(spacing: 5) {
                Circle().fill(healthColor).frame(width: 8, height: 8)
                if playback.health.audioIssue != nil {
                    Image(systemName: "speaker.slash.fill").foregroundStyle(.orange).font(.caption)
                }
                if let quality = qualityShort {
                    Text(quality).font(.caption2.weight(.bold))
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.white.opacity(0.6), lineWidth: 1))
                }
                Image(systemName: "info.circle").font(.title3)
            }
        }
    }

    private var infoPanel: some View {
        let health = playback.health
        return VStack {
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle().fill(healthColor).frame(width: 10, height: 10)
                        Text(String(localized: "Réception : \(health.label)")).font(.subheadline.weight(.semibold))
                    }
                    if let resolution = health.resolution, let quality = health.qualityLabel {
                        Text("\(quality) (\(Int(resolution.width))×\(Int(resolution.height)))")
                    }
                    if health.bitrateKbps > 0 {
                        Text(String(localized: "Débit : \(health.bitrateKbps >= 1000 ? String(format: "%.1f Mb/s", health.bitrateKbps / 1000) : String(format: "%.0f kb/s", health.bitrateKbps))"))
                    }
                    if health.framesPerSecond > 0 {
                        Text(String(format: String(localized: "Images : %.0f par seconde"), health.framesPerSecond))
                    }
                    if health.lostRatio > 0 {
                        Text(String(format: String(localized: "Images perdues : %.1f %%"), health.lostRatio * 100))
                    }
                    Text(health.recentStalls == 0 ? String(localized: "Aucune coupure dans la dernière minute")
                                                  : String(localized: "\(health.recentStalls) coupure(s) dans la dernière minute"))
                    if let issue = health.audioIssue { Text(issue).foregroundStyle(.orange) }
                    if let startup = playback.startupTime {
                        Text("Prête en \(String(format: "%.1f", startup)) s")
                    }
                }
                .font(.caption)
                .foregroundStyle(.white)
                .padding(12)
                .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 18).padding(.top, 62)
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: Gestes

    private var canZap: Bool {
        playback.isLive && !(playback.current?.isReplay ?? false)
    }

    private func showHUD(_ value: IOSPlayerHUD, hold: Double = 1.1) {
        hud = value
        hudTask?.cancel()
        hudTask = Task {
            try? await Task.sleep(for: .seconds(hold))
            if !Task.isCancelled { withAnimation { hud = nil } }
        }
    }

    private func doubleTap(x: CGFloat, width: CGFloat) {
        controlsVisible = false
        if x < width / 3 || x > width * 2 / 3 {
            guard !playback.isLive || playback.timeshiftSeekable else { return }
            let back = x < width / 3
            playback.jump(seconds: back ? -10 : 30)
            showHUD(IOSPlayerHUD(icon: back ? "gobackward.10" : "goforward.30", text: back ? "−10 s" : "+30 s"))
        } else {
            playback.togglePause()
            showHUD(IOSPlayerHUD(icon: playback.isPlaying ? "pause.fill" : "play.fill", text: ""))
        }
    }

    private func dragChanged(_ value: DragGesture.Value, size: CGSize) {
        let dx = value.translation.width
        let dy = value.translation.height
        if dragMode == nil {
            if abs(dx) > abs(dy) {
                if playback.isLive { dragMode = .zap } else if playback.duration > 0 { dragMode = .seek }
            } else {
                dragMode = value.startLocation.x < size.width / 2 ? .brightness : .volume
            }
            switch dragMode {
            case .volume: dragBase = playback.isMuted ? 0 : min(playback.volume, 100)
            case .brightness: dragBase = Double(UIScreen.main.brightness) * 100
            case .seek: dragBase = playback.position * playback.duration
            default: break
            }
        }
        guard let mode = dragMode else { return }
        switch mode {
        case .volume:
            let level = min(max(dragBase - Double(dy) / Double(size.height * 0.6) * 100, 0), 100)
            playback.volume = level
            playback.isMuted = level <= 0
            hud = IOSPlayerHUD(icon: level <= 0 ? "speaker.slash.fill" : "speaker.wave.2.fill", text: "\(Int(level)) %", value: level / 100)
        case .brightness:
            let level = min(max(dragBase - Double(dy) / Double(size.height * 0.6) * 100, 0), 100)
            UIScreen.main.brightness = CGFloat(level / 100)
            hud = IOSPlayerHUD(icon: "sun.max.fill", text: "\(Int(level)) %", value: level / 100)
        case .seek:
            let span = min(max(playback.duration / 1800, 0.5), 4)
            let target = min(max(dragBase + Double(dx) * span, 0), playback.duration)
            seekTarget = target
            let delta = Int(target - dragBase)
            hud = IOSPlayerHUD(icon: delta >= 0 ? "forward.fill" : "backward.fill",
                               text: "\(target.clockString)  (\(delta >= 0 ? "+" : "−")\(abs(delta)) s)")
        case .zap:
            hud = IOSPlayerHUD(icon: dx < 0 ? "chevron.right.2" : "chevron.left.2", text: String(localized: "Changer de chaîne"))
        }
    }

    private func dragEnded(_ value: DragGesture.Value) {
        defer { dragMode = nil; seekTarget = nil }
        let dx = value.translation.width
        switch dragMode {
        case .seek:
            if let target = seekTarget, playback.duration > 0 { playback.seek(to: target / playback.duration) }
        case .zap:
            if abs(dx) > 70 { zap(dx < 0 ? 1 : -1) }
        default:
            break
        }
        hudTask?.cancel()
        hudTask = Task {
            try? await Task.sleep(for: .seconds(0.8))
            if !Task.isCancelled { withAnimation { hud = nil } }
        }
    }

    private func zap(_ offset: Int) {
        guard let item = playback.current, item.kind == .live else { return }
        let list = ui.zapList(for: item, store: store)
        guard list.count > 1, let index = list.firstIndex(where: { $0.id == item.id }) else { return }
        let target = list[(index + offset + list.count) % list.count]
        ui.play(target, store: store, playback: playback)
        showHUD(IOSPlayerHUD(icon: "tv", text: TMDB.cleanTitle(target.name).title), hold: 1.6)
    }

    private func hudView(_ hud: IOSPlayerHUD) -> some View {
        VStack(spacing: 8) {
            Image(systemName: hud.icon).font(.system(size: 34, weight: .semibold))
            if !hud.text.isEmpty { Text(hud.text).font(.headline.monospacedDigit()) }
            if let value = hud.value {
                ProgressView(value: value).tint(.white).frame(width: 130)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 22).padding(.vertical, 16)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Options (vitesse, format, dernière chaîne, épisodes)

    private var optionsMenu: some View {
        Menu {
            if !playback.isLive {
                Picker("Vitesse de lecture", selection: $vodRate) {
                    ForEach([Float(0.5), 0.75, 1, 1.25, 1.5, 2], id: \.self) { speed in
                        Text(String(format: "%g×", Double(speed))).tag(speed)
                    }
                }
            }
            Picker("Format de l'image", selection: $aspect) {
                Text("Ajuster").tag("fit")
                Text("Remplir l'écran").tag("fill")
                Text("16:9").tag("16:9")
                Text("4:3").tag("4:3")
            }
            if canZap, let previous = ui.previousChannel {
                Button("Dernière chaîne : \(TMDB.cleanTitle(previous.name).title)", systemImage: "arrow.uturn.backward") {
                    ui.play(previous, store: store, playback: playback)
                }
            }
            if ui.episodeContext != nil, playback.current?.kind == .episode {
                Button("Épisodes…", systemImage: "list.bullet") { showEpisodes = true }
            }
        } label: {
            Image(systemName: "ellipsis.circle").font(.title3)
        }
        .onChange(of: vodRate) { _, speed in
            playback.player.rate = speed
            showHUD(IOSPlayerHUD(icon: "speedometer", text: String(format: "%g×", Double(speed))))
        }
        .onChange(of: aspect) { _, _ in applyAspect() }
    }

    /// Cadrage de l'image : ajuster (par défaut), remplir l'écran (recadrage), 16:9, 4:3.
    private func applyAspect() {
        let player = playback.player
        var ratio: String?
        var crop: String?
        switch aspect {
        case "fill":
            let bounds = UIScreen.main.bounds
            crop = "\(Int(max(bounds.width, bounds.height))):\(Int(min(bounds.width, bounds.height)))"
        case "16:9": ratio = "16:9"
        case "4:3": ratio = "4:3"
        default: break
        }
        if let ratio {
            ratio.withCString { player.videoAspectRatio = UnsafeMutablePointer(mutating: $0) }
        } else {
            player.videoAspectRatio = nil
        }
        if let crop {
            crop.withCString { player.videoCropGeometry = UnsafeMutablePointer(mutating: $0) }
        } else {
            player.videoCropGeometry = nil
        }
    }

    // MARK: Programme en cours

    private func programmeLine(_ channel: MediaItem) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            if let programme = store.epg.current(for: channel.epgID, at: context.date) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(programme.title) · \(programme.timeRange())")
                        .font(.caption).foregroundStyle(.white.opacity(0.9)).lineLimit(1)
                    ProgressView(value: programme.progress(at: context.date)).tint(IOSPalette.orange).frame(maxWidth: 240)
                    if let next = store.epg.upcoming(for: channel.epgID, after: programme.stop, limit: 1).first {
                        Text("Ensuite · \(next.start.formatted(date: .omitted, time: .shortened)) \(next.title)")
                            .font(.caption2).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                    }
                }
            }
        }
    }

    private func toggleControls() {
        controlsVisible.toggle()
        if controlsVisible { scheduleHide() }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        controlsVisible = true
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { controlsVisible = false }
        }
    }
}
