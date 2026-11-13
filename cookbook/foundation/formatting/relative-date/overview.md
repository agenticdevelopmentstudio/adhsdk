
One shared formatter for a date shown relative to now: `3h ago` or `3 hours ago` while the date is recent, and an absolute day such as `Nov 1, 2026` once it is more than a week old. A commit history, a notes list and an account's last sync all call it, so every relative date in the toolkit reads the same way and none of them builds its own formatter. It is pure Foundation, and the clock, the units style, the locale and the cutoff are all parameters, so a test fixes every one of them.

