
| ID | Requirements | Input | Expected |
|-------|--------|-------|----------|
| skeleton-001 | render-as-div, slot-attribute | Render `<Skeleton />` | Element in DOM with tag name `DIV` and `data-slot="skeleton"` attribute |
| skeleton-002 | pulsing-animation, rounded-corners, surface-background | Render `<Skeleton />` and inspect computed style | Computed `animation-name` is not `"none"` (the pulse keyframe is applied), computed `border-radius` equals the medium radius token's resolved value, and computed `background-color` equals the secondary surface token's resolved value |
| skeleton-003 | class-merge, pulsing-animation, rounded-corners | Render `<Skeleton className="w-12 h-12" />` | Computed width/height reflect the custom sizing classes, while computed `animation-name` and `border-radius` still show the built-in pulsing animation and corner radius |
| skeleton-004 | html-passthrough | Render `<Skeleton id="loader" data-testid="skeleton-1" />` | Element has attributes `id="loader"` and `data-testid="skeleton-1"` |
| skeleton-005 | html-passthrough | Render `<Skeleton style={{ width: '100px', height: '100px' }} />` | Element has `style` attribute with specified width and height |
| skeleton-006 | pulsing-animation | Render `<Skeleton />` and read the computed `animation-name` and its `@keyframes` | `animation-name` resolves to a pulse keyframe whose rule cycles opacity `1 → 0.5 → 1`, with `animation-iteration-count: infinite` |
| skeleton-007 | reduced-motion-support | Render `<Skeleton className="motion-reduce:animate-none" />` under a `prefers-reduced-motion: reduce` media context | Computed `animation-name` is `"none"` |
| skeleton-008 | aria-hidden-while-loading, html-passthrough | Render `<Skeleton aria-hidden="true" />` inside a parent with `aria-busy="true"` | The skeleton element has `aria-hidden="true"`; the parent's `aria-busy="true"` is unaffected |

