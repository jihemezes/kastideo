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

extension View {
    func recordingToast() -> some View { modifier(RecordingToastModifier()) }
}
