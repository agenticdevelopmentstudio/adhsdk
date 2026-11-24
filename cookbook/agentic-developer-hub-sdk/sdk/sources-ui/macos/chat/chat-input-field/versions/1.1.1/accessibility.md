
- **Role**: Text input field (semantic role)
- **Label**: MUST have an accessible label. On web, "Message" is hardcoded via `aria-label`. On macOS (AppKit), the source sets no accessible label on the input — a genuine gap; VoiceOver has only the placeholder to fall back on — see **provide-accessible-label**
- **Keyboard navigation**: Input MUST be focusable via Tab key. Send button MUST be keyboard-accessible (Enter triggers send on focused input, or Tab+Space on the button)
- **Announce state changes**: When input transitions to empty → disabled or disabled → enabled, the disabled state of the send button SHOULD be announced to screen readers. Source has no `aria-live` region or equivalent to drive this today; the change is only as announceable as the native `disabled` attribute is when the button itself receives focus.
- **Touch/Click target**: Minimum 44×44pt on iOS; 48×48dp on Android. Send button MUST meet this minimum
- **Color contrast**: Text MUST have sufficient contrast against background per WCAG AA (minimum 4.5:1 for normal text)
- **Don't rely on color alone**: State changes (focused, disabled) MUST use both color and other visual properties (border, opacity) per "Differentiate Without Color" accessibility guidelines

