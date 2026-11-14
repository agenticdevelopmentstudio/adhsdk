
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Textarea | [adhsdk.ingredient.ui.components.inputs.textarea](cookbook:1e323e69-44d2-4a15-a11e-22a68e8e6a8c) | The markdown source field | yes | `id` (from `useId`), `rows`, `spellCheck`, mono font |
| Label | [adhsdk.ingredient.ui.components.inputs.label](cookbook:c5703986-6d14-4341-8719-b89e44f2ab80) | Caption bound to the textarea via `htmlFor` | yes | mono uppercase caption styling |
| EditorToolbar | [adhsdk.ingredient.ui.components.actions.editor-toolbar](cookbook:3c65c844-6c3c-43e2-b792-8575f5dda9cf) | `role="toolbar"` row holding the controls | yes | `ariaLabel` |
| MarkdownQuickReference | [adhsdk.ingredient.ui.components.actions.markdown-quick-reference](cookbook:f5d2eb1c-fb0e-48e3-b124-7e730ac8231c) | Built-in quick-reference popover control | optional (`quickReference`, default on) | side/align defaults |
| Button | [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) | The "Upload .md" trigger | optional (only when `onUpload` set) | `variant="outline" size="sm"` |

> The Textarea, Label, and EditorToolbar are atomic `@adh-sdk/ui` primitives
> reused as-is; the upload control wraps a hidden native `<input
> type="file">` (the only way to open a file picker — recorded with an
> `adh-ui-allow: cs-no-bespoke` marker in the source).

