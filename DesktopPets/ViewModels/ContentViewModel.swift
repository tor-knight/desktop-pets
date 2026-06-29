import SwiftUI
import Observation

@Observable
@MainActor
final class ContentViewModel {
    let powerManager: PowerStateManager
    let idleManager: IdleTimerManager
    
    var isPermissionsGranted: Bool = false
    
    // Dependencies for testing
    var openURLAction: (URL) -> Void = { NSWorkspace.shared.open($0) }
    var isProcessTrustedAction: () -> Bool = { AXIsProcessTrusted() }
    
    init(powerManager: PowerStateManager? = nil, idleManager: IdleTimerManager? = nil) {
        let pm = powerManager ?? PowerStateManager()
        self.powerManager = pm
        self.idleManager = idleManager ?? IdleTimerManager(powerManager: pm)
    }
    
    func checkPermissions() {
        isPermissionsGranted = isProcessTrustedAction()
    }
    
    func openSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        openURLAction(url)
    }
    
    func onAppear() {
        checkPermissions()
        idleManager.startMonitoring()
    }
}
