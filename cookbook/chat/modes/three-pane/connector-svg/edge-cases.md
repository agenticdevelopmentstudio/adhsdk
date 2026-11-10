
- **Empty pairs array**: See **empty-pairs**.
- **Missing registry entries**: See **unresolved-pair-omission** — an identifier not found in the registry snapshot causes silent omission, not an error.
- **Null container ref**: See **null-container-ref**.
- **Rapid layout changes**: See **raf-batching** — multiple resize or scroll events firing in quick succession are deduplicated so only one recomputation happens per frame.
- **Unmount during scheduled animation frame**: See **raf-cancellation** — a pending frame callback is cancelled to prevent operations on unmounted DOM.
- **Element with zero dimensions**: An element with zero width or height still yields a valid center — for a 0×0 rect at (x, y), the center is (x, y) — and its connector line still renders using that point (see **connector-017**).

