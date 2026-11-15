
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | default-off | Render with a fake linter, do not click | One button named `Check spelling` with `aria-pressed="false"`; no message/panel text in the DOM |
| T2 | default-off, lazy-load-harper | Render with a spy `createLinter`, then enable | `createLinter` is not called on render; it is called exactly once after the toggle is enabled |
| T3 | list-problems, offer-suggestions | Enable over source `"teh cat sat"` (fake flags `teh`→`the`) | The panel shows `teh`, the message, and an apply action named `Replace “teh” with “the”` (curly quotes); the toggle is `aria-pressed="true"` |
| T4 | show-empty-state | Enable over clean source `"the cat sat"` | The panel shows "No issues found." |
| T5 | offer-suggestions, apply-latest-lint | Enable over source with two flagged problems (`teh`, `recieve`); change the source and let a second `lint()` finish with a different list; click the apply action for the second problem | `apply` receives the second index and resolves it against the second `lint()` result, not the first |
| T6 | show-error-state | Enable with a fake `createLinter` whose returned promise rejects | The panel shows the red `CircleAlert` "Spell check is unavailable in this browser." state instead of throwing |
| T7 | reset-on-disable | Enable over source with problems, disable, then re-enable before the fake linter's `lint()` resolves | On re-enable the panel shows "Checking…", not the previously listed problems — the prior list was cleared on disable |
| T8 | relint-on-settle | Enable (immediate first lint resolves), then fire several source changes in quick succession using a spy `lint` and fake timers, then advance past `debounceMs` | `lint` is called once for the initial open and exactly once more after the timers settle — not once per change |
| T9 | lint-markdown-source, use-worker-linter | Mock the `harper.js` module import and call the exported `createHarperLinter()` directly, then call `.lint(source)` | A `WorkerLinter` is constructed (not `LocalLinter`) and its `lint` is called with `{ language: 'markdown', dedup: true }` |
| T10 | be-client-only | Render the closed component with the server renderer (`renderToString`), without enabling | No throw, and no harper import or worker/WASM code executes |
| T11 | dispose-on-unmount | Enable with a fake linter exposing a spied `dispose`, then unmount the component | The spied `dispose()` is called exactly once |
| T12 | offer-suggestions | Enable over source flagged with an empty suggestion (`Remove` kind, `suggestions: [""]`) | The apply chip reads "Remove"; clicking it calls `onApply` with the flagged span deleted |
| T13 | drop-stale-lint | Enable, change the source twice, and resolve the older `lint()` after the newer one | The list shows the newer result only |
| T14 | dismiss-turns-off | Enable, then press Escape (and separately click outside) | The check is off (`aria-pressed="false"`), the listed problems are cleared, and focus is on the toggle |
| T15 | show-problem-count | Enable over source with three problems | The toggle shows a count badge reading `3` |
| T16 | keep-list-during-relint | Enable, let the first lint finish, change the source, and hold the second `lint()` pending | The prior list stays visible and "Checking…" is not shown |
| T17 | offer-suggestions | Enable over a problem with six suggestions | Only the first four apply actions are rendered |
| T18 | offer-suggestions | Enable over a problem with no suggestions | The row shows "No suggestion." and no apply action |
| T19 | show-error-state | Enable with a linter whose `lint()` rejects | The panel shows the "Spell check is unavailable in this browser." state |

> Tests inject a fake `MarkdownLinter` through the `createLinter` prop so no WASM
> runs in jsdom; this also makes the lazy-load contract (T2) directly assertable.

