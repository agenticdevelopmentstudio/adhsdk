
Token roles: a bordered, rounded container on the design system's surface background; a single-row header with small padding and a gap between the chevron, text and actions; a medium-weight primary title in the text color and a smaller subtitle in the muted text color, both truncating; a muted chevron; a divider line between header and open body; a gold focus ring at reduced opacity. On web these map to the Tailwind classes below.

Container: `rounded-lg border border-apt-border bg-apt-surface`. Header:
`flex items-center gap-2 px-3 py-2`; the toggle is a `<button>` showing a
`ChevronRight` that gains `rotate-90` when open (collapsed, it carries `rtl:rotate-180`, so it points inline-start-to-end under RTL), a `text-sm font-medium
text-apt-text` title and an optional `text-xs text-apt-text-muted` subtitle (both
truncate). `actions` are pinned to the right. The open body is separated by
`border-t border-apt-border px-3 py-3`. Focus ring `apt-gold/40`. No raw hex; no
`!important`. The chevron's rotation is animated with the `transition-transform`
class, and `motion-reduce:transition-none` drops the animation when the user prefers reduced motion.

