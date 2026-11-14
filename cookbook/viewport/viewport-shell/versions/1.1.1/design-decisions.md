
**Decision**: `clip` defaults to `true`, which keeps `.viewport-shell`'s own `overflow: hidden`; passing `clip={false}` adds `vp-shell--open` (`overflow: visible`) for content that must deliberately overhang the shell's box, such as a corner badge.
**Rationale**: Most page layouts should constrain overflow to avoid unintended visual overflow and layout shift, so the overhang case is opt-in. The page itself stays locked (`overflow: hidden` on `html`/`body`, via `base.css`) regardless of `clip`, so opening the shell can never introduce a document-level scrollbar.
**Approved**: pending

**Decision**: `useKeyboardInset()` is mounted unconditionally rather than made opt-in.
**Rationale**: Virtual-keyboard tracking is a foundational concern for any page-level shell. The hook writes the `--kb-inset` CSS custom property onto `document.documentElement`, so any descendant can read `var(--kb-inset)` in its own CSS — as `ViewportComposer`'s `.vp-composer` bottom padding does — without prop threading or a React context.
**Approved**: pending

