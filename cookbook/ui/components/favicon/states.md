
| State | Appearance change |
|-------|------------------|
| Default | An image of the first candidate, `/favicon.ico`, loading or loaded. |
| Trying next candidate | The previous image is replaced by a new image for the next path in the list; no intermediate state is drawn. |
| Fallback | The caller's `fallback` replaces the image, or nothing is drawn when there is none. |
| Pressed | Not applicable: the component is not interactive. |
| Disabled | Not applicable: the component is not interactive. |
| Focused | Not applicable: the component is not focusable. |
| Loading | The browser's own image loading; the component draws no placeholder while a candidate is in flight. |

