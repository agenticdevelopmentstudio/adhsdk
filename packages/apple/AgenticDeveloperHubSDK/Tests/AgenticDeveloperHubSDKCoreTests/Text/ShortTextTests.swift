import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct ShortTextTests {

    @Test func underTheLimitIsUnchanged() {
        #expect("short".shortened(to: 10) == "short")
    }

    @Test func exactlyTheLimitIsUnchanged() {
        #expect("0123456789".shortened(to: 10) == "0123456789")
    }

    @Test func overTheLimitIsCutEndingInAnEllipsis() {
        let cut = "0123456789ABC".shortened(to: 10)
        #expect(cut == "0123456…")
        #expect(cut.count == 8)  // prefix(limit - 3) plus the ellipsis: two under the limit
    }

    @Test("short-text-004: sixty characters fit the default limit")
    func shortText004_defaultLimitKeepsSixty() {
        let sixty = String(repeating: "a", count: 60)
        #expect(sixty.shortened() == sixty)
    }

    @Test("short-text-005: sixty-one characters are cut by the default limit")
    func shortText005_defaultLimitCutsSixtyOne() {
        let cut = String(repeating: "a", count: 61).shortened()
        #expect(cut == String(repeating: "a", count: 57) + "…")
        #expect(cut.count == 58)
    }

    @Test("short-text-006: a limit of 3 gives the ellipsis alone")
    func shortText006_limitThreeIsEllipsisOnly() {
        #expect("abcd".shortened(to: 3) == "…")
    }

    @Test("short-text-007: text that fits never reaches the minimum-limit precondition")
    func shortText007_fittingTextAtTinyLimits() {
        #expect("".shortened(to: 0) == "")
        #expect("ab".shortened(to: 2) == "ab")
    }

    @Test("short-text-008: a multi-scalar character is never split")
    func shortText008_countsCharactersNotScalars() {
        let family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"
        let cut = String(repeating: family, count: 6).shortened(to: 5)
        #expect(cut == family + family + "…")
    }

    @Test("short-text-009: the cut ignores word boundaries and keeps trailing whitespace")
    func shortText009_noWordBoundary() {
        #expect("hello world and more".shortened(to: 9) == "hello …")
    }
}
