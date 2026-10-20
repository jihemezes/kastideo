import SwiftUI
import AppKit
import UniformTypeIdentifiers
import KastideoCore

/// Section « Enregistrements » : en cours, conversions, téléchargements, programmés et fichiers enregistrés.
struct RecordingsListView: View {
    @Environment(RecordingCenter.self) private var recordings
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        @Bindable var navigation = navigation
        List(selection: $navigation.selectedItemID) {
            if let live = recordings.activeLive {
                Section("Enregistrement en cours") {
                    LiveRecordingRow(live: live)
                        .selectionDisabled()
                }
            }
            if !recordings.converting.isEmpty {
                Section("Conversion en MP4") {
                    ForEach(recordings.converting, id: \.self) { name in
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(name).lineLimit(1)
                        }
                        .selectionDisabled()
                    }
                }
            }
            if !recordings.downloads.isEmpty {
                Section("Téléchargements") {
                    ForEach(recordings.downloads) { entry in
                        DownloadRow(entry: entry)
                            .selectionDisabled()
                    }
                }
            }
            if !recordings.schedules.isEmpty {
                Section("Programmés") {
                    ForEach(recordings.schedules) { recording in
                        ScheduleRow(recording: recording)
                            .selectionDisabled()
                    }
                }
            }
            Section("Enregistrés (\(recordings.files.count))") {
                if recordings.files.isEmpty {
                    Text("Aucun enregistrement pour le moment. Utilisez ● pendant la lecture, le guide TV, ou le clic droit sur une chaîne, un film ou un épisode.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .selectionDisabled()
                } else {
                    ForEach(recordings.files) { file in
                        FileRow(file: file)
                            .contextMenu {
                                Button("Afficher dans le Finder") { recordings.reveal(file) }
                                Divider()
                                Button("Placer dans la corbeille", role: .destructive) { recordings.deleteFile(file) }
                            }
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Enregistrements")
        .toolbar {
            ToolbarItem {
                Button {
                    recordings.reveal()
                } label: {
                    Label("Ouvrir le dossier", systemImage: "folder")
                }
                .help("Ouvrir le dossier des enregistrements dans le Finder")
            }
        }
        .onAppear { recordings.refreshFiles() }
    }
}

struct LiveRecordingRow: View {
    @Environment(RecordingCenter.self) private var recordings
    let live: RecordingCenter.ActiveLive

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "record.circle.fill").foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text(live.title).lineLimit(1)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(detail(at: context.date))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Arrêter") { recordings.stopLive() }
        }
    }

    private func detail(at date: Date) -> String {
        var text = "\(live.item.name) — \(date.timeIntervalSince(live.startedAt).clockString)"
        if let end = live.endsAt { text += " · fin à \(end.formatted(date: .omitted, time: .shortened))" }
        text += live.mode == .player ? " · pendant la lecture" : " · en arrière-plan"
        return text
    }
}

struct DownloadRow: View {
    @Environment(RecordingCenter.self) private var recordings
    let entry: DownloadItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(entry.state == .failed ? .orange : .secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.fileName).lineLimit(1)
                if entry.state == .downloading || entry.received > 0 {
                    ProgressView(value: entry.progress)
                        .progressViewStyle(.linear)
                        .controlSize(.small)
                }
                Text(status)
                    .font(.caption)
                    .foregroundStyle(entry.state == .failed ? .orange : .secondary)
                    .lineLimit(2)
            }
            Spacer()
            switch entry.state {
            case .downloading:
                Button { recordings.pauseDownload(entry.id) } label: { Image(systemName: "pause.fill") }
                    .buttonStyle(.borderless).help("Mettre en pause")
            case .queued, .paused, .failed:
                Button { recordings.resumeDownload(entry.id, now: true) } label: { Image(systemName: "play.fill") }
                    .buttonStyle(.borderless).help("Télécharger maintenant")
            }
            Button { recordings.cancelDownload(entry.id) } label: { Image(systemName: "xmark") }
                .buttonStyle(.borderless).help("Annuler")
        }
    }

    private var icon: String {
        switch entry.state {
        case .downloading: return "arrow.down.circle"
        case .queued: return entry.startAfter.map { $0 > Date() } == true ? "moon.zzz" : "clock"
        case .paused: return "pause.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }

    private var status: String {
        let size: String = {
            guard entry.expected > 0 else { return ByteCountFormatter.string(fromByteCount: entry.received, countStyle: .file) }
            return "\(ByteCountFormatter.string(fromByteCount: entry.received, countStyle: .file)) sur \(ByteCountFormatter.string(fromByteCount: entry.expected, countStyle: .file))"
        }()
        switch entry.state {
        case .downloading:
            var text = "\(size) — \(Int(entry.progress * 100)) %"
            if let status = recordings.downloadStatus, status.current.id == entry.id {
                text += " · \(DownloadFormat.speed(status.speed))"
                if let eta = status.eta { text += " · reste \(DownloadFormat.remaining(eta))" }
                if let batch = status.batch { text += " · épisode \(batch.position)/\(batch.total)" }
            }
            return text
        case .queued:
            if let start = entry.startAfter, start > Date() {
                return "Programmé : \(start.formatted(date: .abbreviated, time: .shortened))"
            }
            return "En attente (connexion libre requise : aucune lecture ni enregistrement en cours)"
        case .paused:
            return entry.pausedByUser ? "En pause — \(size)" : "Suspendu pendant la lecture — reprendra automatiquement"
        case .failed:
            return entry.error ?? "Échec"
        }
    }
}

struct ScheduleRow: View {
    @Environment(RecordingCenter.self) private var recordings
    let recording: ScheduledRecording

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock").foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(recording.title).lineLimit(1)
                Text("\(recording.item.name) — \(recording.start.formatted(date: .abbreviated, time: .shortened)) → \(recording.end.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { recordings.removeSchedule(recording.id) } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless).help("Supprimer la programmation")
        }
    }
}

struct FileRow: View {
    let file: RecordingFile

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: file.url.pathExtension.lowercased() == "ts" ? "film" : "play.rectangle")
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name).lineLimit(2)
                Text("\(file.date.formatted(date: .abbreviated, time: .shortened)) — \(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file)) — .\(file.url.pathExtension)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Programmation manuelle d'un enregistrement (choix d'un programme du guide ou d'horaires libres).
struct ScheduleRecordingSheet: View {
    @Environment(LibraryStore.self) private var store
    @Environment(RecordingCenter.self) private var recordings
    @Environment(\.dismiss) private var dismiss
    let item: MediaItem

    @State private var title = ""
    @State private var start = Date().addingTimeInterval(300)
    @State private var end = Date().addingTimeInterval(300 + 3600)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                LogoView(url: item.logoURL, name: item.name, size: 44)
                VStack(alignment: .leading) {
                    Text("Programmer un enregistrement").font(.headline)
                    Text(item.name).foregroundStyle(.secondary)
                }
            }
            .padding(16)

            Form {
                let upcoming = store.epg.upcoming(for: item.epgID, after: Date(), limit: 8)
                if !upcoming.isEmpty {
                    Section("Choisir un programme du guide") {
                        ForEach(upcoming) { programme in
                            Button {
                                recordings.schedule(item, programme: programme)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(programme.start.formatted(date: .omitted, time: .shortened))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                    Text(programme.title).lineLimit(1)
                                    Spacer()
                                    if recordings.isScheduled(item, programme) {
                                        Image(systemName: "record.circle").foregroundStyle(.red)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("Ou des horaires libres") {
                    TextField("Titre", text: $title, prompt: Text(item.name))
                    DatePicker("Début", selection: $start, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Fin", selection: $end, in: start..., displayedComponents: [.date, .hourAndMinute])
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Text("Kastideo doit rester ouvert et le Mac allumé à l'heure de l'enregistrement.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Annuler", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Programmer") {
                    let name = title.trimmingCharacters(in: .whitespaces)
                    recordings.schedule(item, title: name.isEmpty ? item.name : name, start: start, end: end)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(end <= start || end <= Date())
            }
            .padding(16)
        }
        .frame(width: 520, height: 560)
    }
}

/// Réglages > Enregistrements.
struct RecordingSettingsView: View {
    @Environment(RecordingCenter.self) private var recordings
    @AppStorage(RecordingKeys.marginBefore) private var marginBefore = 2
    @AppStorage(RecordingKeys.marginAfter) private var marginAfter = 5
    @AppStorage(RecordingKeys.nightHour) private var nightHour = 2
    @AppStorage(RecordingKeys.convertMP4) private var convertMP4 = true
    @AppStorage(RecordingKeys.autoClean) private var autoClean = false
    @AppStorage(RecordingKeys.autoCleanDays) private var autoCleanDays = 30
    @AppStorage(RecordingKeys.notifications) private var notifications = true
    @State private var showPicker = false
    @State private var folderPath = ""

    var body: some View {
        Form {
            Section("Dossier") {
                LabeledContent("Emplacement") {
                    Text(folderPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Button("Choisir…") { showPicker = true }
                    Button("Afficher dans le Finder") { recordings.reveal() }
                    if RecordingFolder.isCustom {
                        Button("Revenir à ~/Movies/Kastideo") {
                            recordings.resetFolder()
                            folderPath = RecordingFolder.current.path
                        }
                    }
                }
            }
            Section("Enregistrement du direct") {
                Stepper("Marge avant le programme : \(marginBefore) min", value: $marginBefore, in: 0...30)
                Stepper("Marge après le programme : \(marginAfter) min", value: $marginAfter, in: 0...60)
                Toggle("Convertir en MP4 (sans perte de qualité, lisible par QuickTime et l'iPhone)", isOn: $convertMP4)
            }
            Section("Téléchargements") {
                Picker("« Cette nuit » commence à", selection: $nightHour) {
                    ForEach(0..<7, id: \.self) { hour in Text("\(hour) h").tag(hour) }
                }
            }
            Section("Nettoyage automatique") {
                Toggle("Placer les anciens enregistrements dans la corbeille", isOn: $autoClean)
                Stepper("Après \(autoCleanDays) jours", value: $autoCleanDays, in: 1...365)
                    .disabled(!autoClean)
            }
            Section("Notifications") {
                Toggle("Notifier les débuts et fins d'enregistrement et de téléchargement", isOn: $notifications)
            }
            Section {
                Text("Votre abonnement n'autorisant qu'une connexion, Kastideo enregistre ou télécharge une seule chose à la fois et vous demande avant d'interrompre une lecture. Pour les enregistrements programmés et les téléchargements de nuit, Kastideo doit rester ouvert et le Mac allumé (la mise en veille automatique est bloquée pendant l'activité).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { folderPath = RecordingFolder.current.path }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                recordings.chooseFolder(url)
                folderPath = RecordingFolder.current.path
            }
        }
    }
}

/// Pastille « ● REC 00:12:34 » affichée sur la vidéo pendant un enregistrement.
struct RecordingBadge: View {
    let live: RecordingCenter.ActiveLive

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 6) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("REC \(context.date.timeIntervalSince(live.startedAt).clockString)")
                    .font(.caption.weight(.bold).monospacedDigit())
                Text(live.title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.black.opacity(0.6), in: Capsule())
            .frame(maxWidth: 320, alignment: .leading)
        }
    }
}
