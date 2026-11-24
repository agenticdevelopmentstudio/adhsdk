
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Channels(initial:)` constructor argument | `[String: ChannelValue]` / `Record<string, ChannelValue>` | `[:]` / `{}` | Seed values a caller supplies at construction; every subsequent value comes from `set`. |
| `Tweens(channels:respond:)` / `createTweens(channels, respond)` `respond` | `(String, ChannelValue) -> ChannelValue` | identity (`{ _, v in v }` / `(_c, v) => v`) | Maps a tween's endpoint (`to`, and an explicit `from`) into whatever space the caller renders in, once, at `add` time. |
| `TweenSpec.duration` | number (seconds) | — (required, no default) | Requested animation length; overridden to `0` for a snapping channel. |
| `TweenSpec.delay` | number (seconds) | `0` | Time after the `add`-time `now` before the tween's start. |
| `TweenSpec.ease` | string (one of 24 fixed names) | `"power3.out"` | Selects the easing curve; an unrecognized name fails closed (see **tween-ease-resolution-fails-closed**). |
| `TweenSpec.from` | `ChannelValue?` | unset (resolved from the channel) | Overrides the tween's starting value. |
| `Scheduler.every` `first` | number (seconds), optional | `interval` | The registration's first due time. |
| Snap channel set (`SNAP_PROPS`) | fixed `Set<String>` / `ReadonlySet<string>` | `{"pivotX", "pivotY"}` | Hardcoded in `Channels.swift`/`channels.ts`; not configurable by a caller. |
| Scheduler catch-up guard | fixed integer constant | `1000` | Hardcoded in `Scheduler.swift`/`scheduler.ts`; not configurable. |
| One-shot stale clamp (`staleAfter`, Apple only) | fixed `Double` constant | `1.0` seconds | Hardcoded in `Scheduler.swift`; has no equivalent constant in `scheduler.ts`. |
| Ease vocabulary | fixed table of 24 names | — | Hardcoded in `Ease.swift`/`ease.ts`; closed by design — "no synthesis at runtime" — so a caller cannot register a custom ease name. |

