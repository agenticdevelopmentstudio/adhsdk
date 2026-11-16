
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hidden-items-rendering-001 | display-none-rule-per-selector | Build the CSS for `["a.ad", "#promo"]` | Two rules: `a.ad { display: none !important; }` and `#promo { display: none !important; }` |
| hidden-items-rendering-002 | selectors-as-json | Build the apply script for `["x\"]); alert(1)//"]` | The script carries the selector as a JSON-escaped string inside a JSON array; the raw quote never closes a string in the script source |
| hidden-items-rendering-003 | empty-removes-style | Build the apply script for `[]`; run it on a page that has the style | The element with id `__adk_hidden_items` is removed |
| hidden-items-rendering-004 | single-style-element | Apply `[".a"]`, then `[".b"]` to the same page | One `__adk_hidden_items` element, holding only the `.b` rule |
| hidden-items-rendering-005 | bad-selector-isolated | Apply `["::not-a-selector((", ".ad"]` | `.ad` elements are hidden; the bad selector is skipped and no error stops the script |
| hidden-items-rendering-006 | installed-at-document-start, user-list-enabled-selectors | User entry `.ad` enabled on `example.com/*`; load `https://example.com/` | The style is installed at document start and `.ad` elements are never drawn |
| hidden-items-rendering-007 | user-list-enabled-selectors | Agent-list entry `#secret` on `example.com/*` and no user entries; load `https://example.com/` | No `__adk_hidden_items` rules; `#secret` is drawn |
| hidden-items-rendering-008 | reapplied-on-change | Page `https://example.com/` showing with `.ad` hidden; disable the entry in the store | `.ad` elements reappear without a reload; re-enabling hides them again |
| hidden-items-rendering-009 | reapplied-on-change | Same page; turn the user site switch for `example.com/*` off | Every user-list rule is gone from the live page; entries remain in the store |
| hidden-items-rendering-010 | reapplied-on-navigation | `.ad` hidden on `example.com/*`; navigate the pane to `https://other.com/` | No `example.com` rules on `other.com` |
| hidden-items-rendering-011 | late-content-hidden | With `.ad` hidden, the page inserts a new `.ad` element after load | The new element is not displayed, with no re-apply |
| hidden-items-rendering-012 | preview-rule-set, preview-independent | Set the preview selectors to `["#x"]`, then to none | `#x` hidden in `__adk_hidden_items_preview`, then that element removed; the store and `__adk_hidden_items` unchanged throughout |
| hidden-items-rendering-013 | single-owner-of-user-scripts | With `.ad` hidden, toggle another user script (the activation shield or Hide Images), which rebuilds the user-script list; load a new page | The hidden-items style is still installed at document start |
| hidden-items-rendering-014 | user-hidden-hidden-from-agent | User entry `.ad` enabled; take an agent snapshot of the page | No content from `.ad` elements in the snapshot |
| hidden-items-rendering-015 | reapplied-on-navigation | Start a navigation to `b.com` with `.b-ad` hidden there; change the store while the navigation's read runs | The navigation reads again and the new document starts with the `.b-ad` rule, not the previous site's |
| hidden-items-rendering-016 | reapplied-on-navigation | `preparedHiddenItemSelectors` with three superseded reads, then a final unchecked read that fails | The final read is called with generation checking off, and the answer is `[]`, not nil (the previous site's rules are not kept) |

