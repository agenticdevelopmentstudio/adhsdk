
- **request-from-site-origin**: The component MUST request the icon from the origin of `href`, and MUST ignore the path, query and fragment of `href`.
- **request-first-candidate-first**: The first request MUST be for the first entry of `FAVICON_PATHS`, `/favicon.ico`, joined to the origin.
- **candidate-order**: The candidate paths MUST be tried in this order: `/favicon.ico`, `/icon.svg`, `/icon.png`, `/icon`, `/apple-icon.png`, `/apple-icon`.
- **advance-on-load-error**: When the current candidate fails to load, the component MUST request the next candidate.
- **keep-first-loaded**: The component MUST keep showing the first candidate that loads and MUST NOT request later candidates.
- **fresh-load-per-candidate**: Each candidate MUST be a new image element, so that a new address is a new load with its own load and error events.
- **fallback-after-exhaustion**: When every candidate has failed, the component MUST render the `fallback` in place of the image and MUST NOT render an image element.
- **fallback-for-invalid-address**: When `href` is not a valid absolute URL, the component MUST render the `fallback` and MUST NOT request any image.
- **fallback-defaults-to-nothing**: When no `fallback` is given and no icon can be shown, the component MUST render nothing.
- **no-third-party-request**: The component MUST NOT request the icon from any host other than the origin of `href`.
- **recheck-failure-before-hydration**: After mounting, when the current image is already complete with a natural width of zero, the component MUST advance to the next candidate, because a failure before hydration is never delivered to the component as an error event.
- **hide-from-assistive-technology**: The image MUST have an empty alternative text and MUST be hidden from assistive technology.
- **square-size**: The image MUST be drawn as a square whose width and height attributes equal `size`, which defaults to 16.
- **decode-asynchronously**: The image MUST request asynchronous decoding.
- **merge-class-name**: The component MUST merge a caller `className` with its own classes `shrink-0`, `rounded-[3px]` and `object-contain`.
- **export-candidate-list**: The module MUST export the candidate list as `FAVICON_PATHS`.
- **load-as-client-module**: The module MUST be marked `"use client"`. This is verified by a static check for the directive at the top of `favicon.tsx`, not by a runtime test vector.

