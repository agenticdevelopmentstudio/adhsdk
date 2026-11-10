
- **Decision**: `ScriptedBackend` supports two separate construction modes
  (fixed `script` vs. `opening` + `turn`) instead of one general-purpose
  scripting API.
  **Rationale**: A one-shot demo script and an ongoing scripted conversation
  have different lifecycles — one finishes the stream, the other never does —
  and collapsing them into a single shape would force every fixed-script
  caller to also handle the turn-based case's open-endedness.
  **Approved**: pending

- **Decision**: `Beat.delay` is applied before yielding its event, not after.
  **Rationale**: A script reads top-to-bottom as a timeline ("wait, then act")
  only if the first beat's delay can also produce a pause before anything
  happens; trailing delay would make the very first beat unable to open with
  silence.
  **Approved**: pending

- **Decision**: `draftUpdated.text` is always the whole draft, never a
  fragment to append.
  **Rationale**: A fragment-based design has no way to signal "this is a
  correction, not a continuation," and a dropped or reordered fragment
  silently corrupts the transcript with no error to catch it; replacing the
  whole string every time removes that failure mode entirely.
  **Approved**: pending

- **Decision**: `statusChanged` is a distinct, out-of-band `InboundEvent`
  and `ChatUpdate` case on apple, rather than being folded into
  `draftUpdated` or omitted from `ChatUpdate` entirely.
  **Rationale**: Folding a "thinking" spinner's text into `draftUpdated` would
  commit it into a user-visible `Message` once the draft finalizes; omitting
  a case from `ChatUpdate` would leave a `@MainActor` view with no signal to
  observe at all, since nothing else in the union fires for a status change.
  **Approved**: pending

- **Decision**: Command activity (`commandInvoked`/`commandCompleted`) is its
  own channel, never folded into `draftUpdated`.
  **Rationale**: `CommandInvocation.id` is deliberately independent of
  `commandName` so that two parallel invocations of the same command do not
  collide; a shared channel with drafts would force command activity through
  the same replace-the-whole-string semantics that drafts use, which does not
  fit a command's start/complete lifecycle.
  **Approved**: pending

- **Decision**: apple's `ShuffleBag` returns `nil` on an empty source and
  never repeats an element back-to-back, even across a refill; web's
  `ShuffleBag` throws on empty and can repeat once across the seam between
  refills.
  **Rationale**: Each platform's given source states its own choice
  independently rather than one being a bug relative to the other — apple's
  own documentation frames the stronger no-repeat guarantee as intentional
  ("closing that seam is the whole point at a [status] cadence"), and returning
  `nil` instead of throwing on empty reflects that a toolkit should not trap a
  host that configured no vocabulary, while web's looser guarantee and
  throw-on-empty behavior is its own considered choice, not left to chance.
  **Approved**: pending

- **Decision**: `CommandActivity` (apple) keeps every entry in place
  indefinitely, while the equivalent `ActiveCommand` (web) is cleared when the
  producing participant's turn ends.
  **Rationale**: Both are documented, deliberate choices in their own given
  sources, not an accidental mismatch — apple's transcript keeps a command's
  pill exactly where the user last saw it, while web's model treats command
  activity as scoped to the turn that produced it. A port MUST pick one
  lifecycle per platform on purpose (see Cross-Platform Divergences) rather
  than assume the two are interchangeable.
  **Approved**: pending

- **Decision**: `ChatViewModel` is declared `@MainActor, AnyObject, Sendable`
  rather than `@unchecked Sendable`.
  **Rationale**: `@unchecked Sendable` would silence the compiler without
  proving isolation; `@MainActor` isolation is what actually guarantees
  `ChatViewModel`'s mutable state is only ever touched from one execution
  context, matching how a view's own layout and action handlers run.
  **Approved**: pending

