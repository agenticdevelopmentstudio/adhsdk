import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite
struct TextFoldingTests {

    @Test("case and diacritic fold to the same string")
    func foldsCaseAndDiacritic() {
        #expect(TextFolding.folded("CAFÉ") == TextFolding.folded("cafe"))
    }

    @Test("the empty string folds to the empty string")
    func foldsEmptyString() {
        #expect(TextFolding.folded("") == "")
    }

    @Test("fc-031: folding ignores the current locale",
          .disabled("the process locale cannot be switched to Turkish inside a unit test"))
    func fc031_localeIndependence() {}
}
