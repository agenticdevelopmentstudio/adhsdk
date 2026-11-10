
The avatar engine runtime is the frame-timing and interpolation core shared by
the Swift and TypeScript avatar engines. It has no visual surface of its own —
a host `Engine` composes it with a scene graph and a config loader to produce
frames, but the runtime itself only stores values, schedules callbacks against
an absolute clock, and interpolates values toward targets. It is three
independent primitives:

- **Channels** (`Channels.swift` / `channels.ts`) — a flat, string-keyed store
  of `ChannelValue`s (a `number` or a `string`). Everything the engine animates
  — a node property, an ink color, a mouth path, a shape family — is a channel,
  so neither the scene tree nor the animation code needs to know about the
  other.
- **Scheduler** (`Scheduler.swift` / `scheduler.ts`) — absolute-time event
  scheduling. It never asks "how much time passed"; it asks "what should have
  happened by now," which is what makes the same sequence of fires happen at
  60Hz, 120Hz, or after one large catch-up tick, regardless of refresh rate.
- **Tweens** (`Tweens.swift` / `tween.ts`) — per-channel interpolation driven
  by the Channels store: `TweenSpec`s describe a target value, a duration, an
  optional delay and ease, and `Tweens.tick` writes the eased value for `now`
  into the channel it targets.

The reference host (`Engine.swift`, `Sources/Engine.swift`) drives all three on
one clock, in one order, per frame: `scheduler.tick(clock)`, then
`arbiter.tick(clock)` (which adds/cancels tweens in response to scheduled
events), then `tweens.tick(clock)`, then reads the channels to render. That
ordering is load-bearing — each swap is documented in source as "its own
frame-late bug" — but it lives in `Engine`, not in these three files; this
recipe specifies the contract each of the three offers to whatever drives it,
not the driving order itself.

