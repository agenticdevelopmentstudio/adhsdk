
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| secure-text-edit-view-001 | masks-entry-with-secure-field | Construct the component with any view model | The field is a secure, masking field, not a plain text field |
| secure-text-edit-view-002 | initializes-from-view-model | View model's value is "abc" | After construction the secure field's string value is "abc", displayed masked |
| secure-text-edit-view-003 | commits-value-on-change | User types "s3cret" into the secure field and the field's action fires | The view model's setting observer value is "s3cret" |
| secure-text-edit-view-004 | skips-redundant-commits | The field's action fires while its string equals the view model's current value | The view model's setting observer is not written |
| secure-text-edit-view-005 | syncs-on-external-change | The view model's value changes externally and its change callback fires | The secure field's string value shows the new value |
| secure-text-edit-view-006 | exposes-constituent-views | Read the row's label and text field after construction | The label shows the view model's title and the text field is the secure, masking field |
| secure-text-edit-view-007 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |
| secure-text-edit-view-008 | stored-secret-shows-as-dots, reveal-state-not-persisted | Construct with a stored value "sk-123" | The field shows six dots; the eye shows the reveal glyph |
| secure-text-edit-view-009 | eye-toggles-reveal, eye-icon-tracks-state | Value "sk-123"; press the eye | The field shows "sk-123" in plain text; the eye shows the conceal glyph; the setting is not written |
| secure-text-edit-view-010 | eye-toggles-reveal | Shown; press the eye again | The field shows six dots; the eye shows the reveal glyph |
| secure-text-edit-view-011 | copy-puts-secret-on-pasteboard | Obscured, value "sk-123"; press copy | The general pasteboard's string is "sk-123" |
| secure-text-edit-view-012 | copy-disabled-when-empty | Value "" | The copy button is disabled |
| secure-text-edit-view-013 | reobscure-on-window-resign-key | Shown; the window resigns key | The field is obscured |
| secure-text-edit-view-014 | reobscure-on-app-resign-active | Shown; the app resigns active | The field is obscured |
| secure-text-edit-view-015 | reobscure-on-leave-window | Shown; remove the row from its window and add it back | The field is obscured |
| secure-text-edit-view-016 | reobscure-on-external-change | Shown; the setting changes elsewhere to "sk-999" | The field is obscured and holds "sk-999" |
| secure-text-edit-view-017 | edits-commit-in-either-state | Shown; type "sk-777" and the field's action fires | The setting is "sk-777" |
| secure-text-edit-view-018 | own-commit-keeps-shown | Shown; type "sk-456" and the field's action fires | The setting is "sk-456" and the field is still shown |
| secure-text-edit-view-019 | labels-accessory-buttons | Value "sk-123"; read the buttons' accessibility labels, press the eye, read the eye's again | Copy is "Copy"; the eye is "Show", then "Hide" |
| secure-text-edit-view-020 | accessory-buttons-follow-field-in-key-order | Read the key-view order from the field, obscured and shown | The field leads to the copy button, and the copy button to the eye |
| secure-text-edit-view-021 | trailing-accessory-buttons | Lay the row out wider than its content | The copy button, then the eye, sit after the field at the row's trailing edge; the field takes the leftover width |
| secure-text-edit-view-022 | copy-puts-secret-on-pasteboard | Shown, value "sk-123"; press copy | The general pasteboard's string is "sk-123" |
| secure-text-edit-view-023 | reveal-state-not-persisted | Show a row's value, then construct a new row over the same setting | The new row is obscured |
| secure-text-edit-view-024 | titles-fields-with-label | Construct with title "API Key"; read each field's accessibility title element, obscured and shown | Both the masked field and the shown field are titled by the row's label, which reads "API Key" |

All other conformance test vectors — row layout, content-hugging, action
wiring, view-model sync, theme styling, placeholder restyling,
constituent-view exposure, the initializer traps, and UI-thread
confinement — are inherited unmodified from the text edit row; see
conformance-test-vectors ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)).

