
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| connector-anchor-001 | render-as-span | Component rendered with id="point-a", registry available | DOM contains a `<span>` element. |
| connector-anchor-002 | accept-id | id="my-anchor", registry available | Rendered span has attribute `data-connector-anchor="my-anchor"`. |
| connector-anchor-003 | register-with-registry | Component mounted with id="test", registry available | Registry's register method called with id="test" and the span's DOM reference. |
| connector-anchor-004 | return-null-if-no-registry | Component mounted, registry unavailable (hook returns null) | Component renders nothing; no DOM elements created. |
| connector-anchor-005 | set-data-connector-anchor | id="anchor-1" | Rendered span has attribute `data-connector-anchor="anchor-1"`. |
| connector-anchor-006 | be-aria-hidden | Component rendered | Rendered span has attribute `aria-hidden="true"`. |
| connector-anchor-007 | accept-classname | id="x", className="custom-class", registry unavailable | Component renders nothing (returns null); no error is thrown. |
| connector-anchor-008 | support-class-composition | className="custom-class" | Rendered span's class attribute is "pc-connector-anchor custom-class". |
| connector-anchor-009 | support-class-composition | className undefined | Rendered span's class attribute is "pc-connector-anchor". |
| connector-anchor-010 | re-register-on-id-change | id changes from "old-id" to "new-id" | Registry's register method is called with "new-id" when the id prop updates. |
| connector-anchor-011 | return-null-if-no-registry, register-with-registry | First render, registry unavailable; then registry becomes available | Component renders nothing on the first render; once the registry becomes available, the component re-renders, registers with the registry, and renders the span. |
| connector-anchor-012 | unregister-on-unmount | Component mounted and registered with id="test", registry available; then unmounted | Registry's returned cleanup function is called; the "test" entry is removed from the registry. |
| connector-anchor-013 | re-register-on-id-change | id changes from "old-id" to "new-id" | The "old-id" entry is unregistered from the registry before "new-id" is registered. |

