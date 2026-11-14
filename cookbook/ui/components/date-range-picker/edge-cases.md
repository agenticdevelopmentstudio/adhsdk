
- **Null and empty input**: A cleared field MUST NOT produce a call to `onChange`; the control keeps showing the empty field until the caller re-renders, because the component holds no value of its own. A caller that passes an empty string for `value.from` or `value.to` gets an empty date control for that end, and the cross bound on the other field becomes an empty attribute value.
- **Boundary values**: A day equal to the other end MUST be accepted: the cross bounds are inclusive, so `from` may equal `to`. A typed date outside `min` or `max` MUST be reported unchanged (the typed-date bypass the source comment names); the browser's own calendar is the part that honours the bounds.
- **Inverted range**: A typed `from` after `to`, or `to` before `from`, MUST be reported as typed. A caller that needs a valid range MUST check it itself, as the source comment states.
- **Concurrent access**: Not applicable: the component holds no state beyond a generated id, so there is nothing for two sessions or threads to contend over; each change event reads the `value` of the render it belongs to, so two changes before a re-render each keep the other end from that render's `value`.
- **Error states**: Not applicable: the component calls no dependency that can fail; the only failure-like input is a date outside the bounds, covered above.
- **Offline or disconnected state**: Not applicable: the component performs no network access.

