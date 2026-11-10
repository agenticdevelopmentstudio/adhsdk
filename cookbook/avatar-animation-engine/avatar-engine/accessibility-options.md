
| Option | Behavior |
|--------|----------|
| Reduce Motion | Read fresh on every poll: while `AvatarEnvironment.reducedMotion`/`Environment.reducedMotion()` reports `true`, the engine's ambient reflex loops (sway, idle fidget, and related scheduled behaviors) settle to rest and do not re-arm, holding the affected channels still; as soon as it reports `false` again, the loops re-arm and the current mood effect restarts from the top — it is a switch, not a one-way door (`Reflexes.swift`; `reflexes.ts`; `EngineTests.testReducedMotionStillsTheAmbientLoops`). |
| Increase Contrast | Not applicable: the engine emits raw ink/paint values sourced from `config`; contrast is a concern of whatever renders the `DisplayList`, not of this engine. |
| Differentiate Without Color | Not applicable: the engine has no rendering surface of its own. |

