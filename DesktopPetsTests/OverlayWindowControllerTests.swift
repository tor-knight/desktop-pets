import XCTest
import SwiftData
import SwiftUI
@testable import DesktopPets

@MainActor
final class OverlayWindowControllerTests: XCTestCase {
    func testShowAndHideOverlay() throws {
        let manager = OverlayWindowManager.shared
        
        let originalFactory = manager.windowFactory
        let originalPresenter = manager.windowPresenter
        
        addTeardownBlock {
            manager.windowFactory = originalFactory
            manager.windowPresenter = originalPresenter
        }
        
        manager.windowFactory = { _ in nil } // Do not create windows in headless environment
        manager.windowPresenter = { _ in } // Do not show window in headless environment
        manager.hideOverlay() // ensure clean state
        XCTAssertTrue(manager.windows.isEmpty)
        
        let container = try ModelContainer(for: HealthBehavior.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        manager.showOverlay(modelContext: container.mainContext, dismissAction: {})
        
        manager.hideOverlay()
        XCTAssertTrue(manager.windows.isEmpty, "Windows should be cleared")
    }
}
