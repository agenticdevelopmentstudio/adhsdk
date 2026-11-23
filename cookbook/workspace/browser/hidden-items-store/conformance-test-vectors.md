
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hidden-items-store-001 | add-returns-stored-entry, site-wide-matching | Add a user-list entry with site `example.com/*`, selector `.ad`; list user items for `https://example.com/a` and for `https://other.com/` | The added entry is returned with a non-nil identifier; `example.com/a` lists it; `other.com` lists nothing |
| hidden-items-store-002 | two-separate-lists | Add an agent-list entry with site `example.com/*`, selector `#secret`; list user items and enabled user selectors for `https://example.com/` | Neither answer contains the agent entry; listing agent items for the same page returns it |
| hidden-items-store-003 | entry-fields | Add an entry with every field set (list agent, site `foo.com/hi/*`, selector `div.x`, scope all items like it, label `div "Sponsored"`, enabled false, a fixed creation time); read it back | Every field equals what was added, plus the assigned identifier |
| hidden-items-store-004 | default-site-pattern | Create an entry from the page `https://News.Example.com/story/1`; then from a page with no host (`about:blank`) | Site is `news.example.com/*`; then `*` |
| hidden-items-store-005 | site-wide-matching | A user entry with site `*` and one with site `example.com/*`; list user items for a place with no address | Only the `*` entry |
| hidden-items-store-006 | items-include-disabled, enabled-selectors-only-enabled | Two user entries on `example.com/*`, `.a` enabled and `.b` disabled; list items and enabled selectors for `https://example.com/` | Items: both. Enabled selectors: `[".a"]` |
| hidden-items-store-007 | set-enabled | Disable `.a` from vector 006, then re-enable it | After disabling, enabled selectors are `[]` and items still list `.a` with all other fields unchanged; after re-enabling, enabled selectors are `[".a"]` |
| hidden-items-store-008 | remove-entry | Remove `.a` from vector 006; list items for `https://example.com/` | Only `.b` |
| hidden-items-store-009 | site-switch-defaults-on | Read the user switch and the agent switch for `example.com/*` on a fresh store | Both on |
| hidden-items-store-010 | site-switch-off-empties-user-list | Enabled user entry `.a` on `example.com/*`; set the user switch for `example.com/*` off; ask enabled user selectors, list user items; set it on; ask again | Off: selectors `[]`, items still list `.a`. On again: selectors `[".a"]` |
| hidden-items-store-011 | agent-list-ignores-site-switch | Enabled agent entry `#s` on `example.com/*`; set the user switch and the agent switch for `example.com/*` off; ask enabled agent selectors for `https://example.com/` | `["#s"]` |
| hidden-items-store-012 | change-notification | Observe the change notification; add, disable, remove an entry and set a site switch | Exactly one notification per change, each posted after the change is readable from the store |
| hidden-items-store-013 | persists-across-reopen, site-switch-persists | Add two entries and set a site switch off; close the store; reopen the same file | The same entries, field for field, and the switch still off |
| hidden-items-store-014 | standalone-file, file-in-app-home | Read the store's default location with no test home override | `~/.agenticdeveloperkitchen/BrowserHiddenItems.db`, a file of its own, not the project database |
| hidden-items-store-015 | file-in-app-home | Read the default location with `APP_TEST_HOME` set to a scratch directory | `BrowserHiddenItems.db` under the scratch home's app directory, never the real home |
| hidden-items-store-016 | opened-at-launch | Launch the browser feature and open two browser panes | One store is opened at launch and both panes answer from it (an entry added through one is in force in the other) |
| hidden-items-store-017 | opened-at-launch | Start `openCurrent` on a valid file and read `current` at once on the main actor | The read waits and returns the opened store, never nil; `hasCurrent` is true before the open finishes |
| hidden-items-store-018 | opened-at-launch | Start `openCurrent` on a path that cannot be opened; read `current` | The read returns nil and `onFailure` is called with the error |
| hidden-items-store-019 | opened-at-launch | Start `openCurrent` on a valid file and await `currentStore()` at once; repeat on a path that cannot be opened | The first await returns the opened store; the second returns nil |

