
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; the field's underlying value equals the view model's value, rendered as one dot-mask glyph per character — the platform's own built-in masked rendering, per the source's doc comment ("so the entry is dot-masked") — see **masks-entry-with-secure-field**. |
| Obscured | The default for every new row: dots, eye button shows `eye`. |
| Shown | The field shows the value in plain text; eye button shows `eye.slash`. Left for Obscured on window resign key, app resign active, leaving the window or an external change. |
| Empty | Copy button disabled; the eye still toggles. |
| All other states | Editing, Committed, Placeholder shown, Disabled, Pressed, and Loading are inherited unmodified from the text edit row; see states ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)). |

