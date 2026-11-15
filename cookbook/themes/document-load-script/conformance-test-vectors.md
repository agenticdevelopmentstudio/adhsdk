
The test beside the source is `DocumentLoadScript.test.tsx` in the themes package `__tests__` folder; vectors 001 to 003 derive from its three tests by name. Vectors 004 to 009 derive from the source and its doc comment and are tested in the same file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| document-load-script-001 | server-render-emits-script, script-element, code-verbatim, script-no-attributes | `DocumentLoadScript.test.tsx` "is in the server HTML": `renderToString` of the component with `code` equal to `window.__ran = 1` | the string is exactly `<script>window.__ran = 1</script>` |
| document-load-script-002 | client-mount-renders-nothing | `DocumentLoadScript.test.tsx` "renders nothing on a client mount, so React never warns about it": client `render` of the component with a spy on `console.error` | the container has no `script` element and the spy was not called |
| document-load-script-003 | hydration-emits-script | `DocumentLoadScript.test.tsx` "hydrates the server node without a mismatch": server HTML from `renderToString` placed in a host element, then `hydrateRoot` of the same component with a spy on `console.error` | hydration finishes and the spy was not called |
| document-load-script-004 | code-verbatim | server render with `code` equal to `if (a < b && c) { x = "1" }` | the markup holds that text unescaped inside the `script` element, with no `&lt;`, `&amp;` or `&quot;` |
| document-load-script-005 | code-verbatim, no-error-surface | server render with `code` equal to the empty string | one empty `script` element is rendered and nothing throws |
| document-load-script-006 | trusted-code-only (documents the hazard, not desired behavior) | server render with `code` equal to `</script><b>x</b>` | the markup contains the closing tag text as given, ending the script element early; this vector records a known hazard that callers must avoid, and a conforming component does not guard against it |
| document-load-script-007 | leaves-tree-after-hydration, output-fixed-while-mounted | hydrate server HTML, then let React finish and commit the client snapshot | the component renders `null`; the `script` element is no longer in its tree |
| document-load-script-008 | script-no-attributes | server render with any `code` | the opening tag is exactly `<script>` with no attributes |
| document-load-script-009 | no-side-effects, no-state-no-effects | render on the client with `window.addEventListener`, `document.addEventListener`, `dispatchEvent`, `localStorage`, `sessionStorage` and `console` spied | no `addEventListener` or `dispatchEvent` call is made, no `localStorage` or `sessionStorage` access occurs, and no `console` method is called |

