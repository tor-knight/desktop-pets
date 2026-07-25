import SwiftUI
import Observation
import AppKit

@Observable
@MainActor
final class ContentViewModel {
    let powerManager: PowerStateManager
    let idleManager: IdleTimerManager

    var isPermissionsGranted: Bool = false
    var isProcessTrustedAction: () -> Bool = { AXIsProcessTrusted() }
    var openURLAction: (URL) -> Void = { NSWorkspace.shared.open($0) }

    init(powerManager: PowerStateManager? = nil, idleManager: IdleTimerManager? = nil) {
        let pm = powerManager ?? PowerStateManager()
        self.powerManager = pm
        self.idleManager = idleManager ?? IdleTimerManager(powerManager: pm)
    }

    func onAppear() {
        idleManager.startMonitoring()
        checkPermissions()
    }

    func checkPermissions() {
        isPermissionsGranted = isProcessTrustedAction()
    }

    func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            openURLAction(url)
        }
    }

    func resetTimer() {
        idleManager.resetTimer()
    }
}
