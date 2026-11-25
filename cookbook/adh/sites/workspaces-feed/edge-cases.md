
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
- **No cached preference on this device**: Before the server's preference
  arrives the feed marks no row current and reports `loading`, so the
  trigger reads "Loading…" rather than naming the personal workspace and
  then swapping to the organization the server holds (workspaces-feed-017,
  workspaces-feed-018). A cached preference that names one of the rows is
  current at once (workspaces-feed-019); one that names none waits like no
  cache (workspaces-feed-020).
- **A stalled preference read**: The account read has no timeout of its
  own. After 3000 ms with no answer the personal workspace stands in, and an
  answer that lands later still takes over (workspaces-feed-023,
  workspaces-feed-024).
- **Another user signs in mid-wait**: Another tab signing in as someone else
  changes the subject with no signed-out render between; the new subject's
  wait is timed from its own start (workspaces-feed-026), as is the wait
  after signing back in (workspaces-feed-025).
- **A failed list while the preference waits**: With nothing to show the
  failure reads as `error`, not "Loading…" (workspaces-feed-021); rows a
  failed background refetch kept stay listed under "Loading…" until a row is
  current (workspaces-feed-022).
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

