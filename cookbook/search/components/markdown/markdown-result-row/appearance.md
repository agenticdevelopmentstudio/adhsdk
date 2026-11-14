
- **Container**: Rounded article element with flex column layout, 8px gaps between sections, 8px corner radius (`--radius-lg` token), 1px border, 16px padding
- **Background**: Neutral background token; selected state uses the accent border token
- **Border**: 1px width; neutral border token in default state; accent token when selected; hover state shows the strong border token
- **Button (select control)**: Flex column, 8px gap, text-left alignment, no default outline, `--radius-md` corner radius, rounded focus ring (2px) in accent color with 25% opacity
- **Badge**: Per-kind variant from renderer; self-aligned to start
- **Title (h3)**: Base font size (16px), semibold weight, text color (primary text token)
- **Highlight mark**: Accent background at 25% opacity, small rounded corners, horizontal padding (0.125rem), text color matches body (primary text token)
- **Category label**: 1px border, neutral border color, 8px horizontal padding, 4px vertical padding, monospace font, 12px size, uppercase, letter-spacing 0.08em, dim text token
- **Snippet**: 14px size, muted text token, maximum 2 lines with ellipsis clamp
- **Tags**: List with 4px gaps, 12px font size, muted text color
- **Footer (author + date)**: Flex wrap with justified spacing, 12px gap (horizontal and vertical), 12px font size, dim text color; author name in muted text; "View paper" link in the accent token with underline offset (8px) and hover underline
- **Link touch target overlay**: Invisible pseudo-element, full width, 24px height, centered vertically (using `top: 50%` and `-translate-y-1/2`)

The semantic tokens above map to the web `apt-*` tokens as listed in the React/Web platform note.
