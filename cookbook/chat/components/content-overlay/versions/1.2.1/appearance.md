
Traced to `packages/web/packages/chat/src/css/components/content-overlay.css`.

- **Corner radius**: None. Root, header, close button, and body are unrounded.
- **Padding**: Header: `10px 12px`. Close button: `6px 0`. Root bottom: `calc(env(safe-area-inset-bottom, 0px) + 44px)`. Body bottom: `env(safe-area-inset-bottom, 0)`.
- **Font**: Close button: `var(--font-mono, ui-monospace, SFMono-Regular, monospace)`, `0.65rem`, `0.06em` letter-spacing.
- **Background**: Root: `rgba(10, 10, 14, 0.3)` with `backdrop-filter: blur(16px)` (`-webkit-backdrop-filter` included for Safari). Header, close button, and body have no background of their own.
- **Foreground/Text**: Close button text: `var(--text-muted, #8a8a9a)` by default, `var(--accent, #c4a35a)` while pressed (`:active`).
- **Border**: Header: `1px solid rgba(42, 42, 54, 0.4)` bottom border. Close button and body have no border.
- **Shadow**: None defined.
- **Min/Max size**: Root fills the viewport (`position: fixed; top/left/right/bottom: 0`). No min/max constraints on header, close button, or body; body uses `flex: 1; min-height: 0` to fill remaining vertical space.
- **Z-index**: Root: `z-index: 1`.
- **Transitions**: Root `opacity` transitions over `0.3s` with `cubic-bezier(0.16, 1, 0.3, 1)`, unconditionally (no `prefers-reduced-motion` gating — see **Accessibility Options**). Close button `color` transitions over `0.15s` (default easing).
- **Layout**: Root is a flex column (`display: flex; flex-direction: column; overflow: hidden`). Header does not shrink (`flex-shrink: 0`). Body is `flex: 1` and is itself a flex column.
- **Responsive**: No `pc-content-overlay`-specific responsive rules are defined in this stylesheet. (The same stylesheet file also carries a `@media (max-width: 768px)` block for `.persona-chat`, `.pc-input`, and `.pc-input-area` — those target content typically hosted in the body slot, e.g. a chat, and belong to the chat ingredient's stylesheet, not this one.)

