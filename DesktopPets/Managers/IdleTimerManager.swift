import Foundation
import AppKit

@Observable
@MainActor
final class IdleTimerManager {
    var shouldShowOverlay: Bool = false
    var isUsingAbsoluteTimer: Bool = false // Kept for API compatibility if needed, though no longer relevant
    var mockPermission: Bool?
    private var powerManager: PowerStateManager
    nonisolated(unsafe) private var timer: Timer?
    private let idleThreshold: TimeInterval = 45 * 60 // 45 minutes
    var timeRemaining: TimeInterval = 45 * 60
    
    init(powerManager: PowerStateManager) {
        self.powerManager = powerManager
    }
    
    func startMonitoring() {
        timer?.invalidate()
        setupTickTimer()
    }
    
    private func setupTickTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    func tick() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        
        // Use macOS built-in CGEventSource to get the exact idle time across the entire system.
        // 0xFFFFFFFF represents all event types (.any).
        let inactiveTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: 0xFFFFFFFF)!)
        
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
    
    func triggerOverlay() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        shouldShowOverlay = true
        timer?.invalidate()
    }
    
    func dismissOverlay() {
        shouldShowOverlay = false
        timeRemaining = idleThreshold
        startMonitoring()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        let currentTimer = timer
        Task { @MainActor in
            currentTimer?.invalidate()
        }
    }
}
