
- **Data collected**: None. The engine holds only the caller-supplied
  `CharacterConfig`, a numeric seed, ephemeral animation state (current
  mood, gaze target, speech text and its expiry), and channel values derived
  from `config` — none of it identifies a person.
- **Storage**: None. Nothing in `Engine.swift`/`Environment.swift`/
  `engine.ts`/`env.ts` writes to disk, `UserDefaults`, `localStorage`, or any
  other persistence layer.
- **Transmission**: None. The engine performs no network I/O; none of the
  four given sources imports a networking type.
- **Retention**: Speech text set via `say(text)` is held only until
  `speech.until` elapses — a few seconds, per the character's configured
  bubble timing — then dropped (`Arbiter.swift`'s `say`/`evaluate`;
  `arbiter.ts`'s `say`/`evaluate`).

