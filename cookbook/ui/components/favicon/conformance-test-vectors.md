
The suite beside the source is `favicon.test.tsx` (`packages/web/packages/ui/src/__tests__/favicon.test.tsx`); vectors derived from it name its tests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| favicon-001 | request-from-site-origin, request-first-candidate-first, no-third-party-request | Render with `href` of `https://example.com/some/page` (test "asks the site itself for its icon") | The image `src` is `https://example.com/favicon.ico` |
| favicon-002 | candidate-order, advance-on-load-error | Render with `href` of `https://example.com` and a fallback; fire an error event on the image six times, reading `src` before each (test "tries each candidate in turn, then shows the fallback") | The `src` values are `https://example.com` joined to each entry of `FAVICON_PATHS`, in order |
| favicon-003 | fallback-after-exhaustion | Same render, after the sixth error event | No image element exists and the fallback text is present |
| favicon-004 | fallback-for-invalid-address | Render with `href` of `not a url` and a fallback (test "shows the fallback for an address that is not one") | The fallback is present and no image element exists |
| favicon-005 | fallback-defaults-to-nothing | Render with `href` of `not a url` and no fallback | The component's output is empty |
| favicon-006 | keep-first-loaded | Render with `href` of `https://example.com`; let the first image load without an error event | The image `src` stays `https://example.com/favicon.ico` and no second image is requested |
| favicon-007 | request-from-site-origin | Render with `href` of `https://example.com:8080/a/b?q=1#frag` | The image `src` is `https://example.com:8080/favicon.ico` |
| favicon-008 | hide-from-assistive-technology, square-size, decode-asynchronously | Render with `href` of `https://example.com` and `size` of 24 | The image has `alt` of the empty string, `aria-hidden` of `true`, `width` and `height` of 24 and `decoding` of `async` |
| favicon-009 | square-size | Render with `href` of `https://example.com` and no `size` | The image has `width` and `height` of 16 |
| favicon-010 | merge-class-name | Render with `className` of `ml-1` | The image carries `ml-1`, `shrink-0`, `rounded-[3px]` and `object-contain` |
| favicon-011 | recheck-failure-before-hydration | In a browser, server-render the component, let the image fail before hydration so it is complete with a natural width of zero, then hydrate | After mount the image `src` is the second candidate, `/icon.svg`, without any error event having been delivered |
| favicon-012 | export-candidate-list | Import `FAVICON_PATHS` | The list equals `/favicon.ico`, `/icon.svg`, `/icon.png`, `/icon`, `/apple-icon.png`, `/apple-icon` in that order |
| favicon-013 | fresh-load-per-candidate | Render, then fire an error event on the image | The image element after the event is a different element from the one before it |

