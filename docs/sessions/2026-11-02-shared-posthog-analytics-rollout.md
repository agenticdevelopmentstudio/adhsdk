# Session: PostHog on every site, from one shared package

- **Date:** 2026-11-02
- **Session:** `5ff3d0df-e144-47ee-9e3b-27077b3d937e`
- **Branch:** `shared-posthog` (toolkit and eleven sites), `docs-update-guib`

## Orientation

The session started from the agent-SEO plan's measurement step: to see referrals from AI
products, the sites needed analytics. PostHog was first scoped to adh.com only. The owner
then turned it on for every site except the Zorks, and asked for it to be shared. The
config moved out of adh into `@agenticdevelopertoolkit/analytics`, and each site adopted
it on a `shared-posthog` worktree. The Vercel projects got `NEXT_PUBLIC_POSTHOG_KEY`
through the Vercel CLI. All twelve branches were squash-merged with `/ship` on
2026-11-02. Nothing is deployed yet: each site starts sending on its next production
deploy, and that deploy is the owner's to make.

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

## Open threads

- The Zorks: PostHog deferred by the owner.
- The non-adh sites that adopted PostHog have no privacy page. The planning repo's
  `docs/planning/agent-seo.md` records this.
- AI referrals become measurable only after each site's next production deploy.

## Pointers

- Package: `packages/web/packages/analytics/` (README is the API reference)
- Design and wiring: [`../web/shared-analytics.md`](../web/shared-analytics.md)
- Toolkit merge: PR #34, `0dc1dcf97`
- Plan: `~/Development/planning/fishlampplanning/docs/planning/agent-seo.md`
