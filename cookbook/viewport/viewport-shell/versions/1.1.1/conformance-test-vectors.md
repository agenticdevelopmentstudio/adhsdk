
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| viewport-001 | render-children | `<ViewportShell><div>Content</div></ViewportShell>` | Rendered div with text "Content" appears in the DOM as a child of the shell |
| viewport-002 | root-class | `<ViewportShell />` | Root element has class `viewport-shell` |
| viewport-003 | open-class, clip-prop | `<ViewportShell clip={false} />` | Root element has classes `viewport-shell` and `vp-shell--open`; computed `overflow` of the root element is `visible` |
| viewport-004 | class-name-merge | `<ViewportShell className="custom-class" />` | Root element has classes `viewport-shell` and `custom-class` |
| viewport-005 | ignore-empty-class-name | `<ViewportShell className="" />` | Root element has class `viewport-shell` only; empty string is not added to class list |
| viewport-006 | clip-prop | `<ViewportShell />` (clip omitted) | Root element does not have `vp-shell--open` class; computed `overflow` of the root element is `hidden` |
| viewport-007 | keyboard-inset | `<ViewportShell />` mounted, then `visualViewport` dispatches a `resize` event such that `innerHeight - visualViewport.height - visualViewport.offsetTop` equals 300 | `document.documentElement.style.getPropertyValue('--kb-inset')` equals `"300px"` |
| viewport-008 | page-lock | `<ViewportShell />` mounted with the package's `base.css` loaded | `getComputedStyle(document.documentElement).overflow` and `getComputedStyle(document.body).overflow` are both `"hidden"` |
| viewport-009 | page-lock | Two `<ViewportShell>` instances mounted at once, then one is unmounted | `document.documentElement`'s computed `overflow` stays `"hidden"` throughout; neither shell's mount nor unmount changes it |
| viewport-010 | render-children | `<ViewportShell>{null}</ViewportShell>` | Root element renders with no child content |
| viewport-011 | render-children | `<ViewportShell>{[]}</ViewportShell>` | Root element renders with no child elements |
| viewport-012 | render-children | `<ViewportShell><span>A</span><span>B</span></ViewportShell>` | Both children appear in the DOM as siblings, in the order provided |
| viewport-013 | class-name-merge | `<ViewportShell className="  " />` | The whitespace-only string is included verbatim in the joined class attribute; it is not trimmed or filtered out |
| viewport-014 | clip-prop, open-class | `<ViewportShell clip={true} />` re-rendered with `clip={false}`, then back to `clip={true}` | Class list and computed `overflow` update synchronously on each render; the same children instance is preserved, not remounted |

