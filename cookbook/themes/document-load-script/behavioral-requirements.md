
### Props and output

- **code-prop**: The component MUST accept a single prop, `code`, of type `string`.
- **script-element**: When it renders the script, the component MUST render exactly one `script` element and no wrapper element.
- **code-verbatim**: The `script` element's content MUST be the `code` string exactly as given, inserted as raw markup (the source uses `dangerouslySetInnerHTML` with `__html: code`) and not escaped or transformed.
- **script-no-attributes**: The `script` element MUST carry no attributes (no `src`, `type`, `nonce`, `async` or `defer`); the server markup for `code` equal to `window.__ran = 1` is exactly `<script>window.__ran = 1</script>`.
- **trusted-code-only**: Callers MUST pass only trusted, static code; the source states "`code` goes into the page as-is" and performs no sanitisation.

### Where the script appears

- **server-render-emits-script**: During a server render the component MUST render the `script` element.
- **hydration-emits-script**: During hydration of server HTML the component MUST render the `script` element, so the hydrated node matches the server HTML and React reports no mismatch.
- **client-mount-renders-nothing**: When React mounts the component on the client with no server HTML to hydrate (a client navigation into a layout that contains it), the component MUST render `null`, creating no `script` element and causing React to log no error.
- **leaves-tree-after-hydration**: After hydration completes, the component SHOULD leave the tree, because the browser has already run the script from the server HTML and a retained element would do nothing further. The source states this in its doc comment; no test asserts it.

### Mechanism and ordering

- **snapshot-selection**: The component MUST decide between the two outputs with `useSyncExternalStore`, whose server snapshot is `true` (used for the server render and for hydration) and whose client snapshot is `false`.
- **subscribe-is-inert**: The subscription function MUST be a constant no-op that returns a no-op unsubscribe, so the answer never changes while the component is mounted; the only change is the swap from the server snapshot to the client snapshot when hydration finishes.
- **no-state-no-effects**: The component MUST keep no state of its own, run no effect, read no global (no `window`, no `document`) and touch no storage.
- **single-thread-ordering**: Not applicable: the component runs inside React's render on the single JavaScript thread, holds no shared mutable state, and has no operation that can interleave; the choice of output is fixed by which snapshot React asks for.

### Errors and side effects

- **no-error-surface**: The component MUST NOT throw, validate `code`, or catch errors from the script it emits; whatever the script does when the browser runs it is outside this component.
- **no-side-effects**: The component MUST NOT write files, call the network, start processes, dispatch events or log; its only output is the returned element or `null`.

