
- **trigger-button-style**: The trigger MUST render as a subdued (non-primary) button at a small size, so it reads as a toolbar utility rather than a call to action. (Web: `variant="outline" size="sm"` — see React/Web platform note.)
- **trigger-book-icon**: The trigger MUST display a book icon positioned at the inline start of any visible label. (Web: lucide-react `BookText` — see React/Web platform note.)
- **trigger-accessible-name**: The trigger MUST have an `aria-label` set to the `ariaLabel` prop, and `ariaLabel` MUST be a non-empty string describing the cheatsheet's purpose (e.g., "Markdown quick reference"). When `triggerLabel` is also provided, `ariaLabel` MUST contain the visible `triggerLabel` text (WCAG 2.5.3 Label in Name), since the component does not derive one from the other — see #edge-cases and quick-ref-002.
- **trigger-disclosure-state**: The trigger MUST expose `aria-expanded` reflecting whether the popover is open, and MUST expose `aria-haspopup` identifying it as a popup trigger (both inherited from the Popover primitive's Base UI `Trigger`; see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))). On web, `aria-expanded="true"` additionally switches the trigger's own background/foreground color (the outline variant's `aria-expanded:` styling).
- **popover-opens-on-click**: The component MUST open the popover when the trigger button is clicked, or activated via keyboard (the trigger is a native `button`, so Enter/Space also activate it).
- **popover-title-display**: The popover MUST display the provided title using field-caption typography styling. (Web: `fieldCaptionClass` — see React/Web platform note.)
- **entries-definition-list**: The component MUST render syntax entries as a definition list (`dl`) in a two-column layout with label (`dt`) and code (`dd`) pairs, the label column narrower than the code column.
- **entry-label-style**: Entry labels (`dt`) MUST render at a small font size and in a muted foreground color, distinguishing them from the code values below them.
- **entry-code-style**: Code values (`dd`) MUST render in a monospace font, smaller than the label text, with whitespace preserved (line breaks and indentation in the source syntax are not collapsed) and normal (non-loose) line spacing.
- **escape-dismissal**: The popover MUST close when the Escape key is pressed (inherited from Popover primitive; see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))).
- **outside-click-dismissal**: The popover MUST close when the user clicks outside the popover bounds (inherited from Popover primitive).
- **focus-restoration**: The component MUST restore focus to the trigger button after the popover is dismissed (inherited from Popover primitive).
- **optional-trigger-label**: The component MUST accept an optional `triggerLabel` prop to display visible text on the trigger button.
- **customizable-width**: The component MAY accept a `contentClassName` prop to customize the popover's rendered width; the default renders at 20rem (see React/Web platform note for the literal class).
- **customizable-columns**: The component MAY accept a `columnsClassName` prop to customize the entries grid's column split; the default makes the label column narrower than the code column (see React/Web platform note for the literal class).
- **customizable-position**: The component MAY accept `side` and `align` props to position the popover relative to the trigger — `side` picks which edge of the trigger it opens from (default `bottom`), and `align` positions it along that edge (default `end`).
- **customizable-trigger-classes**: The component MAY accept a `className` prop to apply additional CSS classes to the trigger button.

