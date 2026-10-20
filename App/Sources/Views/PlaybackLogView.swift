import SwiftUI
import AppKit
import Combine

/// Fenêtre « Journal de lecture » : messages du moteur VLC pour le diagnostic (identifiants masqués).
struct PlaybackLogView: View {
    @State private var lines: [PlaybackLog.Line] = []
    @State private var errorsOnly = false
    @State private var copied = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("Erreurs et alertes seulement", isOn: $errorsOnly)
                    .toggleStyle(.checkbox)
                Spacer()
                Button(copied ? String(localized: "Copié ✓") : String(localized: "Copier le journal")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(PlaybackLog.shared.exportText(), forType: .string)
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copied = false
                    }
                }
                Button("Effacer") {
                    PlaybackLog.shared.clear()
                    lines = []
                }
            }
            .padding(10)
            Divider()
            ScrollViewReader { proxy in
                List(filtered) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(line.date.formatted(date: .omitted, time: .standard))
                            .foregroundStyle(.secondary)
                        Text(line.levelLabel)
                            .foregroundStyle(color(line.level))
                            .frame(width: 52, alignment: .leading)
                        Text(line.text)
                            .textSelection(.enabled)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .id(line.id)
                }
                .onChange(of: lines.last?.id) { _, last in
                    if let last { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
            Divider()
            Text("Les identifiants et mots de passe sont masqués : vous pouvez copier ce journal pour le partager.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
        }
        .onAppear { lines = PlaybackLog.shared.snapshot() }
        .onReceive(timer) { _ in lines = PlaybackLog.shared.snapshot() }
    }

    private var filtered: [PlaybackLog.Line] {
        errorsOnly ? lines.filter { $0.level <= 1 } : lines
    }

    private func color(_ level: Int) -> Color {
        switch level {
        case 0: return .red
        case 1: return .orange
        default: return .secondary
        }
    }
}
