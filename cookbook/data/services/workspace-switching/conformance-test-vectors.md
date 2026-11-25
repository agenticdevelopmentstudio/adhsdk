
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| workspace-switching-001 | every-row-read | the backend returns `me` (individual) and `crew` (team); one enabled reader | resolves to slugs `['me', 'crew']` (`use-workspaces.test.tsx`, "loads every workspace row, teams included") |
| workspace-switching-002 | every-row-disabled-no-request | a reader mounted with `enabled: false` | no request is issued ("asks for nothing while disabled") |
| workspace-switching-003 | every-row-refetch-on-change | an enabled reader holding one row; the backend now returns two; this copy announces a change | the reader resolves to two rows ("refetches when the workspace list is announced as changed") |
| workspace-switching-004 | every-row-one-subscription-per-client, every-row-own-announcement-one-sweep | three readers on one client; this copy announces a change | the workspace-rows entry is invalidated once ("sweeps the entry once per change, however many readers are mounted") |
| workspace-switching-005 | every-row-subscribe-on-read, every-row-one-subscription-per-client | two readers on one client; another copy's change event | the workspace-rows entry is invalidated once ("sweeps once for an announcement another copy of the module sent") |
| workspace-switching-006 | every-row-subscription-refcount | of those two readers, one unmounts, then another foreign event; then the last unmounts, then another foreign event | one more invalidation after the first event; none after the second |
| workspace-switching-007 | composite-id-format, composite-id-carries-type | `{ type: 'organization', slug: 'acme' }` and `{ type: 'team', slug: 'acme' }` | `'organization:acme'` and `'team:acme'` (`workspace-rows.test.ts`) |
| workspace-switching-008 | list-label-trimmed-name | `{ name: '  Acme ', type: 'organization' }`; `{ name: 'Ada', type: 'individual' }` | `'Acme'`; `'Ada'` |
| workspace-switching-009 | list-label-blank-individual, list-label-blank-other, list-label-never-empty | names `''` and `'   '` (individual), `''` (organization), `''` (team) | `'My Workspace'`, `'My Workspace'`, `'Workspace'`, `'Workspace'` |
| workspace-switching-010 | first-per-slug-keeps-first, first-per-slug-order | rows `me`/individual, `acme`/organization, `acme`/team, `crew`/team | the first, second and fourth rows, in that order |
| workspace-switching-011 | preference-seed-browser-cache, preference-server-row-wins, preference-settled | browser cache holds `'cached'`; the row read is pending, then resolves `{ slug: 'server' }` | `slug: 'cached'`, `settled: false`; then `slug: 'server'`, `settled: true` (`use-workspace-preference.test.tsx`) |
| workspace-switching-012 | preference-disabled | browser cache holds `'cached'`; `enabled: false` | no read issued; `slug: null` |
| workspace-switching-013 | preference-seed-read-each-render | mounted disabled with cache `'previous-user'`; cache becomes `'this-user'`; re-rendered enabled with the read pending | `slug: 'this-user'` |
| workspace-switching-014 | preference-choose-survives-first-read | the first read is pending; `choose('acme')`; the read resolves `{ slug: 'me' }` | `slug` stays `'acme'` |
| workspace-switching-015 | preference-choose-order, preference-choose-shows-at-once | the row read resolves `{ slug: 'me' }`; then `choose('acme')` | `slug: 'acme'` at once; the browser cache holds `'acme'`; the server write is called with `{ slug: 'acme' }` |

