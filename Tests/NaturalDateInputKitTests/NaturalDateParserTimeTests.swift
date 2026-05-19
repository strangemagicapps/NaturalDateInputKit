import Foundation
import Testing
@testable import NaturalDateInputKit

@Suite("NaturalDateParser time detection")
struct NaturalDateParserTimeTests {
    typealias Base = NaturalDateParserTests

    private var parser: NaturalDateParser {
        NaturalDateParser(calendar: Base.calendar, locale: Base.locale)
    }

    // MARK: - Bare time

    @Test func `bare am-pm time uses reference day`() {
        // "3pm" on 2026-05-13 → 2026-05-13 15:00
        #expect(parser.parse("3pm", relativeTo: Base.reference) == Base.day(2026, 5, 13, hour: 15))
    }

    @Test func `bare 24-hour time uses reference day`() {
        #expect(parser.parse("15:30", relativeTo: Base.reference) == Base.day(2026, 5, 13, hour: 15, minute: 30))
    }

    @Test func `bare 12-hour time with minutes`() {
        #expect(parser.parse("9:15 am", relativeTo: Base.reference) == Base.day(2026, 5, 13, hour: 9, minute: 15))
    }

    @Test func `bare integer is not interpreted as time`() {
        // "3" has no colon or am/pm marker — should not silently become 15:00.
        #expect(parser.parse("3", relativeTo: Base.reference) == nil)
    }

    // MARK: - Relative day + time

    @Test func `today with time`() {
        #expect(parser.parse("today 3pm", relativeTo: Base.reference) == Base.day(2026, 5, 13, hour: 15))
    }

    @Test func `today at time`() {
        #expect(parser.parse("today at 9:30 am", relativeTo: Base.reference) == Base.day(2026, 5, 13, hour: 9, minute: 30))
    }

    @Test func `tomorrow at time`() {
        #expect(parser.parse("tomorrow at 9am", relativeTo: Base.reference) == Base.day(2026, 5, 14, hour: 9))
    }

    @Test func `yesterday with 24-hour time`() {
        #expect(parser.parse("yesterday 17:00", relativeTo: Base.reference) == Base.day(2026, 5, 12, hour: 17))
    }

    // MARK: - Weekday + time

    @Test func `weekday with time uses this week's occurrence`() {
        // Friday 3pm on Wed 5/13 → 2026-05-15 15:00
        #expect(parser.parse("Friday 3pm", relativeTo: Base.reference) == Base.day(2026, 5, 15, hour: 15))
    }

    @Test func `weekday with at-connector`() {
        #expect(parser.parse("Friday at 3pm", relativeTo: Base.reference) == Base.day(2026, 5, 15, hour: 15))
    }

    @Test func `next-prefixed weekday with at-connector`() {
        #expect(parser.parse("next Friday at 9am", relativeTo: Base.reference) == Base.day(2026, 5, 15, hour: 9))
    }
}
