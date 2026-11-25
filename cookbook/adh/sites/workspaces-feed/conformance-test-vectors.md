
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| workspaces-feed-001 | preference-rows, preference-every-route, feed-default-mode | signed in; rows `me`/individual, `acme`/organization, `crew`/team; no mode | ids `['individual:me', 'organization:acme']`; `everyRoute: true` (`workspacesFeed.test.tsx`, "lists the personal workspace and the organizations, never a team, on every route") |
| workspaces-feed-002 | preference-current | the same rows; preference `null`, then `'acme'`, then `'gone'` | current `individual:me`, then `organization:acme`, then `individual:me` |
| workspaces-feed-003 | preference-pick-records | preference mode; pick `organization:acme` | the preference is recorded as `'acme'` |
| workspaces-feed-004 | preference-href-hub | preference mode, host `localhost:3000` | each row's `href` ends in `/me` or `/acme` |
| workspaces-feed-005 | feed-reads-every-row, feed-error-gated, preference-loading | preference mode, no subject; the read reports loading and error | the read is called with `{ enabled: false }`; `loading: false`; `error: false` |
| workspaces-feed-006 | preference-every-route | preference mode, no subject | `everyRoute` absent |
| workspaces-feed-007 | route-rows, route-current, route-no-every-route | route mode at `/acme/research` | hrefs `['/me', '/acme', '/crew']`; current `organization:acme`; `everyRoute` absent |
| workspaces-feed-008 | route-pick-registered, route-register-hook | route mode, nothing registered, pick `organization:acme`; then a route registers a switch, pick `team:crew` | `/acme` is pushed; then the switch is called with `'crew'` and nothing more is pushed |
| workspaces-feed-009 | route-registration-no-render | route mode; a route registers one switch, then another; pick `organization:acme` | the menu's `select` is the same function; only the second switch is called, with `'acme'` |
| workspaces-feed-010 | route-rows, route-current | route mode at `/rocket/teams`; rows `mine`/individual, `rocket`/organization, `temporal`/organization, `rocket`/team twice | ids `['individual:mine', 'organization:rocket', 'organization:temporal']`; only `organization:rocket` current |
| workspaces-feed-011 | feed-error-gated | route mode, signed in, the read failed with no data | `{ workspaces: [], loading: false, error: true }` |
| workspaces-feed-012 | route-loading, feed-error-gated | route mode, the read loading, then loaded | `loading: true, error: false`, then `loading: false, error: false` |
| workspaces-feed-013 | route-current | route mode at `/settings` | no row current |
| workspaces-feed-014 | route-rows | route mode, the rows of vector 010, at `/mine` | only those three rows; no `Admin` label, no `/admin` href |
| workspaces-feed-015 | route-loading, feed-reads-every-row | route mode, no subject, at `/acme` | the read is called with `{ enabled: false }`; `{ workspaces: [], loading: true, error: false }`; `everyRoute` absent |
| workspaces-feed-016 | route-registrar-provided | a probe reading the registrar under a preference-mode feed and under a route-mode feed | two different registrars (the default no-op, then the feed's) |

