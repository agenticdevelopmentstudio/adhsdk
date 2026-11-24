
Not applicable: the functions are pure and stateless, and the module has no pressed, disabled, focused or loading state. The one state-like input is a Shot that has no image yet.

| State | Appearance change |
|-------|------------------|
| Default | — |
| Shot with no `src` | Shot draws its placeholder frame, with the pending label as its status line |
| Shot with `src` | Shot shows the image at `/screenshots/<src>.png` |
| Pressed | Not applicable: no interactive element of its own |
| Disabled | Not applicable: no interactive element of its own |
| Focused | Not applicable: no interactive element of its own |
| Loading | Not applicable: rendering is synchronous |

