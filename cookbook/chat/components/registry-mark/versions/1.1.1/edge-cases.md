
- **Empty or missing label**: If `label` is empty string or undefined, the link will have no accessible name. Implementations SHOULD validate and provide a default or error; this is a source gap.
- **Missing profileUrl**: If `profileUrl` is empty string, the link's href will be empty (current: `<a href="">`). Clicking navigates to the current page. Implementations SHOULD reject empty or invalid URLs.
- **Long tip content**: If `tip` contains very long text or many nested elements, the popover may exceed viewport bounds. CSS in host's popover-bloom styling SHOULD include overflow handling (this component does not constrain tip size).
- **Tip contains interactive content**: See **popover-visible-on-focus-or-hover** — the popover stays open, and its links stay keyboard-reachable, while focus is anywhere within the mark, via the companion CSS's `:has(:focus-visible)` rule and a pointer bridge (`.pc-rm-tip::after`), not JS-based focus management.
- **Ancestor overflow:hidden**: See **clip-safe-placement** — rendering the mark inside a container with `overflow: hidden` (e.g. `.persona-chat` itself, or an unconfigured `ViewportShell`) clips the popover and the overhanging @.
- **Ancestor with no position context**: The mark's CSS positioning relies on an ancestor with `position: relative` (per source comment). If missing, the mark will position relative to the nearest positioned ancestor (default browser behavior).
- **Concurrent render streaming**: See **stable-tip-reference** — an unstable `tip` (e.g. an inline JSX expression) defeats the component's memoization and causes a re-render on every streamed token.

