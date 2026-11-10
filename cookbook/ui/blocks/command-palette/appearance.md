
- **Corner radius**: 6px (from Tailwind's `rounded-md` on item buttons)
- **Padding**: Dialog content has no padding; internal sections own their own (input section: 12px vertical, 10px right, 12px left; item list: 8px; footer: 8px vertical, 12px horizontal)
- **Font**: Item text is 14px (text-sm), section labels are text-sm, footer is 12px (text-xs)
- **Background**: Dialog uses default modal overlay; item list background inherits from container; highlighted items show `apt-highlight/15` overlay; hover shows `apt-highlight/10`
- **Foreground/Text**: Primary text `apt-text`, muted text `apt-text-muted`, dimmed text `apt-text-dim`, section labels use muted color
- **Border**: Top border on input section (1px `apt-border`), top border on footer section (1px `apt-border`)
- **Shadow**: Delegated to Dialog primitive
- **Min/Max size**: Dialog max-width is 576px (`max-w-xl`); positioned at 12% from top; list max-height is 50vh with vertical scroll overflow; input uses padding-left 36px to accommodate leading icon

