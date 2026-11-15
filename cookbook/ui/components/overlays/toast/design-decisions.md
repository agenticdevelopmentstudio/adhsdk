
**Decision**: Position the toast viewport at the bottom inline-end corner (bottom-right in left-to-right locales, via `end-4`) rather than top-center or full-width.
**Rationale**: Avoids blocking critical interface elements and keeps toasts out of the visual center; bottom-right is a common placement for transient system notifications in desktop web applications, distinct from primary content and navigation regions.
**Approved**: pending

**Decision**: Use opacity-only animation for entrance and exit rather than slide-out or scale-down.
**Rationale**: A fade is one visual property and involves no movement, so there is no slide or scale to distract from the page. The source applies it with `transition-all` on the toast root, which animates every property rather than opacity alone.
**Approved**: pending

**Decision**: Render the toast through `ToastPrimitive.Portal`.
**Rationale**: Escapes the local DOM hierarchy, preventing stacking-context issues and keeping z-index management consistent.
**Approved**: pending

**Decision**: Rely on Base UI's default dismiss behaviors rather than overriding them: the source re-exports `ToastPrimitive.Provider` and `ToastPrimitive.Root` with no `timeout` or `swipeDirection` override, so in addition to clicking Close, a toast auto-closes after Base UI's default 5000ms timeout (paused while hovered or focused), closes on Escape when focus is inside it, and can be swiped away (down or right, past a 40px threshold); these are specified as **auto-dismiss-timeout**, **dismiss-on-escape** and **dismiss-on-swipe**.
**Rationale**: Adopting Base UI's defaults gives users several independent ways to dismiss a toast without the component reimplementing any of them; the Close button remains available as an explicit, discoverable control for users who prefer not to wait, swipe, or use the keyboard.
**Approved**: pending

**Decision**: Reference design tokens (`apt-surface-2`, `apt-text`, `apt-gold/40`, etc.) for background, text, and focus-ring colors rather than hardcoded hex values.
**Rationale**: Enables consistent theming across the application.
**Approved**: pending

