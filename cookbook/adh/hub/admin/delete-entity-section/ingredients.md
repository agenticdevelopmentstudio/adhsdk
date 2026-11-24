
| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Disclosure | [adhsdk.ingredient.ui.components.layout.disclosure](cookbook:c99e2822-f5a9-4e84-8740-9341880bb82a) | The collapsed-by-default Danger-zone container; its open/closed state is controlled by the section so the red accent tracks whether it is disclosed | yes | Open state bound to the section's disclosed state; red styling and title color applied only while disclosed; carries the warning glyph in its title |
| Button | [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) | The disclosed Delete trigger, and the dialog's Cancel/Yes/Permanently-Delete actions | yes | Uses the shared button ingredient's destructive-ghost style for Delete and Yes, a neutral style for Cancel, and its strongest destructive style for the final Permanently Delete action |
| Dialog | [adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1) | The modal that carries the two-phase confirm (warn → type-to-confirm) | yes | Open state controlled by the section; its close control is hidden while busy; uses the shared header/title/description/footer structure |

Composed shared primitives without their own recipe domains: a text input (the
type-to-confirm field, which autofocuses and disables autocomplete and spell-check),
a label (visually hidden, for that input), and the trash/warning/archive glyphs.

The `ingredients` field links Disclosure, Button, and Dialog as recipes
rather than as bare ingredients because each is documented as their own recipe in that toolkit, not as bare
ingredients — this recipe composes those recipes, it doesn't restate them as
ingredients of its own.

