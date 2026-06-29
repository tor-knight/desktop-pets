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
    var isProcessTrustedAction: () -> Bool = {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    init(powerManager: PowerStateManager? = nil, idleManager: IdleTimerManager? = nil) {
        let pm = powerManager ?? PowerStateManager()
        self.powerManager = pm
        self.idleManager = idleManager ?? IdleTimerManager(powerManager: pm)
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkPermissions()
        }
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
