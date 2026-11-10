
| State | Appearance change |
|-------|------------------|
| Default | Bottom padding equals `calc(var(--kb-inset) + var(--safe-bottom))`; full width and bottom placement come from ViewportShell's layout, not the composer |
| Keyboard visible | Bottom padding increases as `--kb-inset` grows |
| Safe area present | Bottom padding includes the resolved `--safe-bottom` (`env(safe-area-inset-bottom)`) |

