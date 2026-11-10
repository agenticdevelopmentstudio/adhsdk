
Every user-facing string in this directory is a hardcoded English literal
with no localization mechanism (no `Intl`, no message catalog, no `t()`
call):

- `ChatBackendAdapter`'s catch-all apology: `"Sorry, something went wrong.
  Let's try again."`
- `ChatBackend`'s `sendMessage`/`submitWidgetResponse` error messages:
  `'ChatBackend has no attachment channel; send text only.'`, `'ChatBackend
  does not support interactive widgets.'`, `'ChatBackendAdapter has been
  destroyed.'`.
- `FetchBackend`'s HTTP-error message template: `` `Chat backend error:
  ${status}` ``.
- `MockBackend`'s entire `DEFAULT_RESPONSES` table (all seven canned replies,
  their `popover` titles/descriptions, and link labels) and its fallback
  string `` `I don't know that one. Try: ${commands}` ``.
- `PersonaChatBackend`'s fallback error strings: `"Couldn't start the
  conversation."`, `` `Couldn't start the conversation (${status}).` ``,
  `'The chat request failed.'`, `'No response stream from adh.'`,
  `'PersonaChatBackend does not support attachments.'`,
  `'PersonaChatBackend does not support widgets.'`,
  `'PersonaChatBackend has been destroyed.'`, `'The chat stream failed.'`.

None of these strings pass through any localization layer; a non-English
deployment would need to intercept or replace them at a layer above this
directory.

