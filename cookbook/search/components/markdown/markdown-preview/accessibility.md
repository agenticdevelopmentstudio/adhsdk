
- **Role**: The root container carries no explicit ARIA role; the error state container is marked with `role="alert"` to announce failures to screen readers.
- **Live region**: The loading state container is marked with `aria-live="polite"` and `aria-busy="true"` to announce the loading phase. The empty state has no live-region marking — its arrival is not announced.
- **Label**: The error detail text serves as the accessible error message; the Retry button's accessible name comes from its visible text content, "Retry".
- **Markdown rendering**: Content is rendered by `MarkdownRenderer` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.sources-ui.shared.markdown.markdown-renderer](cookbook:316aed50-a6cb-4ece-977c-8d6dacb2186b)), which applies semantic HTML (headings, lists, code blocks) and ensures proper color contrast via the theme palette.
- **Keyboard interaction**: The Retry button is keyboard-accessible (Tab, Enter/Space to activate), per `Button`'s own recipe ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0)).
- **Minimum tap target**: The Retry button is a `Button` with `size="sm"` (28px tall) and no ancestor `--adh-button-min-height` override. Per Button's own recipe, `sm` clears the WCAG 2.2 SC 2.5.8 (Target Size Minimum, AA) 24×24 CSS px floor but falls below the Apple HIG 44×44pt / Material 48×48dp guidance unless a surface sets that override; this component sets none.

