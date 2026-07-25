import XCTest
@testable import DesktopPets

@MainActor
final class ContentViewModelTests: XCTestCase {

    func testInitialState() {
        let powerManager = PowerStateManager()
        let idleManager = IdleTimerManager(powerManager: powerManager)
        let viewModel = ContentViewModel(powerManager: powerManager, idleManager: idleManager)

        XCTAssertFalse(viewModel.isPermissionsGranted, "Should initially be false")
    }

    func testOnAppearChecksPermissions() {
        let powerManager = PowerStateManager()
        let idleManager = IdleTimerManager(powerManager: powerManager)
        let viewModel = ContentViewModel(powerManager: powerManager, idleManager: idleManager)

        viewModel.isProcessTrustedAction = { true }
        viewModel.onAppear()

        XCTAssertTrue(viewModel.isPermissionsGranted, "Should update to true after onAppear")
    }

    func testOpenSettingsTriggersURL() {
        let powerManager = PowerStateManager()
        let idleManager = IdleTimerManager(powerManager: powerManager)
        let viewModel = ContentViewModel(powerManager: powerManager, idleManager: idleManager)
        var openedURL: URL?

        viewModel.openURLAction = { url in
            openedURL = url
        }

        viewModel.openSettings()

        XCTAssertEqual(openedURL?.absoluteString, "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func testResetTimerDelegatesToIdleManager() {
        let powerManager = PowerStateManager()
        let idleManager = IdleTimerManager(powerManager: powerManager)
        let viewModel = ContentViewModel(powerManager: powerManager, idleManager: idleManager)

        idleManager.timeRemaining = 10
        viewModel.resetTimer()

        XCTAssertEqual(idleManager.timeRemaining, idleManager.workThreshold, "Reset timer should restore workThreshold")
    }
}
