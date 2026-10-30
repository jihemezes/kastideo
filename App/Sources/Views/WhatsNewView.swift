import SwiftUI
import AppKit

/// Nouveautés de la version installée (affiché après une mise à jour, ou depuis le menu Aide).
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notes: [ReleaseNote] = []
    @State private var showHistory = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nouveautés de Kastideo")
                        .font(.title2.weight(.bold))
                    Text("Version \(ReleaseNotes.currentVersion)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let current {
                        noteSection(current, highlighted: true)
                    } else {
                        Text("Aucune note pour cette version.")
                            .foregroundStyle(.secondary)
                    }
                    if !older.isEmpty {
                        DisclosureGroup("Versions précédentes", isExpanded: $showHistory) {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(older) { note in noteSection(note, highlighted: false) }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
            HStack {
                SupportButton()
                Spacer()
                Button("Continuer") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
            }
            .padding(16)
        }
        .frame(width: 560, height: 520)
        .onAppear { notes = ReleaseNotes.load() }
    }

    private var current: ReleaseNote? {
        notes.first { $0.version == ReleaseNotes.currentVersion } ?? notes.first
    }

    private var older: [ReleaseNote] {
        notes.filter { $0.version != current?.version }
    }

    private func noteSection(_ note: ReleaseNote, highlighted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.version).font(highlighted ? .headline : .subheadline.weight(.semibold))
                if let date = note.date {
                    Text(date).font(.caption).foregroundStyle(.secondary)
                }
            }
            ForEach(note.items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: highlighted ? "sparkles" : "circle.fill")
                        .font(highlighted ? .caption : .system(size: 4))
                        .foregroundStyle(Color.accentColor)
                    Text((try? AttributedString(markdown: item)) ?? AttributedString(item))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
