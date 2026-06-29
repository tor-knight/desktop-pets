import SwiftUI
import SwiftData

@main
@MainActor
struct DesktopPetsApp: App {
    @State private var viewModel = ContentViewModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([HealthBehavior.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
