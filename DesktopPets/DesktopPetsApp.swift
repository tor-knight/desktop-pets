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

        MenuBarExtra {
            Button("Reset Timer") {
                viewModel.resetTimer()
            }
            Button("Settings") {
                NSApp.activate(ignoringOtherApps: true)
                var foundWindow = false
                for window in NSApplication.shared.windows {
                    if window.canBecomeMain {
                        window.makeKeyAndOrderFront(nil)
                        foundWindow = true
                    }
                }
                if !foundWindow {
                    viewModel.openSettings()
                }
            }
            Divider()
            Button("Quit Desktop Pets") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            let minutes = max(0, Int(viewModel.idleManager.timeRemaining)) / 60
            let seconds = max(0, Int(viewModel.idleManager.timeRemaining)) % 60
            Text("🐾 \(String(format: "%02d:%02d", minutes, seconds))")
                .onChange(of: viewModel.idleManager.shouldShowOverlay) { _, show in
                    if show {
                        OverlayWindowManager.shared.showOverlay(modelContext: sharedModelContainer.mainContext) {
                            viewModel.idleManager.dismissOverlay()
                        }
                    }
                }
        }
    }
}
