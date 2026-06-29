import XCTest
@testable import DesktopPets

final class PowerStateManagerTests: XCTestCase {
    @MainActor
    func testPowerStateManagerInit() {
        let manager = PowerStateManager()
        XCTAssertNotNil(manager)
    }
}
