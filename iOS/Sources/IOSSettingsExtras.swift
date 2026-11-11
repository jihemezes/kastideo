import SwiftUI
import KastideoCore

/// Réglages du replay (archive du fournisseur).
struct IOSReplaySection: View {
    @AppStorage(ReplaySettings.enabledKey) private var enabled = true
    @AppStorage(ReplaySettings.guideDaysKey) private var guideDays = 3
    @AppStorage(ReplaySettings.returnToLiveKey) private var returnToLive = true
    @AppStorage(ReplaySettings.offsetKey) private var offset = 0

    var body: some View {
        Section {
            Toggle("Revoir les programmes passés (replay)", isOn: $enabled)
            if enabled {
                Stepper("Jours passés dans le guide : \(guideDays)", value: $guideDays, in: 1...14)
                Toggle("Revenir au direct à la fin d'un replay", isOn: $returnToLive)
                Stepper("Correction de l'heure : \(offset) min", value: $offset, in: -180...180, step: 15)
            }
        } header: {
            Text("Replay")
        } footer: {
            Text("Disponible sur les chaînes marquées ↺ quand votre fournisseur garde une archive (souvent 3 à 14 jours). Si un replay démarre au mauvais moment, ajustez la correction de l'heure.")
        }
    }
}

/// Réglages du bandeau « à la une » de l'affichage Cinéma.
struct IOSCinemaSection: View {
    @Environment(LibraryStore.self) private var store
    @AppStorage(IOSHeroKeys.enabled) private var enabled = true
    @AppStorage(IOSHeroKeys.useRecent) private var useRecent = true
    @AppStorage(IOSHeroKeys.useCategory) private var useCategory = true
    @AppStorage(IOSHeroKeys.categoryMovie) private var categoryMovie = ""
    @AppStorage(IOSHeroKeys.categorySeries) private var categorySeries = ""
    @AppStorage(IOSHeroKeys.interval) private var interval = 8.0

    var body: some View {
        Section {
            Toggle("Afficher le bandeau « à la une »", isOn: $enabled)
            if enabled {
                Toggle("Derniers ajouts du fournisseur", isOn: $useRecent)
                Toggle("Sélection dans une catégorie", isOn: $useCategory)
                if useCategory {
                    Picker("Catégorie des films", selection: $categoryMovie) {
                        Text("Au hasard").tag("")
                        ForEach(store.categoriesByKind[.movie] ?? [], id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Catégorie des séries", selection: $categorySeries) {
                        Text("Au hasard").tag("")
                        ForEach(store.categoriesByKind[.series] ?? [], id: \.self) { Text($0).tag($0) }
                    }
                }
                Stepper("Défilement toutes les \(Int(interval)) s", value: $interval, in: 4...20, step: 1)
            }
        } header: {
            Text("Affichage Cinéma")
        } footer: {
            Text("Le bouton en haut à gauche de Direct, Films et Séries change l'affichage : Cinéma, liste, thèmes ou guide TV.")
        }
    }
}
