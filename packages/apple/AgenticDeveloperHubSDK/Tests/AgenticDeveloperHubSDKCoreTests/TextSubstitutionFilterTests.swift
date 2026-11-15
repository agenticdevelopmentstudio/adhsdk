import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("TextSubstitutionFilter")
struct TextSubstitutionFilterTests {

    private let filter = TextSubstitutionFilter(parsing: "bobby mcfarin = mike fullerton")

    @Test("revealing replaces the alias with the real text")
    func reveals() {
        #expect(filter.revealing("echo bobby mcfarin") == "echo mike fullerton")
    }

    @Test("concealing replaces the real text with the alias, whatever its case")
    func concealsCaseInsensitively() {
        #expect(filter.concealing("Hello Mike Fullerton!") == "Hello bobby mcfarin!")
        #expect(filter.concealing("MIKE FULLERTON") == "bobby mcfarin")
    }

    @Test("a replacement is never rewritten by another pair")
    func singlePass() {
        let chain = TextSubstitutionFilter(parsing: "a = b; b = c")
        #expect(chain.revealing("a b") == "b c")
    }

    @Test("the longest match wins at each position")
    func longestFirst() {
        let both = TextSubstitutionFilter(parsing: "bob = mike\nbobby mcfarin = mike fullerton")
        #expect(both.concealing("mike fullerton and mike") == "bobby mcfarin and bob")
    }

    @Test("parsing skips half-written entries and empty sides")
    func parsingIsForgiving() {
        let parsed = TextSubstitutionFilter(parsing: "x = y; nonsense; = z; w = ;")
        #expect(parsed.pairs == [.init(alias: "x", real: "y")])
    }

    @Test("serialized reads back as the same filter")
    func roundTrips() {
        let both = TextSubstitutionFilter(parsing: "a = b\nc = d")
        #expect(TextSubstitutionFilter(parsing: both.serialized) == both)
    }

    @Test("matchingCase writes each replacement in the case of what it replaces")
    func matchesCase() {
        let birds = TextSubstitutionFilter(parsing: "Redbird = Bluebird")
        #expect(birds.concealing("BLUEBIRD bluebird Bluebird", matchingCase: true) == "REDBIRD redbird Redbird")
        #expect(birds.revealing("REDBIRD redbird Redbird", matchingCase: true) == "BLUEBIRD bluebird Bluebird")
        #expect(birds.concealing("BlueBird", matchingCase: true) == "Redbird", "mixed case keeps the pair as written")
        #expect(birds.concealing("bluebird") == "Redbird", "without matchingCase, as written")
    }

    @Test("wholeWords reveals an alias only where no letter or digit touches it")
    func revealsWholeWords() {
        let robin = TextSubstitutionFilter(parsing: "Robin = Mike")
        #expect(robin.revealing("robinhood.com", wholeWords: true) == "robinhood.com")
        #expect(robin.revealing("https://x.test/Robin/q?robin", wholeWords: true) == "https://x.test/Mike/q?Mike")
        #expect(robin.revealing("robin2 Robin.", wholeWords: true) == "robin2 Mike.")
        #expect(robin.revealing("robinhood.com") == "Mikehood.com", "without wholeWords, anywhere")
    }

    @Test("casing leaves text with no letters as given")
    func casingWithoutLetters() {
        #expect(TextSubstitutionFilter.casing("Ab", like: "42") == "Ab")
        #expect(TextSubstitutionFilter.casing("ab", like: "X") == "AB")
    }

    @Test("with no pairs, text passes through unchanged")
    func identity() {
        #expect(TextSubstitutionFilter.identity.concealing("mike") == "mike")
    }

    @Test("text-substitution-filter-011: init(pairs:) drops pairs with an empty side")
    func filter011_initDropsEmptySides() {
        let built = TextSubstitutionFilter(pairs: [
            .init(alias: "", real: "x"), .init(alias: "y", real: ""), .init(alias: "a", real: "b")
        ])
        #expect(built.pairs == [.init(alias: "a", real: "b")])
    }

    @Test("text-substitution-filter-012: only the first equals sign splits an entry")
    func filter012_firstEqualsSplits() {
        let parsed = TextSubstitutionFilter(parsing: "k = v = w")
        #expect(parsed.pairs == [.init(alias: "k", real: "v = w")])
    }

    @Test("text-substitution-filter-013: patterns match literally")
    func filter013_literalPatterns() {
        let dotted = TextSubstitutionFilter(parsing: "a.c = X")
        #expect(dotted.revealing("abc a.c") == "abc X")
    }

    @Test("text-substitution-filter-014: empty text comes back empty")
    func filter014_emptyTextEarlyExit() {
        #expect(TextSubstitutionFilter(parsing: "a = b").revealing("") == "")
    }

    @Test("text-substitution-filter-015: concealing replaces inside a longer word")
    func filter015_concealingIgnoresWordBoundaries() {
        let robin = TextSubstitutionFilter(parsing: "Robin = Mike")
        #expect(robin.concealing("Mikehood") == "Robinhood")
    }

    @Test("text-substitution-filter-016: an underscore does not block whole-word replacement")
    func filter016_underscoreDoesNotBlock() {
        let robin = TextSubstitutionFilter(parsing: "robin = Mike")
        #expect(robin.revealing("robin_x", wholeWords: true) == "Mike_x")
    }

    @Test("text-substitution-filter-017: the first pair in declaration order wins a tie")
    func filter017_tieOrderIsDeclarationOrder() {
        let tied = TextSubstitutionFilter(pairs: [.init(alias: "a", real: "X"), .init(alias: "A", real: "Y")])
        #expect(tied.revealing("a") == "X")
    }

    @Test("text-substitution-filter-018: accented text matches and the rest is kept")
    func filter018_unicodeMatchAndPassThrough() {
        let cafe = TextSubstitutionFilter(parsing: "café = X")
        #expect(cafe.revealing("un café noir") == "un X noir")
    }

    @Test("text-substitution-filter-019: matchingCase and wholeWords combine")
    func filter019_matchingCaseWithWholeWords() {
        let robin = TextSubstitutionFilter(parsing: "Robin = Mike")
        #expect(robin.revealing("ROBIN robinhood", matchingCase: true, wholeWords: true) == "MIKE robinhood")
    }

    @Test("text-substitution-filter-020: Pair encodes alias and real and decodes back")
    func filter020_pairCoding() throws {
        let pair = TextSubstitutionFilter.Pair(alias: "a", real: "b")
        let data = try JSONEncoder().encode(pair)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(object == ["alias": "a", "real": "b"])
        #expect(try JSONDecoder().decode(TextSubstitutionFilter.Pair.self, from: data) == pair)
    }
}
