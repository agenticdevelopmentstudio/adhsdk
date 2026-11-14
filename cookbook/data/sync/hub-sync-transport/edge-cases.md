
- A 2xx body that is not a pull response (an HTML error page from a proxy) is a `.transport` error, so the engine backs off and retries rather than treating it as a resync.
- The hub's 410 is the only path to `.resyncRequired`; the transport never infers a resync from a body.

