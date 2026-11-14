
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

Each hook owns exactly one concern (transport, caret geometry, gaze, mood,
sizing, scroll, focus, phrase rotation, or image-load gating) in its own
file, and the only cross-hook composition (`useBlockCursor`/`useCaretGaze`
on `useCaretTracker`, `usePersonaGaze` on `useMouseGaze`+`useCaretGaze`) is
one-directional and narrow, so separation-of-concerns passes. Twelve of the
thirteen hooks have a dedicated test file exercising their documented
behavior in real depth (fake timers, jsdom rect stubs, Strict Mode
rendering); `useAllImagesLoaded` has none at all, so unit-test-coverage is
partial rather than passed. Error handling is inconsistent rather than
absent: a legacy backend's rejection is caught and surfaced as a visible
apology message (**session-backend-error-apology**), but the same
`sendMessage`'s call into `orchestrator.submitMessage` swallows any
rejection with `.catch(() => {})` and no caller-visible signal at all — one
path handles the failure explicitly, the other silently discards it — so
explicit-error-handling is partial. Every timer this source starts is paired
with a teardown (`useConnectRitual`'s step/beat timers, `usePersonaMood`'s
rotation/beat timers, `useTransientEcho`'s hold timer, `useCaretTracker`'s
rAF), every listener installed is removed, and in-flight `say`/`sayStream`
lines are landed rather than abandoned on unmount, so fault-tolerance
passes. Every DOM-touching hook that can't find its target (no selector
match, no anchor, no wrapper) quietly reports an inert state instead of
throwing, so a host that omits an optional ref or renders before the DOM is
ready still functions — graceful-degradation passes. Accessibility,
security, networking, and persistence categories beyond what's covered
above are not listed here because these hooks render no visible surface of
their own (see Accessibility), make no network calls directly (transport is
delegated entirely to the caller-supplied backend/orchestrator), and
persist nothing (see Privacy).

