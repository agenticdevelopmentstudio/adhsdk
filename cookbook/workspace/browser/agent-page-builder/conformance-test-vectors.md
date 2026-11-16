
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-page-builder-001 | unknown-kind-dropped-with-subtree, built-up-not-trimmed | Payload with a node of kind `iframe` holding a text child "inner secret" | Neither the node nor "inner secret" appears in the snapshot tree, text or HTML |
| agent-page-builder-002 | unlisted-attribute-dropped | Link node with attributes `onclick="steal()"` and `href="https://a.example/"` | The link keeps only `href`; "steal" appears in no rendering |
| agent-page-builder-003 | href-sanitized, concealed-before-insertion | Privacy words {Acme}; three links: `javascript:alert(1)`, `data:text/html,x`, `/p?u=Acme` on page `https://site.example/` | The first two links carry no address; the third's address is `https://site.example/p?u=` followed by the stand-in, with no "Acme" |
| agent-page-builder-004 | concealed-before-insertion | Privacy words {Acme}; "Acme" in a heading, a text field value, the page title, an `aria-label` and a `title` attribute | "Acme" appears nowhere in the snapshot tree, the text or the HTML; the stand-in appears in each place |
| agent-page-builder-005 | value-kept-only-for-form-controls | A text field with value "hello", a password field with value "hunter2", a button with value "go", a text area with value "private notes" | The text field shows "hello" and the text area "private notes"; "hunter2" and the button's value appear in no rendering |
| agent-page-builder-006 | hide-images | Hide Images on; an image with alt "Logo" | No image node and no "Logo" in any rendering |
| agent-page-builder-007 | hide-images, html-rendering-safe | Hide Images off; an image with alt "Logo" and a source attribute | The HTML shows a placeholder reading "[image: Logo]"; no source address appears anywhere |
| agent-page-builder-008 | fail-closed-on-walker-failure, no-partial-content-on-failure | Payload bytes `{` | Empty page; reason begins `Agent view unavailable: `; no root |
| agent-page-builder-009 | fail-closed-on-walker-failure | The walker reports an error | Empty page with a reason beginning `Agent view unavailable: ` |
| agent-page-builder-010 | fail-closed-on-walker-failure | Walk of a large page with a timeout of 0 milliseconds | Empty page with a reason beginning `Agent view unavailable: ` |
| agent-page-builder-011 | fail-closed-on-vault | Privacy unavailable; a valid payload | Empty page, reason set, no root |
| agent-page-builder-012 | fail-closed-on-vault | Privacy conflicting; a valid payload | Empty page, reason set, no root |
| agent-page-builder-013 | html-rendering-safe | Text node `<script>x</script>` and a node whose page element had a `style` attribute | The HTML contains `&lt;script&gt;x&lt;/script&gt;`, no `<script` element and no `style=` attribute; every emitted element has `data-adk-ref` |
| agent-page-builder-014 | snapshot-tool-contract-unchanged | A fixture payload and the equivalent legacy snapshot tree | The snapshot rendering's lines equal the legacy renderer's lines for that tree, with and without include URLs, with depth unset, 0 and -1; the fixture holds a text area value, inline text split across two text nodes, a slider and a spinbutton |
| agent-page-builder-015 | always-runs | Privacy off; a payload with an unknown kind | The unknown node is still dropped |
| agent-page-builder-016 | walker-skips-hidden-nodes | Live page with four elements hidden by display none, visibility hidden, the `hidden` attribute and `aria-hidden="true"` | None of the four appears in the result |
| agent-page-builder-017 | walker-skips-agent-list | Agent list for the site holds `.ad`; the page has a `.ad` element with a child paragraph | Neither the element nor its paragraph appears |
| agent-page-builder-018 | user-hidden-items-hidden-from-agent | The user list hides `#promo`, the agent list is empty | `#promo` does not appear in the result |
| agent-page-builder-019 | scope-within-walk | Agent list holds `#side`; snapshot scoped to a reference inside `#side` | The result has an empty root |
| agent-page-builder-020 | invalid-exclude-selector-isolated | Agent list holds `::bad(` and `.ad` | `.ad` elements are still excluded; the walk's warnings name `::bad(`; the walk succeeds |
| agent-page-builder-021 | refs-drive-actions | Take a reference for a button from the result and click it | The click succeeds on that button |
| agent-page-builder-022 | single-gatekeeper, one-value-three-renderings | A spy page source; call the snapshot, text and find tools once each | Each tool requests exactly one page from the source; none reads the page another way |
| agent-page-builder-023 | raw-page-tools-refused-when-filtered | Privacy off; the site has one enabled agent-list entry; call screenshot, click-at, evaluate | Each is refused with the agent-list sentence |
| agent-page-builder-024 | raw-page-tools-refused-when-filtered | Privacy on; no agent-list entries; call screenshot | Refused |
| agent-page-builder-025 | raw-page-tools-allowed-when-unfiltered | Privacy off; no enabled agent-list entries; call screenshot | Not refused by the gatekeeper |
| agent-page-builder-026 | console-refused-under-privacy | Privacy on; call the console tool | Refused with the console sentence |
| agent-page-builder-027 | wait-for-uses-agent-text | Text "Ready" exists only inside an agent-list-excluded element; wait for text "Ready" | The wait times out |
| agent-page-builder-028 | find-uses-agent-page | Find "Buy" where one "Buy" button is excluded and one is not | Only the visible button's reference is returned |
| agent-page-builder-029 | titles-dialogs-focus-through-string-path | Privacy words {Acme}; page title "Acme Home"; an alert "Hi Acme"; list panes, then click a button that raises the alert | Neither the pane list nor the reply contains "Acme" |
| agent-page-builder-030 | titles-dialogs-focus-through-string-path | An action moves focus into an agent-list-excluded element | The reply has no focused-element description |
| agent-page-builder-031 | history-through-string-path | Privacy words {Acme}; history holds a visit titled "Acme" | The history tool's reply contains the stand-in, not "Acme" |
| agent-page-builder-032 | string-path | The string "Acme" through the string path with privacy off, on with {Acme}, unavailable, conflicting | "Acme"; the stand-in; ""; "" |
| agent-page-builder-033 | unavailable-page-renders-reason, unavailable-reason-is-the-result | An unavailable page; render HTML; call the snapshot tool | The HTML is one paragraph with the reason; the tool returns the reason as its result, not an error |
| agent-page-builder-034 | allowlist-defined-once, walker-emits-allowlisted-only | Walk a page with an allowlist that omits `table` | No table, row or cell node is emitted |
| agent-page-builder-035 | selector-recorded-per-node | Build a page with a link | The link's node records a selector that matches exactly that link in the document |
| agent-page-builder-036 | snapshot-tool-contract-unchanged | Depth option 0, then -3, on a page three levels deep | Each rendering equals the one with no depth option |
| agent-page-builder-037 | value-kept-only-for-form-controls | A text area labelled "Notes" with value "Line one" newline "   line two" | The snapshot prints `textbox "Notes"` with `[value="Line one line two"]`; the HTML text area holds the value |
| agent-page-builder-038 | snapshot-tool-contract-unchanged | A paragraph with text children "a" and "b"; a button with text "Sign" and a text child "in" | The snapshot prints `text: ab` and `button "Signin"` |
| agent-page-builder-039 | value-kept-only-for-form-controls | A text field of type `range` named "Volume" with value "40" and one of type `number` labelled "Count" with value "3" | The snapshot prints `slider "Volume"` with `[value="40"]` and `spinbutton "Count"` with `[value="3"]` |
