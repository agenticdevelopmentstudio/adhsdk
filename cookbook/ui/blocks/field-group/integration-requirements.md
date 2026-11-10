
- **render-title**: The group MUST render the `title` node as an uppercase-mono
  heading (the shared `fieldCaptionClass`) in the top row.
- **render-title-as-heading**: The group MUST render the `title` inside an
  `<h3>` so the section is a real heading in the document outline.
- **render-trailing-when-set**: When `trailing` is provided, the group MUST
  render it in the title row, right-aligned opposite the title; when unset, the
  title row MUST show the title alone.
- **stack-children**: The group MUST render its `children` (the Fields) as a
  vertical stack below the title row, with consistent spacing between rows.
- **bordered-card**: The group MUST present as a bordered, rounded surface
  (`apt-border` / `apt-surface` tokens) that visually contains its title and fields.
- **merge-classname**: The group MUST merge a caller-supplied `className` onto
  its root `section` without dropping its own layout classes.

