import Foundation
import Testing
@testable import NaturalDateInputKit

@Suite("NaturalDateParser")
struct NaturalDateParserTests {

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static let locale = Locale(identifier: "en_US_POSIX")

    /// 2026-05-13 12:00 UTC — a Wednesday.
    static let reference: Date = date(2026, 5, 13, hour: 12)

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        DateComponents(
            calendar: calendar,
            year: year, month: month, day: day,
            hour: hour, minute: minute
        ).date!
    }

    /// Build a `DateComponents` with year/month/day always set and
    /// hour/minute only when explicitly provided — matching what the parser
    /// returns when a time is or isn't detected.
    static func day(_ year: Int, _ month: Int, _ day: Int, hour: Int? = nil, minute: Int? = nil) -> DateComponents {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        if hour != nil || minute != nil {
            c.hour = hour ?? 0
            c.minute = minute ?? 0
        }
        return c
    }

    private var parser: NaturalDateParser {
        NaturalDateParser(calendar: Self.calendar, locale: Self.locale)
    }

    // MARK: - Relative day keywords

    @Test func `parses today`() {
        #expect(parser.parse("today", relativeTo: Self.reference) == Self.day(2026, 5, 13))
    }

    @Test func `parses tomorrow`() {
        #expect(parser.parse("tomorrow", relativeTo: Self.reference) == Self.day(2026, 5, 14))
    }

    @Test func `parses yesterday`() {
        #expect(parser.parse("yesterday", relativeTo: Self.reference) == Self.day(2026, 5, 12))
    }

    @Test(arguments: ["TODAY", "Today", "  today  ", "ToDay"])
    func `relative day is case and whitespace insensitive`(_ input: String) {
        #expect(parser.parse(input, relativeTo: Self.reference) == Self.day(2026, 5, 13))
    }

    // MARK: - Weekday names (default: prefersFuture == false)

    @Test func `same weekday returns today by default`() {
        // Wednesday parsed on Wednesday → today
        #expect(parser.parse("Wednesday", relativeTo: Self.reference) == Self.day(2026, 5, 13))
    }

    @Test func `upcoming weekday returns this week's occurrence`() {
        // Friday after Wed 5/13 → 5/15
        #expect(parser.parse("Friday", relativeTo: Self.reference) == Self.day(2026, 5, 15))
    }

    @Test func `past weekday returns this week's occurrence by default`() {
        // Monday earlier in the same week as Wed 5/13 → 5/11
        #expect(parser.parse("Monday", relativeTo: Self.reference) == Self.day(2026, 5, 11))
    }

    @Test func `next-prefixed weekday`() {
        #expect(parser.parse("next Friday", relativeTo: Self.reference) == Self.day(2026, 5, 15))
    }

    @Test(arguments: ["FRIDAY", "Friday", "friday", "FrIdAy"])
    func `weekday is case insensitive`(_ input: String) {
        #expect(parser.parse(input, relativeTo: Self.reference) == Self.day(2026, 5, 15))
    }

    @Test func `short weekday name`() {
        // "Fri" should resolve via short weekday symbols
        #expect(parser.parse("Fri", relativeTo: Self.reference) == Self.day(2026, 5, 15))
    }

    // MARK: - Weekday names with prefersFuture: true

    @Test func `same weekday wraps to next week when prefersFuture is true`() {
        #expect(parser.parse("Wednesday", relativeTo: Self.reference, prefersFuture: true) == Self.day(2026, 5, 20))
    }

    @Test func `past weekday wraps forward when prefersFuture is true`() {
        #expect(parser.parse("Monday", relativeTo: Self.reference, prefersFuture: true) == Self.day(2026, 5, 18))
    }

    @Test func `upcoming weekday is unaffected by prefersFuture`() {
        #expect(parser.parse("Friday", relativeTo: Self.reference, prefersFuture: true) == Self.day(2026, 5, 15))
    }

    @Test func `relative day keywords ignore prefersFuture`() {
        // "today" / "tomorrow" / "yesterday" are anchored to the reference date.
        #expect(parser.parse("today", relativeTo: Self.reference, prefersFuture: true) == Self.day(2026, 5, 13))
        #expect(parser.parse("yesterday", relativeTo: Self.reference, prefersFuture: true) == Self.day(2026, 5, 12))
    }

    // MARK: - Misses

    @Test func `unparseable input returns nil`() {
        #expect(parser.parse("banana", relativeTo: Self.reference) == nil)
    }

    @Test func `empty string returns nil`() {
        #expect(parser.parse("", relativeTo: Self.reference) == nil)
        #expect(parser.parse("   ", relativeTo: Self.reference) == nil)
    }
}
