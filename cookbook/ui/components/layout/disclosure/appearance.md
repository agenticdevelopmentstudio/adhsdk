
Container: `rounded-lg border border-apt-border bg-apt-surface`. Header:
`flex items-center gap-2 px-3 py-2`; the toggle is a `<button>` showing a
`ChevronRight` that gains `rotate-90` when open, a `text-sm font-medium
text-apt-text` title and an optional `text-xs text-apt-text-muted` subtitle (both
truncate). `actions` are pinned to the right. The open body is separated by
`border-t border-apt-border px-3 py-3`. Focus ring `apt-gold/40`. No raw hex; no
`!important`. The chevron's rotation is animated with the `transition-transform`
class; no `motion-reduce:` variant is applied, so the rotation does not defer to
the reduced-motion preference (see Compliance).

