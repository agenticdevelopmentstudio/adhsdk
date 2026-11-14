
- **Container**: Flex column layout, full width, no fixed height.
- **Gap between rows**: 12px (Tailwind `gap-3` on React/Web; see Platform Notes for other platforms).
- **Label column width**: Set via the `FIELD_LABEL_GROUP_CLASS` class (`[--apt-field-label-w:6.5rem]`) applied to the root alongside its layout classes and any host `className`; the custom property cascades to both child rows. A host `className` that sets `--apt-field-label-w` again takes precedence through ordinary CSS cascade order (see Edge Cases).
- **Child rows**: Both use inline layout as defined by `CategoryField` and `TagSetField`.
- **No border, shadow, or background**: The component has no intrinsic visual styling; appearance is inherited from child components.

