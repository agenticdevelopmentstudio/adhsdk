
**Decision**: UTC everywhere.
**Rationale**: HogQL reads a zone-less literal, and starts a day or an hour, in the PostHog project's timezone; naming UTC keeps rows in the window's buckets for any project.
**Approved**: pending

**Decision**: Production hosts only.
**Rationale**: Stray local, staging and preview hits can reach PostHog, so the host filter removes them from every figure.
**Approved**: pending

**Decision**: Named properties.
**Rationale**: `SELECT properties` times out; naming the few properties each section needs keeps queries fast.
**Approved**: pending

**Decision**: Throw, don't return empty.
**Rationale**: A failed query fails its section so the cache keeps the last good data and shows an error, instead of drawing zero traffic.
**Approved**: pending

**Decision**: One query at a time, enforced in the fetcher.
**Rationale**: Callers do not know about each other, so the rule lives where the queries are sent.
**Approved**: pending

**Decision**: Detail fetched for all sites at once.
**Rationale**: Moving between sites then costs no query; the high cap and the `truncated` flag cover busy sites.
**Approved**: pending

**Decision**: Detail queries in sequence.
**Rationale**: The first failure ends the section without spending the other two scans.
**Approved**: pending

