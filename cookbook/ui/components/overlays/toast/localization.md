
- **Close button aria-label**: MUST be localized per **localize-close-label**. `Toaster` takes `closeLabel?: string` (default `"Close"`) and applies it as the close button's `aria-label`; callers pass their localized string, the package's label-prop convention (as `cancelLabel` in dialog-actions). Layout mirrors in right-to-left locales: the viewport uses `end-4` and the close button `end-0`.

