
- **exports-class-string**: The module MUST export `sectionLabelClass` as a string so any element can adopt the display micro-heading treatment without the component.
- **applies-display-treatment**: The component MUST apply `sectionLabelClass` (`font-mono text-[0.625rem] font-medium uppercase tracking-[0.1em] text-apt-text-dim`) to the label element.
- **renders-children-as-label**: The component MUST render its `children` as the label text.
- **bare-div-without-trailing**: With no `trailing` node (`trailing == null`), the component MUST render a single `div` carrying `sectionLabelClass` (no wrapping row).
- **row-with-trailing**: Given any `trailing` value other than `null`/`undefined` (including `false`), the component MUST render a `flex items-center justify-between gap-2` row `div` with the label (a `span` carrying `sectionLabelClass`) on the left and the trailing node on the right.
- **merges-classname-on-label**: The component MUST merge any `className` via `cn()` onto the outermost element: after `sectionLabelClass` on the label `div` in the bare form, onto the row `div` in the trailing form. A consumer's layout class therefore means the same thing in both forms.
- **distinct-from-caption-and-title**: The component MUST NOT reuse `fieldCaptionClass` or the `SectionHeader` gold-title treatment — it is a separate, quieter display label.

