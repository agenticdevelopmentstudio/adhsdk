
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `AnimContext` (`config`, `channels`, `tweens`, `prng`, deps) | struct/object, constructor argument | — (required) | The loaded `CharacterConfig`, the runtime `Channels`/`Tweens` instances, and the shared seeded `Prng` every Arbiter/Reflexes instance is built against. |
| `ReflexDeps` (`mood`, `reducedMotion`, `mutter`, and related closures) | injected callbacks | — (required) | Host-supplied functions Reflexes reads every poll: the currently resolved mood, whether reduced motion is active, and the mutter callback invoked on eligible moods. |
| `config.behavior.ladder` (`LadderDef`) | config, loaded JSON | — (authored per character) | The idle rung thresholds/moods, `pollMs` poll cadence, and `alertAfterTypingMs` typing-pin window `Arbiter`/`Reflexes` share one poll cadence from. |
| `config.behavior.poke` (`[PokeRule]`) | config, loaded JSON | — (authored per character) | Ordered `from`/`"*"`-matched poke reactions and their hold windows. |
| `config.behavior.waking` (`WakingDef`) | config, loaded JSON | — (authored per character) | The waking transition's starting mood, destination mood, and window duration. |
| `config.behavior.choreography` | config, loaded JSON, `[String: String]` | `{}` (no mood choreographed) | Maps a mood name to the timeline name the arbiter plays instead of that mood's static pose. |
| `config.poses.poses` | config, loaded JSON | — (required, non-empty) | The pose table every `setMood`/`applyPose`/ladder/poke/waking mood name is validated against. |
| `config.timelines.timelines` | config, loaded JSON | — (authored per character) | The timeline table `play`/choreography names are validated against. |
| `Prng(seed:)` seed | `UInt32` / `number` | host-supplied | Determines the entire random stream (blink waits, wander targets, fidget jitter, mood-effect branch/amplitude draws) for both platforms identically given the same seed and the same sequence of scheduled events. |
| Reduce Motion (host-read, via `ReflexDeps.reducedMotion`) | `Bool`/`boolean` | host-supplied, read every poll | Gates ambient loops, the active mood effect, and fidget/breathe activation off when true (see Accessibility Options). |

