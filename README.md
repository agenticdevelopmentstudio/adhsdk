# adhsdk

## This is not ready for consuption yet, it's still getting reworked

A set of reusable per-platform packages — the shared web libraries (`ui`,
`chat`, `editing`, `markdown`, `search`, `themes`, and more, listed below)
plus the adh app platform and its feature packages, a workspace of Xcode
projects for Apple, and a Python package for Terminal. Android and Windows are
port plans in `docs/planning/ports/`, with no code yet.

The repo also absorbed `adhsdk`, history and all: its Apple
frameworks, AI plugins and host app, its web app platform, and its cookbook
now live here, so shared code has one home.

Persona-chat wiring is one capability among them, not the toolkit's
identity: the `chat` package's `PersonaChatBackend` splices the
[official agentic registry](https://github.com/mfullerton-archive/agenticregistry)
(persona definitions + LLM provider integrations) and
[my-agentic-storage](https://github.com/mfullerton-archive/my-agentic-storage)
(chat history + state) into the shape a chat UI expects, so a consumer app
does not have to re-implement that orchestration.

Supersedes the deprecated `agentic-persona-coordinator`.

## Layout

Each platform folder under `packages/` is the **root of its native build
system** — open it and you'll find the conventional manifest for that
platform.

| Platform | Folder | Manifest | Status |
|---|---|---|---|
| Web (TS) | `packages/web/` | `package.json` (pnpm workspace) | active |
| Apple | `packages/apple/` | `AgenticDeveloperHubSDK.xcworkspace` + one `project.yml` (XcodeGen) per project | active |
| Terminal (Python) | `packages/terminal/` | `pyproject.toml` | active |
| Android | `packages/android/` | (TBD) | placeholder |
| Windows | `packages/windows/` | (TBD) | placeholder |
| Demo site | `websites/demo/` | `package.json` | active |
| Reference site | `websites/site/` | `package.json` | active |

The Apple platform is a workspace of XcodeGen-backed Xcode projects:
`AgenticDeveloperHubSDK` (the multi-platform core and UI frameworks),
`AgenticDeveloperHubClient`, `AgenticDeveloperHubSDK` (the macOS-first product
frameworks), `AgenticDeveloperHubSDKApp` (host app), and `AIPlugins`
(`AIPluginsShared.framework` plus the `.aiplugin` bundles).
`AvatarAnimationEngine` and `SampleApp` stand outside the workspace.

The web platform is a pnpm monorepo with libraries under
`packages/web/packages/`:

- `@adh-sdk/analytics` — privacy-first PostHog analytics any site
  can mount: anonymous, cookieless, allowlist-only, with URLs scrubbed of ids.
- `@adh-sdk/avatar` — headless avatar behaviour and the
  `useAvatarEngine` hook.
- `@adh-sdk/chat` — React chat components (`InlineChat`,
  `ThreePaneChat`, `MobileChat`, `PersonaChat`) with pluggable backends.
- `@adh-sdk/chrome` — site chrome: the menu button and the
  close glyph derived from it.
- `@adh-sdk/controls` — settings, search dialog, dev banner,
  logging panel, and the other small operator-facing controls a consumer site
  wires up around the rest of the kit.
- `@adh-sdk/editing` — a host-agnostic inline-editing
  container: sections, validation, repair, and the scope/server plumbing
  around them.
- `@adh-sdk/landing` — a snap-scrolling, long-form landing
  page kit: the scroll deck, fixed-header chrome, and a vocabulary of
  presentational blocks, themed entirely through `--lp-*` custom properties.
- `@adh-sdk/markdown` — a markdown renderer with its own
  component set, syntax themes, and rendering hooks.
- `@adh-sdk/model` — provider integrations, hooks, and
  library helpers for talking to an LLM provider.
- `@adh-sdk/popover` — hover popovers: the anchored panel, its
  pointing arrow, and the hover-intent state for a row of them.
- `@adh-sdk/registry-profile` — renders a registry service's
  public profile: fields, service list, and the surrounding layout.
- `@adh-sdk/registry-types` — shared types, validation, and
  visibility rules for registry data.
- `@adh-sdk/search` — a search UI (components, data layer,
  and a small results registry) for querying a site's own content.
- `@adh-sdk/textlens` — a travelling lens that magnifies,
  softens and tints each character of a line as it passes.
- `@adh-sdk/themes` — Theme manifest, `ThemeStyle`, and
  `ColorModeProvider`, plus the page-level, unscoped accessibility styles
  (`data-reduce-motion`, `data-contrast`, `data-text-size`) that sit alongside
  the per-widget theme scoping.
- `@adh-sdk/ui` — the shared UI kit: primitives (the shadcn
  slot + `cn` helper), a larger vocabulary of composed blocks, and the global
  styles they share.
- `@adh-sdk/viewport` — iOS-correct viewport / keyboard
  primitives.

Beside them sits the adh app platform, still under its original
`@adh-sdk/*` scope:

- `@adh-sdk/adh` — family site chrome: header, footer, legal.
- `@adh-sdk/adh-ui` — the adh vocabulary the shared UI must not know
  about: rdid pickers and editors, invitation panes, the delete-entity
  danger zone.
- `@adh-sdk/auth` / `data` / `resource` / `crud` — the app platform.
- `@adh-sdk/api-explorer` — the API reference surface.
- `@adh-sdk/messaging` — DMs, notifications, presence.
- `@adh-sdk/persona` — the crossing consumers use to reach the
  persona vocabulary (`chat`, `themes`, `viewport`) without pulling a persona in.
- the packages under `packages/web/packages/features/` — one per product area
  (projects, teams, research, notebook, ecosystems, …), plus `bitbag`, the
  persona himself.

## Build

One-shot bootstrap (installs the web workspace and runs theme codegen):

```bash
./install.sh
```

Per-platform commands:

```bash
# Web
cd packages/web && pnpm build
cd packages/web && pnpm test

# Terminal (Python)
cd packages/terminal && pip install -e . && pytest

# Apple
open packages/apple/AgenticDeveloperHubSDK.xcworkspace
# Full xcodebuild commands in .claude/CLAUDE.md

# Demo site (local dev)
cd websites && ./run.sh

# Reference site
cd websites/site && npm install && npm run dev
```

## Design

How this repo is laid out, how it's consumed, and the recipe for building
sibling toolkit repos the same way:
[`docs/project/repo-pattern.md`](docs/project/repo-pattern.md).

Consumer setup walkthrough (git submodule path, web and Apple):
[`docs/web/consuming-as-submodule.md`](docs/web/consuming-as-submodule.md).

Web-platform docs (adoption, migration, Next.js consumer wiring):
[`docs/web/`](docs/web/).

## Planning

Milestones, the open architectural decision, and design notes live in
[`docs/planning/planning.md`](docs/planning/planning.md).

Agent-oriented orientation: [`AGENTS.md`](AGENTS.md).
Repo conventions and build rules: [`.claude/CLAUDE.md`](.claude/CLAUDE.md).
