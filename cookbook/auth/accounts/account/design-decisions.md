
**Decision**: Login is `presentSignIn(from:)` rather than a method that takes credentials.
**Rationale**: The doc comment says how an account signs in is its own business; a hosted web login, a passkey or a social provider can all fit one verb.
**Approved**: pending

**Decision**: `AccountPresentationAnchor` is a weak, type-erased wrapper over `AnyObject`.
**Rationale**: The doc comment says this keeps the Foundation-only tier from importing AppKit or UIKit; weak storage keeps the anchor from retaining a window or controller.
**Approved**: pending

**Decision**: `onChange` is a single slot, and assigning it again replaces the earlier observer.
**Rationale**: The doc comment names the accounts UI that shows the account as its one observer.
**Approved**: pending

**Decision**: `restore()` is explicit, lazy and idempotent.
**Rationale**: The doc comment says an app pays for the stored-login check only when someone looks at the account.
**Approved**: pending

**Decision**: `initials` never returns an empty string.
**Rationale**: The doc comment says an avatar always has a face; the fallbacks are the email's first letter, then `"?"`.
**Approved**: pending

