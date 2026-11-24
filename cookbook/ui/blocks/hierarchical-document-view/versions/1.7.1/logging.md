
None. The centre-column components are pure render functions. The table of
contents' only effect is an `IntersectionObserver` subscription with no network,
no persistence, and no error path — there is nothing to log that the host's own
render tracing would not already show.

