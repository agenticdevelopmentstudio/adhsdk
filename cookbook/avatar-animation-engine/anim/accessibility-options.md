
`ReflexDeps.reducedMotion` (read every poll in `pollTick`) is the one real
accessibility-driven behavior in this component: when it reports true, the
current mood's effect is stopped rather than started (or re-started) on the
next mood/reduced-motion change, ambient loops that would otherwise be
"live" are stopped instead of armed, and fidget/breathe treat their own
activation predicates as false regardless of what those predicates would
otherwise evaluate to. This is the same code path a mood change drives
`pollTick` through — reduced motion is handled as an input to the same
gating logic, not a separate motion-disable mode. No other accessibility
setting (contrast, larger text, differentiate-without-color) is read
anywhere in the given sources.

