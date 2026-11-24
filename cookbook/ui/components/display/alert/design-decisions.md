
**Decision**: Detect and react to a leading icon structurally, via a CSS
`:has(>svg)` selector, rather than through a dedicated `icon` prop.
**Rationale**: `alert.tsx` has no icon prop; its icon-aware grid widening
and icon sizing are driven entirely by a `has-[>svg]` selector matching any
direct `<svg>` child. This is why `AlertTitle`/`AlertDescription` are plain
`col-start-2` siblings rather than named slots — the whole layout is
structural (presence/absence of an `<svg>` child), not prop-driven. See
#requirements/accept-any-icon-element and the Edge Cases entry on structural
icon detection.
**Approved**: pending

**Decision**: Differentiate the six variants by border/background/icon
tone color alone, with no secondary non-color cue.
**Rationale**: Across `default`/`info`/`success`/`error`/`warning`/`accent`, the
source's only differentiator besides an optional caller-supplied icon is
the border/background/icon tone color; the body text color
(`text-apt-text`) is identical for every variant. An icon-less alert
therefore communicates its severity through color alone.
**Approved**: pending

**Decision**: Every variant renders `role="alert"` (an assertive live region), and a caller who needs a quieter callout overrides `role` through the forwarded props (see **override-role-and-data-slot**).
**Rationale**: `alert.tsx` sets one `role` for all variants, including the neutral `default` and `accent` ones, so a neutral callout present at page load is announced assertively unless the caller passes a different `role` such as `status`. Because `{...props}` is spread after `role`/`data-slot` in the root `<div>`'s JSX (see Edge Cases), the override is the only way to change it.
**Approved**: pending

**Decision**: Recommend, but do not enforce, composing `Alert` with
`AlertTitle`/`AlertDescription` rather than arbitrary children.
**Rationale**: `AlertTitle`/`AlertDescription` exist solely to place text
in the grid's second column alongside an optional icon; using them is not
enforced — `Alert` accepts arbitrary children — but a caller who deviates
(e.g. a raw `<p>` instead of `AlertDescription`) must add `col-start-2`
manually to stay aligned with an icon, since `Alert` itself applies no
column placement to unrecognized children. See
#requirements/compose-title-and-description-as-children.
**Approved**: pending

**Decision**: Treat this `Alert` (the inline, non-modal callout from
`alert.tsx`) and the `alert-and-dialog` recipe's ([adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500)) modal confirm-dialog as
unrelated implementations despite the shared name.
**Rationale**: This cookbook also contains an `alert-and-dialog` recipe
describing a *different*, modal confirm-dialog component that happens to
share the word "Alert." The `Alert` documented here is the inline,
non-modal callout from `alert.tsx`; the two are unrelated implementations
(see `related` in the frontmatter).
**Approved**: pending

