
- **Role/trait**: The options use native controls (a checkbox, two pop-up buttons,
  a text field), which carry their own roles; the chat view owns its own.
- **Label requirements**: Each control has a stable accessibility identifier
  (`personaTerminalChat.options.connect`, `.provider`, `.model`, `.persona`); the
  connect checkbox is titled by its text.
- **control-labels**: NEEDS REVIEW: Not implemented in source. The provider picker, model picker and persona field get an accessibility identifier but no accessibility label or label association with the plain text label above each; evidence to settle it is a VoiceOver pass over the options sheet.
- **Announce state changes**: The status line is set through `setStatus` on the chat
  view; the controller posts no accessibility announcement itself.
- **Minimum tap target**: Not applicable: native macOS controls at their standard
  sizes; the source sets no target size.

