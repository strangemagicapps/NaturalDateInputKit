# NaturalDateInputKit

Extract dates (including relative "today", "tomorrow") from strings.

> **Status:** early development. The API is unstable and may change without notice.

## Requirements

- iOS 26+, macOS 26+
- Swift 6.3 toolchain
- Built with Swift 6 language mode and complete strict concurrency

## Modules

This package exports two libraries:

- `NaturalDateInputKit` — parsing code for detecting dates within `String`s.
- `NaturalDateInputKitUI` — SwiftUI views for building date-aware text fields.

## Usage

### Parsing (`NaturalDateInputKit`)

```swift
import NaturalDateInputKit

// Parser API not yet implemented.
```

### SwiftUI (`NaturalDateInputKitUI`)

```swift
import SwiftUI
import NaturalDateInputKitUI

struct ContentView: View {
    var body: some View {
        Form {
            NaturalDateField()
        }
    }
}
```

`NaturalDateField` is currently a stub; the real implementation lands later.
