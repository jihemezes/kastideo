import SwiftUI
import KastideoCore

/// Barre d'édition de la section Récents : sélection multiple, suppression, tout effacer.
struct RecentsEditBar: View {
    @Environment(LibraryStore.self) private var store
    @Binding var editing: Bool
    @Binding var checked: Set<String>
    let ids: [String]
    @State private var confirmClear = false

    var body: some View {
        HStack(spacing: 10) {
            if editing {
                Button(checked.count == ids.count ? String(localized: "Tout désélectionner") : String(localized: "Tout sélectionner")) {
                    checked = checked.count == ids.count ? [] : Set(ids)
                }
                Spacer()
                Button(role: .destructive) {
                    store.removeRecents(checked)
                    checked = []
                    editing = false
                } label: {
                    Label("Supprimer (\(checked.count))", systemImage: "trash")
                }
                .disabled(checked.isEmpty)
                .keyboardShortcut(.delete, modifiers: [])
                Button("Terminer") {
                    checked = []
                    editing = false
                }
                .keyboardShortcut(.cancelAction)
            } else {
                Text("\(ids.count) éléments")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Modifier") { editing = true }
                    .disabled(ids.isEmpty)
                Button("Tout effacer", role: .destructive) { confirmClear = true }
                    .disabled(ids.isEmpty)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .confirmationDialog(String(localized: "Effacer tout l'historique ?"), isPresented: $confirmClear) {
            Button("Tout effacer", role: .destructive) { store.clearRecents() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Vous pourrez annuler juste après.")
        }
    }
}

/// Bandeau « Annuler » affiché quelques secondes après une suppression dans les récents.
struct RecentsUndoToast: ViewModifier {
    @Environment(LibraryStore.self) private var store

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let backup = store.recentsBackup {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                        Text("\(backup.removedCount) supprimé(s) des récents")
                        Button("Annuler") { withAnimation { store.undoRemoveRecents() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 8, y: 2)
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: backup.removedCount) {
                        try? await Task.sleep(for: .seconds(8))
                        if !Task.isCancelled { withAnimation { store.discardRecentsUndo() } }
                    }
                }
            }
            .animation(.easeOut(duration: 0.2), value: store.recentsBackup != nil)
            .onDisappear { store.discardRecentsUndo() }
    }
}

extension View {
    func recentsUndoToast() -> some View { modifier(RecentsUndoToast()) }
}

/// Liste des récents en mode Classique : lignes avec cases à cocher en mode édition.
struct RecentsList: View {
    @Environment(NavigationModel.self) private var navigation
    @Environment(LibraryStore.self) private var store
    let items: [MediaItem]
    @State private var editing = false
    @State private var checked = Set<String>()

    var body: some View {
        @Bindable var navigation = navigation
        VStack(spacing: 0) {
            RecentsEditBar(editing: $editing, checked: $checked, ids: items.map(\.id))
            Divider()
            if editing {
                List(items) { item in
                    HStack(spacing: 10) {
                        Image(systemName: checked.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(checked.contains(item.id) ? Color.accentColor : Color.secondary)
                            .font(.title3)
                        ItemRow(item: item)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if checked.contains(item.id) { checked.remove(item.id) } else { checked.insert(item.id) }
                    }
                }
                .listStyle(.inset)
            } else {
                List(items, selection: $navigation.selectedItemID) { item in
                    ItemRow(item: item)
                }
                .listStyle(.inset)
                .onDeleteCommand {
                    if let id = navigation.selectedItemID { store.removeRecents([id]) }
                }
            }
        }
        .onChange(of: items.map(\.id)) { _, ids in
            checked = checked.intersection(ids)
        }
    }
}

/// Récents en interface Cinéma : grille de vignettes avec sélection multiple.
struct CinemaRecents: View {
    @AppStorage(AppearanceKeys.cardSize) private var cardSizeRaw = CardSize.medium.rawValue
    let items: [MediaItem]
    @State private var editing = false
    @State private var checked = Set<String>()

    var body: some View {
        let size = CardSize(rawValue: cardSizeRaw) ?? .medium
        let hasTiles = items.first?.kind == .live
        let minimum = hasTiles ? size.tileWidth : size.posterWidth
        VStack(alignment: .leading, spacing: 8) {
            Text("Récents").font(.title2.weight(.bold)).padding(.horizontal, 24).padding(.top, 20)
            RecentsEditBar(editing: $editing, checked: $checked, ids: items.map(\.id))
                .padding(.horizontal, 10)
            if items.isEmpty {
                ContentUnavailableView("Récents", systemImage: "tray",
                                       description: Text(Browse.recents.emptyMessage))
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: 16, alignment: .top)],
                          alignment: .leading, spacing: 20) {
                    ForEach(items) { item in
                        ZStack(alignment: .topLeading) {
                            MediaCard(item: item)
                                .allowsHitTesting(!editing)
                                .opacity(editing && !checked.contains(item.id) ? 0.7 : 1)
                            if editing {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if checked.contains(item.id) { checked.remove(item.id) } else { checked.insert(item.id) }
                                    }
                                Image(systemName: checked.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(checked.contains(item.id) ? Color.accentColor : Color.white)
                                    .shadow(color: .black.opacity(0.6), radius: 2)
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onChange(of: items.map(\.id)) { _, ids in
            checked = checked.intersection(ids)
        }
    }
}
