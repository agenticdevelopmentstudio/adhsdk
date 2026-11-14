
- **Backdrop**: `fixed inset-0` positioning, `bg-black/30` overlay (30% black opacity), `backdrop-blur-sm` blur effect, `z-50` stacking.
- **Popup container**: Centered at `top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2`, width `w-[calc(100%-2rem)]` (100% minus 16px side margins), max-width `max-w-md` (448px), `rounded-xl` corner radius (12px), `border` 1px `border-apt-border`, background `bg-apt-surface`, text color `text-apt-text`, padding `p-5` (20px all sides), `shadow-xl` shadow effect, `z-50` stacking.
- **Close button (×)**: Positioned `absolute top-3.5 right-3.5`, icon size `size-4` (16px × 16px), rounding `rounded`, default text color `text-apt-text-muted`, hover state transitions to `text-apt-text`, focus ring `ring-2 ring-apt-gold/40`, no outline.
- **DialogHeader**: Flex layout `flex-col`, vertical gap `gap-1.5` (6px).
- **DialogFooter**: Flex layout with `items-center justify-end`, horizontal gap `gap-3` (12px).
- **DialogTitle**: Font size `text-base` (16px), weight `font-semibold` (600), text color `text-apt-text`.
- **DialogDescription**: Font size `text-sm` (14px), text color `text-apt-text-muted`.
- **Stacking**: Backdrop and popup both use `z-50`; within the same `Portal` the popup renders after the backdrop (see `dialog.tsx`), so DOM order — not the z-index value — is what keeps the popup above the backdrop.
- **Constraint**: No raw hex color values; no `!important` declarations.

