
`Avatar` is the shared avatar ingredient in `@adh-sdk/ui`: a thin,
three-part wrapper around Base UI's `Avatar` primitive (`@base-ui/react/avatar`),
the reference implementation for this ingredient's delegated behavior. It exports
`Avatar` (wraps `Avatar.Root`), `AvatarImage` (wraps `Avatar.Image`), and
`AvatarFallback` (wraps `Avatar.Fallback`). Each wrapper's only job is to apply
one of the semantic classes `adh-avatar`, `adh-avatar__image`, or
`adh-avatar__fallback` (merged with any consumer-supplied `className`) and
forward every other prop unchanged to the underlying Base UI primitive. The
module is a client component (`'use client'`). The source (`packages/web/packages/ui/src/components/avatar.tsx`) skins the three classes in `packages/web/packages/ui/src/styles/components.css`. The class names are a public theming surface, so they must stay stable; the first Design Decision gives the reason.

