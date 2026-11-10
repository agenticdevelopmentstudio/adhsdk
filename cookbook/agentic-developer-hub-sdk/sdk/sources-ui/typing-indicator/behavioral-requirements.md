
- **support-two-rendering-paths**: The component MUST support two distinct rendering paths selected by whether status words are configured: a three-dot pulsing animation, or a phase-driven line with an animating glyph and rotating status word. See **handle-empty-word-bag** for the exact rule selecting the dot-pulse path when words are empty, absent, or malformed.

- **render-dots-pulse-when-inactive**: In the three-dot rendering path, when the typing status is inactive (false or null), the web component MUST NOT render any visual indicator. On macOS/iOS, the three dots are created visible at setup (30% alpha) and are never hidden by the dot path or by the host chat view; `update(status: nil)` only stops the pulse timer, leaving whichever dot the last tick lit frozen at its current alpha.

- **render-dots-pulse-when-active**: In the three-dot rendering path, when the typing status is active (true or non-null), the component MUST render three circular dots that animate sequentially by fading to full opacity while others fade to 30% opacity on a 0.35-second cycle.

- **cycle-through-status-words**: When status words are configured, the component MUST cycle through the provided word list using draw-without-replacement (each word in the vocabulary is shown once before any word repeats). The transition to a new word MUST occur on the `labelMs` interval (default 1800ms).

- **animate-glyph**: The component MUST animate a rotating glyph character on the `frameMs` interval (default 260ms). The glyph cycles through the provided frame array in order.

- **support-phase-machine**: The component MUST drive phase transitions (idle, thinking, utterance, done) using a shared phase machine that tracks when a turn begins and ends, manages word bag state, and calculates elapsed time.

- **show-active-line-while-typing**: When the phase is "thinking" (during active response generation), the component MUST display the current glyph followed by a space and the current status word with an ellipsis (e.g., "⠙ thinking…"). The text MUST use the `.personaName` color by default.

- **show-utterance-when-provided**: When an utterance is provided (caller-set transient text), the component MUST display it immediately with the animating glyph, overriding any phase-driven content — including the settled line (see **show-settled-line-when-done**). On web, the utterance MUST persist only until explicitly cleared by the caller. On macOS/iOS, the shared `ThinkingPhase.Machine` does not honor this persistence across a turn transition or a fresh status while an utterance is showing; see the **Turn transitions during utterance** edge case.

- **show-settled-line-when-done**: When the phase is "done" (the active turn has ended) and no utterance is currently showing, the component MUST display the done glyph followed by a space, the past-tense form of the last status word, and elapsed seconds in the format "[glyph] [past word] for [N]s". This line MUST use the `.thinkingDoneText` color and MUST NOT be tinted by the `colorful` or `tint` configuration options. On web, if an utterance is showing when the turn settles, **show-utterance-when-provided** wins: the settled line MUST NOT appear until the caller clears the utterance. On macOS/iOS, the shared phase machine settles `.utterance` straight into `.done` on the turn ending, so the settled line replaces the utterance immediately and the caller's later call to clear the utterance is a no-op; see the **Turn transitions during utterance** edge case.

- **show-idle-phrase-when-configured**: When an idle phrase is configured and the phase is "idle" (before the first turn), the component MUST display the idle phrase with the done glyph and an ellipsis using `.thinkingIdleText` color.

- **not-show-idle-phrase-when-not-configured**: When no idle phrase is configured, the component MUST render no visual indicator during the idle phase.

- **reset-idle-on-first-turn**: The idle phrase, when shown, MUST yield to the thinking state on the first turn transition and never return.

- **support-frame-configuration**: The component MUST accept a frame array containing character strings that form a rotating animation. The default frame array is the ten-character braille spinner sequence: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'].

- **support-done-glyph-configuration**: The component MUST accept a single character to display as the settled/done glyph. The default is '✱'.

- **support-frame-interval-configuration**: The component MUST accept a frame interval duration in milliseconds (default 260ms) controlling how often the glyph animation advances.

- **support-word-interval-configuration**: The component MUST accept a word interval duration in milliseconds (default 1800ms) controlling how often the status word rotates.

- **support-colorful-mode**: When `colorful` is enabled, the component MUST flash vivid random non-green hues while thinking or uttering. A non-green hue is one that skips the hue band approximately 75°–165° (greens). The color MUST be generated at HSL 85% saturation and 62% lightness. The color MUST NOT be applied to the settled line. On web, the color MUST change on a 1-second cycle during active phases. On macOS (the only other platform where `colorful` is supported; see Configuration), the color is drawn once when a fresh think begins and once per `say()` call, then held for the rest of that phase — it does not recycle every second.

- **support-tint-configuration**: The component MUST accept an optional tint specification that colors the glyph, words, or both while thinking or uttering. The tint MUST NOT be applied to the settled line when done.

- **support-utterance-clear**: The component MUST provide a mechanism for the caller to clear a transient utterance, causing the indicator to resume showing phase-driven content.

- **announce-status-changes**: The component MUST post accessibility announcements when the phase changes (entering thinking, settling to done) or when a fresh utterance is set. Announcements MUST NOT occur on every frame tick or on every status-word rotation — only on phase transitions and utterance changes.

- **respond-to-theme-changes**: The component MUST listen for theme/palette changes and repaint immediately to reflect new semantic colors without requiring component restart.

- **maintain-glyph-box-width**: In platform representations that separate the glyph from the word text (e.g., AppKit/macOS), the glyph MUST occupy a fixed-width box that does not change based on the current frame. The box MUST be wide enough to accommodate the widest frame character in the configured font.

- **handle-empty-frame-array**: If the frame array is empty (malformed configuration), the component MUST render an empty string for the glyph and not crash.

- **handle-empty-word-bag**: If status words are empty, absent, or otherwise malformed (e.g., configured but the array is empty), the component MUST fall back to the three-dot animation path.

