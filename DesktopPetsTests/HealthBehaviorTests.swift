import XCTest
import SwiftData
@testable import DesktopPets

@MainActor
final class HealthBehaviorTests: XCTestCase {

    func testHealthBehaviorInitialization() {
        let now = Date()
        let record = HealthBehavior(timestamp: now, eventType: "stand_up", actionResult: "completed", durationSec: 300)

        XCTAssertEqual(record.timestamp, now)
        XCTAssertEqual(record.eventType, "stand_up")
        XCTAssertEqual(record.actionResult, "completed")
        XCTAssertEqual(record.durationSec, 300)
    }

    func testHealthBehaviorDefaultTimestamp() {
        let record = HealthBehavior(eventType: "stretch", actionResult: "skipped", durationSec: 0)

        XCTAssertEqual(record.eventType, "stretch")
        XCTAssertEqual(record.actionResult, "skipped")
        XCTAssertEqual(record.durationSec, 0)
        XCTAssertLessThanOrEqual(record.timestamp.timeIntervalSinceNow, 1.0)
    }

    func testSwiftDataPersistence() throws {
        let container = try ModelContainer(for: HealthBehavior.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext

        let record = HealthBehavior(eventType: "test_event", actionResult: "passed", durationSec: 60)
        context.insert(record)

        let descriptor = FetchDescriptor<HealthBehavior>()
        let results = try context.fetch(descriptor)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.eventType, "test_event")
    }
}
