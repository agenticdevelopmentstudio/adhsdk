
- **Host auth ahead of the token**: The host can count the visitor signed in
  (a cached user during bootstrap, a silent sign-on) before the token store
  has a subject. Preference mode then withholds `everyRoute`, so the menu
  needs both signals and the site keeps its own menu (workspaces-feed-006);
  route mode reports `loading`, never an empty list
  (workspaces-feed-015).
- **Signed out**: The read is disabled; what the query still holds is not
  this visitor's, so `error` reads `false` (workspaces-feed-005).
- **A stored preference outside the rows**: A previous user's slug or an
  organization since left is inert; the personal workspace stands in, as it
  does for a caller who never chose (workspaces-feed-002).
- **Duplicate slugs**: An organization and one or more teams sharing a slug
  give one row, the one a bare `/<slug>` opens; two teams under different
  owners would otherwise share an id (workspaces-feed-010).
- **Off a workspace route**: In route mode at a path whose first segment is
  no row's slug (`/settings`, `/login`) no row is current, so the trigger
  reads its generic label (workspaces-feed-013), and a pick follows
  `/<slug>`, since there is no feature to keep.
- **A new switch per navigation**: A workspace route hands up a new switch
  on each in-workspace navigation; it lands in a ref, so neither the root
  nor a menu consumer re-renders (workspaces-feed-009).
- **A pick for an unknown id**: A row id with no kept row does nothing.

