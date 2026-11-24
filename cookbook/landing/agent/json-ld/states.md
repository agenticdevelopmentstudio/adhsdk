
Not applicable: neither export holds state or reacts to input, as the source has no hooks, handlers or props beyond `data`, `site` and `extra`.

| State | Appearance change |
|-------|------------------|
| Default | The script element holds the serialized data; nothing is visible. |
| Pressed | Not applicable; the element is not interactive. |
| Disabled | Not applicable; there is no disabled prop. |
| Focused | Not applicable; a script element cannot take focus. |
| Loading | Not applicable; the data is serialized synchronously during render. |

