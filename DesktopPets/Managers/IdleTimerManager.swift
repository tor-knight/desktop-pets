import Foundation
import AppKit

@Observable
@MainActor
final class IdleTimerManager {
    var shouldShowOverlay: Bool = false
    var isUsingAbsoluteTimer: Bool = false
    var mockPermission: Bool?
    private var powerManager: PowerStateManager
    private var timer: Timer?
    private var globalMonitor: Any?
    private var lastActivity: Date = Date()
    private let idleThreshold: TimeInterval = 45 * 60 // 45 minutes
    
    init(powerManager: PowerStateManager) {
        self.powerManager = powerManager
    }
    
    private var hasAccessibilityPermission: Bool {
        if let mock = mockPermission { return mock }
        return AXIsProcessTrusted()
    }
    
    func startMonitoring() {
        if hasAccessibilityPermission {
            setupGlobalMonitor()
            isUsingAbsoluteTimer = false
        } else {
            setupAbsoluteTimer()
            isUsingAbsoluteTimer = true
        }
    }
    
    private func setupGlobalMonitor() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .any) { [weak self] _ in
            self?.resetIdle()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }
    
    private func setupAbsoluteTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: idleThreshold, repeats: true) { [weak self] _ in
            self?.triggerOverlay()
        }
    }
    
    private func resetIdle() {
        lastActivity = Date()
    }
    
    func checkIdleState() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        
        let now = Date()
        if hasSignificantTimeDrift(lastCheck: lastActivity) {
            // Drift detected (e.g. slept for hours), reset idle
            resetIdle()
            return
        }
        if now.timeIntervalSince(lastActivity) >= idleThreshold {
            triggerOverlay()
        }
    }
    
    func hasSignificantTimeDrift(lastCheck: Date) -> Bool {
        let diff = Date().timeIntervalSince(lastCheck)
        return diff > (idleThreshold + 300) // More than threshold + 5 mins
    }
    
    func triggerOverlay() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        shouldShowOverlay = true
        timer?.invalidate()
    }
    
    func dismissOverlay() {
        shouldShowOverlay = false
        resetIdle()
        startMonitoring()
    }
}
