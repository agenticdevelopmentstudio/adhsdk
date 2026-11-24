
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| composite-tool-source-001 | definitions-concatenated-in-order | Sources `[A advertising a, b; B advertising c]` | `toolDefinitions()` names are `["a", "b", "c"]` (`CompositeChatToolSourceTests.concatenatesDefinitionsInOrder`) |
| composite-tool-source-002 | call-routed-by-name, call-forwards-arguments-and-caller, call-result-passthrough | Sources `[first advertising a; second advertising b]`; `callTool(name: "b", argumentsJSON: {}, caller: "pane-1")` | Result content is `b ok`; `second` records `("b", "pane-1")`; `first` records no call (`CompositeChatToolSourceTests.routesByNameAndPassesCaller`) |
| composite-tool-source-003 | unknown-tool-result, unknown-tool-calls-nothing | Sources `[one advertising a]`; `callTool(name: "zzz", argumentsJSON: empty, caller: nil)` | `isError` is true and content is exactly `unknown tool zzz` (`CompositeChatToolSourceTests.unknownToolIsASentence`) |
| composite-tool-source-004 | two-argument-call-default | One source advertising `a`; call `callTool(name: "a", argumentsJSON: empty)` on it | The source records one call with caller `nil` (`CompositeChatToolSourceTests.twoArgumentCallForwardsWithNilCaller`) |
| composite-tool-source-005 | empty-sources-empty-definitions | Composite built from `[]` | `toolDefinitions()` is `[]` |
| composite-tool-source-006 | unknown-tool-result | Composite built from `[]`; `callTool(name: "a", ...)` | Content `unknown tool a`, `isError` true |
| composite-tool-source-007 | first-match-wins, definitions-not-deduplicated | Sources `[A advertising x; B advertising x]` | `toolDefinitions()` has two entries named `x`; `callTool(name: "x", ...)` reaches A only and B records no call |
| composite-tool-source-008 | call-resolves-by-fresh-definitions, definitions-queried-per-call | Source A advertises `x` only after a flag is set; B always advertises `x`; call `x` before and after setting the flag | Before the flag the call reaches B; after it the call reaches A |
| composite-tool-source-009 | definitions-awaited-sequentially, definitions-concatenated-in-order | Sources whose `toolDefinitions()` record their start and finish | Each source finishes before the next starts, and results keep source order |
| composite-tool-source-010 | call-result-passthrough | Chosen source returns `("boom", true)` | Composite returns `("boom", true)` unchanged |

