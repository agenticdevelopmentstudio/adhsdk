
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
| syntax-highlighter-009 | no-reentry, theme-once | eight concurrent first `highlight` calls with Dark+ on a new highlighter | every `let` run is `#569CD6`; one engine created; `setTheme` called once. |
| syntax-highlighter-010 | theme-once | Dark+, Dark+, Light+, Light+, Dark+ in turn | `setTheme` counts 1, 1, 2, 2, 3. |
| syntax-highlighter-011 | promises-without-run-loop | `new Promise(() => {})` | throws `promiseDidNotSettle`. |
| syntax-highlighter-012 | promises-without-run-loop | `WebAssembly.instantiate` with the empty module's bytes, with that `WebAssembly.Module`, and with `[1, 2, 3]` | `{module, instance}`; an `Instance`; rejected. |
| syntax-highlighter-013 | directory-source | a user grammar with `fileTypes` `["Makefile", "MK", ".gnu"]` | extensions `.makefile`, `.mk`, `.gnu`; file names `Makefile`, `MK`; `Makefile` and `rules.mk` resolve to it. |
| syntax-highlighter-014 | extension-source | an extension contributing grammar `source.widget` (`language` `widget`, `./syntaxes/widget.tmLanguage.json`), an injection grammar `text.widget.injection` (`./syntaxes/injection.json`), and language `widget` with aliases `["Widget"]`, extensions `[".Widget", "wdg"]`, filenames `["Widgetfile"]` | grammar text for both scopes is the files' text; one language: id `widget`, scope `source.widget`, aliases `["Widget"]`, extensions `.widget`, `.wdg`, file names `Widgetfile`; `x.wdg` resolves to `widget` through a registry over the source. |
| syntax-highlighter-015 | extension-source | the same extension, disabled | no languages; neither scope has a grammar. |
| syntax-highlighter-016 | extension-source | a grammar at `./syntaxes/old.tmLanguage` and one at `../outside.json` | neither scope has a grammar. |
