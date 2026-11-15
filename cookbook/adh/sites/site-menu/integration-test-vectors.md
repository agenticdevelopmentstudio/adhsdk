
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | shared-core-both-menus, reference-group-removed | render the marketing and the workspace menu | both are the one `SiteMenu` base over their own config tree, each with a Bitbag row and a Hub row; no "Reference" row in either |
| T2 | top-section-logged-out | unauthenticated, with login and sign-up hrefs | Login + Sign up are the first two rows, above the tree; no Home/Recents |
| T3 | top-section-logged-in, in-hub-rows-authed-only | authenticated, with workspaces and a recorded recent | Home, Workspaces and Recents present, and absent when logged out; the family tree rows are the same signed in and signed out (the shipped trees carry no auth-gated destination rows) |
| T4 | inline-subitem-kind, hub-subitems-inventory | a config with a leaf row followed by an `inline` row | the inline row renders indented, directly under its parent, always visible (no flyout); the shipped trees nest the Hub's pages in a flyout instead |
| T5 | row-icon-label-description, icon-reuse-existing | render any row; resolve the `community` and `narratives` icon keys | icon precedes label; Community resolves to `Users`, Narratives to `ScrollText` |
| T6 | workspaces-flyout | open Workspaces with 3 workspaces | flyout lists all 3, labelled, each linking to its workspace home |
| T7 | recents-flyout, recents-empty-hidden | 0 recents / 3 recents | entry hidden at 0; lists 3 most-recent-first otherwise |
| T8 | recents-settle-only | drill list→detail→leaf within the settle window, stop at leaf | only the leaf is recorded |
| T9 | recents-dedupe-cap | record 11 distinct, then re-record #1 | 10 kept, oldest evicted; #1 moves to front |
| T10 | recents-deep-link | click a recent | navigates to that view's deep URL |
| T11 | recents-persist-local | record, reload | recents survive reload (same device) |
| T12 | keyboard-accessible | open, arrow, flyout, Escape | selection moves, flyout opens/closes, focus returns to trigger |

