
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| AlertAndDialog | [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) | The dialog shell, sized to a moderate maximum width, plus the discard-confirm alert | yes | modal semantics; discard-confirm copy |
| RecipientInput | [adhsdk.ingredient.ui.components.inputs.recipient-input](cookbook:d9ad192e-a642-46a2-8b25-b8aac9d9f441) | Per-section recipient list, configured for email recipients or phone recipients | yes | recipient kind, seeded value, read-only |

Composed shared primitives without their own recipe domains: a multiline text field
(the per-section admin note), a field-grouping/label primitive (section structure +
labels), and a button (footer Cancel/Send).

