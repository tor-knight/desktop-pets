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
    var timeRemaining: TimeInterval = 45 * 60
    
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
        setupTickTimer()
    }
    
    private func setupAbsoluteTimer() {
        setupTickTimer()
    }
    
    private func setupTickTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func resetIdle() {
        lastActivity = Date()
    }
    
    func tick() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        
        let now = Date()
        let inactiveTime = now.timeIntervalSince(lastActivity)
        
        // If the user has been inactive for more than 5 minutes (e.g. walked away),
        // we consider it a break and reset the 45-minute work timer.
        if inactiveTime > 5 * 60 {
            timeRemaining = idleThreshold
            return
        }
        
        // Otherwise, they are working. Count down the time.
        timeRemaining -= 1.0
        
        if timeRemaining <= 0 {
            triggerOverlay()
        }
    }
    
    func checkIdleState() {
        tick()
    }
    
    func hasSignificantTimeDrift(lastCheck: Date) -> Bool {
        return false // Handled in tick() directly now
    }
    
    func triggerOverlay() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        shouldShowOverlay = true
        timer?.invalidate()
    }
    
    func dismissOverlay() {
        shouldShowOverlay = false
        timeRemaining = idleThreshold
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
