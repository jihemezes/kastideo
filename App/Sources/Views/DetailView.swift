import SwiftUI
import KastideoCore

/// Colonne de droite : lecteur ou fiche de série.
struct DetailView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(NavigationModel.self) private var navigation
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings

    var body: some View {
        if let id = navigation.selectedItemID, let item = store.item(id: id) ?? recordings.fileItem(id: id) {
            if item.needsEpisodes {
                SeriesDetailView(series: item)
                    .id(item.id)
            } else {
                PlayerPane(item: item)
            }
        } else {
            ContentUnavailableView("Choisissez un programme",
                                   systemImage: "play.tv",
                                   description: Text("Sélectionnez une chaîne, un film ou une série dans la liste."))
                .onAppear {
                    // Ne pas couper un enregistrement qui dépend de la lecture.
                    if !recordings.isPlayerRecording { playback.stop() }
                }
        }
    }
}

/// Lecteur + informations (guide TV, résumé).
struct PlayerPane: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(NavigationModel.self) private var navigation
    @Environment(RecordingCenter.self) private var recordings
    let item: MediaItem

    var body: some View {
        VStack(spacing: 0) {
            VideoSurface()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if !navigation.isTheater {
                Divider()
                InfoPanel(item: item)
                    .frame(height: 190)
            }
        }
        .task(id: item.id) {
            // Entrée / sortie du plein écran : la vue est recréée, la lecture en cours continue sans redémarrer.
            if playback.current?.id == item.id, playback.errorMessage == nil { return }
            recordings.requestPlay(item, onCancel: {
                // Lecture refusée (enregistrement prioritaire) : on revient à l'élément en cours.
                navigation.selectedItemID = playback.current?.id
            })
            store.recordPlay(item)
        }
    }
}

/// Panneau d'informations sous le lecteur.
struct InfoPanel: View {
    @Environment(LibraryStore.self) private var store
    @Environment(RecordingCenter.self) private var recordings
    let item: MediaItem

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            LogoView(url: item.logoURL, name: item.name, size: 64)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.title2.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    if item.kind == .live {
                        Button {
                            if recordings.isRecording(item) { recordings.stopLive() } else { recordings.recordNow(item) }
                        } label: {
                            Label(recordings.isRecording(item) ? String(localized: "Arrêter") : String(localized: "Enregistrer"),
                                  systemImage: recordings.isRecording(item) ? "stop.circle.fill" : "record.circle")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("Enregistrer la chaîne jusqu'à la fin du programme en cours (⇧⌘R)")
                        Button {
                            recordings.scheduleSheetItem = item
                        } label: {
                            Image(systemName: "calendar.badge.clock")
                        }
                        .buttonStyle(.borderless)
                        .help("Programmer un enregistrement")
                    } else if let url = item.streamURL, !url.isFileURL {
                        Menu {
                            Button("Télécharger maintenant") { recordings.download(item, tonight: false) }
                            Button("Télécharger cette nuit") { recordings.download(item, tonight: true) }
                        } label: {
                            Label("Télécharger", systemImage: "arrow.down.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .help("Télécharger sans regarder")
                    }
                    Button {
                        store.toggleFavorite(item.id)
                    } label: {
                        Image(systemName: store.isFavorite(item.id) ? "star.fill" : "star")
                            .foregroundStyle(store.isFavorite(item.id) ? .yellow : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Ajouter ou retirer des favoris (⌘D)")
                }
                Text(item.group)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if item.kind == .live {
                    GuideStrip(item: item)
                } else if let info = item.info {
                    ScrollView {
                        Text(info)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.background)
    }
}

/// Programme en cours + programmes à venir.
struct GuideStrip: View {
    @Environment(LibraryStore.self) private var store
    @Environment(RecordingCenter.self) private var recordings
    let item: MediaItem
    private var epgID: String? { item.epgID }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = context.date
            if let current = store.epg.current(for: epgID, at: now) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("EN COURS")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.tint, in: Capsule())
                            .foregroundStyle(.white)
                        Text(current.title).font(.headline).lineLimit(1)
                        Spacer()
                        Text("\(current.start.formatted(date: .omitted, time: .shortened)) – \(current.stop.formatted(date: .omitted, time: .shortened))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: current.progress(at: now))
                        .progressViewStyle(.linear)
                    if let desc = current.desc {
                        Text(desc).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.epg.upcoming(for: epgID, after: now)) { programme in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(programme.start.formatted(date: .omitted, time: .shortened))
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                        if recordings.isScheduled(item, programme) {
                                            Image(systemName: "record.circle.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    Text(programme.title).font(.caption).lineLimit(1)
                                }
                                .padding(8)
                                .frame(width: 150, alignment: .leading)
                                .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                                .help((programme.desc ?? programme.title) + String(localized: "\n\nDouble-clic ou clic droit : programmer l'enregistrement"))
                                .onTapGesture(count: 2) { recordings.schedule(item, programme: programme) }
                                .contextMenu {
                                    if recordings.isScheduled(item, programme) {
                                        Text("Enregistrement déjà programmé")
                                    } else {
                                        Button("Programmer l'enregistrement") { recordings.schedule(item, programme: programme) }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Text(epgID == nil ? String(localized: "Pas d'identifiant de guide TV pour cette chaîne.") : String(localized: "Aucun programme disponible pour le moment."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
