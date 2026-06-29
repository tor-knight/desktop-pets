import XCTest
@testable import DesktopPets

@MainActor
final class ContentViewModelTests: XCTestCase {
    
    func testOnAppearChecksPermissions() {
        let powerManager = PowerStateManager()
        let idleManager = IdleTimerManager(powerManager: powerManager)
        let viewModel = ContentViewModel(powerManager: powerManager, idleManager: idleManager)
        
        // Mock permission to true
        viewModel.isProcessTrustedAction = { true }
        
        XCTAssertFalse(viewModel.isPermissionsGranted, "Should initially be false")
        
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
}
