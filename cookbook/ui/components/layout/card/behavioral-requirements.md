
UI Card family (`packages/web/packages/ui/src/components/card.tsx`):

- **export-six-slot-components**: The UI Card family MUST export exactly six components: `Card`, `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`.
- **render-div-root**: Each of the six UI Card family components MUST render a `div` as its root element, with its default classes, whether or not children are supplied.
- **set-data-slot-attribute**: Each of the six UI Card family components MUST set a `data-slot` attribute on its root element identifying its role (`card`, `card-header`, `card-title`, `card-description`, `card-content`, `card-footer`, respectively).
- **merge-classname-prop**: Each of the six UI Card family components MUST merge a caller-supplied `className` prop with its own default class list via the `cn` utility, so that the caller's classes win on conflict (tailwind-merge): `className="rounded-none"` removes the default `rounded-xl`.
- **forward-rest-props**: Each of the six UI Card family components MUST spread all other received props onto its rendered root `div` element.
- **compose-any-slot-subset**: `Card` MUST NOT require any particular slot structure: it renders whichever of `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, and `CardFooter` it receives, in any subset and order.
- **card-corner-radius**: The `Card` root MUST use the `rounded-xl` Tailwind utility for its corner radius; no sub-slot sets its own corner radius.
- **card-vertical-padding**: The `Card` root MUST use vertical padding `py-6` and MUST NOT set horizontal padding of its own.
- **slot-horizontal-padding**: `CardHeader`, `CardContent`, and `CardFooter` MUST each add horizontal padding `px-6`.
- **card-layout**: `Card` MUST lay out its children as a vertical flex column (`flex flex-col`); **card-children-gap** only applies because of it.
- **header-layout**: `CardHeader` MUST lay out its children as a vertical flex column (`flex flex-col`); **header-children-gap** only applies because of it.
- **footer-layout**: `CardFooter` MUST lay out its children as a horizontal row, centered on the cross axis (`flex items-center`).
- **card-children-gap**: `Card` MUST use `gap-6` between its top-level children.
- **header-children-gap**: `CardHeader` MUST use `gap-1.5` between its own children.
- **title-typography**: `CardTitle` MUST use `font-semibold` with `leading-none`.
- **description-font-size**: `CardDescription` MUST use `text-sm`.
- **card-background**: The `Card` root MUST use the `bg-apt-bg` token.
- **card-text-color**: `Card` and `CardTitle` MUST use the `text-apt-text` token.
- **description-text-color**: `CardDescription` MUST use `text-apt-text-muted`.
- **card-border**: The `Card` root MUST use `border` (the Tailwind default 1px width) with the `border-apt-border` color token.
- **card-shadow**: The `Card` root MUST use `shadow-sm`.

