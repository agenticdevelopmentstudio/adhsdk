
Not applicable as a data handler: the module stores and sends nothing. The shapes describe site-level aggregates (hosts, paths, counts, countries, browsers) and error summaries; the `SiteErrorRow` comment notes that PostHog holds no message text, only names, and `RuntimeErrorGroup.message` is the first line of a runtime message, at most 200 characters. No field holds a credential.

