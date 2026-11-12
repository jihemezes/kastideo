import SwiftUI

/// Petit indicateur d'état de la synchronisation iCloud (bas de la barre latérale du Mac).
struct CloudStatusBadge: View {
    @Environment(CloudSync.self) private var cloud

    var body: some View {
        Button {
            Task { await cloud.syncNow() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(color)
                Text(text).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .help(helpText)
    }

    private var icon: String {
        switch cloud.state {
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .problem: return "exclamationmark.icloud"
        default: return "checkmark.icloud"
        }
    }

    private var color: Color {
        if case .problem = cloud.state { return .orange }
        return .secondary
    }

    private var text: String {
        switch cloud.state {
        case .syncing: return String(localized: "Synchronisation…")
        case .problem: return String(localized: "Synchro iCloud : problème")
        default:
            if let date = cloud.lastSync { return String(localized: "iCloud : ") + date.formatted(.relative(presentation: .named)) }
            return String(localized: "iCloud : en attente")
        }
    }

    private var helpText: String {
        if case .problem(let message) = cloud.state { return message }
        return String(localized: "Synchroniser maintenant")
    }
}
