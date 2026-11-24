
| State | Appearance change |
|---|---|
| clean, not deletable | Nothing rendered |
| clean, deletable | Trash button, hidden until row hover / focus |
| dirty | ✓ (gold) + ✕ (muted) pair, always visible |
| delete armed | ✓ ✕ + red trash (right-most, `aria-pressed`); content dimmed + struck |
| busy | Pair soft-disabled (`aria-disabled`, clicks ignored, focus kept); ✓ replaced by a spinner; group `aria-busy` |

