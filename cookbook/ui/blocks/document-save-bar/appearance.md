
- **Corner radius**: The bar has none; the conflict warning uses the Alert's `rounded-lg`.
- **Padding**: The bar is Button Bar's (`px-6 py-2`); the conflict warning passes `p-2`, which the class merge lets replace the Alert's own `px-4 py-3`.
- **Font**: Notices use `text-sm` (14px by Tailwind's scale); the conflict warning is `text-sm`.
- **Background**: The bar is Button Bar's recessed `bg-apt-bg`; the warning is the Alert's warning tint (`bg-apt-orange/10`).
- **Foreground/Text**: Error lines use `text-apt-red`; the changed notice uses `text-apt-orange`; the warning text is `text-apt-text`.
- **Border**: The bar has Button Bar's `border-y border-apt-border`; the warning has a 1px border `border-apt-orange/40`.
- **Shadow**: None.
- **Min/Max size**: The notice group is `flex min-w-0 flex-wrap items-center gap-2`, so notices wrap instead of overflowing; the warning is `mt-2 flex flex-wrap items-center gap-2`, so its message and buttons wrap. The two warning buttons are small (`size="sm"`), "Reload theirs" with the outline variant and "Overwrite" with the destructive variant.

