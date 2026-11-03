import SwiftUI
import AppKit
import KastideoCore

/// Image dans l'image : une seconde chaîne en miniature dans le lecteur (son coupé), échangeable en un clic.
@MainActor
@Observable
final class PipModel {
    static let shared = PipModel()

    private(set) var slot: MultiViewSlot?
    var showPicker = false
    private(set) var message: String?

    var item: MediaItem? { slot?.item }

    /// Vrai si la source de `candidate` a une connexion libre en plus de la lecture principale.
    func canOpen(_ candidate: MediaItem, playback: PlaybackController, store: LibraryStore) -> Bool {
        let source = store.source(id: candidate.sourceID)
        let inUse = playback.current?.sourceID == candidate.sourceID ? 1 : 0
        return inUse + 1 <= MultiViewKeys.limit(for: source)
    }

    func open(_ candidate: MediaItem, playback: PlaybackController, store: LibraryStore) {
        guard candidate.id != playback.current?.id else { return }
        guard canOpen(candidate, playback: playback, store: store) else {
            message = String(localized: "Cette source n'autorise pas de second flux. Choisissez une chaîne d'une autre source.")
            return
        }
        message = nil
        let pip = slot ?? MultiViewSlot()
        slot = pip
        pip.play(candidate, muted: true)
    }

    /// La miniature prend la place de la lecture principale, et inversement.
    func swap(playback: PlaybackController) {
        guard let small = slot?.item, let big = playback.current else { return }
        slot?.stop()
        playback.play(small)
        // Le flux principal précédent passe en miniature une fois l'ancien fermé.
        let pip = slot
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            pip?.play(big, muted: true)
        }
    }

    func close() {
        slot?.stop()
        slot?.videoView.removeFromSuperview()
        slot = nil
        showPicker = false
        message = nil
    }
}

/// Miniature flottante dans le coin du lecteur.
struct PipOverlay: View {
    @Environment(PlaybackController.self) private var playback
    let pip: PipModel
    @State private var hovering = false

    var body: some View {
        if let slot = pip.slot {
            ZStack(alignment: .topTrailing) {
                Color.black
                MultiViewVideo(slot: slot)
                if slot.isLoading { ProgressView().tint(.white) }
                else if slot.failed {
                    Label("Flux refusé", systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
                }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { pip.swap(playback: playback) }
                VStack {
                    HStack(spacing: 6) {
                        Text(slot.item?.name ?? "").font(.caption.weight(.semibold)).lineLimit(1)
                        Spacer()
                        if hovering {
                            Button { pip.swap(playback: playback) } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                                .help("Échanger avec la lecture principale")
                            Button { pip.close() } label: { Image(systemName: "xmark") }
                                .help("Fermer la miniature")
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(6)
                    .background(LinearGradient(colors: [.black.opacity(0.75), .clear], startPoint: .top, endPoint: .bottom))
                    Spacer()
                }
                .foregroundStyle(.white)
            }
            .frame(width: 260, height: 146)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.5), radius: 8)
            .onHover { hovering = $0 }
            .padding(14)
            .padding(.bottom, 70)
        }
    }
}

/// Bouton « Image dans l'image » (chaînes en direct) : choix de la seconde chaîne.
struct PipButton: View {
    @Environment(PlaybackController.self) private var playback
    @Environment(LibraryStore.self) private var store
    let pip: PipModel

    var body: some View {
        @Bindable var pip = pip
        Button {
            if pip.slot != nil { pip.close() } else { pip.showPicker = true }
        } label: {
            Image(systemName: pip.slot != nil ? "pip.exit" : "pip.enter")
                .font(.title3)
                .padding(8)
                .background(.black.opacity(0.55), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .help(pip.slot != nil ? "Fermer la miniature" : "Image dans l'image : une seconde chaîne en miniature")
        .popover(isPresented: $pip.showPicker) {
            VStack(spacing: 0) {
                MultiViewChannelPicker(canPick: { pip.canOpen($0, playback: playback, store: store) }) { item in
                    pip.showPicker = false
                    pip.open(item, playback: playback, store: store)
                }
                if let message = pip.message {
                    Text(message).font(.caption).foregroundStyle(.orange).padding(8)
                }
            }
        }
    }
}
