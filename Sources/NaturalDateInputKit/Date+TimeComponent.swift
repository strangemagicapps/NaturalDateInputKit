//
//  Date+TimeComponent.swift
//  NaturalDateInputKit
//
//  Created by Scott Matthewman on 19/05/2026.
//

import Foundation

extension Date {
    var hasTimeComponent: Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: self)
        return (components.hour ?? 0) != 0 || (components.minute ?? 0) != 0
    }
}
