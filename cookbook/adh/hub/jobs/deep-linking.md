
The panes own no URL. The hub serves them under the workspace segment `jobs`, whose catch-all line
carries the `jobs/templates` and `jobs/environments` sub-paths, and the product admin console (under
`/admin` on each product's own site) serves `JobStatusPane` at `/admin/jobs` and `JobTemplatesPane` at
`/admin/jobs/templates`. Both are specified by [adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae). A
host makes the open row deep-linkable through the `onOpen*` callbacks.

