
`Avatar` is the shared avatar ingredient in `@adh-sdk/ui`: a thin,
three-part wrapper around Base UI's `Avatar` primitive (`@base-ui/react/avatar`),
the reference implementation for this ingredient's delegated behavior. It exports
`Avatar` (wraps `Avatar.Root`), `AvatarImage` (wraps `Avatar.Image`), and
`AvatarFallback` (wraps `Avatar.Fallback`). Each wrapper's only job is to apply
one of the semantic classes `adh-avatar`, `adh-avatar__image`, or
`adh-avatar__fallback` (merged with any consumer-supplied `className`) and
forward every other prop unchanged to the underlying Base UI primitive. The
module is a client component (`'use client'`). The source comment at
`avatar.tsx` documents why the class names must stay stable: "Base UI
avatar styled through the SEMANTIC `adh-avatar*` classes (skinned in
`../styles/components.css`): the class names are a public theming surface for
the theme editor and user CSS themes, so they stay stable hooks in the DOM."

