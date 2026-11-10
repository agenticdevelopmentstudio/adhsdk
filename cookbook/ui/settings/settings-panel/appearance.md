
- **Corner radius**: Not set by this component; it draws nothing of its
  own. Any corner radius on screen belongs to whatever group view cards a
  subclass adds (10pt corner radius by default; see
  [adhsdk.ingredient.ui.settings.layout.group-view](cookbook:775f1761-f757-41d0-b51b-354a410a11f4)).
- **Padding**: Not set by this component. The panel inset and inter-group
  spacing (20pt each, by default) belong to its own content view, hosted
  unchanged; see
  [adhsdk.ingredient.ui.settings.layout.panel-view](cookbook:4b1a3eb0-0a8a-4059-b2ac-824013072bd5).
- **Font**: Not applicable — this component sets no font of its own; any
  text rendered comes from the group views a subclass composes, or from
  content hosted through the hosting helper, whose fonts are the
  subclass's responsibility.
- **Background**: Not set by this component. Its content view paints the
  theme's window-background role behind the group stack, reactively,
  through its own theme-change subscription; see
  [adhsdk.ingredient.ui.settings.layout.panel-view](cookbook:4b1a3eb0-0a8a-4059-b2ac-824013072bd5).
- **Foreground/Text**: Not applicable — this component renders no text of
  its own.
- **Border**: Not applicable — no border is set anywhere in this
  component.
- **Shadow**: Not applicable — no shadow or layer-shadow property is set
  anywhere in this component.
- **Min/Max size**: The component sets no min/max size constraint on its
  own view. Its hosting helper deliberately avoids installing one on the
  content it hosts — see Design Decisions for why a sizing preference is
  used instead of a hard size constraint.

