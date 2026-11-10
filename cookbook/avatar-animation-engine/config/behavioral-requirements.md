
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

