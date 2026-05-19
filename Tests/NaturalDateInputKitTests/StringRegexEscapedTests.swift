import Testing
@testable import NaturalDateInputKit

@Suite("String.regexEscaped")
struct StringRegexEscapedTests {

    @Test func `empty string stays empty`() {
        #expect("".regexEscaped == "")
    }

    @Test func `plain text is unchanged`() {
        #expect("Monday".regexEscaped == "Monday")
        #expect("Hello world 123".regexEscaped == "Hello world 123")
    }

    @Test(arguments: [
        ("a.b", #"a\.b"#),
        ("a*b", #"a\*b"#),
        ("a+b", #"a\+b"#),
        ("a?b", #"a\?b"#),
        ("a|b", #"a\|b"#),
        ("a^b", #"a\^b"#),
        ("a$b", #"a\$b"#),
        ("a(b)c", #"a\(b\)c"#),
        ("a[b]c", #"a\[b\]c"#),
        ("a{b}c", #"a\{b\}c"#),
    ])
    func `escapes individual metacharacters`(input: String, expected: String) {
        #expect(input.regexEscaped == expected)
    }

    @Test func `escapes backslash`() {
        #expect(#"a\b"#.regexEscaped == #"a\\b"#)
    }

    @Test func `escapes all metacharacters together`() {
        let input = #"\.[]{}()*+?|^$"#
        let expected = #"\\\.\[\]\{\}\(\)\*\+\?\|\^\$"#
        #expect(input.regexEscaped == expected)
    }

    @Test func `escaped result is valid as a regex literal`() throws {
        // Round-trip: an escaped literal should match the original literal exactly.
        let literal = "Mon. (next)"
        let pattern = literal.regexEscaped
        let regex = try Regex(pattern)
        #expect(literal.wholeMatch(of: regex) != nil)
        #expect("Mon X (next)".wholeMatch(of: regex) == nil)
    }
}
