
- **Decision**: `glitchtipFetcher` never retries a failed or timed-out request, and one 12 s budget covers the whole walk rather than each page.
  **Rationale**: the source comment states this directly — the issues query can occasionally stall, a retry on a stalled provider would double that cycle's wait, and under sustained degradation stacked retries wedged the scheduler; a per-page budget would let more pages mean a longer cycle.
  **Approved**: pending
- **Decision**: a GlitchTip page of exactly `PAGE_LIMIT` (100) issues with no usable `Link` header is always treated as truncated (`complete: false`), even though 100 could coincidentally be the provider's true total.
  **Rationale**: the source comment explains the asymmetry directly — a reconciling store reads "absent from this poll" as "resolved upstream", which is sound for a whole answer and catastrophic for a truncated one; erring toward "may not have seen everything" costs a delayed resolve, while erring the other way costs a false all-clear during a live incident.
  **Approved**: pending
- **Decision**: a multi-page GlitchTip walk claims `complete` only after re-reading page 1, and a failure after page 1 returns the pages already read as `ok` but not `complete`.
  **Rationale**: the walk is not a snapshot: an issue that fires mid-walk moves to the top of the list, past the pages still to come. Reporting the walk complete would resolve every issue on the unread pages, and reporting it failed would mark a reachable GlitchTip with a large backlog as an outage.
  **Approved**: pending
- **Decision**: the next-page URL is rebuilt from the configured base and the cursor, never taken from the `Link` header.
  **Rationale**: the bearer token goes on every request, so a header value must not be able to choose where it is sent.
  **Approved**: pending
- **Decision**: PostHog's four KPIs come from one HogQL query on a 20 s timeout. They were once four sequential queries.
  **Rationale**: the source comment records the history — the four queries ran on a 10 s timeout each and PostHog answers in 2 to 30 s depending on load, so the batch usually died on the first query and a poll could spend most of 40 s doing it, which stalled the Overview.
  **Approved**: pending
- **Decision**: HogQL queries run one at a time for the whole process, queued per thread and then serialized across threads by a lease in a `SharedArrayBuffer`.
  **Rationale**: the API returns HTTP 503 under concurrent load and the callers do not know about each other. The monitor's worker thread loads its own copy of the module, so a per-thread queue left two queues. A lease (an expiry time) rather than a held flag, because a terminated worker could never clear a flag.
  **Approved**: pending
