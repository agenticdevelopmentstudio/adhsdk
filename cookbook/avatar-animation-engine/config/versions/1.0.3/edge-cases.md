
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

