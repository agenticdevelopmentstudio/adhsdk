
VStack and HStack are layout containers that arrange child elements in a vertical or horizontal direction using CSS Flexbox. They provide a flexible gap property, alignment control via `alignItems`, and justification control via `justifyContent`. Both components render as non-semantic `div` elements — a `div` has no ARIA semantics, so it adds no role or landmark to the accessibility tree — and accept custom CSS classes and inline styles for further customization. No prop other than `children`, `gap`, `align`, `justify`, `className`, and `style` is read or forwarded to the root element.

