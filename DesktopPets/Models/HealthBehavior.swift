import Foundation
import SwiftData

@Model
final class HealthBehavior {
    var timestamp: Date
    var eventType: String
    var actionResult: String
    var durationSec: Int
    
    init(timestamp: Date = .now, eventType: String, actionResult: String, durationSec: Int) {
        self.timestamp = timestamp
        self.eventType = eventType
        self.actionResult = actionResult
        self.durationSec = durationSec
    }
}
