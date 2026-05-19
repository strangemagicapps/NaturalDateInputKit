# NaturalDateInputKit

Extract dates and times from natural-language strings ("tomorrow", "next Friday at 9am", "7 April", "15:30") and bind them to a SwiftUI text field.

> **Status:** early development. The API may change before 1.0.

## Requirements

- iOS 26+, macOS 26+
- Swift 6.3 toolchain
- Built with Swift 6 language mode and complete strict concurrency

## Install

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/strangemagicapps/NaturalDateInputKit.git", from: "0.1.0")
```

Then depend on the product you need:

```swift
// Parser only
.product(name: "NaturalDateInputKit", package: "NaturalDateInputKit")

// SwiftUI field (transitively pulls in the parser)
.product(name: "NaturalDateInputKitUI", package: "NaturalDateInputKit")
```

In Xcode: **File → Add Package Dependencies…** and paste the repository URL.

## Modules

- `NaturalDateInputKit` — `NaturalDateParser` for detecting dates and times in `String`s.
- `NaturalDateInputKitUI` — `NaturalDateField`, a SwiftUI text field built on the parser.

## Usage

### Parsing (`NaturalDateInputKit`)

```swift
import NaturalDateInputKit

let parser = NaturalDateParser()

// Returns DateComponents with year/month/day, and hour/minute only when
// a time was explicitly mentioned.
parser.parse("tomorrow at 9am")        // → y/m/d + 09:00
parser.parse("Friday")                  // → y/m/d (no time)
parser.parse("3pm")                     // → today's y/m/d + 15:00
parser.parse("next Monday", prefersFuture: true)
```

### SwiftUI (`NaturalDateInputKitUI`)

```swift
import SwiftUI
import NaturalDateInputKitUI

struct EventEditor: View {
    @State private var date: Date?

    var body: some View {
        Form {
            NaturalDateField(
                date: $date,
                placeholder: "When?",
                defaultTime: DateComponents(hour: 19, minute: 30)
            )
        }
    }
}
```

`defaultTime` is applied only when the user's input doesn't include one. A `Binding<Date>` convenience initialiser is also available.
