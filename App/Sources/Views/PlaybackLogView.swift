import SwiftUI
import AppKit
import Combine

/// Fenêtre « Journal » : messages de Kastideo et du moteur VLC classés par sujet (identifiants masqués).
struct PlaybackLogView: View {
    @State private var lines: [PlaybackLog.Line] = []
    @State private var previous: [PlaybackLog.Line] = []
    @State private var showPrevious = false
    @State private var topics: Set<LogTopic> = []
    @State private var search = ""
    @State private var errorsOnly = false
    @State private var copied = false
    @State private var detailTick = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            topicBar
            Divider()
            HStack(spacing: 10) {
                Picker("", selection: $showPrevious) {
                    Text("Session en cours").tag(false)
                    Text("Session précédente").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 270)
                TextField("Rechercher dans le journal", text: $search)
                    .textFieldStyle(.roundedBorder)
                Toggle("Erreurs et alertes", isOn: $errorsOnly)
                    .toggleStyle(.checkbox)
                detailMenu
                Spacer(minLength: 0)
                Button(copied ? String(localized: "Copié ✓") : String(localized: "Copier l'affichage")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(PlaybackLog.shared.exportText(filtered, filter: filterDescription), forType: .string)
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
                .disabled(showPrevious)
            }
            .padding(10)
            Divider()
            ScrollViewReader { proxy in
                List(filtered) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(line.date.formatted(date: showPrevious ? .abbreviated : .omitted, time: .standard))
                            .foregroundStyle(.secondary)
                        Text(line.levelLabel)
                            .foregroundStyle(color(line.level))
                            .frame(width: 52, alignment: .leading)
                        Text(line.topic.title)
                            .foregroundStyle(.tertiary)
                            .frame(width: 130, alignment: .leading)
                        Text(line.text)
                            .textSelection(.enabled)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .id(line.id)
                }
                .onChange(of: filtered.last?.id) { _, last in
                    if let last, !showPrevious { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
            Divider()
            HStack {
                Text("\(filtered.count) ligne(s) affichée(s) sur \(shown.count). Identifiants et mots de passe masqués : le journal peut être copié pour être partagé.")
                Spacer()
                Button("Afficher le dossier du journal") {
                    NSWorkspace.shared.activateFileViewerSelecting([PlaybackLog.currentFile])
                }
                .buttonStyle(.link)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(8)
        }
        .onAppear { refresh() }
        .onReceive(timer) { _ in if !showPrevious { lines = PlaybackLog.shared.snapshot() } }
        .onChange(of: showPrevious) { _, _ in refresh() }
    }

    // MARK: - Barre des sujets

    private var topicBar: some View {
        let counts = Dictionary(grouping: shown, by: \.topic).mapValues(\.count)
        return HStack(spacing: 6) {
            Text("Sujets").font(.caption).foregroundStyle(.secondary)
            ForEach(LogTopic.allCases) { topic in
                let on = topics.contains(topic)
                Button {
                    if on { topics.remove(topic) } else { topics.insert(topic) }
                } label: {
                    Text("\(topic.title) \(counts[topic] ?? 0)")
                        .font(.caption)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(on ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
                        .foregroundStyle(on ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
            if !topics.isEmpty {
                Button("Tous") { topics = [] }.buttonStyle(.link).font(.caption)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    /// Niveau de détail enregistré par sujet : s'applique aux lignes écrites à partir de maintenant.
    private var detailMenu: some View {
        Menu("Niveau de détail") {
            ForEach(LogTopic.allCases) { topic in
                Picker(topic.title, selection: Binding(
                    get: { _ = detailTick; return PlaybackLog.detail(for: topic) },
                    set: { PlaybackLog.setDetail($0, for: topic); detailTick += 1 }
                )) {
                    ForEach(LogDetail.allCases) { Text($0.title).tag($0) }
                }
            }
            Divider()
            Text("« Débogage » écrit davantage de lignes : à réserver à la recherche d'un problème.")
        }
        .fixedSize()
    }

    // MARK: - Filtrage

    private var shown: [PlaybackLog.Line] { showPrevious ? previous : lines }

    private var filtered: [PlaybackLog.Line] {
        let needle = search.trimmingCharacters(in: .whitespaces)
        return shown.filter { line in
            (topics.isEmpty || topics.contains(line.topic))
                && (!errorsOnly || line.level <= 1)
                && (needle.isEmpty || line.text.localizedCaseInsensitiveContains(needle))
        }
    }

    private var filterDescription: String {
        var parts: [String] = []
        parts.append(showPrevious ? "session précédente" : "session en cours")
        if !topics.isEmpty { parts.append("sujets : " + LogTopic.allCases.filter(topics.contains).map(\.title).joined(separator: ", ")) }
        if errorsOnly { parts.append("erreurs et alertes") }
        if !search.isEmpty { parts.append("recherche « \(search) »") }
        return parts.joined(separator: " · ")
    }

    private func refresh() {
        if showPrevious { previous = PlaybackLog.previousSession() } else { lines = PlaybackLog.shared.snapshot() }
    }

    private func color(_ level: Int) -> Color {
        switch level {
        case 0: return .red
        case 1: return .orange
        default: return .secondary
        }
    }
}
