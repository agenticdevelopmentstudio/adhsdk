
- **Users pane**: loading, loaded, empty, and failed; a row is paused or active.
- **Admin site page**: no product selected, no site (the form sets one up), a site (the form changes or removes it), and a refused host.
- **Totals**: loading, loaded and failed.

The Support page has four states: loading, loaded (grants listed), failed (the backend's message), and not available (the grants read answered 404 because consented access is off). A step-up refusal is not a state of the page: it leaves the page through the sign-in redirect and returns to `/support`.

The Jobs pages (phase 9) take their states from `JobStatusPane` and `JobTemplatesPane`: loading, loaded, empty (no runs, or no templates), failed (the backend's message), and not available (a 404 while the `jobs_feature` switch is off).
