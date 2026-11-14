
### Channels

- **channel-value-shape**: A channel value MUST be either a number
  (`ChannelValue.number` / a JS `number`) or a string (`ChannelValue.text` / a
  JS `string`); no other shape is a valid channel value.
- **channel-value-json-round-trip**: On the Apple platform, encoding a
  `ChannelValue` to JSON MUST produce a bare JSON number for `.number` and a
  bare JSON string for `.text`, and decoding MUST accept a JSON number or a
  JSON string and MUST fail with an error ("a channel value must be a number
  or a string") for any other JSON type. The TypeScript `ChannelValue` type
  has no equivalent runtime decode step in these runtime files — a `number |
  string` union is enforced only at compile time, so this requirement is
  Apple-only as written in source.
- **channels-get-missing-returns-nothing**: `Channels.get(name)` MUST return
  `nil` (`undefined` in TypeScript) when no value has ever been set for
  `name`, and MUST otherwise return the value most recently set for it.
- **channels-set-overwrites**: `Channels.set(name, value)` MUST create the
  entry if `name` is unset and MUST overwrite the existing value if it is set;
  there is no append or merge behavior.
- **channels-names-sorted**: `Channels.names()` MUST return every channel name
  sorted ascending (lexicographic string order), never in the underlying
  dictionary's/Map's own iteration order — a `Dictionary`'s order is seeded
  per process, so an unsorted read would produce a different display list on
  every launch.
- **snap-channel-classification**: `snaps(channel)` MUST return `true` if and
  only if `channel` contains at least one `"."` and the substring after the
  LAST `"."` is exactly `"pivotX"` or `"pivotY"`; it MUST return `false` for
  every other channel name, including a bare `"pivotX"`/`"pivotY"` with no
  `"."` at all. A pivot is where a transform's motion originates, not a
  quantity that itself moves — tweening it (rather than snapping it) would
  compose a rotation about an origin nobody authored for the length of the
  tween.

### Scheduler

- **scheduler-registers-repeating**: `Scheduler.every(interval, first:,
  run:)` MUST register a callback whose first due time is `first` if given,
  else `interval` (never `0`/"now") — a repeater's initial delay defaults to
  one full interval, not an immediate fire.
- **scheduler-one-shot-classification**: A registration's due time recurs
  (fires and reschedules) only while its stored interval is greater than `0`.
  `Scheduler.once(at:run:)` MUST register with interval `0`; a caller that
  instead calls `every(0, first: at, run:)` MUST observe identical behavior —
  a single fire, then removal — because `tick` itself branches on `interval
  <= 0`, not on which factory method created the entry.
- **scheduler-fires-when-due**: `Scheduler.tick(now)` MUST run every
  registration whose next due time is `<= now`.
- **scheduler-catch-up-fires-every-missed-interval**: For a repeating
  registration, if more than one interval has elapsed since the last `tick`,
  `Scheduler.tick(now)` MUST fire the callback once for every interval that
  became due, each time advancing the due time by exactly `interval` (never
  by `now - due time`), so the same absolute number of fires occurs whether
  they are delivered as one call every interval or as a single catch-up after
  a long gap.
- **scheduler-catch-up-guard**: Within one `tick(now)` call, a repeating
  registration's catch-up loop MUST NOT fire more than 1000 times; on
  exceeding that bound the Scheduler MUST stop firing for that registration
  in this tick and MUST set its next due time to `now + interval`, so an
  absurd interval or a clock that jumped hours cannot hang the calling frame.
- **scheduler-one-shot-fires-once**: `Scheduler.once(at:run:)`'s callback MUST
  run exactly once and the registration MUST be removed immediately upon
  firing; a subsequent `tick` at any later `now` MUST NOT run it again.
- **scheduler-one-shot-stale-clamp** (Apple only): When a one-shot's due time
  is more than `1.0` second (`staleAfter`) in the past at the moment `tick`
  observes it, the Swift `Scheduler` MUST invoke the callback with `max(due
  time, now - 1.0)` rather than the true (arbitrarily old) due time. This
  bounds how far a chain of self-re-arming one-shots (a reflex that re-arms
  itself each time it fires) can replay its backlog after the frame loop was
  stopped for real reasons (display sleep, backgrounding): each link re-arms
  relative to the time it was handed, so an unclamped chain would replay one
  link per frame for as many links as were missed, each walking its target
  channel by one step.
- **scheduler-cancel-removes-and-tolerates-unknown-ids**:
  `Scheduler.cancel(id)` MUST remove the registration for `id` if present,
  and MUST silently do nothing (never throw or trap) if `id` is unknown,
  already fired (a spent one-shot), or already cancelled.
- **scheduler-tick-order-and-snapshot**: `Scheduler.tick(now)` MUST visit
  registrations in the order their ids were assigned (ids are issued
  monotonically starting at `1`), and MUST decide which registrations are due
  from a snapshot taken before any callback in this `tick` call runs — a
  callback that itself registers, cancels, or is itself cancelled during the
  same `tick` MUST NOT change which already-decided registrations this call
  visits, and a registration removed by another callback's side effect during
  the tick MUST be silently skipped rather than erroring when this call
  reaches it.
- **scheduler-mid-run-cancellation**: If a repeating registration's own
  callback cancels its id while that same registration's catch-up loop is
  still running (i.e., the callback removes itself), `Scheduler.tick` MUST
  stop that registration's catch-up loop immediately rather than continuing
  to invoke a callback for a registration that no longer exists.

### Tweens

- **tween-recognized-value-kinds**: A `TweenSpec.to` (and, if present,
  `.from`) value MUST be one of: a number; a hex color string matching
  `#rrggbb` or the 3-digit short form `#rgb`, using only ASCII hex digits (`0`
  through `9`, `a`-`f`, `A`-`F` — Unicode "fullwidth" digit and letter
  look-alikes MUST NOT be accepted as hex digits); an SVG-subset path string
  whose first character is `M` or `m`; or any other string, which is treated
  as an opaque, non-interpolatable value.
- **tween-numeric-interpolation**: When both `from` and `to` resolve to
  numbers, `Tweens` MUST linearly interpolate `from + (to - from) * easedT`
  at each sampled progress.
- **tween-color-interpolation**: When both `from` and `to` are recognized hex
  colors, `Tweens` MUST interpolate perceptually — converting sRGB to OKLab,
  lerping there, and converting back — rather than a componentwise sRGB
  lerp, because a componentwise lerp between two saturated colors visibly
  dips through grey at the midpoint while the OKLab path does not.
- **tween-color-fallback-on-unmixable-pair**: If the perceptual color mix
  operation fails for a pair that passed the hex-shape check (e.g., a
  malformed value that slips past the ASCII-hex guard), `Tweens` MUST hold
  `from` until progress reaches `1` and then snap directly to `to`, the same
  answer given for any unrecognized/uninterpolatable pair — it MUST NOT
  propagate the failure out of the tween loop.
- **tween-path-morph-same-kind**: When both `from` and `to` are recognized
  path strings and their parsed "kind" (the joined command-letter sequence,
  e.g. `"MLL"` or `"MCCCCZ"`) is identical, `Tweens` MUST morph anchor-by-anchor
  between them at each sampled progress.
- **tween-path-snap-cross-kind**: When both `from` and `to` are recognized
  path strings but their parsed kinds differ (no anchor-for-anchor mapping is
  possible between different command sequences), `Tweens` MUST NOT attempt a
  morph and MUST instead treat the pair as uninterpolatable: hold `from` until
  progress reaches `1`, then snap to `to`.
- **tween-unrecognized-pair-snap**: For any `from`/`to` pair that is not
  both-numbers, both-recognized-colors, or both-same-kind-paths (including a
  color paired with a path, two differently-shaped strings, or any other
  mixed pairing), `Tweens` MUST hold `from` for the full duration and MUST
  write `to` verbatim only once progress reaches `1`.
- **tween-snap-channel-forces-zero-duration**: If `TweenSpec.channel` is a
  channel `snaps()` classifies as snapping (see **snap-channel-classification**),
  `Tweens.add` MUST use an effective duration of `0` regardless of
  `TweenSpec.duration`; a caller cannot make a pivot channel animate by
  requesting a longer duration.
- **tween-zero-duration-immediate-apply**: When the effective duration is `0`
  AND `TweenSpec.delay` is `0`, `Tweens.add` MUST write the (respond-mapped)
  `to` value to the channel synchronously, at call time — before any `tick`
  call — and MUST NOT create a live tween entry for it (`Tweens.active` does
  not increase). A same-kind path family snap MUST write `to` verbatim,
  never routed through the morph/lerp path, because two same-instant
  crossings (an authored snap immediately superseded by an authored morph)
  must both resolve without one masking the other.
- **tween-delay-defers-visible-start**: When `TweenSpec.delay` is greater than
  `0`, neither a zero-duration snap's target nor an interpolated tween's first
  sample MUST become visible before `tick(now)` is called with `now >=` (the
  `now` passed to `add`, plus `delay`); until then the channel MUST retain
  whatever value it held when `add` was called.
- **tween-from-resolves-from-channel**: If `TweenSpec.from` is omitted, the
  tween's starting value MUST be resolved from the channel's stored value at
  the moment of the tween's first `write` (its first `tick` at or after its
  start time, or an earlier `settle` — see **tween-add-settles-outgoing-tween**),
  NOT at the moment `add` was called, so a delayed tween picks up whatever the
  channel holds when it actually starts. This resolution MUST happen only
  once per tween and MUST be cached — a later change to the channel's value by
  something else MUST NOT re-resolve it. An unspecified `from` resolved this
  way MUST NOT be passed through `respond`; if the channel has no stored
  value at all at that moment, the starting value MUST be the (already
  respond-mapped) `to` value.
- **tween-from-explicit-through-respond**: If `TweenSpec.from` is provided,
  `Tweens` MUST use it as the starting value in place of the channel's stored
  value, and MUST pass it through `respond` the same way `to` is mapped.
- **tween-respond-maps-endpoints-once**: `Tweens.add`/`createTweens` MUST pass
  `to` (and an explicit `from`) through the constructor's `respond` function
  (identity by default) exactly once, at `add` time, before any
  interpolation — `respond` maps the target value a tween is driving toward,
  not the interpolated value produced on each frame.
- **tween-add-cancels-existing-channel-tween**: Calling `Tweens.add` for a
  channel that already has a live tween MUST cancel that prior tween before
  registering the new one; a channel MUST NOT have two live tweens
  simultaneously.
- **tween-add-settles-outgoing-tween**: Before cancelling a channel's prior
  live tween to replace it, `Tweens.add` MUST first write to the channel the
  value that prior tween would show at the current `now` (the handoff
  instant), so the incoming tween's unspecified `from` resolves against that
  exact instant's value rather than whatever the last discrete `tick` left
  behind — this is what makes the same animation, interrupted at the same
  wall-clock instant, land on the same value regardless of frame rate.
- **tween-cancel-by-channel**: `Tweens.cancel(channel)` MUST remove any live
  tween on `channel` and MUST be a no-op if none is live there.
- **tween-tick-progress-and-completion**: `Tweens.tick(now)` MUST, for every
  live tween whose start time is `<= now`, write the eased value at progress
  `min(1, (now - start) / (end - start))` (or `1` if `end <= start`) to its
  channel, and MUST remove the tween from the live set once progress reaches
  `1`.
- **tween-tick-ignores-future-start**: `Tweens.tick(now)` MUST NOT write to,
  or resolve the `from` of, a tween whose start time is still after `now`.
- **tween-active-count**: `Tweens.active` (a property in Swift,
  `active()` in TypeScript) MUST report exactly the number of tweens
  currently live; it MUST be unaffected by an `add` call that resolved
  immediately (zero duration, zero delay).
- **tween-ease-resolution-fails-closed**: An ease name that is not one of the
  24 names in the fixed ease vocabulary (`none`, `sine.{in,out,inOut}`,
  `power{1-4}.{in,out,inOut}`, bare `power3`, and `back.out`/six explicit
  `back.out(s)` overshoot values) MUST cause resolving that tween's easing
  function to fail rather than silently substitute a default curve. On the
  Apple platform this happens at `Tweens.add` time and crashes the process
  (a forced unwrap on `Ease.resolve`, deliberate: the config loader is
  documented as validating every reachable ease name before a `TweenSpec`
  ever reaches `Tweens`, so an unknown name here is a bug, not bad data). On
  the web platform, `resolveEase` is invoked from inside `write`, which is
  called from every `tick`/`settle` that touches the tween — so an unknown
  name throws an uncaught `Error` the first time the tween is sampled, not at
  `add` time, and (per source comment) nothing in the render loop (`useAvatarEngine`'s
  `requestAnimationFrame` callback) catches it.
- **tween-default-ease-and-delay**: When `TweenSpec.ease` is omitted, `Tweens`
  MUST use `"power3.out"`; when `TweenSpec.delay` is omitted, `Tweens` MUST
  use `0`.

