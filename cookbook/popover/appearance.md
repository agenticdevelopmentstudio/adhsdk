
Numeric spec (full-featured variant; the class names that implement it are listed under **Platform Notes → React/Web**):

- **Corner radius**: 8px
- **Padding**: 1rem (16px) on all sides
- **Font**: 14px (0.875rem), default weight from context
- **Background**: Surface color token (apt-surface)
- **Foreground/Text**: Text color token (apt-text)
- **Border**: 1px solid, border color token (apt-border)
- **Shadow**: Drop shadow with blur and offset
- **Min/Max size**: Maximum width 288px; further constrained by the positioning library's available-width custom property

The lightweight variant's paint and geometry are custom properties declared on `.hover-popover`, outside the two source files this recipe is grounded in; this recipe does not specify their values.

