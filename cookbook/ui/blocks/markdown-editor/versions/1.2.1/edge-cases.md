
- With `quickReference={false}` and no `onUpload`/`toolbarExtras`, there are no
  controls, so the toolbar row is omitted entirely (no empty `role="toolbar"`).
- The same file chosen twice in a row still fires `onUpload` twice — once per
  selection — because the native input value is reset after each selection.
- `onUpload` reports raw file text + name only; deriving a title (or anything
  else) is the consumer's job — the editor never mutates `value` from an upload.
- Each instance gets a distinct `useId` textarea id, so multiple editors on one
  page never collide on the Label↔Textarea association.
- An empty `value` shows the `placeholder`; the editor renders no empty/error
  state of its own (the body is always valid text — validation belongs to the
  consuming form).
- Disabling the editor (`disabled`) reaches the textarea and the upload
  control only; the quick-reference control and any `toolbarExtras` stay
  interactive (see **propagate-disabled**).

