
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented: the engine drives several unconditional, indefinite animation loops (idle-fidget breathing and sway in `idleLife.ts`, the antenna sway and face bob/wiggle loops in `pose.ts`, the blink cadence in `reflexes.ts`, the gaze wander in `gaze.ts`) with no check against `prefers-reduced-motion` and no configuration field (in `AvatarEngineConfig` or `Tuning`) to disable or dampen idle motion — a grep of the whole package for `matchMedia`/`reduce`/`prefers` finds nothing. |
| Increase Contrast | Not applicable: color for a mood comes entirely from the caller's `pose.body` value and the rig's own fills; `applyPose`'s `faceEl` tween (**face-chameleon-color**) only interpolates toward whatever color the avatar supplies — the engine sets no palette of its own. |
| Differentiate Without Color | Not applicable: moods are differentiated by pose geometry (eye/mouth/brow/antenna shape via `Pose`) that the avatar author supplies through `AvatarRig`, not by the engine encoding state through color alone. |

