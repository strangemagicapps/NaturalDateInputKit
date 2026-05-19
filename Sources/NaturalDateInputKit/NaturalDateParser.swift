import Foundation
import RegexBuilder

public struct NaturalDateParser: Sendable {
    public var calendar: Calendar
    public var locale: Locale

    public init(
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.calendar = calendar
        self.locale = locale
    }

    public func parse(
        _ string: String,
        relativeTo reference: Date = .now
    ) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        if let relative = parseRelativeDay(trimmed, relativeTo: reference) {
            return relative
        }

        if let manual = parseOtherPatterns(trimmed, relativeTo: reference) {
            return manual
        }

        if let detected = parseWithDataDetector(string) {
            return ensureFuture(detected, relativeTo: reference)
        }

        return nil
    }

    // MARK: - Localised names

    private var localisedNames: LocalisedDateNames {
        LocalisedDateNames(locale: locale, calendar: calendar)
    }

    // MARK: - Relative day keywords

    private func parseRelativeDay(_ text: String, relativeTo reference: Date) -> Date? {
        let today = ["today", "now", "heute", "aujourd'hui", "hoy", "oggi", "今日"]
        let tomorrow = ["tomorrow", "morgen", "demain", "mañana", "domani", "明日"]
        let yesterday = ["yesterday", "gestern", "hier", "ayer", "ieri", "昨日"]

        let startOfReferenceDay = calendar.startOfDay(for: reference)

        if today.contains(text) {
            return startOfReferenceDay
        }
        if tomorrow.contains(text) {
            return calendar.date(byAdding: .day, value: 1, to: startOfReferenceDay)
        }
        if yesterday.contains(text) {
            return calendar.date(byAdding: .day, value: -1, to: startOfReferenceDay)
        }
        return nil
    }

    // MARK: - Other manual patterns

    private func parseOtherPatterns(_ text: String, relativeTo reference: Date) -> Date? {
        if let (weekday, time) = parseWeekdayWithTime(from: text),
           let date = nextOccurrence(of: weekday, after: reference),
           let withTime = applyTime(time, to: date) {
            return withTime
        }

        if let weekday = parseWeekday(from: text),
           let date = nextOccurrence(of: weekday, after: reference) {
            return date
        }

        if let (month, day, time) = parseMonthDayTime(from: text),
           let date = nextOccurrence(of: month, day: day, after: reference),
           let withTime = applyTime(time, to: date) {
            return withTime
        }

        if let (month, day) = parseMonthDay(from: text),
           let date = nextOccurrence(of: month, day: day, after: reference) {
            return date
        }

        return nil
    }

    // MARK: - NSDataDetector fallback

    private func parseWithDataDetector(_ text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, options: [], range: range).first?.date
    }

    // MARK: - Future adjustment

    private func ensureFuture(_ date: Date, relativeTo reference: Date) -> Date {
        if date > reference { return date }
        if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: date),
           nextWeek > reference {
            return nextWeek
        }
        if let nextYear = calendar.date(byAdding: .year, value: 1, to: date),
           nextYear > reference {
            return nextYear
        }
        return date
    }

    // MARK: - Weekday parsing

    private func parseWeekday(from text: String) -> Int? {
        let names = localisedNames
        var cleaned = text
        for prefix in names.nextPrefixes where cleaned.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespaces)
            break
        }
        return names.weekdays[cleaned]
    }

    private func parseWeekdayWithTime(from text: String) -> (weekday: Int, time: String)? {
        let names = localisedNames
        let pattern = "(?i)^(\(names.nextPrefixPattern)\(names.weekdayPattern))\\s+(.+)$"
        guard let regex = try? Regex(pattern),
              let match = text.firstMatch(of: regex),
              let weekdaySubstring = match.output[1].substring,
              let timeSubstring = match.output[2].substring,
              let weekday = parseWeekday(from: String(weekdaySubstring).lowercased())
        else { return nil }
        return (weekday, String(timeSubstring))
    }

    // MARK: - Month/day parsing

    private func parseMonthDay(from text: String) -> (month: Int, day: Int)? {
        let names = localisedNames

        let pattern1 = "(?i)^(\(names.monthPattern))\\s+(\\d{1,2})(?:st|nd|rd|th)?$"
        if let regex = try? Regex(pattern1),
           let match = text.firstMatch(of: regex),
           let monthSubstring = match.output[1].substring,
           let daySubstring = match.output[2].substring,
           let month = names.months[String(monthSubstring).lowercased()],
           let day = Int(daySubstring) {
            return (month, day)
        }

        let pattern2 = "(?i)^(\\d{1,2})(?:st|nd|rd|th)?\\.?\\s+(\(names.monthPattern))$"
        if let regex = try? Regex(pattern2),
           let match = text.firstMatch(of: regex),
           let daySubstring = match.output[1].substring,
           let monthSubstring = match.output[2].substring,
           let month = names.months[String(monthSubstring).lowercased()],
           let day = Int(daySubstring) {
            return (month, day)
        }

        return nil
    }

    private func parseMonthDayTime(from text: String) -> (month: Int, day: Int, time: String)? {
        let names = localisedNames
        let pattern =
            "(?i)^(?:(\\d{1,2})(?:st|nd|rd|th)?\\.?\\s+(\(names.monthPattern))|(\(names.monthPattern))\\s+(\\d{1,2})(?:st|nd|rd|th)?)\\s+(.+)$"

        guard let regex = try? Regex(pattern),
              let match = text.firstMatch(of: regex),
              let timeSubstring = match.output[5].substring
        else { return nil }
        let time = String(timeSubstring)

        if let daySubstring = match.output[1].substring,
           let monthSubstring = match.output[2].substring,
           let day = Int(daySubstring),
           let month = names.months[String(monthSubstring).lowercased()] {
            return (month, day, time)
        }

        if let monthSubstring = match.output[3].substring,
           let daySubstring = match.output[4].substring,
           let month = names.months[String(monthSubstring).lowercased()],
           let day = Int(daySubstring) {
            return (month, day, time)
        }

        return nil
    }

    // MARK: - Next occurrence

    private func nextOccurrence(of weekday: Int, after reference: Date) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: reference)
        var daysToAdd = weekday - currentWeekday
        if daysToAdd <= 0 { daysToAdd += 7 }
        return calendar.date(byAdding: .day, value: daysToAdd, to: calendar.startOfDay(for: reference))
    }

    private func nextOccurrence(of month: Int, day: Int, after reference: Date) -> Date? {
        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = calendar.component(.year, from: reference)

        guard var date = calendar.date(from: components) else { return nil }
        if date <= reference {
            components.year = (components.year ?? 0) + 1
            date = calendar.date(from: components) ?? date
        }
        return date
    }

    // MARK: - Time application

    private func applyTime(_ timeString: String, to date: Date) -> Date? {
        let timeRegex = Regex {
            Anchor.startOfSubject
            Capture { Repeat(1...2) { .digit } }
            Optionally {
                ":"
                Capture { Repeat(count: 2) { .digit } }
            }
            ZeroOrMore(.whitespace)
            Optionally {
                Capture {
                    ChoiceOf { "am"; "pm"; "a.m."; "p.m." }
                }
            }
            Anchor.endOfSubject
        }
        .ignoresCase()

        guard let match = timeString.wholeMatch(of: timeRegex),
              var hour = Int(match.output.1)
        else { return nil }

        var minute = 0
        if let minuteMatch = match.output.2 {
            minute = Int(minuteMatch) ?? 0
        }

        if let period = match.output.3 {
            let normalized = period.lowercased().replacing(".", with: "")
            if normalized == "pm" && hour < 12 {
                hour += 12
            } else if normalized == "am" && hour == 12 {
                hour = 0
            }
        } else if hour >= 1 && hour <= 12 {
            if hour < 12 { hour += 12 }
        }

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }
}
