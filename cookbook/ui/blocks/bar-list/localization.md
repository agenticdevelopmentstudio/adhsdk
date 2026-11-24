
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `bar_list.show_all` | "Show all {count}" | Expand button while collapsed; `{count}` is the total number of items |
| `bar_list.show_fewer` | "Show fewer" | Expand button while expanded |
| `bar_list.empty` | "Nothing to show." | Default `emptyLabel` (overridable by the host) |

The two button strings are hardcoded English with no override prop. The default value formatter fixes the English locale, so digit grouping and compact suffixes do not follow the user's locale unless the host passes `formatValue`. `ariaLabel`, `name`, `detail` and `emptyLabel` are host-supplied and are the host's to translate. The name's `overflow-wrap: anywhere` and the left-aligned layout use no physical-direction logic beyond `text-left` on a selectable row and `rounded-r` on the bar fill, so a right-to-left layout would still align the row to the left and round the right end of the bar.

