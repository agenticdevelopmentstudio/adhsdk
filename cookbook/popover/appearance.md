
Numeric spec (full-featured variant; the class names that implement it are listed under **Platform Notes → React/Web**):

- **Corner radius**: 8px
- **Padding**: 1rem (16px) on all sides
- **Font**: 14px (0.875rem), default weight from context
- **Background**: Surface color token (apt-surface)
- **Foreground/Text**: Text color token (apt-text)
- **Border**: 1px solid, border color token (apt-border)
- **Shadow**: Tailwind `shadow-lg`: `0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)` (default theme)
- **Min/Max size**: Maximum width 288px; further constrained by the positioning library's available-width custom property

The lightweight variant's paint and geometry are custom properties declared on `.hover-popover`, outside the two source files this ingredient is grounded in; this ingredient does not specify their values.

