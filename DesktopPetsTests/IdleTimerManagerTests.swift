import XCTest
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
