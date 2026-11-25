
The data side of the shared header's workspace menu. The menu lives in
chrome every site shares and must stay data-free, so a site that opts in
mounts this provider, which reads the signed-in user's workspaces through
[adhsdk.ingredient.data.services.workspace-switching](cookbook:14a8624d-5527-47e5-9513-1727910a5f47),
pre-resolves them into plain menu rows (id, label, href, current), and hands
them, with a loading state, an error flag and a pick handler, to the menu
through the workspaces-menu context. The
[adhsdk.recipe.adh.sites.site-menu](cookbook:f2d56415-ac36-4a27-bee5-b447c4186513)
switcher reads that context and decides where the menu shows.

It runs in one of two switch modes, the one way the hub and a satellite
differ:

- **preference** (the default; a satellite, which has no workspace routes):
  the personal workspace and the organizations, current by the stored
  cross-site preference, a pick records the preference without navigating,
  and the menu shows on every route.
- **route** (the hub): every row a bare `/<slug>` can reach, teams included,
  current by the URL, a pick goes through the switch a mounted workspace
  route registered, else follows `/<slug>`.

It was moved from the hub so the hub and every satellite that opts in run
one copy. This ingredient covers the provider, the route-switch registrar,
and the workspaces-menu context contract the provider fills. It draws
nothing itself.

