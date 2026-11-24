
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | opens-new-tab, applies-safe-rel | `<ExternalLink href="https://example.com">PostHog</ExternalLink>` | anchor has `target="_blank"` and `rel="noopener noreferrer"` |
| T2 | renders-trailing-glyph-by-default | same as T1 | link text content contains `↗` |
| T3 | glyph-is-decorative | same as T1 | accessible name equals exactly `PostHog`, not including the arrow |
| T4 | suppresses-glyph-when-false | `<ExternalLink href="…" glyph={false}>GitHub</ExternalLink>` | link named `GitHub` has no `↗` text content |
| T5 | forwards-anchor-props | `href="https://us.posthog.com"` | anchor `href` equals `https://us.posthog.com` |
| T6 | merges-classname, default-deep-link-skin | `className="font-sans text-apt-text-muted"` | `cn()` is `twMerge(clsx(...))`, so the conflicting font-family utility is resolved: className contains `font-sans` and not `font-mono`; anchor still has `target="_blank"` and `rel="noopener noreferrer"` |
| T7 | safe-attrs-not-overridable | `<ExternalLink href="https://example.com" target="_self" rel="">PostHog</ExternalLink>` | anchor `target` equals `_blank` and `rel` equals `noopener noreferrer` (the passed-in `target`/`rel` do not win) |
| T8 | focus-ring | same as T1 | className contains `focus-visible:ring-2` and `focus-visible:ring-apt-gold/40` |
| T9 | default-deep-link-skin | same as T1 | className contains `whitespace-nowrap` and `no-underline` |

