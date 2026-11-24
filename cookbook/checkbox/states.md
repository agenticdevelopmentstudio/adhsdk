
| State | Appearance Change |
|-------|------------------|
| Default | Border and background render from the `apt-border`/`apt-bg` tokens; checkmark not rendered (React/Web: `border-apt-border bg-apt-bg`) |
| Checked | Border and background render from the `apt-gold` token; checkmark renders in the `apt-bg` glyph color (React/Web: `data-[checked]:border-apt-gold data-[checked]:bg-apt-gold`) |
| Focused | A visible focus indicator appears (React/Web: 2px ring at `apt-gold/25` opacity) |
| Disabled | Non-interactive. The Wrapper's native `<input>` carries the standard browser `disabled` attribute. The Primitive's Base UI `<span>` carries `aria-disabled`/`data-disabled` with `tabindex="-1"` and blocks toggling internally; it renders at 50% opacity with pointer events off through `data-[disabled]:opacity-50 data-[disabled]:pointer-events-none` |
| Switch Mode | Wrapper's input carries `role="switch"`; the rendered look (track/thumb vs. box) is set by the `aws-field--checkbox-switch` stylesheet rule, outside both source files |
| Check Mode | Wrapper's input keeps the implicit checkbox role; the rendered look is set by the `aws-field--checkbox-check` stylesheet rule, outside both source files |

