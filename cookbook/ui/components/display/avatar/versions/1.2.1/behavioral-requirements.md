
- **render-root-with-semantic-class**: `Avatar` MUST render Base UI's `Avatar.Root` (`AvatarPrimitive.Root`) with the class name `adh-avatar` applied.
- **render-image-with-semantic-class**: `AvatarImage` MUST render Base UI's `Avatar.Image` (`AvatarPrimitive.Image`) with the class name `adh-avatar__image` applied.
- **render-fallback-with-semantic-class**: `AvatarFallback` MUST render Base UI's `Avatar.Fallback` (`AvatarPrimitive.Fallback`) with the class name `adh-avatar__fallback` applied.

These three class names are the public theming surface quoted in Overview — stable DOM hooks consumed by the theme editor and user CSS themes — so renaming any of `adh-avatar`, `adh-avatar__image`, or `adh-avatar__fallback` is a breaking change for every theme built against them, not a local refactor.

- **merge-consumer-classname**: Each of `Avatar`, `AvatarImage`, and `AvatarFallback` MUST merge a consumer-supplied `className` prop with its own semantic class name (via the `cn` helper imported from `../lib/utils`) rather than dropping either class.
- **forward-remaining-props**: Each of `Avatar`, `AvatarImage`, and `AvatarFallback` MUST forward every prop other than `className` unchanged to its underlying Base UI primitive.
- **load-as-client-module**: The module MUST be marked `'use client'`, so `Avatar`, `AvatarImage`, and `AvatarFallback` render as client components. This is verified by a static check for the `'use client'` directive at the top of `avatar.tsx`, not by a runtime conformance test vector.

