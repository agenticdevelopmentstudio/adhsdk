
No test sits beside the source file. Vector 007 comes from `testAppMatchesAgentOrTerminalByPrefix`, which reaches `match` through the conversation summary; the others follow from the source's own values and logic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| known-terminals-001 | match-contract, catalog-iterm2 | `match(termProgram: "iTerm.app")` | the iTerm2 entry, bundle id `com.googlecode.iterm2` |
| known-terminals-002 | match-contract, catalog-terminal-app | `match(termProgram: "Apple_Terminal")` | the Terminal.app entry, bundle id `com.apple.Terminal` |
| known-terminals-003 | match-contract, catalog-warp | `match(termProgram: "WarpTerminal")` | the Warp entry, bundle id `dev.warp.Warp-Stable` |
| known-terminals-004 | match-contract, catalog-vscode | `match(termProgram: "vscode")` | the VS Code entry, bundle id `com.microsoft.VSCode` |
| known-terminals-005 | match-contract | `match(termProgram: "ghostty")` | nil |
| known-terminals-006 | match-exact | `match(termProgram: "iterm.app")` | nil, because the comparison is case sensitive |
| known-terminals-007 | display-name-use, match-contract | a session with `TERM_PROGRAM` `iTerm.app`, app filter `ITERM` (`testAppMatchesAgentOrTerminalByPrefix`) | the filter matches (by prefix on the raw `TERM_PROGRAM` or the matched `displayName`, case ignored), and a filter of `ghostty` does not |
| known-terminals-008 | match-contract | `match(termProgram: "")` | nil |
| known-terminals-009 | catalog-extensible, term-program-values-plural | a custom catalog with one entry holding values `a` and `b`; `match(termProgram: "b", in: custom)` | that entry |
| known-terminals-010 | catalog-extensible | `match(termProgram: "iTerm.app", in: [])` | nil |
| known-terminals-011 | catalog-order | the `displayName` of each entry of `all` | iTerm2, Terminal.app, Warp, VS Code, in that order |
| known-terminals-012 | match-contract | a custom catalog with two entries that both list `x`; `match(termProgram: "x", in: custom)` | the first of the two |
| known-terminals-013 | entry-conformance | two `KnownTerminal` values built with the same three arguments | equal |
| known-terminals-014 | catalog-no-duplicates | every `termProgramValues` value across the entries of `all` | no value appears in two entries |
