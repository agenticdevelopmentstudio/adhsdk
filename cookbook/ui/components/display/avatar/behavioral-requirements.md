
- **render-root-with-semantic-class**: `Avatar` MUST render Base UI's `Avatar.Root` (`AvatarPrimitive.Root`) with the class name `adh-avatar` applied.
- **render-image-with-semantic-class**: `AvatarImage` MUST render Base UI's `Avatar.Image` (`AvatarPrimitive.Image`) with the class name `adh-avatar__image` applied.
- **render-fallback-with-semantic-class**: `AvatarFallback` MUST render Base UI's `Avatar.Fallback` (`AvatarPrimitive.Fallback`) with the class name `adh-avatar__fallback` applied.

These three class names are the public theming surface quoted in Overview — stable DOM hooks consumed by the theme editor and user CSS themes — so renaming any of `adh-avatar`, `adh-avatar__image`, or `adh-avatar__fallback` is a breaking change for every theme built against them, not a local refactor.

- **merge-consumer-classname**: Each of `Avatar`, `AvatarImage`, and `AvatarFallback` MUST merge a consumer-supplied `className` prop with its own semantic class name (via the `cn` helper imported from `../lib/utils`) rather than dropping either class.
- **forward-remaining-props**: Each of `Avatar`, `AvatarImage`, and `AvatarFallback` MUST forward every prop other than `className` unchanged to its underlying Base UI primitive.
- **load-as-client-module**: The module MUST be marked `'use client'`, so `Avatar`, `AvatarImage`, and `AvatarFallback` render as client components. This is verified by a static check for the `'use client'` directive at the top of `avatar.tsx`, not by a runtime conformance test vector.

<!-- appkit-avatar -->
AppKit `AvatarView`:

- **appkit-content**: `content` (`AvatarContent?`) MUST drive the view: setting a different value MUST cancel any load in flight, show the initials and start a load for `imageURL`; setting an equal value MUST do nothing.
- **appkit-initials**: The initials MUST be `PersonInitials.of(name:fallback: seed)`: the uppercased first letters of `name`'s first two whitespace-separated words, else the uppercased first letter of `seed`, else `?`. `AccountUser` and `HubUser` use the same function with the email as the fallback.
- **appkit-initials-size**: The initials MUST be set at `side × 0.4` points in the theme's heading family, semibold, so they fit the circle at every side.
- **appkit-initials-ink**: The initials MUST be drawn in `SemanticPalette.laneTextColor(i)` for the circle's lane `i`: opaque black or white, whichever has the higher WCAG contrast against the fill, reaching 4.5:1 wherever either can.
- **appkit-no-url-no-fetch**: An `imageURL` of `nil` MUST never call the fetch.
- **appkit-picture**: A fetch answering 2xx (or a non-HTTP response) with bytes that decode as an image MUST replace the initials with the picture; an error, a non-2xx answer (even one that decodes) or undecodable bytes MUST leave the initials up and log at debug level.
- **appkit-retry**: Moving into a window while no picture is showing MUST retry the load; a picture already showing MUST NOT be fetched again.
- **appkit-colour**: The circle MUST be filled with `SemanticPalette.laneColor(i)`, `i` the FNV-1a 64-bit hash of `seed`'s UTF-8 bytes modulo 12, so one person keeps one colour across launches; it MUST repaint on theme change.
- **appkit-side**: `init(side:fetch:)` MUST size the view to `side × side` (default 48 pt) with corners of radius `side / 2`.
- **appkit-fetch-seam**: The fetch MUST be injectable (`Fetch = @Sendable (URL) async throws -> (Data, URLResponse)`); the default goes through `URLSession.shared`, whose HTTP cache follows the server's headers, and the view keeps no cache of its own.

