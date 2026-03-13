import SwiftUI
import SwiftData

@main
struct TypeWashApp: App {

    let container: ModelContainer = {
        let schema = Schema([Preset.self, PresetOperation.self, HistoryEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed to initialize: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, idealWidth: 1000, minHeight: 600, idealHeight: 750)
                .onAppear { seedPresetsIfNeeded() }
        }
        .modelContainer(container)

        Settings {
            SettingsView()
        }
        .modelContainer(container)
    }

    private func seedPresetsIfNeeded() {
        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<Preset>())) ?? 0
        if count == 0 {
            BuiltInPresets.seed(into: context)
        }
    }
}
