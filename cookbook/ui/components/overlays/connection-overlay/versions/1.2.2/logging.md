
Not applicable: the component performs no logging. It declares no subsystem or category and makes no `console` or logger call on any path — show, hide, tick, auto-retry or manual retry. Outage diagnostics come from the `detail` prop the consumer passes in and from the consumer's own retry handler.

