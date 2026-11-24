
The Separator component renders a thin line that visually and semantically separates adjacent content. It is a layout primitive with no interactivity, used to organize sections within a layout. It supports both horizontal and vertical orientations and communicates its orientation to assistive technologies.

A related component, [adhsdk.ingredient.controls.user-settings.components.divider](cookbook:89a912f3-f0a0-4896-ba06-a386407ecb15), comes from a different source package and renders a semantic `<hr>`-based, horizontal-only line. This Separator instead renders a styled element with `role="separator"` that supports both orientations and is not tied to the `<hr>` element — use Divider where a plain thematic-break line is enough, and Separator where orientation control or ARIA orientation sync is needed.

