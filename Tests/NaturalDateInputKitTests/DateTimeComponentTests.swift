import Foundation
import Testing
@testable import NaturalDateInputKit

@Suite("Date.hasTimeComponent")
struct DateTimeComponentTests {

    // `hasTimeComponent` reads via `Calendar.current`, so we build fixtures
    // with the same calendar to stay timezone-agnostic.
    private static let calendar = Calendar.current

    private static func date(hour: Int, minute: Int) -> Date {
        let midnight = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: midnight)!
    }

    @Test func `midnight has no time component`() {
        #expect(Self.date(hour: 0, minute: 0).hasTimeComponent == false)
    }

    @Test func `non-zero hour has time component`() {
        #expect(Self.date(hour: 9, minute: 0).hasTimeComponent == true)
    }

    @Test func `non-zero minute has time component`() {
        #expect(Self.date(hour: 0, minute: 30).hasTimeComponent == true)
    }

    @Test func `hour and minute has time component`() {
        #expect(Self.date(hour: 14, minute: 45).hasTimeComponent == true)
    }
}
