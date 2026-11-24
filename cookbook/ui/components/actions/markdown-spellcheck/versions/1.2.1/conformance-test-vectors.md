
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | default-off | Render with a fake linter, do not click | One button named `Check spelling` with `aria-pressed="false"`; no message/panel text in the DOM |
| T2 | default-off, lazy-load-harper | Render with a spy `createLinter`, then enable | `createLinter` is not called on render; it is called exactly once after the toggle is enabled |
| T3 | list-problems, offer-suggestions | Enable over source `"teh cat sat"` (fake flags `teh`→`the`) | The panel shows `teh`, the message, and an apply action named `Replace "teh" with "the"`; the toggle is `aria-pressed="true"` |
| T4 | show-empty-state | Enable over clean source `"the cat sat"` | The panel shows "No issues found." |
| T5 | offer-suggestions, apply-latest-lint | Enable over source with two flagged problems (`teh`, `recieve`), click the apply action for the second problem | `onApply` is called with `recieve` replaced, not `teh` — the index resolves against the latest `lint()` result |
| T6 | show-error-state | Enable with a fake `createLinter` whose returned promise rejects | The panel shows the red `CircleAlert` "Spell check is unavailable in this browser." state instead of throwing |
| T7 | reset-on-disable | Enable over source with problems, disable, then re-enable before the fake linter's `lint()` resolves | On re-enable the panel shows "Checking…", not the previously listed problems — the prior list was cleared on disable |
| T8 | relint-on-settle | Enable (immediate first lint resolves), then fire several source changes in quick succession using a spy `lint` and fake timers, then advance past `debounceMs` | `lint` is called once for the initial open and exactly once more after the timers settle — not once per change |
| T9 | lint-markdown-source, use-worker-linter | Mock the `harper.js` module import and call the exported `createHarperLinter()` directly, then call `.lint(source)` | A `WorkerLinter` is constructed (not `LocalLinter`) and its `lint` is called with `{ language: 'markdown', dedup: true }` |
| T10 | be-client-only | Import the component module in a simulated server environment (no `window`/`document`) and render without enabling | No throw, and no harper import or worker/WASM code executes |
| T11 | dispose-on-unmount | Enable with a fake linter exposing a spied `dispose`, then unmount the component | The spied `dispose()` is called exactly once |
| T12 | offer-suggestions | Enable over source flagged with an empty suggestion (`Remove` kind, `suggestions: [""]`) | The apply chip reads "Remove"; clicking it calls `onApply` with the flagged span deleted |

> Tests inject a fake `MarkdownLinter` through the `createLinter` prop so no WASM
> runs in jsdom; this also makes the lazy-load contract (T2) directly assertable.

