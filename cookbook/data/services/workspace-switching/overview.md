
The shared data layer behind every surface that offers workspaces: the hub's
switcher and rail, and the header workspace menu a satellite site opts into.
It was moved out of the hub so every such surface reads, names, labels and
de-duplicates workspaces one way. It has three parts:

- an **every-row read state** that reads every workspace the caller can
  switch to, teams included, through the
  [adhsdk.ingredient.data.services.resource-data](cookbook:ec6e6ca5-8780-4ce2-8b3a-087adc50ed35)
  all-rows operation, cached once on the toolkit's query client
  ([adhsdk.ingredient.data.services.query-cache](cookbook:0fcd16c1-a8da-4184-b63f-97b68ed6378d))
  and refreshed when the workspace list is announced as changed;
- a **workspace-preference read state** that reads and records the caller's
  cross-site workspace choice through the one shared item-cache entry, for a
  surface that records a choice without navigating;
- **pure row helpers** (no React, no fetch, so a server module can use
  them): a workspace's selection id across types, the label a workspace is
  shown by, and the first row of each slug.

The workspace client, the cache keys, the change announcement and the
preference's storage and endpoints belong to Resource Data; this ingredient
is the read side every switcher shares on top of them. It has no visual
surface.

