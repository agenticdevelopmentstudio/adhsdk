
- **page-lock**: The component MUST prevent `html` and `body` from scrolling. This is provided by the package's `base.css` (`html, body { overflow: hidden; overscroll-behavior: none }`), imported once at the app root — the shell does not set or restore this style itself, so mounting, unmounting, or nesting multiple `<ViewportShell>` instances has no effect on it.
- **render-children**: The component MUST render its `children` prop as the content of a flex container.
- **keyboard-inset**: The component MUST call `useKeyboardInset()` on render. The hook MUST write the `--kb-inset` CSS custom property, in pixels, onto `document.documentElement`, computed from `window.visualViewport`'s `height` and `offsetTop` on every `resize` and `scroll` event; descendants read the current inset via `var(--kb-inset)` (e.g. `ViewportComposer`'s `.vp-composer` bottom padding).
- **root-class**: The component MUST apply the CSS class `viewport-shell` to its root element.
- **clip-prop**: The component MUST accept a `clip` boolean prop that defaults to `true`. `.viewport-shell` sets `overflow: hidden`, so the default clips the shell's own overflow.
- **open-class**: When `clip` is `false`, the component MUST also apply the CSS class `vp-shell--open` to its root element. `.viewport-shell.vp-shell--open` sets `overflow: visible`.
- **class-name-merge**: The component MUST accept an optional `className` prop and append it to the root element's class list.
- **ignore-empty-class-name**: When `className` is `undefined` or the empty string `''`, the component MUST NOT add it to the class list. Any other string — including one that is only whitespace — is added as-is, since the implementation filters with `Array.prototype.filter(Boolean)`, which only removes falsy values.

