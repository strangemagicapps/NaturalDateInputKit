import Testing
@testable import NaturalDateInputKit

@Suite("String.regexEscaped")
struct StringRegexEscapedTests {

    @Test func emptyStringStaysEmpty() {
        #expect("".regexEscaped == "")
    }

    @Test func plainTextIsUnchanged() {
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
    func escapesIndividualMetacharacters(input: String, expected: String) {
        #expect(input.regexEscaped == expected)
    }

    @Test func escapesBackslash() {
        #expect(#"a\b"#.regexEscaped == #"a\\b"#)
    }

    @Test func escapesAllMetacharactersTogether() {
        let input = #"\.[]{}()*+?|^$"#
        let expected = #"\\\.\[\]\{\}\(\)\*\+\?\|\^\$"#
        #expect(input.regexEscaped == expected)
    }

    @Test func resultIsValidInARegex() throws {
        // Round-trip: an escaped literal should match the original literal exactly.
        let literal = "Mon. (next)"
        let pattern = literal.regexEscaped
        let regex = try Regex(pattern)
        #expect(literal.wholeMatch(of: regex) != nil)
        #expect("Mon X (next)".wholeMatch(of: regex) == nil)
    }
}
