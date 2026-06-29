import Foundation
import SwiftData
import Observation

@MainActor
@Observable
class PetViewModel {
    var holdProgress: CGFloat = 0
    private var timer: Timer?
    var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func startHold() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.holdProgress < 1.0 {
                    self.holdProgress += 0.02
                }
            }
        }
    }
    
    func endHold() {
        timer?.invalidate()
        timer = nil
        if holdProgress >= 0.95 {
            holdProgress = 1.0
        } else {
            holdProgress = 0
        }
    }
    
    func recordAction(result: String) {
        guard let context = modelContext else { return }
        let record = HealthBehavior(eventType: "stand_up", actionResult: result, durationSec: 0)
        context.insert(record)
    }
    
    func onDisappear() {
        timer?.invalidate()
        timer = nil
    }
}
