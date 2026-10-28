import Foundation
import Combine
import Observation
import Sparkle

/// Clés de réglages liées aux mises à jour.
enum UpdateKeys {
    static let betaChannel = "betaChannel"
    /// Recherche au démarrage (et toutes les 24 h), gérée par Kastideo et non par Sparkle.
    static let checkAtLaunch = "updates.checkAtLaunch"
    static let skippedVersion = "updates.skippedVersion"
}

/// Délégué Sparkle : canal « beta » et résultat des recherches discrètes.
final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    var onFound: ((String) -> Void)?
    var onNotFound: (() -> Void)?

    func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        UserDefaults.standard.bool(forKey: UpdateKeys.betaChannel) ? ["beta"] : []
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        PlaybackLog.shared.note("Mise à jour : version \(version) disponible", topic: .updates)
        DispatchQueue.main.async { [weak self] in self?.onFound?(version) }
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        PlaybackLog.shared.note("Mise à jour : aucune version plus récente", topic: .updates)
        DispatchQueue.main.async { [weak self] in self?.onNotFound?() }
    }
}

/// Mises à jour automatiques via Sparkle (flux appcast publié sur GitHub par le workflow Release).
@MainActor
@Observable
final class UpdaterController {
    private let delegate: UpdaterDelegate
    private let controller: SPUStandardUpdaterController
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    private(set) var canCheckForUpdates = false
    private(set) var lastCheck: Date?
    /// Version disponible trouvée par la recherche discrète (affichée en bandeau, jamais pendant une lecture).
    private(set) var availableVersion: String?
    /// Bandeau masqué pour cette session (« Plus tard »).
    var bannerDismissed = false
    /// Indique si une lecture est en cours (aucune proposition de mise à jour pendant un visionnage).
    @ObservationIgnored var isBusy: () -> Bool = { false }
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var lastProbe = Date.distantPast

    init() {
        let delegate = UpdaterDelegate()
        self.delegate = delegate
        self.controller = SPUStandardUpdaterController(startingUpdater: true,
                                                       updaterDelegate: delegate,
                                                       userDriverDelegate: nil)
        controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                MainActor.assumeIsolated { self?.canCheckForUpdates = value }
            }
            .store(in: &cancellables)
        controller.updater.publisher(for: \.lastUpdateCheckDate)
            .receive(on: RunLoop.main)
            .sink { [weak self] date in
                MainActor.assumeIsolated { self?.lastCheck = date }
            }
            .store(in: &cancellables)

        // Les recherches automatiques de Sparkle peuvent ouvrir une fenêtre à tout moment, y compris pendant
        // un film : Kastideo les remplace par une recherche discrète au démarrage, puis toutes les 24 h.
        let defaults = UserDefaults.standard
        if defaults.object(forKey: UpdateKeys.checkAtLaunch) == nil {
            defaults.set(true, forKey: UpdateKeys.checkAtLaunch)
        }
        controller.updater.automaticallyChecksForUpdates = false
        delegate.onFound = { [weak self] version in
            MainActor.assumeIsolated { self?.found(version) }
        }
        delegate.onNotFound = { [weak self] in
            MainActor.assumeIsolated { self?.availableVersion = nil }
        }
    }

    /// Démarre la recherche discrète : quelques secondes après le lancement, puis toutes les 24 h
    /// (reportée tant qu'une lecture est en cours).
    func startBackgroundChecks() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            while !Task.isCancelled {
                guard let self else { return }
                if self.automaticallyChecks, !self.isBusy(), Date().timeIntervalSince(self.lastProbe) > 24 * 3600 {
                    self.probe()
                }
                try? await Task.sleep(for: .seconds(15 * 60))
            }
        }
    }

    /// Recherche sans aucune fenêtre : seul le résultat est mémorisé.
    private func probe() {
        guard controller.updater.canCheckForUpdates else { return }
        lastProbe = Date()
        PlaybackLog.shared.note("Mise à jour : recherche discrète d'une nouvelle version", topic: .updates, detail: .detailed)
        controller.updater.checkForUpdateInformation()
    }

    private func found(_ version: String) {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        guard version != current, version != UserDefaults.standard.string(forKey: UpdateKeys.skippedVersion) else { return }
        availableVersion = version
    }

    /// « Ignorer cette version » : plus de bandeau tant qu'une version plus récente ne sort pas.
    func skipAvailableVersion() {
        if let availableVersion { UserDefaults.standard.set(availableVersion, forKey: UpdateKeys.skippedVersion) }
        availableVersion = nil
    }

    /// Ouvre la fenêtre Sparkle (notes de version, téléchargement, installation).
    func installAvailableUpdate() {
        bannerDismissed = true
        controller.checkForUpdates(nil)
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    var automaticallyChecks: Bool {
        get { UserDefaults.standard.bool(forKey: UpdateKeys.checkAtLaunch) }
        set {
            UserDefaults.standard.set(newValue, forKey: UpdateKeys.checkAtLaunch)
            if newValue { lastProbe = .distantPast }
        }
    }

    var automaticallyDownloads: Bool {
        get { controller.updater.automaticallyDownloadsUpdates }
        set { controller.updater.automaticallyDownloadsUpdates = newValue }
    }
}
