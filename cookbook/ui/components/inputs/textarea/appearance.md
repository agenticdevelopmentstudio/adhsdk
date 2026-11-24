
- **Corner radius**: `rounded-lg` (from `fieldShellClass`; no override in source).
- **Padding**: 8px vertical × 12px horizontal (py-2 px-3).
- **Font**: weight regular (default), size 14px (text-sm).
- **Background**: `bg-apt-bg` token (from `fieldShellClass`; no override in source).
- **Foreground/Text**: `apt-text` token color.
- **Border**: 1px `apt-border` token (from `fieldShellClass`) with state-driven overrides (golden on focus, red on invalid).
- **Shadow**: None at rest; `fieldShellClass` defines no shadow. The focus and invalid states add a 2px ring.
- **Min/Max size**: Minimum height 64px; full width (100%); no maximum enforced.
- **Placeholder text**: Uses `apt-text-dim` token color for reduced visibility.

