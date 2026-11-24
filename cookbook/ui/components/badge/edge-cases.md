
- **Empty children.** With no children the element still renders as a padded, empty bordered pill.
- **Long text.** Because `whitespace-nowrap` is set, long text does not wrap and can overflow a narrow container; the component sets no `max-width` or truncation.
- **Unknown variant.** `variant` is typed to the six keys. A value outside them (possible from untyped code) matches no variant entry, so the badge gets the base classes and no tone color.
- **Variant `undefined`.** An explicit `undefined` falls back to `neutral` through `defaultVariants`.
- **Consumer overrides.** `className` is passed through `badgeVariants` and then `cn()`, so a consumer class that conflicts with a base class is merged by `cn()` rather than simply appended.
- **Prop order.** `{...props}` is spread after `data-slot` and `className`, so a consumer `data-slot` replaces the default.
- **Icons.** An `svg` child is forced to `size-3` regardless of its own size attributes by the `[&_svg]` selector.

