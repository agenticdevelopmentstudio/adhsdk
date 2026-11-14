
`Avatar` is the shared avatar ingredient in `@adh-sdk/ui`: a thin,
three-part wrapper around Base UI's `Avatar` primitive (`@base-ui/react/avatar`),
the reference implementation for this ingredient's delegated behavior. It exports
`Avatar` (wraps `Avatar.Root`), `AvatarImage` (wraps `Avatar.Image`), and
`AvatarFallback` (wraps `Avatar.Fallback`). Each wrapper's only job is to apply
one of the semantic classes `adh-avatar`, `adh-avatar__image`, or
`adh-avatar__fallback` (merged with any consumer-supplied `className`) and
forward every other prop unchanged to the underlying Base UI primitive. The
module is a client component (`'use client'`). The source (`packages/web/packages/ui/src/components/avatar.tsx`) skins the three classes in `packages/web/packages/ui/src/styles/components.css`. The class names are a public theming surface, so they must stay stable; the first Design Decision gives the reason.

<!-- appkit-avatar -->
**AppKit (`AvatarView`).** The macOS face of the same ingredient is `AvatarView` in `AgenticDeveloperHubSDKMacOS` (`macOS/UI/Avatar/`): a round view showing a picture when one loads and initials on a coloured circle until then and whenever it does not. It is drawn from an `AvatarContent` (`name`, `seed`, `imageURL`) rather than any feature's user type, so the Accounts settings and the git window's commit authors share it. The circle's colour comes from a stable hash of `seed` over the [commit graph cell](cookbook:595f1a5e-0f92-49c5-a980-af6f809be932)'s lane palette, from the [theme engine](cookbook:0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6).

