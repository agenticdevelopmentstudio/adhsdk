
- **One surface fill painted once**
  **Decision**: The chat surface (Apple `palette.nsColor(.chatSurface)`) is painted exactly once, at the root view level (Apple `applyTheme`), and never repeated by sub-containers.
  **Rationale**: Painting the surface once prevents stacking opacity when the surface is translucent, and ensures the `surfaceTransparency` multiplier applies to a single layer rather than compounding across nested fills.
  **Approved**: pending

- **Engagement-driven sizing is opt-in**
  **Decision**: The component defaults to fixed sizing (today's behavior: `>= 200pt` minimum height); engagement tracking and dynamic sizing activate only when `sizing.inactive` is explicitly set.
  **Rationale**: This preserves backward compatibility for call sites that do not need collapsing behavior.
  **Approved**: pending

- **Minimal mode uses exact zero, not isHidden**
  **Decision**: In minimal mode, the transcript height constraint is set to exactly 0 rather than relying on `isHidden` alone.
  **Rationale**: `isHidden` alone leaves AppKit constraints active, which would let the transcript retain its old height behind the hidden view.
  **Approved**: pending

- **Block caret blinking is separate from chrome**
  **Decision**: `blinksCaret` is a user-preference setting (per-reader), kept separate from `chrome.usesBlockCaret`, a design-system choice (per-theme).
  **Rationale**: This separation allows a theme to prefer block carets while the reader independently disables blinking.
  **Approved**: pending

- **Status prioritizes remote statuses over typing flag**
  **Decision**: When multiple participants are active, `refreshStatus()` sorts remote participants by ID and uses the first status value; when no remote participant has an explicit status, it falls back to whether any remote participant is typing. The local participant is filtered out of both checks, so the local user's own `isTyping` flag never drives the indicator.
  **Rationale**: This avoids echoing the user's own activity back at them, matching the equivalent web design pattern.
  **Approved**: pending

- **Click-outside detection uses local monitor**
  **Decision**: Apple's click-outside detection uses `NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown)` rather than a global monitor.
  **Rationale**: The component belongs to a specific window and should not disrupt the rest of the application.
  **Approved**: pending

- **Prompt baseline drop is computed, not hard-coded**
  **Decision**: The prompt glyph's baseline offset (`PromptGlyphAlignment.baselineDrop()`) is derived per font at every theme and text-scale change, rather than hard-coded.
  **Rationale**: The prompt glyph and composed text use different font families and widths, so a shared baseline does not center the ink; the constant must be recomputed whenever either font changes.
  **Approved**: pending

- **Drafts render through same bubble as messages**
  **Decision**: In-flight drafts are adapted to the `Message` protocol (`DraftMessageAdapter`) so they reuse the same `MessageBubbleView` styling as committed messages.
  **Rationale**: Reduces duplication and keeps draft appearance in sync with messages.
  **Approved**: pending

- **Auto-scroll tolerance is 40pt**
  **Decision**: The at-bottom threshold for auto-scroll is 40pt (Apple).
  **Rationale**: Allows minor scroll bounce and interaction without triggering a false "scrolled away" state, while still stopping auto-scroll once the user deliberately scrolls up to read history.
  **Approved**: pending

- **Thinking indicator is not in scrolling transcript**
  **Decision**: The status row sits between the transcript scroll view and the input row, not inside the transcript.
  **Rationale**: Keeps the status line always visible at eye level where the user is typing, even on a long conversation.
  **Approved**: pending

