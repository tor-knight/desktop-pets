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

    // Configurable work interval and idle threshold
    var workThreshold: TimeInterval = 45 * 60 // Default 45 minutes
    var idleThreshold: TimeInterval = 5 * 60  // 5 minutes of system idle resets timer
    var timeRemaining: TimeInterval = 45 * 60

    private var lastCheckTime: Date?

    init(powerManager: PowerStateManager) {
        self.powerManager = powerManager
    }

    func startMonitoring() {
        timer?.invalidate()
        lastCheckTime = Date()
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

        let now = Date()
        if let last = lastCheckTime, hasSignificantTimeDrift(lastCheck: last) {
            // System woke from sleep or clock adjusted, reset timer safely
            lastCheckTime = now
            resetTimer()
            return
        }
        lastCheckTime = now

        // System idle checking
        let inactiveTime: TimeInterval
        if let mockPerm = mockPermission, !mockPerm {
            // Mock accessibility/CGEvent permission denied
            isUsingAbsoluteTimer = true
            inactiveTime = 0
        } else {
            inactiveTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: 0xFFFFFFFF)!)
        }

        // If user is idle for more than idleThreshold (e.g., 5 min), reset work timer
        if inactiveTime > idleThreshold {
            timeRemaining = workThreshold
            return
        }

        // Count down work timer
        if timeRemaining > 0 {
            timeRemaining -= 1.0
        }

        if timeRemaining <= 0 && !shouldShowOverlay {
            triggerOverlay()
        }
    }

    func checkIdleState() {
        tick()
    }

    func hasSignificantTimeDrift(lastCheck: Date) -> Bool {
        let elapsed = Date().timeIntervalSince(lastCheck)
        // If elapsed real time exceeds 10 seconds between 1-second ticks, system slept/drifted
        return elapsed > 10.0 || elapsed < 0
    }

    func triggerOverlay() {
        guard !powerManager.isSleeping, !powerManager.isLowPower else { return }
        shouldShowOverlay = true
        timer?.invalidate()
    }

    func dismissOverlay() {
        shouldShowOverlay = false
        resetTimer()
        startMonitoring()
    }

    func resetTimer() {
        timeRemaining = workThreshold
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
