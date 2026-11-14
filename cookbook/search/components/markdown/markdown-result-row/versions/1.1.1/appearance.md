
- **Container**: Rounded article element with flex column layout, 8px gaps between sections, 8px corner radius (`--radius-lg` token), 1px border, 16px padding
- **Background**: Neutral background color (`apt-bg`); selected state uses accent border color (`apt-gold`)
- **Border**: 1px width; neutral color (`apt-border`) in default state; accent color (`apt-gold`) when selected; hover state shows strong border (`apt-border-strong`)
- **Button (select control)**: Flex column, 8px gap, text-left alignment, no default outline, `--radius-md` corner radius, rounded focus ring (2px) in accent color with 25% opacity
- **Badge**: Per-kind variant from renderer; self-aligned to start
- **Title (h3)**: Base font size (16px), semibold weight, text color (`apt-text`)
- **Highlight mark**: Gold background at 25% opacity (`apt-gold/25`), small rounded corners, horizontal padding (0.125rem), text color matches body (`apt-text`)
- **Category label**: 1px border, neutral border color, 8px horizontal padding, 4px vertical padding, monospace font, 12px size, uppercase, letter-spacing 0.08em, dim text color (`apt-text-dim`)
- **Snippet**: 14px size, muted text color (`apt-text-muted`), maximum 2 lines with ellipsis clamp
- **Tags**: List with 4px gaps, 12px font size, muted text color
- **Footer (author + date)**: Flex wrap with justified spacing, 12px gap (horizontal and vertical), 12px font size, dim text color; author name in muted text; "View paper" link in accent color with underline offset (8px) and hover underline
- **Link touch target overlay**: Invisible pseudo-element, full width, 24px height, centered vertically (using `top: 50%` and `-translate-y-1/2`)

