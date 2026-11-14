
| State | Appearance change |
|-------|------------------|
| Unchecked (default) | Track uses the unchecked color; thumb sits at its leftmost position |
| Checked | Track uses the checked color; thumb translates 16px to the right (`translate-x-4`); the free travel inside the padding is 14px, so the thumb overshoots the 2px right padding by 2px and rests against the track's inner edge |
| Disabled | No visual change (track/thumb keep full opacity, cursor stays `pointer`); toggling is blocked by Base UI's internal guards, not by CSS |
| Focus-visible (keyboard) | 2px focus ring around the track, in the checked color at 40% opacity |
| Checked + Disabled | Checked appearance only; no dimming (see **Disabled**) |

