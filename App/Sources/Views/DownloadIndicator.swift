import SwiftUI
import KastideoCore

/// Formats lisibles pour les tailles, vitesses et durées restantes.
enum DownloadFormat {
    static func bytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }

    static func speed(_ bytesPerSecond: Double) -> String {
        guard bytesPerSecond > 1 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytesPerSecond), countStyle: .file) + "/s"
    }

    /// « moins d'une minute », « 12 min », « 1 h 05 ».
    static func remaining(_ seconds: TimeInterval?) -> String {
        guard let seconds, seconds.isFinite else { return String(localized: "calcul en cours…") }
        let minutes = Int((seconds / 60).rounded(.up))
        if minutes < 1 { return String(localized: "moins d'une minute") }
        if minutes < 60 { return String(localized: "\(minutes) min") }
        return String(format: "%d h %02d", minutes / 60, minutes % 60)
    }

    /// Version courte pour la barre d'outils : « 12 min », « 1 h 05 ».
    static func compactRemaining(_ seconds: TimeInterval?) -> String? {
        guard let seconds, seconds.isFinite else { return nil }
        let minutes = Int((seconds / 60).rounded(.up))
        if minutes < 1 { return String(localized: "< 1 min") }
        if minutes < 60 { return String(localized: "\(minutes) min") }
        return String(format: "%d h %02d", minutes / 60, minutes % 60)
    }
}

/// Anneau d'avancement.
struct ProgressRing: View {
    let progress: Double
    var paused = false
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 3)
            Circle()
                .trim(from: 0, to: max(min(progress, 1), 0.02))
                .stroke(paused ? Color.orange : Color.accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if paused {
                Image(systemName: "pause.fill")
                    .font(.system(size: size * 0.38))
                    .foregroundStyle(.orange)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Indicateur de téléchargement toujours visible dans la barre d'outils tant qu'un film ou un épisode se télécharge.
struct DownloadIndicator: View {
    @Environment(RecordingCenter.self) private var recordings
    @State private var showDetails = false

    var body: some View {
        if let status = recordings.downloadStatus {
            Button {
                showDetails.toggle()
            } label: {
                HStack(spacing: 7) {
                    ProgressRing(progress: status.batch?.progress ?? status.current.progress,
                                 paused: !status.isActive)
                    Text(summary(status))
                        .font(.caption.weight(.medium).monospacedDigit())
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
            }
            .help(helpText(status))
            .popover(isPresented: $showDetails, arrowEdge: .bottom) {
                DownloadDetails(status: status, close: { showDetails = false })
            }
        }
    }

    /// Texte court : « Ép. 3/10 · 42 % · 1 h 12 », « 42 % · 4 min ».
    private func summary(_ status: DownloadStatus) -> String {
        guard status.isActive else { return String(localized: "En pause") }
        var parts: [String] = []
        if let batch = status.batch { parts.append(String(localized: "Ép. \(batch.position)/\(batch.total)")) }
        parts.append("\(Int(status.current.progress * 100)) %")
        if let remaining = DownloadFormat.compactRemaining(status.batch?.eta ?? status.eta) { parts.append(remaining) }
        return parts.joined(separator: " · ")
    }

    private func helpText(_ status: DownloadStatus) -> String {
        if !status.isActive { return String(localized: "Téléchargement suspendu pendant la lecture : il reprendra automatiquement.") }
        return String(localized: "Téléchargement en cours — cliquez pour le détail")
    }
}

/// Détail du téléchargement : fichier en cours, position dans la série, temps restant.
struct DownloadDetails: View {
    @Environment(RecordingCenter.self) private var recordings
    @Environment(NavigationModel.self) private var navigation
    let status: DownloadStatus
    let close: () -> Void

    var body: some View {
        let current = status.current
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: status.isActive ? "arrow.down.circle.fill" : "pause.circle.fill")
                    .foregroundStyle(status.isActive ? Color.accentColor : .orange)
                Text(status.isActive ? String(localized: "Téléchargement en cours") : String(localized: "Téléchargement suspendu"))
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title(for: current)).font(.callout.weight(.semibold)).lineLimit(2)
                ProgressView(value: current.progress)
                    .progressViewStyle(.linear)
                HStack {
                    Text(sizeText(current))
                    Spacer()
                    Text("\(Int(current.progress * 100)) %").monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if status.isActive {
                    Label("Reste environ \(DownloadFormat.remaining(status.eta)) · \(DownloadFormat.speed(status.speed))",
                          systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let batch = status.batch {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(batch.title) — épisode \(batch.position) sur \(batch.total)")
                        .font(.callout.weight(.semibold))
                        .lineLimit(2)
                    ProgressView(value: batch.progress)
                        .progressViewStyle(.linear)
                    HStack {
                        Text("Terminés : \(max(batch.position - 1, 0)) sur \(batch.total)")
                        Spacer()
                        Text("\(Int(batch.progress * 100)) %").monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if status.isActive {
                        Label("Reste environ \(DownloadFormat.remaining(batch.eta)) pour tout le lot",
                              systemImage: "hourglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !status.isActive {
                Text("Votre abonnement n'autorise qu'une connexion : le téléchargement reprendra automatiquement quand la lecture ou l'enregistrement se terminera.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if status.othersQueued > 0 {
                Text("+ \(status.othersQueued) en attente")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if status.isActive {
                    Button { recordings.pauseDownload(current.id) } label: { Label("Pause", systemImage: "pause.fill") }
                } else {
                    Button { recordings.resumeDownload(current.id, now: true) } label: { Label("Reprendre", systemImage: "play.fill") }
                }
                Spacer()
                Button("Enregistrements") {
                    navigation.go(.recordings)
                    close()
                }
            }
        }
        .padding(16)
        .frame(width: 360)
    }

    private func title(for item: DownloadItem) -> String {
        let media = item.item
        if media.kind == .episode {
            let number = media.number.map { String(format: "É%02d · ", $0) } ?? ""
            return "\(media.group) — \(number)\(media.name)"
        }
        return media.name
    }

    private func sizeText(_ item: DownloadItem) -> String {
        guard item.expected > 0 else { return DownloadFormat.bytes(item.received) }
        return String(localized: "\(DownloadFormat.bytes(item.received)) sur \(DownloadFormat.bytes(item.expected))")
    }
}
