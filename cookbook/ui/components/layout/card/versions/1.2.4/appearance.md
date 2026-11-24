The UI Card family expresses appearance by class name rather than by literal value, and the class name is the requirement — it names Tailwind utilities and `apt-*` design tokens inline. Each fact below is stated once, in the requirement it links; this section adds only what no requirement says.

- **Corner radius**: #requirements/card-corner-radius
- **Padding and gap**: #requirements/card-vertical-padding, #requirements/slot-horizontal-padding, #requirements/card-children-gap, #requirements/header-children-gap
- **Layout**: #requirements/card-layout, #requirements/header-layout, #requirements/footer-layout
- **Font**: #requirements/title-typography, #requirements/description-font-size. `Card`, `CardHeader`, `CardContent`, and `CardFooter` set no font utility and inherit from their ancestor. No literal point size appears in the source; the Tailwind scale step is the specification.
- **Background**: #requirements/card-background. No sub-slot sets a background.
- **Foreground/Text**: #requirements/card-text-color, #requirements/description-text-color. `CardHeader`, `CardContent`, and `CardFooter` set no text color and inherit `text-apt-text` from the `Card` root.
- **Border**: #requirements/card-border. No sub-slot has its own border.
- **Shadow**: #requirements/card-shadow. No sub-slot has its own shadow.
- **Min/Max size**: The UI Card family does not constrain width or height: the `Card` sets no sizing utility, so it fills the inline size its parent gives it and sizes to its content in the block direction.
