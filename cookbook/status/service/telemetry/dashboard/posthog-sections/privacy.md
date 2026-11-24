
The module passes `POSTHOG_API_KEY` to the fetcher as a bearer token and never returns it. It reads only aggregate counts per host, path, device, browser, country and referrer, and no person data or `person_id`; this matches the privacy-first capture the events come from.

