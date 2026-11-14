
- **Width**: 320px (fixed)
- **Icon size**: 16px × 16px (Tailwind `size-4` on the web implementation)
- **Icon color**: `apt-text-muted` (design system token for muted text)
- **Icon margin**: 2px top margin, no left/right margin
- **Content gap**: 10px horizontal gap between icon and text block
- **Title font**: font-weight `500` (medium), inherits body size
- **Title color**: `apt-text` (design system token for primary text)
- **Title margin**: 4px bottom margin (creates visual separation from body)
- **Body font**: inherits body size and line-height
- **Body color**: `apt-text-muted` (design system token for muted text)
- **Text block**: `min-w-0` applied on the web implementation so the text column can shrink below its content's intrinsic width inside the flex layout; no truncation is applied — long title or body text wraps instead (see Edge Cases)
- **Arrow**: Rendered by PopoverContent component; inherits popover positioning and alignment

