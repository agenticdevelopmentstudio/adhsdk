
| State | Appearance change |
|---|---|
| Trigger closed | Label = committed value (item label or free text) or `triggerPlaceholder`; chevron always shown |
| Trigger focused | `focus-visible` ring 2px `apt-gold/25`, border color unchanged |
| Trigger disabled | Opacity 50%, cursor `not-allowed`, non-interactive |
| Trigger hover | Border color `apt-border-strong` (on enabled trigger only) |
| Open, no highlight | Field shows the typed text; no row highlighted |
| Open, item highlighted | `bg-apt-highlight/15` on the roving row; field previews its label; `aria-activedescendant` points to that option |
| Open, committed row visible | ✓ (Check) icon shown in `apt-gold` on the committed item's row; `aria-selected="true"` on that option |
| No exact case-insensitive label match (trimmed text non-empty), `allowCreate` | Create row shows in addition to any items the filter still matches (e.g. typing "sv" leaves "SvelteKit" in the list and still shows "+ Add \"sv\""); OK enabled |
| Filter matches nothing, no create | Empty message ("No matches") shown; OK disabled |
| Nothing acceptable | OK button disabled, Cancel always enabled |
| Listbox max height exceeded | Vertical scroll enabled on list container |

The control is synchronous over the in-memory `items` prop, so it has no intrinsic loading or error state; a caller fetching items owns those and passes the resolved array (mirroring `OptionMenu` / `RecipientInput`).

