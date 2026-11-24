
- **Null and empty input** (MUST): Building the workspace link for an empty slug
  returns nothing rather than minting `//` (workspace-href-single-shape). Parsing a
  workspace slug for an empty path resolves the path to `/`, whose first segment is
  empty, and therefore returns nothing. The cross-site URL builder, for a site
  identifier not present in the roster, returns the given path unmodified rather than
  throwing. An unset or empty `NEXT_PUBLIC_LOCAL_SITES` means every site is served
  locally (local-sites-unset-means-all). A blank or unknown site passed to reserved-slug
  lookup answers false (reserved-slug-unknown-site-fail-open).
- **Boundary values** (MUST): A site with no testing deploy and no staging deploy (a
  production-only site) resolves to its bare `prodHost` from every non-local
  environment, because environment host resolution's two-level fallback ends on the
  bare host, never on nothing. A site definition with neither a workspace route nor a
  home route is a valid, fully supported shape (an operations console such as `admin`,
  `status`, or `bitbag`), so the absence of both is not itself an inconsistency to
  flag. Nor is a home route without a workspace route (`myagenticdevteam`, a
  coming-soon placeholder whose only signed-in surface is a gated `/home`): a home
  route never implies a workspace route. A site marked `nativeApp` carries a true testing-deploy flag
  yet is excluded from every return-origin list, so the flags
  alone never decide membership.
- **Concurrent access** (not applicable): This registry is synchronous and stateless.
  Every value is computed once when the registry loads and every operation is a pure
  function over that data, with no shared mutable state written at runtime, so there
  is no interleaving for two callers reading the site roster, the merged route map, or
  the merged guided-tour graph at once to race against. The one runtime input, the
  local-sites environment variable, is read per call and never written here.
- **Error states, a shared hub feature segment with no clear owner** (SHOULD): The
  reverse feature-segment lookup's tie-break (site-for-hub-segment-tiebreak) resolves
  deterministically by "does the site's own identifier equal the segment," but a
  future segment shared by two sites where neither site's identifier equals the
  segment resolves to whichever site's feature-segment entry was declared first in
  source order; a new shared segment SHOULD therefore be given an owner whose
  identifier equals it. This is a documented convention, not an oversight.
- **Error states, a route share whose generator has not run yet in this checkout**
  (MUST): A region's generated route share can legitimately be empty in a checkout
  whose own region generator has not run yet. A dedicated check's own fill-expectation
  table names `main` as the one region currently expected to be empty, and any other
  region going empty without an entry in that table is what the "has every share
  filled in" check exists to catch. An empty share contributes no fleet members, so a
  fleet whose share is empty yields an empty fleet list.
- **Error states, a local hop to a site the local server does not run** (MUST): With
  `NEXT_PUBLIC_LOCAL_SITES` naming only some sites, a hop to a site off the list
  resolves to its production host rather than to a local host nothing answers
  (local-sites-list-limits-local-hops).
- **Offline or disconnected state** (not applicable): Every part of this component
  performs only synchronous, local computation over in-memory constants and one
  environment-variable read; none of it makes a network request.

