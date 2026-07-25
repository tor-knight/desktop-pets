import XCTest
import SwiftData
import SwiftUI
@testable import DesktopPets

@MainActor
final class IdleTimerManagerTests: XCTestCase {

    func testFallbackToAbsoluteTime() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        manager.mockPermission = false // Simulate denied
        manager.tick()
        XCTAssertTrue(manager.isUsingAbsoluteTimer)
    }

    func testTimeDriftCompensation() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        let past = Date().addingTimeInterval(-7200) // 2 hours ago
        XCTAssertTrue(manager.hasSignificantTimeDrift(lastCheck: past))
    }

    func testTimeDriftNormalCheck() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        let recent = Date().addingTimeInterval(-1) // 1 second ago
        XCTAssertFalse(manager.hasSignificantTimeDrift(lastCheck: recent))
    }

    func testResetTimer() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        manager.timeRemaining = 100
        manager.resetTimer()
        XCTAssertEqual(manager.timeRemaining, manager.workThreshold)
    }

    func testDismissOverlayResetsTimer() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        manager.shouldShowOverlay = true
        manager.timeRemaining = 0
        manager.dismissOverlay()

        XCTAssertFalse(manager.shouldShowOverlay)
        XCTAssertEqual(manager.timeRemaining, manager.workThreshold)
    }

    func testStopMonitoringInvalidatesTimer() {
        let manager = IdleTimerManager(powerManager: PowerStateManager())
        manager.startMonitoring()
        manager.stopMonitoring()
        // verify no crash and clean teardown
        XCTAssertFalse(manager.shouldShowOverlay)
    }
}
