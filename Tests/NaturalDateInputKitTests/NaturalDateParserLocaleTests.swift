import Foundation
import Testing
@testable import NaturalDateInputKit

@Suite("NaturalDateParser locale variants")
struct NaturalDateParserLocaleTests {
    typealias Base = NaturalDateParserTests

    private func parser(_ localeID: String) -> NaturalDateParser {
        var calendar = Base.calendar
        let locale = Locale(identifier: localeID)
        calendar.locale = locale
        return NaturalDateParser(calendar: calendar, locale: locale)
    }

    // MARK: - German

    @Test func `German relative days`() {
        let p = parser("de_DE")
        #expect(p.parse("heute", relativeTo: Base.reference) == Base.day(2026, 5, 13))
        #expect(p.parse("morgen", relativeTo: Base.reference) == Base.day(2026, 5, 14))
        #expect(p.parse("gestern", relativeTo: Base.reference) == Base.day(2026, 5, 12))
    }

    @Test func `German weekday`() {
        let p = parser("de_DE")
        #expect(p.parse("Freitag", relativeTo: Base.reference) == Base.day(2026, 5, 15))
    }

    @Test func `German next-prefixed weekday`() {
        let p = parser("de_DE")
        #expect(p.parse("nächsten Freitag", relativeTo: Base.reference) == Base.day(2026, 5, 15))
    }

    // MARK: - French

    @Test func `French relative days`() {
        let p = parser("fr_FR")
        #expect(p.parse("aujourd'hui", relativeTo: Base.reference) == Base.day(2026, 5, 13))
        #expect(p.parse("demain", relativeTo: Base.reference) == Base.day(2026, 5, 14))
        #expect(p.parse("hier", relativeTo: Base.reference) == Base.day(2026, 5, 12))
    }

    @Test func `French weekday`() {
        let p = parser("fr_FR")
        #expect(p.parse("vendredi", relativeTo: Base.reference) == Base.day(2026, 5, 15))
    }

    // MARK: - Spanish

    @Test func `Spanish relative days`() {
        let p = parser("es_ES")
        #expect(p.parse("hoy", relativeTo: Base.reference) == Base.day(2026, 5, 13))
        #expect(p.parse("mañana", relativeTo: Base.reference) == Base.day(2026, 5, 14))
        #expect(p.parse("ayer", relativeTo: Base.reference) == Base.day(2026, 5, 12))
    }

    @Test func `Spanish weekday`() {
        let p = parser("es_ES")
        #expect(p.parse("viernes", relativeTo: Base.reference) == Base.day(2026, 5, 15))
    }

    // MARK: - Italian

    @Test func `Italian relative days`() {
        let p = parser("it_IT")
        #expect(p.parse("oggi", relativeTo: Base.reference) == Base.day(2026, 5, 13))
        #expect(p.parse("domani", relativeTo: Base.reference) == Base.day(2026, 5, 14))
        #expect(p.parse("ieri", relativeTo: Base.reference) == Base.day(2026, 5, 12))
    }

    @Test func `Italian weekday`() {
        let p = parser("it_IT")
        #expect(p.parse("venerdì", relativeTo: Base.reference) == Base.day(2026, 5, 15))
    }
}
