
Not applicable: the source fires no analytics events. Nothing is emitted on render, on the deploying-to-unreachable transition, on the button click, or on auto-retry, and the component imports no telemetry client. A consumer that wants outage or retry metrics instruments its own `onRetry` handler.

