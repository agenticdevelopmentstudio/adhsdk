
The shared `ReactionBar` in `@adh-sdk/ui` — the emoji reactions on **one subject**,
rendered as a row of count chips plus a small palette for adding one. It is the single home
for the reaction treatment, so a work-item comment, a discussion post and anything else the
backend's polymorphic reaction store can name all react the same way.

The component is **presentational**, like the rest of the package: it receives the tallies
already folded (`{ emoji, count, mine }`) and calls back with an emoji. It never fetches, never
writes, and holds no reaction state — the only state it owns is whether its palette popover is
open. That is what keeps one bar reusable across subjects that have nothing else in common.

A chip is a **toggle, not a counter**. Pressing a chip you are already part of takes your
reaction back; pressing one you are not adds it. Both directions call the same `onToggle` with
the same argument, because the caller can already tell which way it goes from the `mine` flag it
supplied — two callbacks would be two chances for them to disagree.

Two exports ship from `@adh-sdk/ui/components/reaction-bar`: the `ReactionBar`
component and `DEFAULT_REACTIONS`, the default palette, exported so a host starts from one
fact rather than restating a literal per surface.

