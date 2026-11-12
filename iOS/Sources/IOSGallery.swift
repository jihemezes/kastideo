import SwiftUI
import Photos
import AVFoundation
import UIKit
import KastideoCore

struct IOSGalleryAlbum: Identifiable, Hashable {
    let id: String
    let name: String
    let count: Int
}

enum IOSGalleryError: LocalizedError {
    case denied, notFound, failed(String)

    var errorDescription: String? {
        switch self {
        case .denied:
            return String(localized: "Kastideo n'a pas accès à la galerie. Autorisez-le dans Réglages de l'iPhone > Kastideo > Photos.")
        case .notFound:
            return String(localized: "Cette vidéo n'est plus dans la galerie (supprimée, ou hors de la sélection autorisée).")
        case .failed(let detail):
            return String(localized: "Impossible de lire cette vidéo de la galerie.") + (detail.isEmpty ? "" : " " + detail)
        }
    }
}

/// Vidéos de la galerie de l'iPhone / iPad : source « Vidéos locales » (PhotoKit).
enum IOSGallery {
    static let autoRefreshKey = "ios.gallery.autorefresh"

    static var status: PHAuthorizationStatus { PHPhotoLibrary.authorizationStatus(for: .readWrite) }
    static var isAuthorized: Bool { status == .authorized || status == .limited }

    /// Demande l'accès si besoin ; renvoie l'état final.
    @discardableResult
    static func requestAccess() async -> PHAuthorizationStatus {
        if status == .notDetermined { return await PHPhotoLibrary.requestAuthorization(for: .readWrite) }
        return status
    }

    // MARK: Albums

    private static func videoOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return options
    }

    /// Albums qui contiennent au moins une vidéo (albums intelligents d'abord, puis vos albums).
    static func albums() -> [IOSGalleryAlbum] {
        guard isAuthorized else { return [] }
        var result: [IOSGalleryAlbum] = []
        var seen = Set<String>()
        func add(_ collection: PHAssetCollection) {
            guard seen.insert(collection.localIdentifier).inserted else { return }
            let count = PHAsset.fetchAssets(in: collection, options: videoOptions()).count
            guard count > 0 else { return }
            result.append(IOSGalleryAlbum(id: collection.localIdentifier, name: collection.localizedTitle ?? "?", count: count))
        }
        let smart = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        smart.enumerateObjects { collection, _, _ in
            if collection.assetCollectionSubtype == .smartAlbumAllHidden { return }
            add(collection)
        }
        let user = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        user.enumerateObjects { collection, _, _ in add(collection) }
        return result
    }

    static var totalVideoCount: Int {
        guard isAuthorized else { return 0 }
        return PHAsset.fetchAssets(with: videoOptions()).count
    }

    // MARK: Examen de la galerie

    private static var thumbsFolder: URL {
        let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Kastideo/galerie-miniatures", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static var exportsFolder: URL {
        let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Kastideo/galerie-lecture", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func safeName(_ id: String) -> String {
        String(id.map { $0.isLetter || $0.isNumber ? $0 : "_" })
    }

    static func assetURL(_ localIdentifier: String) -> URL? {
        var parts = URLComponents()
        parts.scheme = PlaybackController.galleryScheme
        parts.host = "asset"
        parts.queryItems = [URLQueryItem(name: "id", value: localIdentifier)]
        return parts.url
    }

    private static func isGenericName(_ name: String) -> Bool {
        if name.isEmpty { return true }
        if name.allSatisfy({ $0.isNumber || "_-. ".contains($0) }) { return true }
        if UUID(uuidString: name) != nil { return true }
        let pattern = #"^(?:IMG|MVI|VID|PXL|MOV|RPReplay|DSC|DJI|GOPR|GH\d*|VIDEO|TRIM|WA\d|Screen ?Recording)[A-Za-z]*[_\- ]?\d[\w\- ]*$"#
        return name.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Construit le contenu de la source : une entrée par vidéo, miniature comme affiche.
    static func scan(_ source: Source) async throws -> SourceContent {
        guard case .gallery(let albumIDs, _) = source.kind else { throw LibraryError.galleryUnavailable }
        guard await requestAccess() != .denied, isAuthorized else { throw IOSGalleryError.denied }

        // (vidéo, nom de l'album retenu)
        var entries: [(asset: PHAsset, album: String)] = []
        var seen = Set<String>()
        if albumIDs.isEmpty {
            PHAsset.fetchAssets(with: videoOptions()).enumerateObjects { asset, _, _ in
                if seen.insert(asset.localIdentifier).inserted { entries.append((asset, "")) }
            }
        } else {
            let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: albumIDs, options: nil)
            collections.enumerateObjects { collection, _, _ in
                let name = collection.localizedTitle ?? ""
                PHAsset.fetchAssets(in: collection, options: videoOptions()).enumerateObjects { asset, _, _ in
                    if seen.insert(asset.localIdentifier).inserted { entries.append((asset, name)) }
                }
            }
            entries.sort { ($0.asset.creationDate ?? .distantPast) > ($1.asset.creationDate ?? .distantPast) }
        }

        let thumbs = thumbsFolder
        let prefix = String(localized: "Vidéos") + " · "
        let fallbackAlbum = String(localized: "Galerie")
        let sourceID = source.id
        var items: [MediaItem] = []
        items.reserveCapacity(entries.count)
        for entry in entries {
            let asset = entry.asset
            let resources = PHAssetResource.assetResources(for: asset)
            let resource = resources.first { $0.type == .video || $0.type == .fullSizeVideo } ?? resources.first
            let base = ((resource?.originalFilename ?? "") as NSString).deletingPathExtension
            let generic = isGenericName(base)
            let date = asset.creationDate
            let dateText = date?.formatted(date: .abbreviated, time: .shortened) ?? ""
            let name = generic
                ? (dateText.isEmpty ? String(localized: "Vidéo") : String(localized: "Vidéo du \(dateText)"))
                : base
            var item = MediaItem(id: "\(sourceID.uuidString):\(asset.localIdentifier)", sourceID: sourceID, kind: .movie,
                                 name: name, group: prefix + (entry.album.isEmpty ? fallbackAlbum : entry.album),
                                 logoURL: nil, streamURL: assetURL(asset.localIdentifier),
                                 info: generic && !dateText.isEmpty ? String(localized: "Prise le \(dateText)") : nil,
                                 added: date)
            item.runtime = max(1, Int((asset.duration / 60).rounded()))
            if generic { item.epgID = GalleryHook.genericMarker }
            let file = thumbs.appendingPathComponent(safeName(asset.localIdentifier) + ".jpg")
            if FileManager.default.fileExists(atPath: file.path) { item.logoURL = file }
            items.append(item)
        }

        // Miniatures manquantes : 6 à la fois, sans télécharger depuis iCloud.
        let assets = entries.map(\.asset)
        let missing = assets.indices.filter { items[$0].logoURL == nil }
        var next = 0
        await withTaskGroup(of: (Int, URL?).self) { group in
            func launch() {
                guard next < missing.count else { return }
                let index = missing[next]
                next += 1
                let asset = assets[index]
                group.addTask { (index, await IOSGallery.makeThumbnail(asset, in: thumbs)) }
            }
            for _ in 0..<6 { launch() }
            for await (index, url) in group {
                if let url { items[index].logoURL = url }
                launch()
            }
        }
        return SourceContent(items: items, epgURL: nil)
    }

    private static func makeThumbnail(_ asset: PHAsset, in folder: URL) async -> URL? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        let image: UIImage? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 480, height: 480),
                                                  contentMode: .aspectFill, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
        guard let data = image?.jpegData(compressionQuality: 0.8) else { return nil }
        let file = folder.appendingPathComponent(safeName(asset.localIdentifier) + ".jpg")
        do { try data.write(to: file, options: .atomic); return file } catch { return nil }
    }

    // MARK: Lecture

    /// Adresse de fichier lisible pour une vidéo de la galerie (téléchargée d'iCloud si nécessaire).
    @MainActor
    static func resolve(_ item: MediaItem) async throws -> URL {
        guard let url = item.streamURL,
              let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value
        else { throw IOSGalleryError.notFound }
        guard await requestAccess() != .denied, isAuthorized else { throw IOSGalleryError.denied }
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else {
            throw IOSGalleryError.notFound
        }
        let av = try await requestAVAsset(asset)
        if let urlAsset = av as? AVURLAsset, FileManager.default.isReadableFile(atPath: urlAsset.url.path) {
            return urlAsset.url
        }
        // Ralenti ou accès au fichier refusé : copie lisible dans le cache.
        let file = exportsFolder.appendingPathComponent(safeName(id) + ".mp4")
        if FileManager.default.fileExists(atPath: file.path) { return file }
        return try await export(av, to: file)
    }

    private static func requestAVAsset(_ asset: PHAsset) async throws -> AVAsset {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.version = .current
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { av, _, info in
                if let av {
                    continuation.resume(returning: av)
                } else {
                    let detail = (info?[PHImageErrorKey] as? Error)?.localizedDescription ?? ""
                    continuation.resume(throwing: IOSGalleryError.failed(detail))
                }
            }
        }
    }

    private static func export(_ av: AVAsset, to file: URL) async throws -> URL {
        guard let session = AVAssetExportSession(asset: av, presetName: AVAssetExportPresetHighestQuality) else {
            throw IOSGalleryError.failed("")
        }
        try? FileManager.default.removeItem(at: file)
        session.outputURL = file
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = false
        return try await withCheckedThrowingContinuation { continuation in
            session.exportAsynchronously {
                if session.status == .completed {
                    continuation.resume(returning: file)
                } else {
                    continuation.resume(throwing: IOSGalleryError.failed(session.error?.localizedDescription ?? ""))
                }
            }
        }
    }

    /// Supprime les copies de lecture vieilles de plus de 3 jours (au lancement).
    static func purgeCaches() {
        let limit = Date().addingTimeInterval(-3 * 24 * 3600)
        let urls = (try? FileManager.default.contentsOfDirectory(at: exportsFolder, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        for url in urls {
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if date < limit { try? FileManager.default.removeItem(at: url) }
        }
    }

    // MARK: Accès limité

    /// « Choisir d'autres vidéos » quand l'utilisateur n'a autorisé qu'une sélection.
    @MainActor
    static func presentLimitedPicker() {
        guard status == .limited,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
              var controller = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        while let presented = controller.presentedViewController { controller = presented }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
    }

    @MainActor
    static func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
}

// MARK: - Choix des albums (ajout / modification de la source)

struct IOSGalleryAlbumsSection: View {
    @Binding var all: Bool
    @Binding var selected: Set<String>
    @State private var albums: [IOSGalleryAlbum] = []
    @State private var status = IOSGallery.status

    var body: some View {
        Group {
            Section {
                switch status {
                case .denied, .restricted:
                    Text("Kastideo n'a pas accès à la galerie.").foregroundStyle(.orange)
                    Button { IOSGallery.openSystemSettings() } label: {
                        Label("Ouvrir les réglages de l'iPhone", systemImage: "gearshape")
                    }
                case .notDetermined:
                    Button { Task { await refresh() } } label: { Label("Autoriser l'accès aux vidéos", systemImage: "photo.on.rectangle") }
                default:
                    Toggle("Toutes les vidéos", isOn: $all)
                    if !all {
                        if albums.isEmpty { Text("Aucun album avec des vidéos.").font(.footnote).foregroundStyle(.secondary) }
                        ForEach(albums) { album in
                            Button {
                                if selected.contains(album.id) { selected.remove(album.id) } else { selected.insert(album.id) }
                            } label: {
                                HStack {
                                    Text(album.name).foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(album.count)").foregroundStyle(.secondary)
                                    Image(systemName: selected.contains(album.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selected.contains(album.id) ? IOSPalette.orange : .secondary)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Albums")
            } footer: {
                if status == .limited {
                    Text("Vous n'avez autorisé qu'une sélection de photos et vidéos : seules celles-ci apparaissent.")
                } else {
                    Text("Les films nommés correctement (titre exact) reçoivent une affiche et un résumé TMDB ; les vidéos de la caméra gardent leur miniature.")
                }
            }
            if status == .limited {
                Section {
                    Button { IOSGallery.presentLimitedPicker() } label: {
                        Label("Choisir d'autres vidéos…", systemImage: "plus.rectangle.on.rectangle")
                    }
                }
            }
        }
        .task { await refresh() }
    }

    private func refresh() async {
        status = await IOSGallery.requestAccess()
        albums = IOSGallery.albums()
    }
}

// MARK: - Réglages

struct IOSGallerySettingsSection: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage(IOSGallery.autoRefreshKey) private var autoRefresh = true
    @State private var adding = false
    @State private var problem: String?

    private var gallerySources: [Source] {
        store.sources.filter { if case .gallery = $0.kind { return true } else { return false } }
    }

    var body: some View {
        Section {
            if gallerySources.isEmpty {
                Button { Task { await addAll() } } label: {
                    if adding { ProgressView() } else { Label("Ajouter les vidéos de la galerie", systemImage: "photo.on.rectangle") }
                }
                .disabled(adding)
            } else {
                Toggle("Actualiser à l'ouverture de l'app", isOn: $autoRefresh)
                if IOSGallery.status == .limited {
                    Button { IOSGallery.presentLimitedPicker() } label: {
                        Label("Choisir d'autres vidéos…", systemImage: "plus.rectangle.on.rectangle")
                    }
                }
                if IOSGallery.status == .denied || IOSGallery.status == .restricted {
                    Button { IOSGallery.openSystemSettings() } label: {
                        Label("Autoriser l'accès dans les réglages de l'iPhone", systemImage: "gearshape")
                    }
                }
            }
            if let problem { Text(problem).font(.footnote).foregroundStyle(.red) }
        } header: {
            Text("Vidéos locales")
        } footer: {
            Text("Les vidéos de la galerie apparaissent dans Films, sous « Mes vidéos ». Touchez la source dans la liste ci-dessus pour choisir des albums.")
        }
    }

    private func addAll() async {
        adding = true
        problem = nil
        defer { adding = false }
        let status = await IOSGallery.requestAccess()
        guard status == .authorized || status == .limited else {
            problem = IOSGalleryError.denied.errorDescription
            return
        }
        let source = Source(id: UUID(), name: String(localized: "Vidéos locales"), kind: .gallery(albumIDs: [], albumNames: []),
                            epgURL: nil, isEnabled: true, lastRefresh: nil)
        store.addSource(source, password: nil)
        if store.catalogOrigin == .iptv { store.catalogOrigin = .all }
    }
}
