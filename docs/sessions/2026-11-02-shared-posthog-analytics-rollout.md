# Session: PostHog on every site, then the toolkit's Dependabot alerts

- **Date:** 2026-11-02
- **Session:** `5ff3d0df-e144-47ee-9e3b-27077b3d937e`
- **Branch:** `shared-posthog` (toolkit and eleven sites), `docs-update-guib`, `dependabot-fixes`, statussite `toolkit-hono-zod`, `docs-update-abaser`

## Orientation

The session started from the agent-SEO plan's measurement step: to see referrals from AI
products, the sites needed analytics. PostHog was first scoped to adh.com only. The owner
then turned it on for every site except the Zorks, and asked for it to be shared. The
config moved out of adh into `@agenticdevelopertoolkit/analytics`, and each site adopted
it on a `shared-posthog` worktree. The Vercel projects got `NEXT_PUBLIC_POSTHOG_KEY`
through the Vercel CLI. All twelve branches were squash-merged with `/ship` on
2026-11-02. Nothing is deployed yet: each site starts sending on its next production
deploy, and that deploy is the owner's to make.

Afterwards the owner asked for the toolkit's Dependabot alerts to be fixed. There were 274
open, and they fell to 1 (deepmerge, which has no fixed release). The fixes landed as toolkit
PR #36 (`81d81c930`). They bumped hono and zod for status-server, so the status site followed
in its PR #22 (`2ca36d63`) to keep the vendored `openapi.json` identical.

## Decisions

- **One shared package, not a copy per site.** The config is privacy policy, and twelve
  copies of it would drift. adh consumes it too, through `TelemetryProvider`.
- **Cookieless, anonymous, allowlist-only.** No autocapture, replay, profiles or persistence.
  That means no consent banner is needed, and `$referrer` cut to origin and path still
  answers the AI-referral question.
- **Every site except the Zorks.** The owner deferred the Zorks ("we will circle back on the
  zorks"). Tools and subdomain sites were also left out.
- **Inert without a key**, so local and preview builds send nothing.
- **Squash merges.** The owner asked for `/ship` with squashing and updated the skill to
  allow it. Squashing the toolkit first stranded each site's submodule branch. Fix: move
  each site's submodule to toolkit `main` before its merge (details in
  [`../web/shared-analytics.md`](../web/shared-analytics.md)).
- **olylo Dependabot alerts fixed on its branch** (next `^15.5.28`, esbuild override,
  fresh lockfile under pnpm 12's minimum-release-age rule).

- **Security floors, not pins, for transitive alerts**, mirrored in `package.json` and
  `pnpm-workspace.yaml` so pnpm 9 and 10 agree. Scoped to one major where an older
  major is legitimately in the tree.
- **Patch redocly rather than hold minimatch back.** minimatch 11 is CJS-named-only,
  and a floor below 11 would leave the alerts open.
- **Accept the regenerated `openapi.json`.** zod 4.6 writes nullable fields as `type`
  arrays. The schema is equivalent, and keeping the old zod would keep its alert.
- **Regenerate the terminal client from the previous spec** (`e4d17a7b0`'s
  `AgenticDeveloperHubClient/openapi.json`), so the diff is only the generator's.
  0.26.2 reproduced the committed tree exactly before 0.29.1 was run.
- **The status site vendors the analytics package.** Advancing its submodule pulled in
  adh's analytics import, and `check-vendor-fresh` exited 5 until it was vendored.

## Open threads

- The Zorks: PostHog deferred by the owner.
- The non-adh sites that adopted PostHog have no privacy page. The planning repo's
  `docs/planning/agent-seo.md` records this.
- AI referrals become measurable only after each site's next production deploy.
- deepmerge 4.3.1: one low alert left, waiting on a fixed release.

## Pointers

- Package: `packages/web/packages/analytics/` (README is the API reference)
- Design and wiring: [`../web/shared-analytics.md`](../web/shared-analytics.md)
- Toolkit merge: PR #34, `0dc1dcf97`
- Dependency policy: [`../web/dependency-security.md`](../web/dependency-security.md)
- Dependabot merge: PR #36, `81d81c930`; status site PR #22, `2ca36d63`
- Plan: `~/Development/planning/fishlampplanning/docs/planning/agent-seo.md`
