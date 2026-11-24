
- **Container**: Flex layout with horizontal direction, centered vertical alignment, 4px gap between buttons.
- **Button size**: 28×28px.
- **Border radius**: 6px.
- **Border width**: 1px.
- **Font**: weight 600 (semibold), size 12px.
- **Content alignment**: Label centered both horizontally and vertically within the button.
- **Transition**: Border, background, and text color animate on state change.

### Default (off) state colors:
- **Border**: `apt-border` token.
- **Background**: `apt-bg` token (full opacity).
- **Text**: `apt-text-muted` token.
- **Hover text**: `apt-text` token (brighter on hover).

### Enabled (on) state colors:
- **Border**: `apt-gold` token.
- **Background**: `apt-gold` token at 20% opacity.
- **Text**: `apt-gold-bright` token.

### Disabled or blocked state:
- **Cursor**: `not-allowed`.
- **Opacity**: 40% (0.4).
- **Hover text**: `apt-text-muted` (suppressed hover effect).

