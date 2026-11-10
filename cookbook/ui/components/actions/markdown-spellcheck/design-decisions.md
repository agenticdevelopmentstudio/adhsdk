
- **Decision**: A popover panel/list, not inline squiggles on the textarea.
  **Rationale**: Per-character overlay positioning over a `<textarea>` is costly
  and brittle; a list of problems with explicit apply actions is cheaper, more
  accessible, and matches the "lightweight panel" brief.
  **Approved**: pending
- **Decision**: harper's `WorkerLinter`, lazy-loaded on first enable.
  **Rationale**: The WASM is multi-MB; keeping it off the initial bundle and off
  the UI thread (a Web Worker) is essential. Loading only when the user opts in
  honors the opt-in principle.
  **Approved**: pending
- **Decision**: Markdown source mode (`language: 'markdown'`).
  **Rationale**: The reason to add this over native spellcheck is to skip code
  blocks and markdown syntax and check only prose.
  **Approved**: pending
- **Decision**: A `createLinter` DI seam with a harper-free public type surface.
  **Rationale**: Tests inject a fake (no WASM in jsdom) and the lazy contract is
  assertable; keeping harper out of the exported `.d.ts` means consumers need not
  resolve harper to type-check.
  **Approved**: pending
- **Decision**: harper's own `applySuggestion` performs edits.
  **Rationale**: It handles `Replace` / `Remove` / `InsertAfter` suggestion
  kinds correctly, which a naive substring splice would not.
  **Approved**: pending

