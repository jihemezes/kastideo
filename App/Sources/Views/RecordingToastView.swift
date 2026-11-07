import SwiftUI
import AppKit

/// Bandeau affiché en bas de la fenêtre après un enregistrement ou un téléchargement.
struct RecordingToastModifier: ViewModifier {
    @Environment(RecordingCenter.self) private var recordings

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = recordings.toast {
                    HStack(spacing: 12) {
                        Image(systemName: toast.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(toast.isError ? Color.orange : Color.green)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(toast.title).font(.headline)
                            Text(toast.message)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                            if let file = toast.file {
                                Text(file.deletingLastPathComponent().path.replacingOccurrences(of: RecordingFolder.realHome.path, with: "~"))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .frame(maxWidth: 420, alignment: .leading)
                        if let file = toast.file {
                            Button("Afficher") { NSWorkspace.shared.activateFileViewerSelecting([file]) }
                        }
                        Button {
                            recordings.toast = nil
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(radius: 10, y: 3)
                    .padding(.bottom, 22)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: recordings.toast?.id)
    }
}

/// Bandeau affiché juste après le démarrage d'un enregistrement : l'enregistrement a déjà commencé,
/// l'utilisateur peut choisir un autre arrêt programmé (sinon, fin du programme ou durée par défaut).
struct DurationPromptModifier: ViewModifier {
    @Environment(RecordingCenter.self) private var recordings

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if recordings.durationPrompt != nil, let live = recordings.activeLive {
                    HStack(spacing: 12) {
                        Image(systemName: "record.circle.fill").foregroundStyle(.red).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enregistrement démarré").font(.headline)
                            if let end = live.endsAt {
                                Text("Arrêt automatique à \(end.formatted(date: .omitted, time: .shortened))")
                                    .font(.callout).foregroundStyle(.secondary)
                            } else {
                                Text("Sans limite de durée").font(.callout).foregroundStyle(.secondary)
                            }
                        }
                        StopDurationMenu()
                        Button {
                            recordings.durationPrompt = nil
                        } label: { Image(systemName: "xmark") }
                            .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(radius: 10, y: 3)
                    .padding(.top, 54)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: recordings.durationPrompt?.id)
    }
}

/// Bandeau « Annuler » après le retrait d'un contenu de « Reprendre la lecture ».
struct ResumeUndoModifier: ViewModifier {
    @Environment(WatchProgressStore.self) private var watch

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let undo = watch.resumeUndo {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.uturn.backward.circle").font(.title3)
                        Text(undo.ids.count > 1 ? String(localized: "Retirés de « Reprendre la lecture ».") : String(localized: "Retiré de « Reprendre la lecture »."))
                        Button("Annuler") { watch.undoHideResume() }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(radius: 10, y: 3)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: watch.resumeUndo?.id)
    }
}

extension View {
    func resumeUndoBanner() -> some View { modifier(ResumeUndoModifier()) }
    func durationPromptBanner() -> some View { modifier(DurationPromptModifier()) }
    func recordingToast() -> some View { modifier(RecordingToastModifier()) }
}
