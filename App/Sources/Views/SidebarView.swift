import SwiftUI
import KastideoCore

struct SidebarView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(RecordingCenter.self) private var recordings
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation
        List(selection: $navigation.browse) {
            Section("Bibliothèque") {
                row(.all(.live), icon: "dot.radiowaves.left.and.right", count: store.count(for: .live))
                row(.all(.movie), icon: "film", count: store.count(for: .movie))
                row(.all(.series), icon: "rectangle.stack", count: store.count(for: .series))
                row(.favorites, icon: "star", count: store.favoriteIDs.count)
                row(.recents, icon: "clock.arrow.circlepath", count: nil)
                row(.recordings, icon: recordings.activeLive != nil ? "record.circle.fill" : "record.circle",
                    count: recordings.activityCount)
            }

            let kind = navigation.lastKind
            let categories = store.categoriesByKind[kind] ?? []
            if !categories.isEmpty {
                Section("Catégories — \(kind.label)") {
                    ForEach(categories, id: \.self) { name in
                        Label(name, systemImage: "folder")
                            .lineLimit(1)
                            .tag(Browse.category(kind, name))
                    }
                }
            }

            Section("Sources") {
                ForEach(store.sources) { source in
                    SourceStatusRow(source: source)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func row(_ browse: Browse, icon: String, count: Int?) -> some View {
        HStack {
            Label(browse.title, systemImage: icon)
            Spacer()
            if let count, count > 0 {
                Text(count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .tag(browse)
    }
}

/// Ligne d'état d'une source dans la barre latérale (non sélectionnable).
struct SourceStatusRow: View {
    @Environment(LibraryStore.self) private var store
    let source: Source

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(source.name)
                .lineLimit(1)
                .foregroundStyle(source.isEnabled ? .primary : .secondary)
            Spacer()
            if store.loading.contains(source.id) {
                ProgressView().controlSize(.mini)
            }
        }
        .help(helpText)
        .selectionDisabled()
    }

    private var icon: String {
        if store.errors[source.id] != nil { return "exclamationmark.triangle.fill" }
        if !source.isEnabled { return "pause.circle" }
        switch source.kind {
        case .xtream: return "server.rack"
        case .m3uURL: return "link"
        case .m3uFile: return "doc.text"
        }
    }

    private var color: Color {
        if store.errors[source.id] != nil { return .orange }
        return .secondary
    }

    private var helpText: String {
        if let error = store.errors[source.id] { return error }
        let count = store.contents[source.id]?.items.count ?? 0
        return "\(source.kind.typeLabel) — \(count) éléments"
    }
}
