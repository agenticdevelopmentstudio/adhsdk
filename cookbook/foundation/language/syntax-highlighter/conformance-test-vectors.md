
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| syntax-highlighter-001 | runs, strict-colours, one-engine | `let x = 1` as `source.swift` with Dark+ (`themes/dark-plus.json`) | the run at `NSRange(0, 3)` is `#569CD6`. |
| syntax-highlighter-002 | line-split | `/* a` then `b */` on the next line | line 2's first run is Dark+'s comment colour `#6A9955`. |
| syntax-highlighter-003 | runs | a Markdown fenced `swift` block holding `let y = 1` | the `let` run inside the block is `#569CD6`. |
| syntax-highlighter-004 | limits | 1 000 001 bytes, or one line of 10 001 UTF-16 units | nil. |
| syntax-highlighter-005 | unknown-scope | scope `source.nonexistent` | nil. |
| syntax-highlighter-006 | first-source-wins | a user `swift.tmLanguage.json` (`scopeName` `source.swift`) ahead of the bundled source | the registry's `source.swift` text is the user file's. |
| syntax-highlighter-007 | resolution-order | `Package.swift`, `x.PY`, `Makefile`, an override answering `json`, `notes.unknownext` | `swift`, `python`, `make`, `json`, nil. |
| syntax-highlighter-008 | line-split | `a\rb`, `a\r\nb` | two lines each. |

