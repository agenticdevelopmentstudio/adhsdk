
- **Corner radius**: fully rounded (`rounded-full`, a pill).
- **Padding**: `0.15rem` vertical × `0.45rem` horizontal (`py-[0.15rem] px-[0.45rem]`).
- **Font**: mono family, weight 500, `0.6rem`, uppercase, line height 1.4, letter spacing `0.08em`.
- **Background**: transparent (`bg-transparent`).
- **Foreground/Text**: the tone color (see the tone requirements): `apt-text-dim` for `neutral`, otherwise the same `apt-*` color as the border.
- **Border**: 1px, solid by the Tailwind default, in the tone color (`apt-border` for `neutral`).
- **Shadow**: none.
- **Min/Max size**: no constraints; the chip is as wide as its content because it does not wrap. Icons are `size-3` (0.75rem).

Layout is `inline-flex items-center gap-1`.

