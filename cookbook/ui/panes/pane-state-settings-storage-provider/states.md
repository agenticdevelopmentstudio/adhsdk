
| State | Appearance change |
|-------|------------------|
| Default (nothing stored) | `get` returns the setting's default; `contains` is false; the index entry does not exist |
| Stored | The value is a one-element JSON array under the prefixed key; the name is in the index; `contains` is true and `get` returns the stored value |
| Malformed stored text | `get` returns the default and `contains` is false; `keys(withPrefix:)` leaves the name out; the text stays in the store until `set` or `remove` replaces it |
| Pressed | Not applicable: the provider has no pointer interaction |
| Disabled | Not applicable: the provider has no enabled or disabled state in source |
| Focused | Not applicable: the provider is not a focusable control |
| Loading | Not applicable: every read and write is synchronous against the store |

