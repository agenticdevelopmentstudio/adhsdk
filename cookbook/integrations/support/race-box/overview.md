
`RaceBox<T>` is a small internal class in `Integrations/Support/RaceBox.swift`. Several tasks race to settle it with a `Result<T, Error>`; the first call to `finish` wins and every later call is ignored. Any number of callers can wait on `value()`, and all of them are released the moment the box settles.

The source comment gives the reason it exists: unlike a task group, a waiter is released as soon as the box settles, even if the losing tasks never finish. The integration code uses it to put a deadline around work that may ignore cancellation: `withSignInDeadline` (Google sign-in) and `MailIntegrationService.stop(timeout:)` each race the work, a timer and, for sign-in, the caller's cancellation.

The type is generic over `T: Sendable`, is marked `@unchecked Sendable`, and guards its two pieces of mutable state (the settled result and the waiter list) with one `NSLock`. It does no I/O, starts no task, and logs nothing.

