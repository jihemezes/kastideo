import SwiftUI
import KastideoCore

/// Fenêtre principale : accueil si aucune source, sinon navigation en trois colonnes.
struct RootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(PlaybackController.self) private var playback
    @Environment(NavigationModel.self) private var navigation
    @AppStorage(SettingsKeys.autoRefresh) private var autoRefresh = true
    @State private var showAddSource = false

    var body: some View {
        @Bindable var navigation = navigation
        Group {
            if store.hasSources {
                MainSplitView()
            } else {
                WelcomeView(showAddSource: $showAddSource)
            }
        }
        .sheet(isPresented: $showAddSource) {
            SourceEditorView(existing: nil)
                .environment(store)
        }
        .sheet(isPresented: $navigation.showWhatsNew) {
            WhatsNewView()
        }
        .task {
            if ReleaseNotes.shouldAnnounceUpdate() { navigation.showWhatsNew = true }
            await store.start(autoRefresh: autoRefresh)
        }
    }
}

struct MainSplitView: View {
    @Environment(LibraryStore.self) private var store
    @State private var columns = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } content: {
            ItemListView()
                .navigationSplitViewColumnWidth(min: 280, ideal: 360, max: 520)
        } detail: {
            DetailView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if store.isBusy {
                    ProgressView().controlSize(.small)
                        .help("Chargement des sources ou du guide TV…")
                }
                Button {
                    store.refreshAll()
                } label: {
                    Label("Actualiser", systemImage: "arrow.clockwise")
                }
                .help("Actualiser toutes les sources (⌘R)")
                SettingsLink {
                    Label("Sources", systemImage: "antenna.radiowaves.left.and.right")
                }
                .help("Gérer les sources et les réglages (⌘,)")
            }
        }
    }
}
