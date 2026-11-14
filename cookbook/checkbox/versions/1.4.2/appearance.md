
- **Checkbox Size**: 16px (`size-4` in Tailwind: 1rem). The indicator spans the full size with centered content (Primitive, `size-4` class on `CheckboxPrimitive.Root`).
- **Border**: 1px solid, color `apt-border` in default state; changes to `apt-gold` when checked (Primitive, `border border-apt-border` and `data-[checked]:border-apt-gold`).
- **Background Color**: `apt-bg` in default state; changes to `apt-gold` when checked (Primitive, `bg-apt-bg` and `data-[checked]:bg-apt-gold`).
- **Corner Radius**: `rounded` (typically 4px) (Primitive, `rounded` class).
- **Checkmark Icon**: Lucide React `Check` icon, size 3 (12px / 0.75rem), stroke width 3 (Primitive, `<Check className="size-3" strokeWidth={3} />`).
- **Checkmark Color**: `apt-bg` token color in both states, inherited via the Indicator's `text-current` class from the Root's constant `text-apt-bg` (Primitive); the glyph itself renders only while checked, per the Indicator's own conditional-rendering behavior. There is no color swap in the source — only the background fill changes between states.
- **Focus Ring**: 2px ring with `apt-gold/25` color, visible on focus (Primitive, `focus-visible:ring-2 focus-visible:ring-apt-gold/25`).
- **Transition**: `transition-colors` only — border and background color changes are animated; no size, position, or opacity motion is animated (Primitive, `transition-colors` class).
- **Label Styling**: Applied via `aws-checkbox__label` class in the wrapper, or via the passed ReactNode; font and size determined by the label text type (Wrapper, `<span className="aws-checkbox__label">`).
- **Hint Styling**: Applied via `aws-field__hint` class; appears below the checkbox with paragraph styling (Wrapper, `<p className="aws-field__hint">`).

