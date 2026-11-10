
A standalone editor-toolbar control in `@adh-sdk/ui`
(`components/markdown-spellcheck`) that adds an **optional**, **markdown-aware**
spelling & grammar check to a markdown editor. It is built for the
`MarkdownEditor` `toolbarExtras` slot: the consumer passes the same markdown
`value` plus an `onApply` handler, and the control renders a toggle in the
toolbar.

The check is **off by default**. The first time it is enabled, the control
lazy-loads [harper.js](https://writewithharper.com) — an offline grammar checker
whose WebAssembly runs inside a Web Worker (`WorkerLinter`), so neither the WASM
nor the worker ships on initial page load and linting never blocks the UI
thread. harper is asked to parse the input as **Markdown source**, so fenced code
blocks and markdown syntax are skipped and only prose is checked — the whole
point over the browser's native textarea spellcheck.

Problems are surfaced in a lightweight popover **panel/list** (not inline
squiggles on the textarea, which would be far costlier): each row shows the
flagged text, harper's message, and one apply-a-suggestion action per
replacement. Applying edits the markdown source through `onApply`; the panel then
re-lints. It reuses the shared `Popover` (Escape / outside-click dismissal +
focus restore) and `Button`, and holds no source of its own.

