
- **No children**: `children` is required by the component's type, but an untyped caller that omits it gets an empty container; padding is still applied.
- **Multiple className strings**: If `className` contains spaces or multiple class names, all are preserved in the output.
- **Base stylesheet not loaded**: `--kb-inset` and `--safe-bottom` are defined only by `:root` rules in the package's `base.css` (imported once at the app root per the package's setup instructions). Without that stylesheet the `.vp-composer` rule itself is also absent, so the composer gets no bottom padding and no transition at all, not a padding of `0`. With `base.css` loaded, both terms of **adjust-bottom-padding** are always valid.
- **Safe area not present (unsupported browser)**: On browsers without `env()` support for `safe-area-inset-bottom`, `--safe-bottom` falls back to `0px`; the component continues to function with keyboard-only padding.
- **Missing `viewport-fit=cover`**: `env(safe-area-inset-bottom)` only reports a non-zero value when the page's viewport meta tag includes `viewport-fit=cover` (documented in the package's required HTML/Next.js setup). None of `ViewportShell`, `ViewportSpacer`, or `ViewportComposer` set this meta tag; providing it is the consuming app's responsibility.
- **Children unmount/remount**: The composer's own element and its computed `padding-bottom` are unchanged when its children are replaced.

