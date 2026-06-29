import XCTest
import SwiftData
import SwiftUI
@testable import DesktopPets

@MainActor
final class IdleTimerManagerTests: XCTestCase {
    func testFallbackToAbsoluteTime() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        manager.mockPermission = false // Simulate denied
        manager.startMonitoring()
        XCTAssertTrue(manager.isUsingAbsoluteTimer)
    }
    
    func testTimeDriftCompensation() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        let past = Date().addingTimeInterval(-7200) // 2 hours ago
        XCTAssertTrue(manager.hasSignificantTimeDrift(lastCheck: past))
    }
}

@MainActor
final class OverlayWindowControllerTests: XCTestCase {
    func testShowAndHideOverlay() throws {
        let manager = OverlayWindowManager.shared
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

@MainActor
final class PetViewModelTests: XCTestCase {
    func testHoldProgressAndTimer() {
        let viewModel = PetViewModel()
        XCTAssertEqual(viewModel.holdProgress, 0)
        
        viewModel.startHold()
        
        let expectation = XCTestExpectation(description: "Timer increments progress")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssertGreaterThan(viewModel.holdProgress, 0.0)
            viewModel.endHold()
            XCTAssertEqual(viewModel.holdProgress, 0.0, "Progress should reset to 0 if ended early")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTimerInvalidationOnDisappear() {
        let viewModel = PetViewModel()
        viewModel.startHold()
        
        // Simulating disappear
        viewModel.onDisappear()
        
        let initialProgress = viewModel.holdProgress
        
        let expectation = XCTestExpectation(description: "Timer should be invalidated")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // Should not increment after disappear
            XCTAssertEqual(viewModel.holdProgress, initialProgress)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
