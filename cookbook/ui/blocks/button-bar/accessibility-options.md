
| Option | Behavior |
|--------|----------|
| Reduce Motion | The Button Bar itself renders no motion or animated transitions; the Save label's text change ("Save" → "Saving…") is a text swap, not an animation, and needs no Reduce Motion accommodation. Buttons composed within it SHOULD follow the shared Button component's own Reduce Motion behavior (accessibility-options ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0))), which is that component's concern, not this one's. |
| Increase Contrast | Buttons inherit Increase Contrast behavior from the shared Button component. The muted text color (`text-apt-text-muted`) for disabled Save button MUST maintain sufficient contrast when Increase Contrast is enabled. |
| Differentiate Without Color | Buttons MUST be distinguishable without relying on color alone; the disabled state is indicated by both color and the HTML `disabled` attribute. The destructive-ghost variant for Delete MUST be distinguishable via shape, icon, or other non-color properties. |

