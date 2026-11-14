
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| text-substitution-filter-001 | parse-pair, revealing | Filter parsed from `bobby mcfarin = mike fullerton`; `revealing("echo bobby mcfarin")` (test: reveals). | `echo mike fullerton`. |
| text-substitution-filter-002 | concealing, case-insensitive | Same filter; `concealing("Hello Mike Fullerton!")` and `concealing("MIKE FULLERTON")` (test: concealsCaseInsensitively). | `Hello bobby mcfarin!` and `bobby mcfarin`. |
| text-substitution-filter-003 | single-pass | Filter parsed from `a = b; b = c`; `revealing("a b")` (test: singlePass). | `b c`. |
| text-substitution-filter-004 | longest-wins | Filter parsed from `bob = mike` and `bobby mcfarin = mike fullerton` on two lines; `concealing("mike fullerton and mike")` (test: longestFirst). | `bobby mcfarin and bob`. |
| text-substitution-filter-005 | parse-forgiving, init-drops-empty | `init(parsing: "x = y; nonsense; = z; w = ;")` (test: parsingIsForgiving). | `pairs` equals one pair, alias `x` and real `y`. |
| text-substitution-filter-006 | serialized, round-trip | Filter parsed from `a = b` and `c = d` on two lines; parse its `serialized` (test: roundTrips). | The reparsed filter equals the original; `serialized` is `a = b; c = d`. |
| text-substitution-filter-007 | matching-case, casing-rule, replacement-as-given | Filter parsed from `Redbird = Bluebird`; `concealing("BLUEBIRD bluebird Bluebird", matchingCase: true)`; `revealing("REDBIRD redbird Redbird", matchingCase: true)`; `concealing("BlueBird", matchingCase: true)`; `concealing("bluebird")` (test: matchesCase). | `REDBIRD redbird Redbird`; `BLUEBIRD bluebird Bluebird`; `Redbird` (mixed case keeps the pair as written); `Redbird` (no case matching, as written). |
| text-substitution-filter-008 | whole-words | Filter parsed from `Robin = Mike`; `revealing` with `wholeWords: true` on `robinhood.com`, on `https://x.test/Robin/q?robin`, on `robin2 Robin.`; and without `wholeWords` on `robinhood.com` (test: revealsWholeWords). | `robinhood.com`; `https://x.test/Mike/q?Mike`; `robin2 Mike.`; `Mikehood.com`. |
| text-substitution-filter-009 | casing-rule | `casing("Ab", like: "42")` and `casing("ab", like: "X")` (test: casingWithoutLetters). | `Ab` (no letters, as given) and `AB` (one capital letter). |
| text-substitution-filter-010 | identity, early-exit | `TextSubstitutionFilter.identity.concealing("mike")` (test: identity). | `mike`. |
| text-substitution-filter-011 | init-drops-empty | `TextSubstitutionFilter(pairs: [Pair(alias: "", real: "x"), Pair(alias: "y", real: ""), Pair(alias: "a", real: "b")]).pairs` (derived from the source; no test). | One pair, alias `a` and real `b`. |
| text-substitution-filter-012 | parse-pair | `init(parsing: "k = v = w")` (derived from the source; no test). | One pair, alias `k` and real `v = w`. |
| text-substitution-filter-013 | literal-patterns | Filter parsed from `a.c = X`; `revealing("abc a.c")` (derived from the source; no test). | `abc X`: the dot matches only a literal dot. |
| text-substitution-filter-014 | early-exit | `TextSubstitutionFilter(parsing: "a = b").revealing("")` (derived from the source; no test). | The empty string. |
| text-substitution-filter-015 | concealing, no whole-words | Filter parsed from `Robin = Mike`; `concealing("Mikehood")` (derived from the source; no test). | `Robinhood`: concealing replaces inside a longer word. |
| text-substitution-filter-016 | whole-words-underscore | Filter parsed from `robin = Mike`; `revealing("robin_x", wholeWords: true)` (derived from the source; no test). | `Mike_x`: an underscore does not block replacement. |
| text-substitution-filter-017 | tie-order | Filter from `[Pair(alias: "a", real: "X"), Pair(alias: "A", real: "Y")]`; `revealing("a")` (derived from the source; no test). | `X`: the first pair in declaration order wins. |
| text-substitution-filter-018 | unmatched-text-kept, case-insensitive | Filter parsed from `café = X`; `revealing("un café noir")` (derived from the source; no test). | `un X noir`. |
| text-substitution-filter-019 | revealing, matching-case, whole-words | Filter parsed from `Robin = Mike`; `revealing("ROBIN robinhood", matchingCase: true, wholeWords: true)` (derived from the source; no test). | `MIKE robinhood`. |
| text-substitution-filter-020 | pair-shape | Encode `Pair(alias: "a", real: "b")` as JSON and decode it again (derived from the source; no test). | JSON with the fields `alias` and `real`; the decoded pair equals the original. |
