
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| connector-anchor-001 | render-as-span | Component rendered with id="point-a", registry available | DOM contains a `<span>` element. |
| connector-anchor-002 | accept-id, register-with-registry | id="my-anchor", registry available | Registry's register method is called with "my-anchor" as its first argument. |
| connector-anchor-003 | register-with-registry | Component mounted with id="test", registry available | Registry's register method called with id="test" and the span's DOM reference. |
| connector-anchor-004 | return-null-if-no-registry | Component mounted, registry unavailable (hook returns null) | Component renders nothing; no DOM elements created. |
| connector-anchor-005 | set-data-connector-anchor | id="anchor-1" | Rendered span has attribute `data-connector-anchor="anchor-1"`. |
| connector-anchor-006 | be-aria-hidden | Component rendered | Rendered span has attribute `aria-hidden="true"`. |
| connector-anchor-007 | accept-classname | id="x", className="custom-class", registry available | The rendered span's class list contains "custom-class". |
| connector-anchor-008 | support-class-composition | className="custom-class" | Rendered span's class attribute is "pc-connector-anchor custom-class". |
| connector-anchor-009 | support-class-composition | className undefined | Rendered span's class attribute is "pc-connector-anchor". |
| connector-anchor-011 | return-null-if-no-registry, register-with-registry | First render, registry unavailable; then registry becomes available | Component renders nothing on the first render; once the registry becomes available, the component re-renders, registers with the registry, and renders the span. |
| connector-anchor-012 | unregister-on-unmount | Component mounted and registered with id="test", registry available; then unmounted | Registry's returned cleanup function is called; the "test" entry is removed from the registry. |
| connector-anchor-013 | re-register-on-id-change | id changes from "old-id" to "new-id" | The "old-id" entry is unregistered from the registry before "new-id" is registered, and the registry's register method is called with "new-id". |
| connector-anchor-014 | re-register-on-registry-change | Anchor mounted with registry A; the provided registry changes to registry B | Registry A's cleanup function is called; registry B's register method is called with the same id and the span. |
| connector-anchor-015 | support-class-composition | className="" | Rendered span's class attribute is "pc-connector-anchor". |
| connector-anchor-016 | support-class-composition | className=" " (whitespace) | Rendered span's class attribute is "pc-connector-anchor  " (base class, one separator space, then the whitespace as given). |
