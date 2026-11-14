
- **Decision**: `itemNoun` is accepted as a plain, host-supplied string; the component does not translate or restructure the sentence around it.
  **Rationale**: Different hosts categorize different things ("notes", "documents"), so only the host knows the right noun; the component supplies just the fixed sentence template `itemNoun` is interpolated into. A localized build MUST still let the translation layer control grammatical gender and plural form for the injected noun, since `itemNoun` is always supplied already pluralized and some locales inflect the surrounding sentence by gender or number — see Localization.
  **Approved**: pending
- **Decision**: The description is built from block-level `<span>` elements rather than `<p>` elements.
  **Rationale**: `AlertModal` wraps the entire description fragment in `DialogDescription`, which Base UI renders as a `<p>`; nesting a `<p>` inside a `<p>` is invalid HTML, so the browser closes the outer element and re-parents the inner content outside it, silently breaking the dialog's accessible description. Block-level spans preserve the same line-break layout without violating that constraint.
  **Approved**: pending
- **Decision**: The component retains the most recently supplied non-null `node` for the lifetime of its component instance (via `useLastPresent`), rather than clearing to a fallback the instant the host sets `node` back to `null`.
  **Rationale**: The host clears `node` at the start of the dismissal transition; unmounting or blanking immediately would make the dialog's fade-out show an empty or generic label instead of the category the user was just looking at. Holding the last value costs nothing the user can observe, since the host — not this component — still owns whether the dialog is open.
  **Approved**: pending
- **Decision**: The component performs no automatic error recovery — it neither retries nor clears the `error` prop itself.
  **Rationale**: Error state is entirely host-controlled; only the host knows whether a retry is appropriate and when the error is no longer relevant.
  **Approved**: pending
- **Decision**: `orphanedNames` is computed by the host, not derived internally from a category tree the component receives.
  **Rationale**: The same tree can be displayed in more than one place (e.g. a sidebar); having the host compute the orphan set ensures the warning always matches the exact tree state the user is looking at, rather than a copy this component might recompute differently.
  **Approved**: pending

