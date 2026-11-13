
- **relative-when-recent**: A date no more than the cutoff before now MUST render as the platform's localized relative phrase for the interval from now to the date (`3 hours ago`).
- **absolute-when-old**: A date more than the cutoff before now MUST render as an absolute day with the year, the abbreviated month and the day, in the given locale (`Nov 1, 2026`), with no time of day.
- **cutoff-boundary**: A date exactly the cutoff before now MUST still render relatively; only a strictly larger interval switches to the absolute form.
- **default-cutoff**: The cutoff MUST default to seven days (604,800 seconds).
- **no-cutoff**: A caller MUST be able to pass no cutoff, in which case every date renders relatively, however old.
- **future-is-relative**: A date after now MUST render relatively (`in 3 hours`), never in the absolute form.
- **units-style**: The units style MUST be a parameter, defaulting to abbreviated (`3h ago` in `en_US`); full gives `3 hours ago`.
- **locale-and-clock-injected**: The locale and the reference date MUST be parameters, defaulting to the current locale and the current time.

