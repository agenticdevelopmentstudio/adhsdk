# Shared PostHog analytics

`@adh-sdk/analytics` (`packages/web/packages/analytics/`) holds the one
PostHog configuration every site sends with. Its README is the API reference; this doc
records why it exists, how each kind of site wires it, and what was decided along the way.

Derived from: commit `0dc1dcf97` ("Shared PostHog analytics package for every site", PR
#34) and the eleven site merges that adopted it on 2026-11-02.

## Why a shared package

PostHog started inside adh's `TelemetryProvider`. When every other site was turned on too,
the choice was between copying that setup into each site or moving it down a tier. It moved
down: the config is privacy policy, and a privacy policy that exists in twelve copies drifts.
adh now calls `startPostHog()` from the package, so adh and non-adh sites send identical
events from one source.

## The configuration, and why each part

- **No autocapture, no session replay.** Only allowlisted events leave the page.
- **In-memory persistence, no person profiles.** No ID survives the visit and no visitor is
  identified, so there is no cookie and no consent banner is needed.
- **URLs scrubbed** of query, hash and id-shaped path segments before sending. `$referrer`
  is cut to origin and path, which still names the referring AI product (chatgpt.com,
  perplexity.ai, claude.ai and the rest), the measurement the agent-SEO plan wanted.
- **Inert without `NEXT_PUBLIC_POSTHOG_KEY`.** Local and preview builds send nothing unless
  the key is set. The key was set on every adopting site's Vercel project.

The scrubbers (`scrubPath`, `scrubUrl`) are exported because error reporting uses the same
rules.

## How each kind of site wires it

| Kind | Wiring |
|---|---|
| adh family | adh's `TelemetryProvider` calls `startPostHog()`; nothing per site. |
| Templated sites (site-template) | `analytics: true` in `site/site.json`; `assemble_site.py` mounts `PostHogAnalytics` beside Vercel Analytics. |
| Leaf sites (own layout) | Mount `<PostHogAnalytics />` in the root layout's `<body>`. |

Sites whose build doesn't already build the toolkit (scratchyfish, myagenticprojects,
myinbox) run the site-template `build-site.py` from `vercel.json`, which builds the
package's `dist` before `next build`. myagenticprojects and myinbox also moved their pnpm
workspace root up to `websites/`, because Turbopack won't resolve a package linked from
`../external` when it sits outside the inferred root.

Adopted on 2026-11-02 by every site except the Zorks (deferred by the owner): adkitchen,
adstenographer, ads, fishlamp, mikefullerton, learntruefacts, olylo, whatsnow, scratchyfish,
myagenticprojects, myinbox.

## Landing note: squash merges and submodule branches

The toolkit branch was squash-merged, so every site's `<site>/shared-posthog` submodule
branch pointed at a commit that never reached toolkit `main`. Replaying it conflicted, and
the merge gate rejected it as `off-main-no-branch`. The fix, per site: move the submodule to
toolkit `origin/main` (lossless, because the squash commit's tree equals the old tip),
commit the gitlink bump, then merge the site. When a toolkit change is squash-merged, land
its consumers this way.
