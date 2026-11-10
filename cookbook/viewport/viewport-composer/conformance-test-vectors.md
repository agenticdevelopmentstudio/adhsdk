
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| vp-composer-001 | render-children | `<ViewportComposer><button>Send</button></ViewportComposer>` | Button element renders as the sole child of the container, at the same position it was passed, with no wrapper element inserted |
| vp-composer-002 | compose-classname | `<ViewportComposer className="custom-class">Text</ViewportComposer>` | Rendered element's class attribute is `vp-composer custom-class` |
| vp-composer-003 | compose-classname | `<ViewportComposer>Text</ViewportComposer>` (no `className`) | Rendered element's class attribute is `vp-composer` only |
| vp-composer-004 | adjust-bottom-padding | Unit test: render `<ViewportComposer>` and read the `padding-bottom` and `transition` declarations applied to `.vp-composer` | `padding-bottom` declaration is `calc(var(--kb-inset) + var(--safe-bottom))`; `transition` includes `padding-bottom 180ms ease-out` |
| vp-composer-005 | adjust-bottom-padding | Playwright: set `--kb-inset: 300px` on the enclosing `ViewportShell` root and measure the composer | Composer's resolved bottom padding equals `300px` plus the device's safe-area-inset-bottom, and its bounding box shifts upward by that amount |
| vp-composer-006 | kb-inset-read-only | Inspect the component's source and its rendered output | ViewportComposer neither imports nor calls `useKeyboardInset()` and sets no inline style or property on `--kb-inset`; the variable's only writer is `useKeyboardInset()`, mounted by `ViewportShell` |

