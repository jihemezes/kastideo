import Foundation
import Combine
import Observation
import Sparkle

/// Clés de réglages liées aux mises à jour.
enum UpdateKeys {
    static let betaChannel = "betaChannel"
}

/// Délégué Sparkle : active le canal « beta » si l'utilisateur l'a demandé.
final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        UserDefaults.standard.bool(forKey: UpdateKeys.betaChannel) ? ["beta"] : []
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
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    var automaticallyChecks: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    var automaticallyDownloads: Bool {
        get { controller.updater.automaticallyDownloadsUpdates }
        set { controller.updater.automaticallyDownloadsUpdates = newValue }
    }
}
