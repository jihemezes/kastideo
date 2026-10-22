import SwiftUI

/// Bandeau « Nouvelle version disponible » : discret, facultatif, jamais affiché pendant une lecture.
struct UpdateBanner: View {
    @Environment(UpdaterController.self) private var updater
    @Environment(PlaybackController.self) private var playback
    @Environment(RecordingCenter.self) private var recordings

    var body: some View {
        if let version = updater.availableVersion, !updater.bannerDismissed,
           playback.current == nil, recordings.activeLive == nil {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(KastideoPalette.orange)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Kastideo \(version) est disponible").font(.headline)
                    Text("La mise à jour est facultative ; elle s'installe en quelques secondes et Kastideo redémarre.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Button("Ignorer cette version") { updater.skipAvailableVersion() }
                    .buttonStyle(.borderless)
                Button("Plus tard") { updater.bannerDismissed = true }
                Button("Mettre à jour…") { updater.installAvailableUpdate() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: 760)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(radius: 10, y: 3)
            .padding(.top, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
