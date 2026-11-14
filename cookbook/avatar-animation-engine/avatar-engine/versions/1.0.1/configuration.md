
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` | `CharacterConfig` (Apple) / `CharacterConfig` (web) | required | A pre-validated character config produced by the loader (`CharacterConfig.load`/`loadConfig`); the engine trusts every invariant the loader is documented to enforce, including that every reachable mood has at least one saying. |
| `seed` | `UInt32` (Apple) / `number` (web) | `1` | Seeds the single `Prng` stream shared by the ambient reflexes and `randomSaying`. |
| `env` | `AvatarEnvironment` (Apple) / `Partial<Environment>` (web) | `reducedMotion: () => false` | Supplies the reduced-motion predicate. Apple takes a full `AvatarEnvironment`; web merges a partial object over `defaultEnvironment`. |
| `variant` | `String?` (Apple) / `string?` (web) | `nil`/`undefined` (the true rig) | A scene-build-time rig patch name, consumed once at construction by the `Scene` builder. |

