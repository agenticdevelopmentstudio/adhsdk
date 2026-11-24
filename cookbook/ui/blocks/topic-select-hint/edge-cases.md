
- **Empty string `noun`**: An empty string is falsy in JavaScript, so `noun` is treated the same as not provided; the headline falls through to `listTitle` (if given) or the fully generic default. See **use-fallback-headline**.
- **Empty string `listTitle`**: Likewise falsy; `listTitle=""` falls through to the fully generic default rather than producing a "Select an item from " string with a trailing space.
- **Naive article selection**: `article()` (`/^[aeiou]/i.test(noun)`) tests only the noun's first letter, not English pronunciation, so it picks the wrong article for words like "hour" ("a hour" instead of "an hour") and "user" ("an user" instead of "a user"). This is a known, accepted limitation, not required behavior: a port may use a better article rule without breaking conformance — see **compute-headline-from-noun**.
- **Custom title with selectable false**: `title` is checked with `??` (nullish coalescing), which only defers to the computed headline when `title` is `null`/`undefined`. An explicit `title` therefore still renders even when `selectable` is false; `selectable` only ever suppresses the *computed* headline. See **hide-headline-when-not-selectable**.
- **null/undefined children**: Component correctly skips rendering the children section entirely when not provided.
- **selectable false with no children**: Component hides the computed headline and renders no fallback; only the icon is shown.
- **Very long noun or listTitle**: Component does not define text truncation; long values will wrap or overflow based on Card max-width constraint.

