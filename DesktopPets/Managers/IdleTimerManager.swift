import Foundation
import AppKit

@Observable
@MainActor
final class IdleTimerManager {
    var shouldShowOverlay: Bool = false
    var isUsingAbsoluteTimer: Bool = false
    var mockPermission: Bool?
    private var powerManager: PowerStateManager
    nonisolated(unsafe) private var timer: Timer?
    nonisolated(unsafe) private var globalMonitor: Any?
    nonisolated(unsafe) private var localMonitor: Any?
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
        timer?.invalidate()
        if hasAccessibilityPermission {
            setupGlobalMonitor()
            isUsingAbsoluteTimer = false
        } else {
            setupAbsoluteTimer()
            isUsingAbsoluteTimer = true
        }
    }
    
    private func setupGlobalMonitor() {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .any) { [weak self] _ in
            self?.resetIdle()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .any) { [weak self] event in
            self?.resetIdle()
            return event
        }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdleState()
            }
        }
    }
    
    private func setupAbsoluteTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: idleThreshold, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.triggerOverlay()
            }
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
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    deinit {
        let currentTimer = timer
        let currentGlobal = globalMonitor
        let currentLocal = localMonitor
        
        Task { @MainActor in
            currentTimer?.invalidate()
            if let g = currentGlobal { NSEvent.removeMonitor(g) }
            if let l = currentLocal { NSEvent.removeMonitor(l) }
        }
    }
}
