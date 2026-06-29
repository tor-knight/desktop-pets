import XCTest
@testable import DesktopPets
import AppKit

final class PowerStateManagerTests: XCTestCase {
    @MainActor
    func testPowerStateManagerInit() {
        let manager = PowerStateManager()
        XCTAssertNotNil(manager)
    }
    
    @MainActor
    func testPowerStateManagerSleepWakeTransitions() {
        let mockNotificationCenter = NotificationCenter()
        let manager = PowerStateManager(notificationCenter: mockNotificationCenter)
        
        // Initial state
        XCTAssertFalse(manager.isSleeping)
        
        // Trigger sleep
        mockNotificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
        XCTAssertTrue(manager.isSleeping, "Manager should be sleeping after receiving willSleepNotification")
        
        // Trigger wake
        mockNotificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertFalse(manager.isSleeping, "Manager should be awake after receiving didWakeNotification")
    }
    
    @MainActor
    func testPowerStateManagerLowPowerToggle() {
        let mockNotificationCenter = NotificationCenter()
        let manager = PowerStateManager(notificationCenter: mockNotificationCenter)
        
        // Test that isLowPower property can be manually toggled to verify it is accessible and mutable by logic
        manager.isLowPower = true
        XCTAssertTrue(manager.isLowPower)
        
        manager.isLowPower = false
        XCTAssertFalse(manager.isLowPower)
    }
}
