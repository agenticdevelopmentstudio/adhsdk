# AGENTS.md

Orientation for agents (and humans) working in this repo.

## Purpose

A set of reusable per-platform packages: the shared web libraries under
`packages/web/packages/` (`ui`, `chat`, `editing`, `markdown`, `search`,
`themes`, and more, listed below) beside the adh app platform and its feature
packages, a workspace of Xcode projects for Apple, and a Python package for
Terminal. Android and Windows are port plans in `docs/planning/ports/`, with
no code yet. The former `adhsdk` repo was merged in with its history,
so its Apple, web and cookbook content lives here too.

Persona-chat wiring is one capability among them, not the toolkit's
identity: the `chat` package's `PersonaChatBackend` wires apps to the
[agentic registry](https://github.com/mfullerton-archive/agenticregistry) and
[my-agentic-storage](https://github.com/mfullerton-archive/my-agentic-storage).

Each platform folder under `packages/` is the **root of its native build
system** — its conventional manifest file lives there.

## Layout

| Platform | Folder | Manifest | Status |
|---|---|---|---|
| Web (TS) | `packages/web/` | `package.json` (pnpm workspace) | active |
| Apple | `packages/apple/` | `AgenticDeveloperHubSDK.xcworkspace` + one `project.yml` (XcodeGen) per project | active |
| Terminal (Python) | `packages/terminal/` | `pyproject.toml` | active |
| Android | `packages/android/` | (Gradle, planned) | [port plan](docs/planning/ports/android-coordinator.md) |
| Windows | `packages/windows/` | (`.csproj`, planned) | [port plan](docs/planning/ports/windows-coordinator.md) |
| Demo site | `websites/demo/` | `package.json` | active |
| Reference site | `websites/site/` | `package.json` (Next.js) | active |

### Apple

XcodeGen-backed Xcode projects wired together by
`packages/apple/AgenticDeveloperHubSDK.xcworkspace`:

- `packages/apple/AgenticDeveloperHubSDK/` — the multi-platform core and UI
  frameworks (`AgenticDeveloperHubSDK`, `AgenticDeveloperHubSDKUI`).
- `packages/apple/AgenticDeveloperHubClient/` — the hub client framework.
- `packages/apple/AgenticDeveloperHubSDK/` — the macOS-first product frameworks
  (`AgenticDeveloperHubSDKCore`, `AgenticDeveloperHubSDKMacOS`, `AIPluginKit`, the Hub, HTDV,
  Markdown, Sync and Database frameworks, …) and their test bundles. It
  references the two projects above by their in-repo paths.
- `packages/apple/AgenticDeveloperHubSDKApp/` — host app (`AgenticDeveloperHubSDKApp.app`).
- `packages/apple/AIPlugins/` — `AIPluginsShared.framework` plus the
  `.aiplugin` bundles (`ClaudeAPI`, `ClaudeLocal`, `Google`, `OpenAI`,
  `OpenAICompatible`).

`AvatarAnimationEngine/` and `SampleApp/` are standalone projects outside the
workspace.

### Web

The web platform is one pnpm workspace; its libraries live under
`packages/web/packages/`. The shared libraries:

- `@adh-sdk/analytics`
- `@adh-sdk/avatar`
- `@adh-sdk/chat`
- `@adh-sdk/chrome`
- `@adh-sdk/controls`
- `@adh-sdk/editing`
- `@adh-sdk/landing`
- `@adh-sdk/markdown`
- `@adh-sdk/model`
- `@adh-sdk/popover`
- `@adh-sdk/registry-profile`
- `@adh-sdk/registry-types`
- `@adh-sdk/search`
- `@adh-sdk/textlens`
- `@adh-sdk/themes`
- `@adh-sdk/ui`
- `@adh-sdk/viewport`

Beside them, still under the `@adh-sdk/*` scope they shipped with:
the adh app platform (`adh`, `adh-ui`, `auth`, `data`, `resource`, `crud`,
`api-explorer`, `messaging`, `persona`, and the rest) and one package per
product area under `packages/web/packages/features/`.

`websites/site/` is the reference consumer. It sits **outside** the pnpm
workspace and uses `file:` refs so its wiring matches what external apps will
use.

## Where to look first

- Planning, milestones, open architectural decisions →
  [`docs/planning/planning.md`](docs/planning/planning.md)
- Repo conventions, build commands, ground rules →
  [`.claude/CLAUDE.md`](.claude/CLAUDE.md)
- Cookbook recipes referenced by the project → [`recipes/`](recipes/)
- The cookbook spec corpus that came with `adhsdk` →
  [`cookbook/`](cookbook/)
- Repo layout pattern (this design) → [`docs/project/repo-pattern.md`](docs/project/repo-pattern.md)
- Consumer flow (git submodule path, web and Apple) →
  [`docs/web/consuming-as-submodule.md`](docs/web/consuming-as-submodule.md)
- Apple toolkit code review checklist →
  [`docs/project/toolkit-checklist.md`](docs/project/toolkit-checklist.md)
- Web platform docs (adoption, migration, Next.js consumer) → [`docs/web/`](docs/web/)

## Build entry points

- One-shot bootstrap (Apple xcodegen + web install and build): `./install.sh`
- Web build / test: `cd packages/web && pnpm build` / `pnpm test`
- Terminal: `cd packages/terminal && pip install -e .` then `pytest`
- Apple: `open packages/apple/AgenticDeveloperHubSDK.xcworkspace`
  (`xcodebuild` commands in `.claude/CLAUDE.md`)
- Demo site: `cd websites/demo && python3 scripts/build.py` (or
  `websites/run.sh` for local dev)
- Reference site: `cd websites/site && npm run dev`

## Conventions you should know

- The repo root has **no `package.json`** and no loose build configs.
  Tooling that needs one should `cd` into the relevant platform folder.
- Library packages may only depend on other packages within the same
  platform — never on ad-hoc paths outside their workspace.
- `project.yml` is the source of truth for every Apple Xcode project.
  Hand-edits to `project.pbxproj` are lost on the next regeneration; run
  `xcodegen` (or `cc-xcgen`) after editing `project.yml`.
- `learntruefacts` is the dogfood site for the web SDK. Features should
  demonstrate themselves there before being considered done.
