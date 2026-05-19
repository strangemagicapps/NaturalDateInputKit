import Foundation
import RegexBuilder

/// Parses natural-language date and time expressions ("tomorrow", "next Friday at 9am",
/// "7 April", "15:30") into a ``Foundation/DateComponents`` value the caller can resolve
/// to a ``Foundation/Date``.
///
/// The parser is intentionally lossy about what it didn't see: ``parse(_:relativeTo:prefersFuture:)``
/// returns components containing `year`, `month`, and `day`, with `hour` and `minute`
/// populated **only** when the input explicitly mentions a time. This lets callers apply
/// their own default time (e.g. 09:00 for a calendar app) without guessing whether the
/// user provided one.
public struct NaturalDateParser: Sendable {
    /// The calendar used for all date arithmetic (week boundaries, month/year wrapping,
    /// component extraction). Defaults to ``Foundation/Calendar/current``.
    public var calendar: Calendar

    /// The locale used to recognise localised weekday and month names. Defaults to
    /// ``Foundation/Locale/current``.
    public var locale: Locale

    /// Creates a parser bound to the given calendar and locale.
    ///
    /// - Parameters:
    ///   - calendar: Calendar used for all date arithmetic. Defaults to `.current`.
    ///   - locale: Locale used to recognise localised weekday and month names. Defaults to `.current`.
    public init(
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.calendar = calendar
        self.locale = locale
    }

    /// Parses a natural-language date or time expression.
    ///
    /// The returned ``Foundation/DateComponents`` always carries `year`, `month`, and `day`.
    /// `hour` and `minute` are populated only when the input explicitly mentions a time
    /// (e.g. `"3pm"`, `"today at 9:30"`, `"Friday 15:00"`); otherwise they remain `nil` so
    /// callers can decide how to default them.
    ///
    /// Recognised forms include:
    /// - Relative-day keywords: `"today"`, `"tomorrow"`, `"yesterday"` (plus localised
    ///   variants for German, French, Spanish, Italian, Japanese), optionally followed by
    ///   a time, with an optional `at` connector.
    /// - Weekday names (`"Friday"`, `"next Friday"`, `"Fri"`), optionally with a time.
    /// - Month / day combinations (`"7 April"`, `"April 7"`), optionally with a time.
    /// - Bare times (`"3pm"`, `"15:30"`), resolved against the reference date.
    /// - A fallback pass through `NSDataDetector` for anything else date-like.
    ///
    /// - Parameters:
    ///   - string: The user-supplied text to parse.
    ///   - reference: The "now" anchor used to resolve relative inputs. Defaults to ``Foundation/Date/now``.
    ///   - prefersFuture: When `true`, weekday and month/day matches that would resolve to
    ///     a past date are rolled forward (next week, next year). Relative-day keywords
    ///     (`today` / `tomorrow` / `yesterday`) are unaffected. Defaults to `false`.
    /// - Returns: Parsed components, or `nil` if no date could be extracted.
    public func parse(
        _ string: String,
        relativeTo reference: Date = .now,
        prefersFuture: Bool = false
    ) -> DateComponents? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        if let withTime = parseRelativeDayWithTime(trimmed, relativeTo: reference) {
            return components(from: withTime, includingTime: true)
        }

        if let relative = parseRelativeDay(trimmed, relativeTo: reference) {
            return components(from: relative, includingTime: false)
        }

        if let manual = parseOtherPatterns(trimmed, relativeTo: reference, prefersFuture: prefersFuture) {
            return components(from: manual.date, includingTime: manual.hasTime)
        }

        if let timeOnly = parseTimeOnly(trimmed, relativeTo: reference) {
            return components(from: timeOnly, includingTime: true)
        }

        if let detected = parseWithDataDetector(string) {
            let final = prefersFuture ? ensureFuture(detected, relativeTo: reference) : detected
            return components(from: final, includingTime: hasNonMidnightTime(final))
        }

        return nil
    }

    /// Extracts the public-facing components from a resolved `Date`. Time fields are
    /// included only when the matching branch reported that a time was detected, so the
    /// caller can distinguish "no time given" from "explicitly midnight".
    private func components(from date: Date, includingTime: Bool) -> DateComponents {
        let fields: Set<Calendar.Component> = includingTime
            ? [.year, .month, .day, .hour, .minute]
            : [.year, .month, .day]
        return calendar.dateComponents(fields, from: date)
    }

    /// Heuristic used for `NSDataDetector` results, which don't tell us whether the user
    /// typed a time. Treats any hour or minute other than 0 as "time was specified".
    /// This means an actual midnight input is misclassified as no-time — accepted tradeoff.
    private func hasNonMidnightTime(_ date: Date) -> Bool {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) != 0 || (c.minute ?? 0) != 0
    }

    // MARK: - Localised names

    private var localisedNames: LocalisedDateNames {
        LocalisedDateNames(locale: locale, calendar: calendar)
    }

    // MARK: - Relative day keywords

    private static let relativeDayKeywords: [(keyword: String, offset: Int)] = [
        ("today", 0), ("now", 0), ("heute", 0), ("aujourd'hui", 0), ("hoy", 0), ("oggi", 0), ("今日", 0),
        ("tomorrow", 1), ("morgen", 1), ("demain", 1), ("mañana", 1), ("domani", 1), ("明日", 1),
        ("yesterday", -1), ("gestern", -1), ("hier", -1), ("ayer", -1), ("ieri", -1), ("昨日", -1),
    ]

    /// Matches a standalone relative-day keyword and returns the start-of-day for the
    /// resolved date. Returns `nil` if the input contains anything beyond the keyword.
    private func parseRelativeDay(_ text: String, relativeTo reference: Date) -> Date? {
        guard let offset = Self.relativeDayKeywords.first(where: { $0.keyword == text })?.offset else {
            return nil
        }
        return calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: reference))
    }

    /// Matches a relative-day keyword followed by a time expression, with an optional
    /// `at` connector (e.g. `"today 3pm"`, `"tomorrow at 09:00"`, `"yesterday 17:00"`).
    /// Returns `nil` if the time portion cannot be parsed.
    private func parseRelativeDayWithTime(_ text: String, relativeTo reference: Date) -> Date? {
        for (keyword, offset) in Self.relativeDayKeywords {
            let pattern = "(?i)^\(keyword.regexEscaped)\\s+(?:at\\s+)?(.+)$"
            guard let regex = try? Regex(pattern),
                  let match = text.firstMatch(of: regex),
                  let timeSubstring = match.output[1].substring
            else { continue }
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: reference)),
                  let withTime = applyTime(String(timeSubstring), to: day)
            else { continue }
            return withTime
        }
        return nil
    }

    // MARK: - Bare time

    /// Matches a standalone time expression (e.g. `"3pm"`, `"15:30"`) and returns the
    /// reference day at that time.
    ///
    /// Gated on the presence of a colon or am/pm suffix to avoid swallowing bare integers
    /// like `"3"` — without a marker the input is too ambiguous to interpret as a time.
    private func parseTimeOnly(_ text: String, relativeTo reference: Date) -> Date? {
        let hasColon = text.contains(":")
        let hasPeriod = ["am", "pm", "a.m.", "p.m."].contains(where: text.hasSuffix)
        guard hasColon || hasPeriod else { return nil }
        return applyTime(text, to: calendar.startOfDay(for: reference))
    }

    // MARK: - Other manual patterns

    private func parseOtherPatterns(
        _ text: String,
        relativeTo reference: Date,
        prefersFuture: Bool
    ) -> (date: Date, hasTime: Bool)? {
        if let (weekday, time) = parseWeekdayWithTime(from: text),
           let date = occurrence(of: weekday, relativeTo: reference, prefersFuture: prefersFuture),
           let withTime = applyTime(time, to: date) {
            return (withTime, true)
        }

        if let weekday = parseWeekday(from: text),
           let date = occurrence(of: weekday, relativeTo: reference, prefersFuture: prefersFuture) {
            return (date, false)
        }

        if let (month, day, time) = parseMonthDayTime(from: text),
           let date = occurrence(of: month, day: day, relativeTo: reference, prefersFuture: prefersFuture),
           let withTime = applyTime(time, to: date) {
            return (withTime, true)
        }

        if let (month, day) = parseMonthDay(from: text),
           let date = occurrence(of: month, day: day, relativeTo: reference, prefersFuture: prefersFuture) {
            return (date, false)
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

    /// Rolls `date` forward until it lies in the future relative to `reference`. Used
    /// only for `NSDataDetector` results when `prefersFuture` is `true`; the manual
    /// pattern paths already produce a future-shifted result via ``occurrence(of:relativeTo:prefersFuture:)``.
    ///
    /// Tries adding a week first (covers weekday-style inputs), then a year (covers
    /// month/day inputs without an explicit year). Falls back to the original date if
    /// neither produces a future value.
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

    /// Resolves a weekday number (1 = Sunday … 7 = Saturday) to a concrete date relative
    /// to `reference`.
    ///
    /// With `prefersFuture == false` (the default), the result lies in the current week —
    /// so "Monday" parsed on a Wednesday yields the past Monday. With `prefersFuture == true`,
    /// same-day and earlier-in-week matches are rolled forward by 7 days.
    private func occurrence(of weekday: Int, relativeTo reference: Date, prefersFuture: Bool) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: reference)
        var daysDelta = weekday - currentWeekday
        if prefersFuture && daysDelta <= 0 { daysDelta += 7 }
        return calendar.date(byAdding: .day, value: daysDelta, to: calendar.startOfDay(for: reference))
    }

    /// Resolves a month/day pair to a concrete date in the reference year. With
    /// `prefersFuture == true`, a date that has already passed in the current year is
    /// rolled forward to the next year.
    private func occurrence(of month: Int, day: Int, relativeTo reference: Date, prefersFuture: Bool) -> Date? {
        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = calendar.component(.year, from: reference)

        guard var date = calendar.date(from: components) else { return nil }
        if prefersFuture && date <= reference {
            components.year = (components.year ?? 0) + 1
            date = calendar.date(from: components) ?? date
        }
        return date
    }

    // MARK: - Time application

    /// Parses a time fragment (`"3pm"`, `"15:30"`, `"9:15 am"`, `"at 3pm"`) and returns
    /// the given date with its hour/minute set accordingly.
    ///
    /// A leading `at ` connector is stripped so callers don't need to pre-process. When
    /// the input is a bare 1–12 hour with no am/pm marker (e.g. `"3"`), PM is assumed —
    /// a deliberate bias toward typical "event time" inputs.
    private func applyTime(_ timeString: String, to date: Date) -> Date? {
        var cleaned = timeString.trimmingCharacters(in: .whitespaces)
        if let atRange = cleaned.range(of: #"^at\s+"#, options: [.regularExpression, .caseInsensitive]) {
            cleaned.removeSubrange(atRange)
        }

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

        guard let match = cleaned.wholeMatch(of: timeRegex),
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
