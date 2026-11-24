
**Decision**: Login is `presentSignIn(from:)` rather than a method that takes credentials.
**Rationale**: A credentials method would exclude passkeys, social login and hosted web login; one verb that lets the account present its own UI fits all of them.
**Approved**: pending

**Decision**: `AccountPresentationAnchor` is a weak, type-erased wrapper over `AnyObject`.
**Rationale**: Holding the presenter as `AnyObject` keeps the Foundation-only tier from importing AppKit or UIKit; weak storage keeps the anchor from retaining a window or controller after it closes.
**Approved**: pending

**Decision**: `onChange` is a single slot, and assigning it again replaces the earlier observer.
**Rationale**: One account is shown by one accounts UI, so one observer is enough; a single slot avoids observer lists and the cleanup they need.
**Approved**: pending

**Decision**: `restore()` is explicit, lazy and idempotent.
**Rationale**: Explicit and lazy means the stored-login check (a Keychain read, a network call) is paid only when someone looks at the account; idempotent means a second view cannot start a second check.
**Approved**: pending

**Decision**: `initials` never returns an empty string.
**Rationale**: An avatar always needs a face to draw; the fallbacks are the email's first letter, then `"?"`.
**Approved**: pending

