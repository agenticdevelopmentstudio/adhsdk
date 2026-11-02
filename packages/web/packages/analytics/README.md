# @agenticdevelopertoolkit/analytics

Privacy-first product analytics for any site, adh or not. It holds the one PostHog
configuration every site sends with: no autocapture, no session replay, in-memory
persistence (so no cookie and no consent banner), no person profiles, and URLs stripped
of their query, hash and id-shaped path segments before an event leaves the page.

```tsx
import { PostHogAnalytics } from '@agenticdevelopertoolkit/analytics'

// in the root layout's <body>
<PostHogAnalytics />
```

It reads `NEXT_PUBLIC_POSTHOG_KEY` (and optionally `NEXT_PUBLIC_POSTHOG_HOST`, default
`https://us.i.posthog.com`) and does nothing without a key, so a local build sends nothing.

adh sites don't mount it: adh's `TelemetryProvider` calls `startPostHog()` itself.

| Export | What it does |
|---|---|
| `PostHogAnalytics` | Client component; starts PostHog on mount and renders nothing. |
| `startPostHog()` | Starts PostHog once per page; returns whether it is running. |
| `captureAnalyticsEvent(name, props)` | Sends a custom event through the started instance; a no-op before it has started. |
| `scrubPath(url)`, `scrubUrl(url)` | The URL scrubbers, shared with error reporting. |
