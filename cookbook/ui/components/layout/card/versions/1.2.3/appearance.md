
The UI Card family expresses appearance by class name rather than by literal value, and the class name is the requirement — it names Tailwind utilities and `apt-*` design tokens inline.

- **Corner radius** (#requirements/card-corner-radius):
  - UI Card family: the `Card` root uses the `rounded-xl` Tailwind utility; no sub-slot sets its own corner radius.
- **Padding** (#requirements/card-vertical-padding, #requirements/slot-horizontal-padding, #requirements/card-children-gap, #requirements/header-children-gap):
  - UI Card family: the `Card` root uses vertical padding `py-6` and sets no horizontal padding of its own; `CardHeader`, `CardContent`, and `CardFooter` each add horizontal padding `px-6`. `Card` uses `gap-6` between its top-level children and `CardHeader` uses `gap-1.5` between its own children.
- **Font** (#requirements/title-font-weight, #requirements/description-font-size):
  - UI Card family: `CardTitle` uses `font-semibold` with `leading-none`; `CardDescription` uses `text-sm`. `Card`, `CardHeader`, `CardContent`, and `CardFooter` set no font utility and inherit from their ancestor. No literal point size appears in the source; the Tailwind scale step is the specification.
- **Background** (#requirements/card-background):
  - UI Card family: the `Card` root uses the `bg-apt-bg` token; no sub-slot sets a background.
- **Foreground/Text** (#requirements/card-text-color, #requirements/description-text-color):
  - UI Card family: `Card` and `CardTitle` use the `text-apt-text` token; `CardDescription` uses `text-apt-text-muted`. `CardHeader`, `CardContent`, and `CardFooter` set no text color and inherit `text-apt-text` from the `Card` root.
- **Border** (#requirements/card-border):
  - UI Card family: the `Card` root uses `border` (the Tailwind default 1px width) with the `border-apt-border` color token; no sub-slot has its own border.
- **Shadow** (#requirements/card-shadow):
  - UI Card family: the `Card` root uses `shadow-sm`; no sub-slot has its own shadow.
- **Min/Max size**: The UI Card family does not constrain width or height: the `Card` sets no sizing utility, so it fills the inline size its parent gives it and sizes to its content in the block direction.

