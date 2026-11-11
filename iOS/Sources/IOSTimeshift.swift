import SwiftUI
import KastideoCore

/// Ligne de temps du direct en différé : glisser vers la droite pour rattraper le direct (tout à droite).
struct IOSTimeshiftBar: View {
    @Environment(PlaybackController.self) private var playback
    @State private var dragFraction: Double?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let delay = playback.delay(at: context.date)
            let total = max(playback.peakDelay, delay, 1)
            let current = (total - delay) / total
            GeometryReader { geo in
                let width = max(geo.size.width, 1)
                let shown = dragFraction ?? current
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.22)).frame(height: 5)
                    Capsule().fill(Color.white.opacity(playback.timeshiftSeekable ? 0.45 : 0.12))
                        .frame(width: width * CGFloat(current), height: 5)
                    if let target = playback.catchUpTarget {
                        Rectangle().fill(Color.yellow)
                            .frame(width: 2, height: 14)
                            .offset(x: width * CGFloat((total - target) / total) - 1)
                    }
                    Circle().fill(Color.yellow)
                        .frame(width: 16, height: 16)
                        .offset(x: width * CGFloat(min(max(shown, 0), 1)) - 8)
                }
                .frame(maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    if let dragFraction {
                        Text(Self.label(total * (1 - dragFraction)))
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.black.opacity(0.75), in: Capsule())
                            .fixedSize()
                            .offset(x: min(max(width * CGFloat(dragFraction) - 26, 0), width - 60), y: -18)
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = Double(min(max(value.location.x / width, 0), 1))
                        dragFraction = playback.timeshiftSeekable ? fraction : max(fraction, current)
                    }
                    .onEnded { _ in
                        if let fraction = dragFraction {
                            playback.catchUp(toDelay: total * (1 - fraction))
                        }
                        dragFraction = nil
                    })
            }
        }
    }

    static func label(_ delay: TimeInterval) -> String {
        delay < 1 ? String(localized: "Direct") : "−" + delay.clockString
    }
}

/// Réglages du différé (Réglages > Lecture).
struct IOSTimeshiftSection: View {
    @AppStorage(PlaybackKeys.timeshiftMax) private var maxMinutes = 120
    @AppStorage(PlaybackKeys.catchUpSpeed) private var speed = 1.5

    var body: some View {
        Section {
            Picker("Durée maximale du différé", selection: $maxMinutes) {
                Text("30 min").tag(30)
                Text("1 h").tag(60)
                Text("2 h").tag(120)
                Text("3 h").tag(180)
                Text("Sans limite").tag(0)
            }
            Picker("Vitesse pour rattraper le direct", selection: $speed) {
                Text("×1,25").tag(1.25)
                Text("×1,5").tag(1.5)
                Text("×2").tag(2.0)
            }
        } header: {
            Text("Direct en différé")
        } footer: {
            Text("Mettez le direct en pause : il continue d'être mémorisé (dans le stockage temporaire de l'application) et vous reprenez là où vous l'avez quitté. Le bouton « Retour au direct » le rattrape.")
        }
    }
}
