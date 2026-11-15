
The vectors are derived from the source and covered by `StreamingTextSubstitutionConformanceTests.swift`. The vectors are derived from the source, and they are the tests to write for this type. Unless stated, the filter has one pair, alias `robin` and real `mike`, direction `concealing`; `feed` takes ASCII bytes and returns the bytes shown as text.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| streaming-text-substitution-001 | emit-complete-match, direction-concealing | `feed("hello mike")` | `hello robin`, `isHolding` false. |
| streaming-text-substitution-002 | hold-partial, hold-released | `feed("hello mi")`, then `feed("ke!")` | First call returns `hello ` with `isHolding` true; second returns `robin!` with `isHolding` false. |
| streaming-text-substitution-003 | hold-released | `feed("mi")`, then `feed("x")` | First returns empty, second returns `mix`. |
| streaming-text-substitution-004 | flush, is-holding | `feed("mik")`, then `flush()` | `feed` returns empty with `isHolding` true; `flush` returns `mik` and `isHolding` is false. |
| streaming-text-substitution-005 | ascii-case-fold, replacement-as-given | `feed("MIKE Mike")` | `robin robin`. |
| streaming-text-substitution-006 | direction-revealing | Same filter, direction `revealing`; `feed("robin")` | `mike`. |
| streaming-text-substitution-007 | longest-first | Pairs (`rob`, `mike`) and (`robert`, `mike fullerton`), concealing; `feed("mike fullerton")` | `robert`. |
| streaming-text-substitution-008 | hold-over-shorter-match, flush | Same two pairs; `feed("mike")`, then `flush()` | `feed` returns empty and holds; `flush` returns `rob`. |
| streaming-text-substitution-009 | single-pass | Pairs (`b`, `a`) and (`c`, `b`), concealing; `feed("ab")` | `bc`, not `cc`. |
| streaming-text-substitution-010 | ascii-case-fold | Pair (`x`, `É`), concealing; `feed` of the bytes of `é` (0xC3 0xA9), then of `É` (0xC3 0x89) | The first call returns its bytes unchanged; the second returns `x`. |
| streaming-text-substitution-011 | binary-safe, no-patterns | Identity filter; `feed([0xFF, 0x6D])` | `[0xFF, 0x6D]`, `isHolding` false. |
| streaming-text-substitution-012 | binary-safe, hold-partial | Filter as default; `feed([0xFF, 0x6D])` | `[0xFF]` with `m` held; `isHolding` true. |
| streaming-text-substitution-013 | no-word-boundary | `feed("mimike")` | `mirobin`. |
| streaming-text-substitution-014 | flush-empty | A new instance; `flush()` | Empty array. |
| streaming-text-substitution-015 | order-preserved | `feed("a mike b")` | `a robin b`. |
| streaming-text-substitution-016 | no-patterns | Identity filter; `feed("abc")` | `abc`, `isHolding` false. |
| streaming-text-substitution-017 | generic-input | `feed` of a `[UInt8]` array, then of an `ArraySlice<UInt8>`, each holding bytes of `mi` and `ke` respectively | Both calls compile and run; the second returns `robin`. |
| streaming-text-substitution-018 | hold-bound | Pair (`robert`, `mike fullerton`), concealing; `feed("mike fullert")` | Returns empty; the held run is 12 bytes, shorter than the 14-byte pattern. |
| streaming-text-substitution-019 | pass-through-bytes | `feed("hello world")` | `hello world`, `isHolding` false; no byte is held because none is the first byte of a pattern (`m`). |
| streaming-text-substitution-020 | hold-released, hold-over-shorter-match | Pairs (`rob`, `mike`) and (`robert`, `mike fullerton`), concealing; `feed("mike x")` | `rob x`, `isHolding` false. |
| streaming-text-substitution-021 | flush, emit-complete-match | Same two pairs; `feed("mike fu")`, then `flush()` | `feed` returns empty and holds; `flush` returns `rob fu`. |
