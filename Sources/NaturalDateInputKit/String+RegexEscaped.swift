//
//  String+RegexEscaped.swift
//  NaturalDateInputKit
//
//  Created by Scott Matthewman on 19/05/2026.
//

import Foundation

extension String {
    /// Escapes regex metacharacters for use in a regex pattern
    internal nonisolated var regexEscaped: String {
        let metacharacters: Set<Character> = ["\\", ".", "[", "]", "{", "}", "(", ")", "*", "+", "?", "|", "^", "$"]
        return self.map { metacharacters.contains($0) ? "\\\($0)" : String($0) }.joined()
    }
}
