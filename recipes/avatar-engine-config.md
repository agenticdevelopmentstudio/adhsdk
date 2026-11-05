---
id: d3e1f776-8ad1-431f-9485-386ac285a039
title: Avatar Engine Config
domain: adhsdk://recipes/avatar-engine-config
type: ingredient
category: engine
version: 1.0.3
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'The two-platform contract for the avatar animation engine''s config loader:
  validates and normalizes six authored JSON files into one CharacterConfig.'
platforms:
- swift
- macos
- ios
- typescript
- web
tags:
- avatar
- engine
- config
- validation
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Avatar Engine Config

## Overview

The avatar engine config loader is the single entry point that turns six
author-written JSON files — `character.json`, and the rig/poses/timelines/
behavior/sayings files it names — into one validated, in-memory
`CharacterConfig`. It is a headless **engine** component: a pure function from
raw config text to a typed model, with no view, no window, and no rendering.
Every per-frame consumer downstream (rig walker, pose blender, timeline
player, behavior arbiter) trusts the shapes and cross-references
`CharacterConfig` hands it; the loader is the one place a bad reference, a bad
colour, or a bad shape is still attributable to the authored key that caused
it.

Two independent implementations conform to this contract:

- **Apple** (Swift, macOS + iOS): `CharacterConfig.load(_:)` in
  `packages/apple/AvatarAnimationEngine/Sources/Config/Loader.swift`, over the
  types in `Sources/Config/Types.swift`. `RawFiles.read(fromDirectory:)`
  additionally reads the six files from disk (Apple-only; there is no web
  equivalent because the web build receives already-bundled JSON modules).
- **Web** (TypeScript): `loadConfig(input)` in
  `packages/web/packages/avatar-engine/src/config/load.ts`, over the types in
  `src/config/types.ts`.

Both loaders MUST agree on the verdict (accept the config, or reject it) for
every input. They are not required to agree on exact error message text —
several messages differ deliberately between platforms, and each divergence
called out below is intentional, not a defect.

Because this recipe documents a validation contract rather than a widget, the
Appearance, States, and Accessibility sections below each collapse to one
line: the loader draws nothing, has no interaction state, and exposes nothing
to assistive technology.

## Behavioral Requirements

### Loading entry points

- **directory-read** (Apple only): `RawFiles.read(fromDirectory:)` MUST read
  `character.json` from the given directory, decode its `files` object
  (`{rig, poses, timelines, behavior, sayings}`), and then read each of those
  five named files from the same directory. The five sibling filenames are
  never hardcoded — they are authored data, taken from `character.json`
  itself.
- **load-is-pure**: `CharacterConfig.load(_:)` / `loadConfig(input)` MUST be a
  synchronous, side-effect-free function of its input: no network calls, no
  disk writes, no global mutable state. Given the same six inputs, both
  implementations MUST return an equal result or throw for the same reason.
- **load-does-not-mutate-caller-input**: `loadConfig` (web) MUST NOT mutate
  the `RawFiles` object it receives — it clones the input defensively before
  colourizing or canonicalizing any value in place. This guard exists
  specifically because a bundler can hand the same parsed JSON module object
  to more than one call. The Apple loader has no equivalent clone step
  because `CharacterConfig.load(_:)` decodes fresh `Codable` values from
  `Data` on every call, so there is no shared reference to protect; this is a
  deliberate, source-driven asymmetry, not a missing guard on the Apple side.
- **schema-version-required**: every one of the six files MUST declare a
  `schemaVersion` field equal to the loader's own constant (`Schema.version` /
  the web `SCHEMA_VERSION`, both `1`). A missing or mismatched
  `schemaVersion` on any file MUST reject, and the error MUST name the file
  and both the declared and expected version numbers.
- **returns-full-config**: on success the loader MUST return, in addition to
  the six parsed (and normalized) files themselves: `channels` (the closed
  set of every legal concrete channel name), `expand` (channel-or-group name
  → concrete channel names), `respond` (channel, raw value → rendered value,
  applying bend damping where relevant), `families` (node id → shape family),
  `rest` (channel → resting value derived from the rig tree), and `nodes`
  (node id → parsed rig node).

### Colour and ink resolution

- **palette-hex-format**: every `character.palette` entry MUST be a
  loadable hex colour — ASCII `#rgb` or `#rrggbb` — or the load rejects,
  naming the palette key and the offending value.
- **ink-precedence-inks-before-palette**: when resolving a colour name that
  exists in both `character.inks` and `character.palette`, the loader MUST
  resolve it as an ink, never as a palette colour. Ink names and palette
  names share one lookup order, not two independent namespaces.
- **ink-channel-normalization**: any authored `.ink` channel value that names
  a palette entry MUST be rewritten (colourized) to its resolved hex literal
  during load; a value that already names an ink key MUST be left as that
  key, unresolved, since ink resolution happens per-frame at render time via
  the ink table, not at load time.
- **shaped-node-requires-ink**: a rig node with a `shape` MUST have a
  non-nil `ink`, or the load rejects naming the node.
- **shaped-node-rejects-bare-palette-colour**: a shaped node's `ink` MUST
  name an ink key, never a bare palette colour used directly as paint; the
  load rejects a node whose `ink` resolves only via the palette and never via
  `character.inks`.
- **node-ink-must-resolve**: a node's `ink` MUST resolve to a known entry in
  either `character.inks` or `character.palette` (subject to
  shaped-node-rejects-bare-palette-colour above), or the load rejects naming
  the node and the unresolved ink key.
- **ink-late-binding-target**: an ink whose colour value begins with `@`
  (a late-bound reference, e.g. `@torso`) MUST name a node id that both
  exists in the rig and is palette-driven (has no `family`, is not
  bend-driven); the load rejects an `@`-reference to a missing node or to a
  node that isn't palette-driven.

### Rig and channels

- **duplicate-node-id-rejected**: walking the rig tree MUST reject a second
  node that reuses an id already seen earlier in the walk. Apple's message
  reads "two nodes share the id …"; the web message reads "duplicate node
  id: …" — the wording differs deliberately, the verdict (reject) MUST NOT.
- **channel-set-derivation**: for every rig node and every property in the
  closed `Animatable`/`ANIMATABLE` set (`x, y, rotation, scale, scaleX,
  scaleY, pivotX, pivotY, bend, ink, alpha, shape, family` — 13 properties),
  the loader MUST derive one concrete channel name `"<nodeId>.<prop>"` and
  add it to the returned `channels` set.
- **rest-value-derivation**: for every node, the returned `rest` map MUST
  supply a resting value for its `x`, `y`, `rotation`, `scaleX`, `scaleY`,
  `bend`, `alpha`, `pivotX`, `pivotY` channels: authored transform overrides
  where present, else the fixed numeric defaults (`x=0, y=0, rotation=0,
  scaleX=1, scaleY=1, bend=0, alpha=1`, pivot defaulting to `(0,0)`). It
  MUST additionally supply an `.ink` rest value only for a node that
  authors an `ink`, and a `.family` rest value (plus, for a
  non-bend-driven node, a computed `.shape` rest path — see
  rest-shape-computed below) only for a node whose shape resolves to a
  family (see bend-driven-node-has-no-shape-rest-channel). A node's
  derived `.scale` channel MUST NOT receive a rest value; nothing reads it
  directly (see group-expansion).
- **empty-group-rejected**: a `rig.groups` entry with an empty member list
  MUST reject, naming the group.
- **group-name-collision-rejected**: an authored group name that collides
  with a concrete channel name, or with the derived `.scale` channel name
  every node receives automatically, MUST reject.
- **group-member-must-be-concrete-channel**: every member listed in a
  `rig.groups` entry MUST itself be a concrete channel — either a leaf
  `"<nodeId>.<prop>"` name, or a node's derived `<nodeId>.scale` channel
  (which `expand` flattens one further level; see group-expansion) — never
  an authored group name. A group naming another authored group as a
  member MUST reject; authored group nesting is not supported by this
  loader.
- **group-expansion**: `expand(name)` MUST flatten any group name to its
  full set of leaf channel members. A derived `.scale` channel MUST be
  synthesized for every node, mapping it to that node's `.scaleX` and
  `.scaleY` channels; when an authored group's member list names a node's
  `<nodeId>.scale` channel, `expand` MUST flatten it through that same
  mapping, so the group's final member set never contains a `.scale`
  channel, only leaves.
- **primitive-with-family-rejected**: a node whose shape kind is a primitive
  (`ring`, `disc`, or `arc`) MUST NOT also declare a `family`; the load
  rejects a primitive shape carrying family metadata.
- **shape-field-requirements-enforced**: `requireShapeFields` MUST reject a
  shape missing any field its declared `kind` requires (for example a
  `path`-kind shape missing `points`).
- **bend-driven-node-has-no-shape-rest-channel**: a bend-driven node (a
  bezier shape whose geometry is a function of its `.bend` channel) MUST NOT
  receive a `.shape` rest channel, because its shape is rebuilt every frame
  from the current bend value rather than held as a static rest path.
- **rest-shape-computed-via-builders**: a non-bend-driven, family-driven
  node's `.shape` rest value MUST be computed by calling the same path
  builder functions the renderer uses at draw time (`restShape`), not by any
  separate load-time approximation — the rest path and a runtime-rendered
  path for the same inputs MUST be identical.
- **bend-response-damping**: `respond(channel, value)` for a channel with an
  associated `Bend` definition (a `"<id>.bend"` channel) MUST apply the
  configured inward damping when the value's sign matches the bend's
  `inwardSign`, and MUST pass the value through unchanged otherwise.

### Reference integrity, pairs, and value typing (shared mechanism)

These rules describe one mechanism — a general reference-and-shape check
applied at many authoring sites — rather than one behavior per site; each is
independently testable at any of its listed call sites.

- **reference-integrity**: every authored reference to another config entity
  MUST resolve to something that exists, or the load rejects naming the
  reference and the field that carried it. This rule applies at (non-
  exhaustively): pose channel/group targets, spin channels and carries,
  timeline step channels and eases, `behavior.channelDelays` keys,
  `behavior` gaze/blink/idleFidget/pinpricks channels and eases,
  `moodEffects`/`ladder`/`waking`/`eyesShutMood`/`poke`/`choreography`/
  `sayings` mood names (which MUST each be a real pose), `choreography`
  timeline names, `idleFidget.brow.nodes` and `pinpricks.nodes` (which MUST
  each be a real rig node id), and `crop` feature names (which MUST be a
  feature some node actually declares).
- **pair-fields-exactly-two**: every field documented as a two-number pair
  (`gaze.reachCurious`, `gaze.reachIdle`, `idleFidget.durationRange`,
  `idleFidget.rearm.gapMs`, a mood-effect step's own `durationRange`,
  `moodEffects.*.firstDelayMs`/`rearmMs` when present,
  `speech.bubble.distance`) MUST contain exactly two numbers; one, three, or
  more MUST reject.
- **value-type-matches-channel**: `requireValue` MUST reject a value whose
  shape doesn't match its target channel's kind — a bare number written to a
  `.shape` or `.ink` channel, unsupported path syntax written to a `.shape`
  channel, or an unresolved colour written to an `.ink` channel.
- **shape-path-syntax-validated**: any value written to a `.shape` channel
  (in a pose or a non-promote timeline step) MUST parse as a supported path
  grammar (`parsePath`), or the load rejects.
- **shape-value-canonicalized**: any accepted `.shape` value MUST be
  re-emitted through the canonical path printer before storage, so two
  authored spellings of the same path (e.g. differing whitespace) compare
  equal downstream.

### Poses

- **pose-channel-validated**: every channel a pose drives MUST pass
  reference-integrity, MUST NOT target an empty-expanding group, and its
  value MUST pass value-type-matches-channel after colourization and
  canonicalization.
- **command-signature-agreement**: for any `.shape` channel, the path
  "kind" (its command signature — e.g. an `M` followed by `n` `L`s) MUST be
  identical across the rig's rest shape and every pose that drives that
  channel; a pose whose path kind disagrees with the rest shape or with
  another pose driving the same channel MUST reject, naming both
  conflicting sources.
- **spin-channel-concrete**: a pose's `spin` field, if present, MUST name a
  single concrete channel, never a group.
- **spin-carries-validated**: each channel listed in a pose's spin `carries`
  MUST be a channel that (a) exists, (b) is not the spin channel itself, and
  (c) is among the channels that same pose already drives.
- **poses-order-integrity**: every name in `poses.order` MUST be a key of
  `poses.poses`; an unknown name MUST reject.

### Timelines

- **promote-step-shape**: a timeline step is a promotion only when it
  carries an explicit `promote` field (not merely a `family` that differs
  from the channel's currently in-force family); such a step MUST NOT also
  carry a `to` value, and MUST target only a `.shape` channel. A step that
  changes a channel's `family` without a `promote` field is not a
  promotion and MAY carry a `to` value (see
  timeline-step-value-processing and family-change-requires-snap).
- **timeline-step-value-processing**: a non-promote step's `to` value MUST
  be present, and MUST pass through the same colourize/canonicalize/
  value-type-matches-channel pipeline as a pose value.
- **family-change-requires-snap**: any step that changes a channel's family
  (whether or not it is also treated as a promotion) MUST have `duration`
  `0`; a non-zero-duration family change MUST reject.
- **promotion-source-target-kind**: a promotion's source family path kind
  MUST be an open polyline of the form `M` followed by one or more `L`
  commands; its target family path kind MUST be `M` followed by that many
  `C` commands (a whole multiple of the source's line-segment count) — any
  other source/target kind pairing MUST reject.
- **timeline-duration-floor**: a timeline's declared `duration` MUST be
  greater than or equal to `max(step.at + step.duration)` across all its
  steps; a declared duration that is shorter than its own last step MUST
  reject. The declared duration is a floor, never merely advisory.
- **step-order-stable-on-ties**: steps sharing the same `at` value MUST be
  applied in their originally authored order. (Swift's `sort` is not a
  stable sort, so the Apple loader must explicitly preserve original index
  as a tiebreaker to get this guarantee; the web loader gets it for free
  from `Array.prototype.sort`'s specified stability. Both MUST still produce
  the same effective order.)

### Behavior: predicates, loops, and gates

- **predicate-resolution**: every predicate reference (`enabledWhen`,
  `disabledWhen`, `activeWhen`, `shownWhen`, and similar boolean gates —
  but not `suppressedIn`, which names moods rather than a predicate; see
  blink-suppression-moods-real) MUST resolve to one of the two builtin
  predicates (`"eyesShut"`, `"curious"`) or to a `behavior.params` entry of
  boolean (`gt`) form; any other name, including a `select` param's name
  (which resolves to a number, not a boolean; see
  amplitude-ref-resolution), MUST reject.
- **gt-param-operand-pose-supplied**: the left-hand operand name of a `gt`
  param MUST be a numeric key that every pose supplies via that pose's
  `loops`; a `gt` param referencing a name even one pose omits MUST reject.
- **select-param-guard-resolves**: a `select` param's guard predicate MUST
  itself resolve via predicate-resolution.
- **amplitude-ref-resolution**: an amplitude or duration reference that
  names a `behavior.params` entry MUST resolve to a `select` (numeric)
  param when a param of that name exists, and otherwise MUST resolve to a
  per-pose numeric value (the same mechanism as gt-param-operand-pose-
  supplied).
- **loop-fields-validated**: every `behavior` loop definition's `channel`,
  `ease`, `restEase`, `amplitude`, `duration`, `enabledWhen`, and
  `disabledWhen` fields MUST each independently satisfy reference-integrity
  and predicate-resolution as applicable to that field's kind. This same
  six-field validation MUST be applied identically to a `moodEffects.*.loop`
  entry.
- **blink-suppression-moods-real**: every mood named in `behavior.blink.
  suppressedIn` MUST be a real pose.
- **gaze-fields-validated**: `behavior.gaze`'s look/tilt/lean channels and
  eases MUST satisfy reference-integrity, and `reachCurious`/`reachIdle`
  MUST each satisfy pair-fields-exactly-two.
- **idle-fidget-fields-validated**: `behavior.idleFidget`'s breath channel
  and ease, sway channel, `brow.nodes`, settle ease, the top-level
  `durationRange`, and `rearm.gapMs` MUST each satisfy reference-integrity
  and/or pair-fields-exactly-two as applicable.
- **pinpricks-fields-validated**: `behavior.pinpricks.nodes` MUST each be a
  real rig node id, and its `ease` MUST satisfy reference-integrity.
- **mood-effect-target-validated**: every `moodEffects` key MUST be a real
  pose, and its `target` MUST be a real rig node.
- **mood-effect-step-channels-numeric**: every channel named in a
  `moodEffects` step (`twitch`, `drift`, or `once`), once expanded, MUST
  resolve only to channels that hold a plain number — never `.shape` or
  `.ink` — because mood-effect values are always numeric offsets.
- **mood-effect-branch-target-restricted**: an effect's `branch` list MUST
  name only `"twitch"` or `"drift"` as branch targets; `"once"` is never a
  legal branch target.
- **mood-effect-branch-list-defined**: a branch target name MUST refer to a
  step list that is actually defined (non-nil) on that effect. An authored
  empty list (`[]`) is a defined, accepted branch target, distinct from an
  absent (nil) one, which is rejected.
- **poke-rule-moods-validated**: a `behavior.poke` rule's `from` MUST be
  either the literal `"*"` or a real pose name, and its `expression` MUST be
  a real pose name.
- **choreography-entries-validated**: every `behavior.choreography` key
  MUST be a real pose and every value MUST be a real timeline name. The
  pose key is required to exist even though the engine never actually
  applies that pose while a choreography timeline is driving its channels.
- **waking-moods-validated**: `behavior.waking`'s `from`, `to`, and `play`
  fields MUST each be a real pose name (`play` names a mood to play, not a
  timeline).
- **eyes-shut-mood-validated**: `behavior.eyesShutMood`, when present, MUST
  be a real pose.
- **ladder-three-rungs-required**: `behavior.ladder.moods` MUST supply
  exactly the three rungs `"active"`, `"bored"`, and `"asleep"`; a missing
  or extra rung MUST reject.
- **ladder-moods-are-real-poses**: each of the three ladder rungs MUST map
  to a real pose.
- **speech-fields-validated**: `behavior.speech.bubble.distance` MUST
  satisfy pair-fields-exactly-two, and `bubble.in.ease`/`bubble.out.ease`
  MUST satisfy reference-integrity.

### Variants and sayings

- **variant-ink-patch-validated**: a variant's ink patch MUST name an ink
  that already exists in `character.inks`, and MUST touch only the `kind`,
  `color`, and `width` fields.
- **variant-shape-patch-target-validated**: a variant's shape patch MUST
  name a node that exists and has a shape, and that node MUST NOT be
  morphable (MUST NOT already carry a `.shape` rest channel) — patching a
  channel-driven shape would be silently overwritten every frame, so the
  load rejects that case instead.
- **variant-shape-patch-field-validated**: every field a shape patch touches
  MUST be one the target shape's `kind` actually declares (patchable);
  patching an undeclared field MUST reject.
- **variant-shape-patch-preserves-shape**: a points-array patch MUST
  preserve the original point count, and a numeric field's patch MUST
  remain numeric — a patch is never permitted to change a field's
  fundamental type or cardinality.
- **saying-mood-validated-and-nonempty**: every `sayings` key MUST be a real
  pose, and its list of lines MUST be non-empty.
- **fallback-mood-has-sayings**: the pose named by `ladder.moods["active"]`
  (the ladder's fallback mood) MUST have a non-empty `sayings` entry, since
  it is the mood the engine falls back to when no other saying applies.

### Errors and failure semantics

- **errors-are-descriptive-and-attributable**: every rejection MUST be
  surfaced as a typed error (`ConfigError` on Apple; an `Error` whose
  message is prefixed `"avatar config: "` on the web) whose message names
  the offending file, key, or reference — never a generic or unattributed
  failure.
- **errors-abort-atomically**: on any rejection, the loader MUST NOT return
  a partial `CharacterConfig`; loading is whole-or-nothing.
- **raw-file-read-errors-unwrapped** (Apple only): `RawFiles.read
  (fromDirectory:)`'s own file-system reads (`Data(contentsOf:)`) and its
  decode of `character.json`'s `files` list MUST propagate the underlying
  Foundation/`JSONDecoder` error as-is, without `ConfigError` wrapping or
  the `"avatar config: "`-style prefix that `CharacterConfig.load(_:)`
  applies to every decode inside it. This is an observed asymmetry between
  the two Apple entry points, not a defect in either.

### Concurrency

- **character-config-isolation**: `CharacterConfig` (Apple) is a `public`
  struct with no `Sendable` conformance, unlike its component types
  (`RawFiles`, `RigNode` and the six parsed file types, which are
  `Sendable`). Under Swift 6 strict concurrency the value
  `CharacterConfig.load(_:)` returns MUST stay in the isolation domain that
  loaded it; the compiler rejects sending it across an actor boundary. A port
  that shares one loaded config between threads adds that guarantee itself.
- **points-count**: NEEDS REVIEW: Not implemented in source. Neither loader validates that a shape's `points` array has a count consistent with what its path-builder kind requires (for example, a cubic-bezier family's point count is expected to satisfy `3n + 1` by the renderer's `Build` functions, which are not part of this recipe's source set); `requireShapeFields` confirms `points` is present but not that its count is valid for the declared kind, so a geometrically-malformed but structurally-present `points` array is accepted at load with undefined downstream behavior.

## Appearance

Not applicable: the loader has no visual output of its own — it produces a
data model (`CharacterConfig`) that other, separately-recipe'd components
render.

## States

Not applicable: the loader has no interactive or lifecycle state of its own
— each call to `load`/`loadConfig` either returns a complete result or
throws; there is no partially-loaded or in-progress state exposed to
callers.

## Accessibility

Not applicable: the loader draws nothing and exposes nothing to assistive
technology; accessibility is entirely the concern of the components that
render the `CharacterConfig` it produces.

## Conformance Test Vectors

| # | Requirement | Input | Expected | Source |
|---|---|---|---|---|
| 1 | schema-version-required | A rig file with `schemaVersion: 2` while the loader expects `1` | Rejects, naming the file and both version numbers | `ConfigTests.swift` schema-version tests; `load.test.ts` schema version describe block |
| 2 | duplicate-node-id-rejected | Two rig nodes both authored with id `"torso"` | Rejects on both platforms; Swift message contains "two nodes share the id", TS message contains "duplicate node id" | `ConfigTests.swift` duplicate id test; `load.test.ts` duplicate id test |
| 3 | palette-hex-format | `character.palette` entry `"ink1": "notahex"` | Rejects, naming the palette key and value | `ConfigTests.swift` `isLoadableHex` / palette tests |
| 4 | shaped-node-requires-ink | A `path`-shaped rig node with `ink: null` | Rejects, naming the node | `ConfigTests.swift` shape/ink tests |
| 5 | bend-response-damping | `respond("antennaLeft.bend", 10)` where the bend's `inwardSign` matches the value's sign and damping is configured | Returns a damped value; `load.test.ts` asserts `toBeCloseTo(7.2, 10)` for this exact channel/value pair | `load.test.ts` bend-damping test |
| 6 | command-signature-agreement | Two poses driving the same `.shape` channel with different path command signatures (e.g. one `M L L`, one `M C C`) | Rejects, naming both conflicting poses/sources | `ConfigTests.swift` all-pairs path-kind tests |
| 7 | promotion-source-target-kind | A promote step from an `M L L` family to an `M C C C C` family (4 curves for 2 lines, a whole multiple) accepted; a promote step to `M C C C` (3 curves for 2 lines) rejected | First accepted, second rejected naming the mismatched segment counts | `ConfigTests.swift` promotion tests |
| 8 | timeline-duration-floor | A timeline with `duration: 1000` but a step at `at: 1200, duration: 0` | Rejects, since the last step ends after the declared duration | `ConfigTests.swift` timeline duration tests |
| 9 | pair-fields-exactly-two | `idleFidget.rearm.gapMs: [500]` (one element) | Rejects for having fewer than two numbers | `ConfigTests.swift` pair-field tests (rearm.gapMs) |
| 10 | mood-effect-branch-list-defined | An effect with `branch: ["twitch"]` where `twitch: []` is authored as an empty array | Accepted — an authored empty list is a defined branch target, distinct from an absent one | `ConfigTests.swift` comment/test: "still accepts an effect whose branch list is authored empty" |
| 11 | ladder-three-rungs-required | `behavior.ladder.moods` supplying only `"active"` and `"bored"` (missing `"asleep"`) | Rejects, naming the missing rung | `ConfigTests.swift` ladder tests |
| 12 | ink-late-binding-target | An ink `color: "@missingNode"` where no rig node has id `"missingNode"` | Rejects, naming the unresolved late-bound reference | `ConfigTests.swift` / `load.test.ts` ink late-binding tests |
| 13 | variant-shape-patch-target-validated | A variant shape patch targeting a node that already has a `.shape` rest channel (is morphable) | Rejects, since patching a channel-driven shape would be overwritten every frame | `ConfigTests.swift` variant patch tests |
| 14 | fallback-mood-has-sayings | `sayings` omitting an entry for the pose named at `ladder.moods["active"]` | Rejects, naming the missing fallback mood | `ConfigTests.swift` sayings tests |
| 15 | load-does-not-mutate-caller-input | Calling `loadConfig` twice with the identical shared `RawFiles` object reference | Both calls succeed independently and the caller's original object is unchanged after either call | `load.test.ts` "loads olylo" fixture tests |

## Edge Cases

- **Empty/absent collections**: an empty `rig.groups` member list is
  rejected (empty-group-rejected); an authored-empty `moodEffects` branch
  list (`[]`) is accepted and distinct from an absent one
  (mood-effect-branch-list-defined); an empty `sayings` list for an
  otherwise-valid mood is rejected (saying-mood-validated-and-nonempty).
- **Boundary values around exact-pair fields**: any pair field
  (`reachCurious`, `rearm.gapMs`, `speech.bubble.distance`, and similar)
  accepts exactly two numbers; one or three numbers are both rejected the
  same way, with no special-casing for "close to two" (pair-fields-exactly-
  two).
- **Concurrent / repeated calls**: the loader is a pure, synchronous
  function with no shared mutable state of its own, so independent calls
  never interfere with each other. The one platform-specific hazard is a
  caller handing the same parsed `RawFiles` object to more than one web
  call; `loadConfig` guards this by cloning its input before mutating
  anything in place (load-does-not-mutate-caller-input). The Apple loader
  has no equivalent hazard since it decodes fresh `Codable` values from
  `Data` per call.
- **Error states**: every validation failure raises a typed, attributable
  error and aborts without returning a partial result (errors-abort-
  atomically). The one place this attribution is weaker is Apple's
  `RawFiles.read(fromDirectory:)`, whose own file-read and `files`-list
  decode propagate an un-wrapped Foundation/`JSONDecoder` error rather than
  a `ConfigError` (raw-file-read-errors-unwrapped).
- **Offline/disconnected**: not applicable — neither `Loader.swift` nor
  `load.ts` performs a network call of any kind; all input is either
  already-parsed in-memory data (web) or a local directory read (Apple).

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `RawFiles` | struct (Apple) / object (web, `unknown` fields) | — | The six unparsed sources the caller supplies: `character`, `rig`, `poses`, `timelines`, `behavior`, `sayings`. |
| directory (Apple only) | `URL` | — | Passed to `RawFiles.read(fromDirectory:)`; the directory MUST contain `character.json` plus the five files it names in its `files` object. |
| `character.json`'s `files` field | object `{rig, poses, timelines, behavior, sayings}` | — | Authored filenames for the other five sources; the loader never hardcodes sibling filenames. |
| `schemaVersion` (each of the six files) | integer | — | MUST equal the loader's built-in `Schema.version` / `SCHEMA_VERSION` constant (currently `1`); not caller-configurable. |

## Deep Linking

Not applicable: the loader has no navigable surface and participates in no
URL or deep-link scheme.

## Localization

Not applicable: the loader reads structured JSON keys and numeric/geometric
values; it renders no user-facing strings of its own (`sayings` text passes
through unmodified as opaque author-supplied strings).

## Accessibility Options

Not applicable: see the Accessibility section above.

## Feature Flags

Not applicable: neither `Loader.swift` nor `load.ts` reads any flag,
environment variable, or build configuration; loader behavior is fixed by
the source code and by the `schemaVersion` gate alone.

## Analytics

Not applicable: neither source file emits any analytics, telemetry, or
usage event.

## Privacy

Not applicable: the loader touches only local, already-authored
character-configuration JSON; it collects no user data, stores nothing
beyond its return value, and makes no network calls.

## Logging

Not applicable: neither `Loader.swift` nor `load.ts` contains a `print`,
`log`, or `console` call; every diagnostic is carried in the thrown error's
message, never as a separate log line.

## Platform Notes

- **SwiftUI**: this is the Apple source platform. The engine is pure
  Foundation model code (`Codable` structs/enums decoded with
  `JSONDecoder`) with no `import SwiftUI` anywhere in `Loader.swift` or
  `Types.swift`; a SwiftUI host consumes the returned `CharacterConfig` as
  plain data, never observing it as `@Published`/`@Observable` state, since
  the loader itself never mutates it after return.
- **AppKit/UIKit**: no distinction from the SwiftUI note above — the same
  `CharacterConfig.load(_:)` and `RawFiles.read(fromDirectory:)` serve both
  UI hosts identically, since neither imports any UI framework.
- **React/Web**: this is the other source platform.
  `packages/web/packages/avatar-engine/src/config/load.ts` and `types.ts`
  mirror the Apple types with TypeScript interfaces and perform the
  identical validation phases; the one Apple-only entry point is
  `RawFiles.read(fromDirectory:)`, since the web build receives its six
  sources as already-parsed JSON module imports rather than reading files
  itself.
- **Compose (Kotlin/Android, port target)**: a Kotlin port would model the
  six file shapes as `kotlinx.serialization`-annotated data classes/sealed
  classes in place of `Codable` structs/TS interfaces, decode with
  `Json.decodeFromString`, and implement `load` as an ordinary synchronous
  function — no coroutine or `Flow` is warranted, since the reference
  loader on both platforms is synchronous and side-effect-free.
- **WinUI 3 (.NET, port target)**: a .NET port would model the six file
  shapes as C# records deserialized with `System.Text.Json`, use
  `Windows.Storage.StorageFolder.GetFileAsync`/`File.ReadAllBytesAsync` in
  place of `RawFiles.read(fromDirectory:)`, and raise a dedicated exception
  type (mirroring `ConfigError`) whose message carries the same file/key
  attribution the Apple and web messages do. `ObservableCollection`/
  `INotifyPropertyChanged` do not apply: the returned config is an
  immutable value produced once per call, never observed for later
  in-place changes.

## Design Decisions

**Decision**: document Behavioral Requirements as ~60 discrete, grouped
requirements rather than compressing the full validation surface into a
handful of broad statements.
**Rationale**: the source validates on the order of sixty distinct
invariants across six file types (palette/ink resolution, rig/channel
derivation, pose/timeline/behavior cross-references, variant patches,
sayings fallback); a comparable-complexity recipe should track that
complexity rather than a template's usual UI-widget scale, per the
cross-recipe-consistency guideline's "comparable complexity is defined by
distinct behaviors, not visual simplicity."
**Approved**: pending

**Decision**: state the reference-integrity, pair-fields-exactly-two, and
value-type-matches-channel rules once each as a shared mechanism, listing
every call site, rather than repeating a near-identical bullet per field.
**Rationale**: each of these is genuinely one rule applied uniformly at many
authoring sites in the source; restating it per site would be a compound
requirement's opposite failure — needless duplication that obscures that
it is one mechanism, not many.
**Approved**: pending

**Decision**: include the Apple-only `raw-file-read-errors-unwrapped`
requirement as a documented asymmetry rather than a defect to flag.
**Rationale**: the behavior is real, source-observable, and consistently
reproducible (an un-wrapped Foundation/`JSONDecoder` error from
`RawFiles.read(fromDirectory:)`); it does not meet the bar for an
unimplemented-behavior marker because the source fully answers what
happens, it simply answers it inconsistently with
`CharacterConfig.load(_:)`'s own wrapping.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |

`separation-of-concerns` is passed: the loader lives in its own `Config` module on both platforms (`Sources/Config/` alongside the sibling `Anim`, `Math`, `Path`, `Render`, `Runtime`, and `Scene` modules on Apple; `src/config/` on web), and it is a pure function with no view, window, or per-frame rendering concern of its own. `unit-test-coverage` is passed: `ConfigTests.swift` and `load.test.ts` both exist and are cited throughout Conformance Test Vectors for schema-version, duplicate-id, palette, shape/ink, bend-damping, path-kind, promotion, timeline-duration, pair-field, branch-list, ladder, ink late-binding, variant-patch, and sayings behavior. `explicit-error-handling` is passed: every rejection surfaces as a typed, attributable error (`ConfigError` on Apple, a prefixed `Error` on web) naming the offending file, key, or reference, and a rejection MUST NOT return a partial `CharacterConfig` — nothing is silently swallowed. `fault-tolerance` is passed: the loader is built to reject malformed or contradictory authored input cleanly rather than crash — `pair-fields-exactly-two` rejects one or three numbers with no special-casing near the boundary, and `primitive-with-family-rejected`/`shape-field-requirements-enforced` reject shape data whose kind and fields disagree — rather than trusting unpredictable authored JSON at face value. `data-integrity` is partial: the loader validates roughly sixty distinct invariants across the six files (references, pair shapes, value types, path syntax), but the recipe itself flags an unresolved gap under Behavioral Requirements → Concurrency — neither loader validates that a shape's `points` array has a count consistent with its declared path-builder kind — so a geometrically-malformed but structurally-present `points` array is accepted at load with undefined downstream behavior.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial recipe, covering the Apple and web avatar-engine config loaders. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Compliance section rewritten as linked checks against the compliance catalog |
| 1.0.2 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.3 | 2026-09-25 | Mike Fullerton | Corrected promote-step-shape (promote field, not family diff), rest-value-derivation (.ink/.family/.shape conditional, no .scale rest), group-member/group-expansion (.scale flattening), predicate-resolution (suppressedIn is moods not a predicate; select is numeric), and pair-fields/idle-fidget field names (idleFidget.durationRange, per-step durationRange). Reworded a Design Decisions rationale sentence that spelled out "NEEDS REVIEW" as prose (word-wrapped across a line break), which was tripping the marker checker; verified the points-count NEEDS REVIEW marker itself already matches the required one-line bullet form and the gap it documents is real (`requireShapeFields` checks field presence only, not count validity), so left it unchanged. |
