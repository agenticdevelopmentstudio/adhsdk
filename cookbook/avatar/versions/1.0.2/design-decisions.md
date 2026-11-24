
- **Decision**: Rank a click reaction above a waking one-shot, and both
  above the resting mood, when computing `effective`
  (**effective-mood-priority**).
  **Rationale**: A user-triggered poke is the most immediate, most
  intentional signal the engine ever receives; letting an ambient natural
  transition (like a waking yawn) or the plain resting mood override it
  would make the avatar feel unresponsive to direct interaction. The
  reverse priority — resting outranking waking, or waking outranking a
  click — is never checked anywhere in `arbitration.ts`.
  **Approved**: pending

- **Decision**: Use `overwrite: "auto"` on the body scale/rotation tween in
  `applyPose` (**body-scale-rotation**).
  **Rationale**: Documented directly in `pose.ts`: React re-runs this
  effect — including React Strict Mode's intentional double-invoke of
  effects in development — and without `overwrite: "auto"`, the resulting
  duplicate transform tweens on the same element cancel each other back to
  an identity transform, visually snapping the avatar flat. This is a
  workaround for a real defect class, not a stylistic preference.
  **Approved**: pending

- **Decision**: Give the antenna bend loop a bbox-relative `transformOrigin`
  (`origin?: string`, default `"50% 0%"`) instead of an absolute
  `svgOrigin` (**antennae-per-pose-and-continuous-sway**).
  **Rationale**: Documented directly in `pose.ts`: an absolute `svgOrigin`
  was tried and drifted unboundedly, because GSAP re-derives an SVG origin
  against the element's *current* bounding box, and the antenna path is
  continuously morphed by the sway loop itself — each morph shifts the
  bbox out from under an absolute origin. A bbox-relative origin
  re-resolves cleanly on every tween instead.
  **Approved**: pending

- **Decision**: Scope the pose-application, per-expression-effect, and
  onSpeak-echo effects' dependency arrays to `[effective]` only (each
  carries an explicit `eslint-disable-next-line react-hooks/exhaustive-deps`
  in `engine.ts`), rather than also depending on `poses`, `rig`, `tuning`,
  `choreography`, or `perExpressionEffects`.
  **Rationale**: These objects are expected to be stable across a mounted
  avatar's lifetime (an avatar's pose table and rig don't change shape at
  runtime); scoping to `[effective]` avoids re-killing and re-starting
  loop tweens on every unrelated re-render. The real cost, honestly stated:
  if a caller *does* mutate `poses`, `tuning`, `rig`, `choreography`, or
  `perExpressionEffects` in place without changing `effective`, the engine
  will not pick up the change until the next mood transition — this is the
  documented trade-off, not an oversight.
  **Approved**: pending

- **Decision**: Keep the underlying `useSpeech` reflex running while
  `mute` is true, and only null out the value `useAvatarEngine` returns
  (**speech-mute**), rather than suspending the reflex itself.
  **Rationale**: Muting is presented to the driver as "keeps its
  expressions but stays silent," not as pausing the mood-driven speech
  cadence. Keeping the reflex live means unmuting mid-cycle resumes
  naturally at whatever point the internal cadence has reached, instead of
  restarting the utterance schedule from the moment of unmuting.
  **Approved**: pending

- **Decision**: Keep morph-target point-count matching to a source comment
  and a SHOULD requirement (**morph-path-point-count-consistency**) rather
  than a validated MUST, and record both as caller preconditions instead of
  inventing enforcement the source doesn't have.
  **Rationale**: The source truly performs no such validation anywhere
  (`pose.ts`, `types.ts`); documenting an enforcement mechanism that
  doesn't exist would be source-fidelity idealization. See
  **morph-point-count-validation** and **pose-shape-validation**.
  **Approved**: pending

