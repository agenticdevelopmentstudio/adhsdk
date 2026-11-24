
Not applicable beyond the options below: the module reads no environment variables or settings files; everything comes from `SectionedDashboardOptions`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ttlMs` | number | required | How long a fully successful section is good for, and the cap on every retry wait |
| `retryMs` | number | 60,000, clamped to `ttlMs` | First retry wait after a failed or incomplete section; doubles with each further failure in a row |
| `concurrency` | number | 1 | How many due sections run at once; 1 runs strictly in order |
| `sections` | readonly array of section names | required | The section names, in refresh order |
| `loaders` | function from key to a record of loader functions | required | Built per refresh, one async function per section |
| `incomplete` | function from section name and data to boolean | none (every answer is complete) | True for an answer that is shown but known to be short |
| `now` | function returning epoch ms | `Date.now` | Clock, replaceable in tests |

The dashboard set passes `ANALYTICS_TTL_MS` for the PostHog, Vercel and site-health dashboards, and `ERRORS_TTL_MS` for GlitchTip. The Vercel dashboard supplies `incomplete`.

