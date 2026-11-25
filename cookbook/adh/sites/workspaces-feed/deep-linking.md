
Each row's `href` is a deep link to that workspace's home: `/<slug>` on the
hub in route mode, and the hub's URL for `/<slug>` (built from the request
host, else the hub's production URL, through
[adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae))
in preference mode, for open-in-new-tab. Route mode reads the URL's first
path segment to mark the current row. The feed registers no route.

