
- **Users pane**: loading, loaded, empty, and failed; a row is paused or active.
- **Product site page**: no product selected; loading; failed to load; no base domain (address not configured); a site, with the console off, on and live, or on and not answering yet; the handle field closed, or open with the rename warning; and a refused handle or switch.
- **Custom domain section**: hidden (loading, or the switch off); failed to load; loaded with no domain, or with domain boxes each pending, pending with an error, verified, verified and primary, failed or removing; the add field shown or not; a check, primary change or remove in flight; the remove confirmation open; and a refusal under the field or a box.
- **Totals**: loading, loaded and failed.

The Support page has four states: loading, loaded (grants listed), failed (the backend's message), and not available (the grants read answered 404 because consented access is off). A step-up refusal is not a state of the page: it leaves the page through the sign-in redirect and returns to `/support`.

The Jobs pages (phase 9) take their states from `JobStatusPane` and `JobTemplatesPane`: loading, loaded, empty (no runs, or no templates), failed (the backend's message), and not available (a 404 while the `jobs_feature` switch is off).
