
| State | Appearance change |
|-------|------------------|
| Default (visible on page load) | Opacity 1, no transform; no animation occurs |
| Armed (below viewport, observing) | Opacity 0, `translateY(22px)`; awaiting intersection |
| Revealed (intersected viewport) | Transitions from armed to resting values over 0.7s (`cubic-bezier(0.2, 0.7, 0.3, 1)`, opacity and transform); observer disconnects |

