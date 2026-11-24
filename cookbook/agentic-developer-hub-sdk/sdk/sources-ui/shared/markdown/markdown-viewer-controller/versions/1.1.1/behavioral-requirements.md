
- **fetch-by-id**: Component MUST fetch markdown content by document `id` via the configured fetcher.
- **fetch-timeout**: Fetch operation MUST abort its `AbortSignal` if it exceeds the configured `timeoutMs` (default 15000ms). Reaching the error state from this depends on the fetcher honoring that signal (rejecting once aborted, as the default native-fetch fetcher does); a fetcher that ignores `AbortSignal` is not itself interrupted and can still resolve, or keep loading, past the timeout.
- **abort-on-id-change**: If `id` changes while a fetch is in flight, the component MUST abort the previous fetch's `AbortSignal`. With a fetcher that honors the signal, this makes any late response for the stale id rejected and ignored. Exception: if the stale fetch had already timed out before `id` changed, its signal is already aborted with the timeout reason, and the id-change cleanup's second `abort()` call is a no-op that cannot change that reason — so with a fetcher that does not honor `AbortSignal`, a late success or error for the stale id can still overwrite the newer id's state instead of being ignored (see Edge Cases).
- **fetch-error-handling**: Component MUST display an error state with the error message if the fetch fails.
- **sanitized-rendering**: Markdown content MUST be rendered as sanitized HTML using an allowlist: elements limited to prose structure (headings, paragraphs, lists, tables, blockquotes, code, links, images, inline emphasis, `details`/`summary`, and similar), with `<script>`, `<style>`, `<iframe>`, `<object>`, `<embed>`, and `<form>` always stripped. `href`/`cite` accept only the `http`, `https`, `mailto`, and `tel` protocols and `src` accepts only `http`/`https` (no `javascript:` or other schemes). No `on*` event-handler attribute is permitted on any element.
- **code-syntax-highlighting**: Code blocks in markdown MUST receive syntax highlighting via the configured highlighter.
- **theme-persistence**: On web, the component MUST persist the selected theme ID to storage (`localStorage`) so it survives app restarts — the component owns this state itself. On Apple, the component does not select or persist a theme: `palette` is a host-injected configuration value, and the host application owns theme selection and any persistence of it (e.g. via `UserDefaults`, if the host chooses to persist).
- **theme-palette-application**: Active theme palette MUST be applied to all rendered content (text colors, backgrounds, code highlighting).
- **toolbar-display**: Component MUST render a toolbar containing the document title and a theme switcher control.
- **document-title-display**: Toolbar MUST display the document's title (or empty string if not yet loaded).
- **theme-switcher-touch-target**: The toolbar theme switcher control MUST have a tap target of at least 44×44pt (iOS) / 48×48dp (Android).
- **loading-state**: While fetch is in progress, component MUST display a loading indicator with live region announcement.
- **idle-state**: Before any document is requested, component MUST display an idle message ("No document selected").
- **empty-state**: If document fetches successfully but content is empty or whitespace-only, component MUST display an empty state message.
- **no-flash-theme**: On web with SSR, a pre-hydration bootstrap script SHOULD apply the persisted theme before React hydration to prevent flash of default theme.

