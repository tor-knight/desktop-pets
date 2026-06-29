import Foundation
import AppKit
import IOKit.ps

@Observable
@MainActor
final class PowerStateManager {
    var isLowPower: Bool = false
    var isSleeping: Bool = false
    
    init() {
        setupSleepWakeNotifications()
        updateBatteryState()
    }
    
    private func setupSleepWakeNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleSleep), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
    }
    
    @objc private func handleSleep() {
        isSleeping = true
    }
    
    @objc private func handleWake() {
        isSleeping = false
        updateBatteryState()
    }
    
    func updateBatteryState() {
        let timeRemaining = IOPSGetTimeRemainingEstimate()
        let isPlugged = timeRemaining == kIOPSTimeRemainingUnlimited
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        var lowBattery = false
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: Any]
            if let current = info[kIOPSCurrentCapacityKey] as? Int, let max = info[kIOPSMaxCapacityKey] as? Int {
                let percent = Double(current) / Double(max)
                if percent < 0.20 {
                    lowBattery = true
                }
            }
        }
        isLowPower = !isPlugged && lowBattery
    }
}
