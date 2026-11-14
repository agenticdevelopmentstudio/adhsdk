
**Decision**: Default and `auto` are represented by the absence of a `data-*` attribute, except `data-color-mode`, which is always set.
**Rationale**: An unset preference leaves the document pristine so the matching `@media` query governs; `colorMode` is always recorded because `applyAppearance` also resolves the `dark` class itself.
**Approved**: pending

**Decision**: The storage key, the pref lists and the pre-paint script live in a plain `.mjs` file, and `appearance.ts` imports and re-exports them.
**Rationale**: A Vite or Next config runs in plain Node before any bundler exists and cannot load TypeScript, yet it needs the script; one definition feeds the config, the script and the browser code.
**Approved**: pending

**Decision**: The pre-paint script reads `localStorage` as a cache, not the truth, and applies it without validation.
**Rationale**: A returning signed-in user repaints in their own color mode with no flash; the truth arrives from the server and corrects the document, and the cache is cleared on sign-out so the next visitor is not handed a stranger's theme. Skipping validation keeps the inline script small, at the cost that a corrupted cache value is written as an attribute until the store normalizes it.
**Approved**: pending

**Decision**: Storage failures on write and clear are discarded, and read failures fall back to defaults, with no log or error returned.
**Rationale**: Private mode and quota errors are routine and must never break rendering; the cost is that a failed cache write is invisible to the caller.
**Approved**: pending

**Decision**: Color mode is honored in every environment, production included.
**Rationale**: It was once pinned dark outside local, staging and testing, when light was an unfinished preview. Every site now reads the signed-in user's saved mode, and a production lock would make the setting silently do nothing where it matters most.
**Approved**: pending

**Decision**: `clearAppearance` exists alongside `applyAppearance` and iterates the same lists.
**Rationale**: A client navigation keeps the same `<html>`, so a site that wears preferences on only some routes must be able to remove exactly what was applied.
**Approved**: pending

**Decision**: The Vite plugin injects the script at the end of `<head>`.
**Rationale**: Prepended, it and the dev server's preamble push `<meta charset>` past the first 1024 bytes, where browsers stop looking for the encoding; a script anywhere in `<head>` still runs before the body paints.
**Approved**: pending

**Decision**: Test coverage for this module is indirect: `clearAppearance.test.ts` exercises `applyAppearance` and `clearAppearance` directly, and `appearanceScope.test.ts` and `AppearanceScope.test.tsx` exercise them through the store. No test file targets `normalizeAppearance`, the storage functions or the pre-paint script, so the vectors for those are derived from the source.
**Rationale**: Records the evidence source for the vectors above, per the source-fidelity guideline.
**Approved**: pending

