//
//  LocalisedDateNames.swift
//  NaturalDateInputKit
//
//  Created by Scott Matthewman on 19/05/2026.
//

import Foundation

struct LocalisedDateNames: Sendable {
    let weekdays: [String: Int]
    let months: [String: Int]
    let weekdayPattern: String
    let monthPattern: String
    let nextPrefixes: [String]
    let nextPrefixPattern: String

    nonisolated init(locale: Locale, calendar: Calendar) {
        var cal = calendar
        cal.locale = locale

        var weekdayLookup: [String: Int] = [:]
        var weekdayNames: [String] = []

        let fullWeekdays = cal.weekdaySymbols
        let shortWeekdays = cal.shortWeekdaySymbols
        let veryShortWeekdays = cal.veryShortWeekdaySymbols

        for (index, name) in fullWeekdays.enumerated() {
            let weekdayIndex = index + 1
            weekdayLookup[name.lowercased()] = weekdayIndex
            weekdayNames.append(name.regexEscaped)
        }

        for (index, name) in shortWeekdays.enumerated() {
            weekdayLookup[name.lowercased()] = index + 1
            let cleaned = name.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            if cleaned != name {
                weekdayLookup[cleaned.lowercased()] = index + 1
            }
            weekdayNames.append(name.regexEscaped)
            if cleaned != name {
                weekdayNames.append(cleaned.regexEscaped)
            }
        }

        for (index, name) in veryShortWeekdays.enumerated() {
            weekdayLookup[name.lowercased()] = index + 1
        }

        var monthLookup: [String: Int] = [:]
        var monthNames: [String] = []

        let fullMonths = cal.monthSymbols
        let shortMonths = cal.shortMonthSymbols

        for (index, name) in fullMonths.enumerated() {
            let monthIndex = index + 1
            monthLookup[name.lowercased()] = monthIndex
            monthNames.append(name.regexEscaped)
        }

        for (index, name) in shortMonths.enumerated() {
            monthLookup[name.lowercased()] = index + 1
            let cleaned = name.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            if cleaned != name {
                monthLookup[cleaned.lowercased()] = index + 1
            }
            monthNames.append(name.regexEscaped)
            if cleaned != name {
                monthNames.append(cleaned.regexEscaped)
            }
        }

        self.weekdays = weekdayLookup
        self.months = monthLookup

        self.weekdayPattern = "(?:" + weekdayNames.sorted { $0.count > $1.count }.joined(separator: "|") + ")"
        self.monthPattern = "(?:" + monthNames.sorted { $0.count > $1.count }.joined(separator: "|") + ")"

        self.nextPrefixes = [
            "next ", "nächsten ", "nächste ", "prochain ", "prochaine ",
            "próximo ", "próxima ", "prossimo ", "prossima ",
            "volgende ", "nästa ", "neste ", "næste ", "来週の",
        ]

        self.nextPrefixPattern = "(?:" + nextPrefixes.map { $0.regexEscaped }.joined(separator: "|") + ")?"
    }
}
