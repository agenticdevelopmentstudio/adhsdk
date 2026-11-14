
- **Corner radius**: `rounded-xl` (border-radius 0.75rem / 12px)
- **Padding**: 5 (1.25rem / 20px on all sides)
- **Gap between sections**: 2 (0.5rem / 8px between title/identifier area, description, and meta)
- **Font (title)**: font-medium (500 weight), token role **text-primary** (`apt-text`)
- **Font (identifier)**: font-mono, text-xs (0.75rem / 12px), token role **text-muted** (`apt-text-muted`)
- **Font (description)**: text-sm (0.875rem / 14px), token role **text-muted** (`apt-text-muted`), line-clamped to 3 lines
- **Font (meta)**: font-mono, text-xs (0.75rem / 12px), token role **text-dim** (`apt-text-dim`), flex-wrapped with gap-x-4 (1rem / 16px) and gap-y-1 (0.25rem / 4px)
- **Border**: 1px solid, token role **border** (`apt-border`)
- **Background**: token role **surface** (`apt-surface`)
- **Layout**: flex column, full width, with transition-colors animation
- **Interactive hover**: border becomes token role **border-strong** (`apt-border-strong`); background becomes token role **surface-hover** (`apt-surface-2`)
- **Interactive focus-visible**: border becomes token role **focus-accent** (`apt-gold` at 60% opacity)
- **Interactive cursor**: pointer

