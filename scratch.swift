import Foundation
import AppKit
import IOKit.ps

@MainActor
final class PowerStateManager {
    var isLowPower: Bool = false
    var isSleeping: Bool = false
    
    nonisolated private let notificationCenter: NotificationCenter
    nonisolated(unsafe) private var powerSourceRunLoopSource: CFRunLoopSource?
    
    init(notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        self.notificationCenter = notificationCenter
        setupSleepWakeNotifications()
        setupPowerSourceNotifications()
        updateBatteryState()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }
    
    private func setupSleepWakeNotifications() {
        notificationCenter.addObserver(self, selector: #selector(handleSleep), name: NSWorkspace.willSleepNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
    }
    
    @objc private func handleSleep() {
        isSleeping = true
    }
    
    @objc private func handleWake() {
        isSleeping = false
        updateBatteryState()
    }
    
    private func setupPowerSourceNotifications() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let runLoopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let manager = Unmanaged<PowerStateManager>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                manager.updateBatteryState()
            }
        }, context).takeRetainedValue()
        
        self.powerSourceRunLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
    }
    
    func updateBatteryState() {
        let timeRemaining = IOPSGetTimeRemainingEstimate()
        let isPlugged = timeRemaining == kIOPSTimeRemainingUnlimited
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        var lowBattery = false
        for ps in sources {
            guard let infoRaw = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() else {
                continue
            }
            if let info = infoRaw as? [String: Any],
               let current = info[kIOPSCurrentCapacityKey] as? Int,
               let max = info[kIOPSMaxCapacityKey] as? Int {
                let percent = Double(current) / Double(max)
                if percent < 0.20 {
                    lowBattery = true
                }
            }
        }
        isLowPower = !isPlugged && lowBattery
    }
}
