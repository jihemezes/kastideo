import SwiftUI

/// Journal de lecture sur Apple TV : dernières lignes du moteur VLC et de l'application (identifiants masqués),
/// pour comprendre un échec (replay, chaîne qui ne démarre pas…).
struct TVLogView: View {
    @State private var lines: [PlaybackLog.Line] = []
    @State private var playbackOnly = true

    private var shown: [PlaybackLog.Line] {
        let filtered = playbackOnly ? lines.filter { $0.topic == .playback } : lines
        return Array(filtered.suffix(120).reversed())
    }

    var body: some View {
        List {
            Toggle("Lecture et relais seulement", isOn: $playbackOnly)
            Button("Actualiser") { reload() }
            Button("Effacer le journal", role: .destructive) { PlaybackLog.shared.clear(); reload() }
            if shown.isEmpty {
                Text("Aucune ligne.").foregroundStyle(.secondary)
            }
            ForEach(shown) { line in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(line.date.formatted(date: .omitted, time: .standard)) · \(line.levelLabel)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(line.level == 0 ? Color.red : (line.level == 1 ? Color.orange : Color.secondary))
                    Text(line.text).font(.callout)
                }
                .focusable()
            }
        }
        .navigationTitle("Journal de lecture")
        .onAppear { reload() }
    }

    private func reload() { lines = PlaybackLog.shared.snapshot() }
}
