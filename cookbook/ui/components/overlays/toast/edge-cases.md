
- **Empty title and description**: Toast renders with no title or description content; only close button visible. MUST NOT error.
- **Very long title text**: Title text MUST wrap to multiple lines and remain readable; no text truncation or overflow.
- **Very long description text**: Description text MUST wrap to multiple lines; container height expands to fit content.
- **Close button rapid clicks**: Rapid clicks on close button MUST dismiss toast once (no double-dismiss error); subsequent clicks on dismissed toast MUST have no effect.
- **Viewport overflow (many toasts)**: The viewport is a fixed flex container with vertical layout and no overflow scrolling defined in the source. Base UI's `ToastProvider` accepts a `limit` prop that caps the number of simultaneously visible toasts (marking the rest `data-limited` and excluding them from keyboard focus), but this component does not set one, so the cap is the library's default of 3 rather than a value this recipe controls (see **set-explicit-limit**).
- **Viewport near right or bottom edge**: When rendered near right or bottom edges, toast MUST respect max-width and not overflow window; responsive max-width constraint ensures this.
- **Multiple providers in same app**: See **independent-provider-queues** (toast-013). Each `ToastProvider` instance reads and writes only its own React context, so nested or sibling providers never share a queue.

