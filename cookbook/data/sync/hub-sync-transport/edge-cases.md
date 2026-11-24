
- A 2xx body that is not a pull response (an HTML error page from a proxy) is a `.transport` error, so the engine backs off and retries rather than treating it as a resync.
- A persistent decode failure, such as version skew between client and hub, is mapped to `.transport` with the decoding error's description on every cycle. The transport does not escalate repeated failures; the description is kept so a failure event can show it, and any retry limit belongs to the engine.
- The hub's 410 is the only path to `.resyncRequired`; the transport never infers a resync from a body.

