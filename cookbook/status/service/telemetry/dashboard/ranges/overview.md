
`ranges.ts` defines the time axis that the Analytics and Errors dashboard topics share. It names the three selectable ranges, turns a range and a clock reading into a window of bucket start times, and aligns a provider's timestamped values onto that window.

Every provider's answer is aligned onto the same buckets, so a quiet hour reads as a zero rather than a gap, and PostHog's and Vercel's series can share one chart. The module is pure: it reads no clock, no network and no storage. The caller passes the current time in as `nowMs`.

