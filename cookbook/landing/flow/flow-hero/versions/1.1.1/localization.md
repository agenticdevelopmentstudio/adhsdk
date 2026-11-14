
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — | — | All content is supplied by the host via props; the component renders no hardcoded strings. |

`.lp-hero-meta`'s `text-transform: uppercase` is a locale-sensitive casing transform (for example, Turkish's dotted/dotless I changes which letter `i` uppercases to); hosts should not assume it produces identical casing in every locale, and no invariant-culture-style call should be introduced to normalize it — locale-sensitive casing is the correct behavior for user-facing text. Content that must not change case in some locale should use the child-element opt-out described under **Metadata styling** and **Accessibility opt-out for uppercase meta**.

