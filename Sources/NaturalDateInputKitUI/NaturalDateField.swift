import SwiftUI
import NaturalDateInputKit

/// A SwiftUI text field that interprets natural-language date and time input
/// using ``NaturalDateInputKit/NaturalDateParser`` and writes a resolved
/// ``Foundation/Date`` to the bound value.
///
/// When the user types something the parser can't recognise, the binding is
/// cleared (or, for the non-optional convenience init, left untouched). When
/// the parser recognises a date but the input contains no time, the configured
/// ``defaultTime`` is applied.
public struct NaturalDateField: View {
    @Binding private var date: Date?
    private let placeholder: String
    private let referenceDate: Date
    private let prefersFuture: Bool
    private let defaultTime: DateComponents
    private let calendar: Calendar
    private let locale: Locale

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    /// Creates a field bound to an optional `Date`.
    ///
    /// - Parameters:
    ///   - date: Binding that receives the resolved date, or `nil` when the
    ///     input is empty or unparseable.
    ///   - placeholder: Prompt text shown when the field is empty.
    ///   - referenceDate: "Now" anchor used to resolve relative inputs like
    ///     `tomorrow` or `Friday`. Defaults to ``Foundation/Date/now``.
    ///   - prefersFuture: When `true`, weekday and month/day matches that would
    ///     resolve to the past are rolled forward. Defaults to `false`.
    ///   - defaultTime: Time applied when the user's input doesn't include one.
    ///     Defaults to 09:00. Pass `DateComponents()` for midnight.
    ///   - calendar: Calendar used for parsing and resolution. Defaults to
    ///     ``Foundation/Calendar/current``.
    ///   - locale: Locale used for parsing localised weekday and month names.
    ///     Defaults to ``Foundation/Locale/current``.
    public init(
        date: Binding<Date?>,
        placeholder: String = "Enter date…",
        referenceDate: Date = .now,
        prefersFuture: Bool = false,
        defaultTime: DateComponents = DateComponents(hour: 9, minute: 0),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self._date = date
        self.placeholder = placeholder
        self.referenceDate = referenceDate
        self.prefersFuture = prefersFuture
        self.defaultTime = defaultTime
        self.calendar = calendar
        self.locale = locale
    }

    public var body: some View {
        TextField("Date", text: $text, prompt: Text(placeholder))
            .focused($isFocused)
            .onChange(of: text) { updateParsedDate() }
            .onSubmit(handleSubmit)
    }

    private func handleSubmit() {
        if date != nil { isFocused = false }
    }

    private func updateParsedDate() {
        guard !text.isEmpty else {
            date = nil
            return
        }

        let parser = NaturalDateParser(calendar: calendar, locale: locale)
        guard var components = parser.parse(
            text,
            relativeTo: referenceDate,
            prefersFuture: prefersFuture
        ) else {
            date = nil
            return
        }

        if components.hour == nil {
            components.hour = defaultTime.hour ?? 0
            components.minute = defaultTime.minute ?? 0
        }

        date = calendar.date(from: components)
    }
}

public extension NaturalDateField {
    /// Convenience initialiser for a non-optional `Date` binding.
    ///
    /// The binding is updated only when parsing succeeds; invalid or empty
    /// input leaves the bound value untouched so the field always reflects a
    /// concrete date.
    init(
        date: Binding<Date>,
        placeholder: String = "Enter date…",
        referenceDate: Date = .now,
        prefersFuture: Bool = false,
        defaultTime: DateComponents = DateComponents(hour: 9, minute: 0),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.init(
            date: Binding<Date?>(
                get: { date.wrappedValue },
                set: { newValue in
                    if let newValue { date.wrappedValue = newValue }
                }
            ),
            placeholder: placeholder,
            referenceDate: referenceDate,
            prefersFuture: prefersFuture,
            defaultTime: defaultTime,
            calendar: calendar,
            locale: locale
        )
    }
}

#Preview {
    @Previewable @State var date: Date?

    Form {
        NaturalDateField(date: $date)

        if let date {
            LabeledContent("Selected date") {
                Text(date, format: .dateTime)
            }
        }
    }
    .formStyle(.grouped)
}
