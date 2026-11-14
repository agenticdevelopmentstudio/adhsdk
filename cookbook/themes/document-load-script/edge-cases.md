
- **Empty `code`**: the component MUST render an empty `script` element in the server HTML and nothing on the client; it does not validate `code`.
- **`code` containing the closing script tag**: the string goes into the page as-is, so the browser ends the element at that text; this component MUST NOT escape it, and callers MUST NOT pass untrusted text.
- **Null or non-string `code`**: the prop type is `string`, enforced only by TypeScript; the source adds no runtime check, so the result for a non-string value is whatever React does with it and is not specified here.
- **Client navigation into a layout that contains the component**: MUST render `null` and MUST NOT make React log the script-tag warning; this is the reason the component exists.
- **Hydration**: MUST render the script so the hydrated node matches the server HTML; after hydration the element SHOULD leave the tree.
- **Concurrent access**: not applicable; the component holds no shared state and runs inside React's render on the single JavaScript thread.
- **Offline or disconnected state**: not applicable; the component makes no network request. Whether the script it emitted ran is a property of the document load, not of this component.
- **Script failure**: if the emitted code throws in the browser, nothing in this component observes or reports it; the failure is the script's own.
- **Client-only app with no server HTML**: the component never emits the script, so a page that relies on it must receive the script from a server render, as the doc comment states.

