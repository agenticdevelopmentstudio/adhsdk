
- **Decision**: Use `role="region"` (not `role="log"` with `aria-live="polite"`) for the scroll container.
  **Rationale**: `role="log"` carries an implicit live region that announces on every mutation; streamed replies mutate the last bubble a token at a time, so a live region would re-announce the same growing sentence on every frame. `role="region"` lets the user navigate and read the transcript at their own pace, while the typing indicator signals that new content is coming without verbose re-announcement. See the WAI-ARIA `log` and `region` role definitions (references).
  **Approved**: pending

- **Decision**: Make the scroll container keyboard-focusable (`tabIndex={0}` on Web).
  **Rationale**: The container scrolls, and a scroll container that cannot take focus cannot be scrolled from the keyboard — there is no other way to reach the arrow keys' target. This is usually masked by a visible, draggable scrollbar; a theme that hides the scrollbar (e.g., substituting a fade for it) removes the last non-pointer affordance, and without focus, keyboard-only users would have no way to reach older messages.
  **Approved**: pending

- **Decision**: Anchor the fade mask to the bottom of the visible viewport, not to the bottom of the message stack.
  **Rationale**: A stack-anchored fade would keep the same messages faded no matter where the reader scrolls — once a message is dimmed by its position in the stack, it stays dimmed even after being scrolled back into view. A viewport-anchored fade instead computes opacity from position in the visible window, so scrolling any older message back down toward the bottom restores its full opacity, while the newest content still reads as the visual focus by default.
  **Approved**: pending

- **Decision**: Make `selectedIndex` optional, defaulting to `-1`.
  **Rationale**: Not every host needs message selection. Omitting the prop cleanly means no `MessageBubble` receives `isSelected={true}`, so selection state never interferes with hosts that don't use it.
  **Approved**: pending

- **Decision**: Keep `thinkingColorful` and `thinkingTint` as two separate props.
  **Rationale**: Colorfulness (flashing random non-green colors) and tint (applying a specific color tone to specific elements) are independent visual behaviors. Separating them lets a host flash colors without tinting, or tint without flashing.
  **Approved**: pending

- **Decision**: Render the `renderPopover` result as a sibling of `MessageBubble`, not nested inside it.
  **Rationale**: Keeping the message structure flat lets the host application control popover layout (positioning, sizing, animation) without fighting `MessageBubble`'s own DOM structure.
  **Approved**: pending

