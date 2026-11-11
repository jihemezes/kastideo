import SwiftUI
import KastideoCore

/// Fichier enregistré ou téléchargé, présent dans le dossier de l'application.
struct IOSLocalFile: Identifiable, Hashable {
    let url: URL
    let size: Int64
    let date: Date
    var id: String { url.path }
    var name: String { url.deletingPathExtension().lastPathComponent }

    static func scan(_ folder: URL) -> [IOSLocalFile] {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys,
                                                                      options: [.skipsHiddenFiles]) else { return [] }
        return urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else { return nil }
            return IOSLocalFile(url: url, size: Int64(values.fileSize ?? 0), date: values.contentModificationDate ?? .distantPast)
        }
        .sorted { $0.date > $1.date }
    }
}

extension Int64 {
    var byteText: String { ByteCountFormatter.string(fromByteCount: self, countStyle: .file) }
}

/// Enregistrements du direct et films téléchargés : lecture, partage, suppression.
struct IOSRecordingsView: View {
    @Environment(IOSRecorder.self) private var recorder
    @Environment(IOSDownloads.self) private var downloads
    @Environment(PlaybackController.self) private var playback
    @Environment(IOSUI.self) private var ui
    @State private var recordings: [IOSLocalFile] = []
    @State private var downloaded: [IOSLocalFile] = []
    @AppStorage("ios.record.minutes") private var recordMinutes = 0

    var body: some View {
        List {
            if recorder.isRecording || !downloads.jobs.isEmpty {
                Section("En cours") {
                    if recorder.isRecording, let started = recorder.startedAt {
                        HStack {
                            Image(systemName: "record.circle.fill").foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recorder.channelName).font(.body.weight(.medium))
                                TimelineView(.periodic(from: .now, by: 1)) { context in
                                    Text("Enregistrement · \(context.date.timeIntervalSince(started).clockString)")
                                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Arrêter") { recorder.stop(playback: playback) }
                                .buttonStyle(.bordered).tint(.red)
                        }
                    }
                    ForEach(downloads.jobs) { job in
                        IOSDownloadRow(job: job)
                    }
                }
            }
            if let message = recorder.message {
                Section { Text(message).font(.footnote).foregroundStyle(.secondary) }
            }

            Section {
                if recordings.isEmpty {
                    Text("Aucun enregistrement. Pendant un direct, touchez le bouton rond rouge du lecteur.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(recordings) { file in row(file) }
            } header: {
                Text("Enregistrements")
            }

            Section {
                if downloaded.isEmpty {
                    Text("Aucun téléchargement. Ouvrez la fiche d'un film ou d'un épisode et touchez « Télécharger ».")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(downloaded) { file in row(file) }
            } header: {
                Text("Téléchargements")
            } footer: {
                Text("Les fichiers sont dans l'app Fichiers, dossier Kastideo. Votre fournisseur n'autorise souvent qu'une connexion à la fois : un téléchargement peut interrompre une lecture en cours.")
            }

            Section("Durée par défaut d'un enregistrement") {
                Picker("Arrêt automatique", selection: $recordMinutes) {
                    Text("Sans limite").tag(0)
                    Text("30 min").tag(30)
                    Text("1 h").tag(60)
                    Text("2 h").tag(120)
                    Text("3 h").tag(180)
                }
            }

            Section {
                Button {
                    if let url = URL(string: "shareddocuments://" + IOSFiles.root.path) { UIApplication.shared.open(url) }
                } label: { Label("Ouvrir dans Fichiers", systemImage: "folder") }
            }
        }
        .navigationTitle("Enregistrements")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
        .onChange(of: downloads.filesVersion) { _, _ in reload() }
        .onChange(of: recorder.isRecording) { _, _ in reload() }
        .onChange(of: recorder.message) { _, _ in reload() }
        .refreshable { reload() }
    }

    private func row(_ file: IOSLocalFile) -> some View {
        Button {
            ui.showPlayer = true
            playback.play(IOSFiles.mediaItem(for: file.url, name: file.name))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill").font(.title2).foregroundStyle(IOSPalette.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name).font(.body).lineLimit(2).multilineTextAlignment(.leading)
                    Text("\(file.size.byteText) · \(file.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .swipeActions {
            Button(role: .destructive) { delete(file) } label: { Label("Supprimer", systemImage: "trash") }
            ShareLink(item: file.url) { Label("Partager", systemImage: "square.and.arrow.up") }.tint(.blue)
        }
    }

    private func delete(_ file: IOSLocalFile) {
        try? FileManager.default.removeItem(at: file.url)
        reload()
    }

    private func reload() {
        recordings = IOSLocalFile.scan(IOSFiles.recordings)
        downloaded = IOSLocalFile.scan(IOSFiles.downloads)
    }
}

struct IOSDownloadRow: View {
    let job: IOSDownloadJob
    @Environment(IOSDownloads.self) private var downloads

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "arrow.down.circle.fill").foregroundStyle(IOSPalette.orange)
                Text(job.name).font(.body.weight(.medium)).lineLimit(1)
                Spacer()
                switch job.state {
                case .running:
                    Button { downloads.pause(job.id) } label: { Image(systemName: "pause.fill") }.buttonStyle(.borderless)
                case .paused, .failed:
                    Button { downloads.resume(job.id) } label: { Image(systemName: "play.fill") }.buttonStyle(.borderless)
                case .queued:
                    EmptyView()
                }
                Button(role: .destructive) { downloads.cancel(job.id) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.borderless)
            }
            if job.state == .failed, let error = job.error {
                Text(error).font(.caption).foregroundStyle(.red)
            } else {
                ProgressView(value: job.progress).tint(IOSPalette.orange)
                Text(job.expected > 0 ? "\(job.received.byteText) / \(job.expected.byteText)" : job.received.byteText)
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                if job.state == .paused { Text("En pause").font(.caption).foregroundStyle(.secondary) }
                if job.state == .queued { Text("En attente : un seul téléchargement à la fois").font(.caption).foregroundStyle(.secondary) }
            }
        }
        .padding(.vertical, 2)
    }
}

/// Bouton de la barre : enregistrements et téléchargements (pastille rouge pendant un enregistrement).
struct IOSRecordingsLink: View {
    @Environment(IOSRecorder.self) private var recorder
    @Environment(IOSDownloads.self) private var downloads

    var body: some View {
        NavigationLink {
            IOSRecordingsView()
        } label: {
            Image(systemName: recorder.isRecording ? "record.circle.fill" : (downloads.jobs.isEmpty ? "tray.full" : "arrow.down.circle"))
                .foregroundStyle(recorder.isRecording ? Color.red : Color.accentColor)
        }
    }
}
