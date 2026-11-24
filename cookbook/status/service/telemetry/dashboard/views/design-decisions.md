
**Decision**: Joins, sorts, thresholds and per-site cuts are computed on the server and sent as `views`.
**Rationale**: Computing them once on the server means the website only renders fields, and each site's page is in `siteReports` so opening a site costs no second request.
**Approved**: pending

**Decision**: PostHog and Vercel counts are kept side by side and never summed.
**Rationale**: They measure different things, and a site reporting to both would count every visit twice.
**Approved**: pending

**Decision**: A provider with no answer is `null`, not zero or an empty list.
**Rationale**: A null is not the same as a zero, so the page can tell "not seen" from "seen nothing".
**Approved**: pending

**Decision**: When combining hosts, counts add and p95 takes the worse one.
**Rationale**: Percentiles do not add, so the worse one is the safe figure.
**Approved**: pending

**Decision**: Chart axes are joined on their union, with gaps instead of zeros.
**Rationale**: The sections are fetched separately, so around a day boundary the axes can differ by a bucket; a zero would be a false reading.
**Approved**: pending

**Decision**: Health alone never adds a site to a traffic table or the site list.
**Rationale**: It would add every API host. A health-only host still gets a report so a deep link to it draws.
**Approved**: pending

**Decision**: A failed provider section with no data is reported in `failures`, even on pages that hide absences.
**Rationale**: Leaving out what a site does not have must not also leave out what we failed to ask about.
**Approved**: pending

**Decision**: Zero counts as absent in a site report, except errors on a site that served requests.
**Rationale**: For such a site, zero is the finding: it says the site is healthy.
**Approved**: pending

**Decision**: Vercel values are reworded to match PostHog's panels.
**Rationale**: The two providers then read alike side by side.
**Approved**: pending

**Decision**: Site lists are alphabetical, while tables are ranked.
**Rationale**: A site then stays where the reader last found it.
**Approved**: pending

