# Dependency security: floors, patches and pins

How the toolkit clears Dependabot alerts, and what has to stay true when the
next batch arrives. The pass of 2026-11-02 took the repo from 274 open alerts
to 1 (toolkit PR #36, squashed as `81d81c930`).

## Where the alerts come from

Three manifests carry them:

| Manifest | Tool | How it is fixed |
|---|---|---|
| `packages/web/pnpm-lock.yaml` | pnpm 9 workspace | direct bumps, plus security floors in overrides |
| `websites/demo/package-lock.json` | npm | direct bumps, plus npm `overrides` |
| `packages/terminal/pyproject.toml` | pip | bump the generator, then regenerate the client |

Check a lockfile against the open alerts before you push, not after. The
alert ranges are in `gh api repos/agenticdevelopmentstudio/adhsdk/dependabot/alerts`.
Each alert's `vulnerable_version_range` can be compared with the versions the
lockfile resolves.

## Security floors in the web workspace

Most alerts are transitive. They are cleared with overrides that set a minimum
version (`"postcss": "^8.5.23"`, `"undici@7": "^7.30.1"`), never an exact pin.

- **They live in two places.** `package.json` `pnpm.overrides` is read by pnpm 9.
  `pnpm-workspace.yaml` `overrides:` is read by pnpm 10 and later. Keep the two
  identical, along with `patchedDependencies`.
- **Scope a floor to one major** (`body-parser@2`, `js-yaml@3`, `next@15`)
  when an older major is still legitimately in the tree. An unscoped floor
  would pull that consumer across a breaking change.
- **Drop an entry** once every dependent resolves above it without help. Floors
  that outlive their reason hide the real version tree.

## The minimatch 11 patch

The floor `minimatch: ^11.0.1` breaks `@redocly/openapi-core` 1.34.20.
minimatch 11's CommonJS build exports only a named `minimatch`, but redocly
calls `require("minimatch")` as a function. The fix is a pnpm patch,
`patches/@redocly__openapi-core@1.34.20.patch`, which changes `lib/utils.js` to
destructure the named export.

- The patch is keyed to that exact redocly version. When openapi-typescript
  moves redocly forward, the patch stops applying. Re-create it with
  `pnpm patch`, or drop it if the new redocly imports minimatch correctly.
- To check the patch, call redocly's header matcher (`readFileFromUrl` with
  a `headers` matcher). It is the code path that calls minimatch. Generating
  types with openapi-typescript does not reach it.

glob 14 also keeps the `./raw` subpath that `@bundled-es-modules/glob`
re-exports, so the glob floor is safe for style-dictionary. The themes token
build confirms it: `pnpm --filter ./packages/themes run build:tokens` should
leave `packages/web/packages/themes/src` unchanged.

## status-server: exact pins, and the hosts that follow them

`packages/web/packages/status-server` pins hono, zod and `@hono/zod-openapi` **exactly** in
its devDependencies. The committed `openapi.json` is generated from them and
checked byte for byte, both here and in each host that vendors status-server.
Bumping either package therefore changes the spec. zod 4.6, for example,
writes nullable fields as `"type": ["string","null"]` instead of
`anyOf`, which is the same schema in a different shape.

When you bump them:

1. Change the pins and the peer ranges (`^4.13.11`, `^4.6.6`).
2. Run `pnpm build`, then
   `pnpm --filter ./packages/status-server run openapi:dump`, and commit the
   new `openapi.json`.
3. In each host, move hono and zod to the same versions, advance the toolkit
   submodule and re-vendor. The status site
   (the statussite repo, PR #22, `2ca36d63`) follows the order in its
   `.claude/CLAUDE.md` and finishes with `check-vendor-fresh.py`.

Advancing a host's submodule can also pull in packages it has never vendored.
In this pass, adh's telemetry imported `@adh-sdk/analytics`, so
the status site had to add it to `WEB_PACKAGES`. `check-vendor-fresh` exits 5
when this happens.

## Next.js

Every package and the site-template skeleton pins Next to one version (16.4.3
as of this pass). The "Next is pinned" section of
`packages/web/packages/site-template/README.md` says how to move it. The test
`assemble_site_test.py` asserts the version, so it must change alongside the
pin. The demo site is still on Next 15, kept at `^15.5.28`.

## The terminal client

`packages/terminal` generates its API client with `openapi-python-client`.
To bump the generator, first regenerate from the **same spec as the last run**,
so the diff contains only the generator's own changes. That spec is the
`AgenticDeveloperHubClient/openapi.json` that was current when
`src/apt_terminal/generated/` was last committed. Pulling in a newer spec at
the same time would mix the two diffs.

Starting with 0.29, generated models use `from __future__ import annotations`,
so an attrs `field.type` is source text, not a type. `crud.py`'s `field_type`
evaluates that text in the model's own module before `coerce_enums` checks
for an enum.

## What remains open

- **deepmerge 4.3.1** (low). It has no fixed release, so there is nothing to
  move to. Re-check it when a patched version ships.
