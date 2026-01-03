import SwiftUI
import SwiftData

@main
struct MindCityApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                KnowledgeItem.self,
                Building.self,
                UserStats.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Ensure UserStats exists on first launch
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<UserStats>()
            let existingStats = try? context.fetch(descriptor)
            if existingStats?.isEmpty ?? true {
                let stats = UserStats()
                context.insert(stats)
                try? context.save()
            }
        } catch {
            fatalError("Failed to configure SwiftData: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
