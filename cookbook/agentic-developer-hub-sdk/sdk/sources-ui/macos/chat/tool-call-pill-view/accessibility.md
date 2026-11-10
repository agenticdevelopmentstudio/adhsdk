
- **Role**: The pill container is a plain `NSView` that sets no accessibility role, label, or value and is not itself an accessibility element; the only element VoiceOver reaches is the inner `NSTextField(labelWithString:)`, which exposes the static-text role.
- **Label and value**: The source makes no `setAccessibility*` calls. VoiceOver reads the label's `stringValue` — the same text `title(for:)` paints: the command name alone while running or on success, and `"<name> — <message>"` on a failure that carries a non-empty `errorMessage`.
- **Status reading**: Status is not announced. Running and success read identically (just the command name), and a failure with a `nil` or empty `errorMessage` also reads as just the name, so VoiceOver users cannot tell those states apart; only a failure with a message is audibly distinct, via its appended text. No accessibility notification is posted when the status changes.
- **Truncated text**: VoiceOver reads the full `stringValue`, including any portion hidden by the tail ellipsis from `truncate-overflow-text`.
- **Keyboard focus**: The pill is not focusable. The label is a non-editable, non-selectable static text field, and the view does not override `acceptsFirstResponder`, so it never enters the key-view loop and has no keyboard interaction.
- **Hit target**: The pill is display-only with no click, gesture, or action handling, so no interactive hit-target minimum applies. The source sets no minimum size; its height is the caption font's line height plus 8 points of vertical padding.
- **Color dependence**: Status is conveyed visually only by the text and border color (`.info` / `.success` / `.danger`); see **Differentiate Without Color** under Accessibility Options.
- **contrast-verification**: NEEDS REVIEW: Not implemented in source. Text and border colors come from `SemanticPalette` roles drawn on the `elevated-surface` background, and the ratio depends on the active theme, so contrast cannot be decided from this file.

