
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; the text field's value equals the view model's value, rendered as plain typed characters. |
| Editing | Not styled by the component — no focus-ring customization is applied; the platform's own default focus indicator applies when the field becomes focused. |
| Committed | After the field's edit-completion signal fires (on Return and on the field losing focus, per the platform's own default semantics) and the new value differs from the committed value, the new value is written into the committed value. |
| Placeholder shown | Shown while an editable field is empty, once the caller sets the component's `placeholder` option (the view model carries no placeholder value of its own). Setting it puts the text on every editable field and styles it at once in the theme's placeholder-text color and body-role font; every later theme change restyles it per restyles-existing-placeholder. It is never styled by the construction-time theme apply, which runs before the option can be set (see Design Decisions). |
| Disabled | Not implemented: the enabled state is never read or set on the label or the text field. A caller may set the text field's enabled state directly through the exposed property, at which point the platform's native disabled dimming applies. |
| Pressed | Not applicable: a text field has no discrete pressed state distinct from becoming focused and placing the caret; no such state is drawn. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator. |

