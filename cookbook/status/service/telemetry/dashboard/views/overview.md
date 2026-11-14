
`views.ts` computes every join, sort, threshold and per-site cut that the Analytics and Errors pages draw. PostHog answers per host and Vercel per project; the views join `www.x.com` to `x.com`, join a project to its site, rank, rate a web vital and call a failure rate high once, on the server. The result rides the dashboard response as `views`, so the website only renders fields. Each site's page is in `siteReports`, so opening a site costs no provider query and no second request.

The module is pure: every export is a function of its arguments, with no I/O, no clock and no state. The two entry points are `analyticsViews(sections, configured)` and `errorsViews(sections, configured)`; the rest are the building blocks they and the tests call.

Absence is explicit. A provider that has not answered is `null`, which is different from an answer of zero or an empty list. A site's report leaves out anything it does not have, so the page has no "nothing for this site" states of its own.

