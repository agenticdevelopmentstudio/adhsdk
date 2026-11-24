
- **Data collected**: Vercel log messages (first line, 200 characters), request paths with ids replaced by `:id` in groups, methods, statuses, domains, deployment ids and one request id per group. Messages can contain whatever the application logged.
- **Storage**: Not stored by this module; the store behind `RuntimeErrorsStore` keeps the grouped snapshot. The query string and fragment are removed before grouping.
- **Transmission**: Not transmitted by this module; the report is returned to the route that serves it.
- **Retention**: Each successful read replaces the stored groups, so what persists is the 24-hour window of the last successful read, not a window ending now. While reads fail, that older snapshot stays (see `#requirements/report-no-rewindow`).

