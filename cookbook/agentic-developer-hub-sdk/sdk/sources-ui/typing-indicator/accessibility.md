
- Role/trait: The component is a status indicator and does NOT require interactive controls.
- Label requirements: The indicator's content (status words, elapsed time, idle phrase) MUST be accessible to assistive technologies via a live region or announcement mechanism.
- Announce state changes: MUST announce via accessibility API when the phase changes or when a fresh utterance is provided. These announcements MUST be announced at medium or polite priority. Announcing every frame or every word rotation MUST NOT occur.
- Visual hidden text for screen readers: On web, an `aria-live` region holding the current phase announcement (separate from the visual DOM) MUST be present and updated only on phase transitions, not on every glyph frame.
- Minimum tap target: Not applicable; this component is a status display, not an interactive control.
- Color contrast: The status words and done text MUST meet WCAG AA contrast ratio requirements against their backgrounds when rendered in any theme, using the semantic palette's `.personaName`, `.thinkingDoneText`, and `.thinkingIdleText` colors. This guarantee does not extend to **support-colorful-mode**: its hue is drawn at a fixed 85% saturation / 62% lightness without checking the active theme's background, so a given draw is not guaranteed to meet AA contrast on every theme, particularly light ones.

