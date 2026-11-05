/**
 * "This field is not a credential" — a copy of `@adh-sdk/ui/lib/autofill`,
 * which is the list of record. A parity guard in the consuming application pins
 * these two copies together and catches them drifting apart.
 *
 * This site is its own workspace and does not depend on the UI kit, so the
 * attributes are repeated here rather than imported. Each vendor reads its own
 * attribute and none of them read the others; `autocomplete="off"` alone moves
 * none of them, because it speaks only to the browser's own autofill:
 *
 *   - `data-form-type="other"`      Dashlane (its SAWF "ignore" value)
 *   - `data-1p-ignore`              1Password 8
 *   - `data-lpignore`               LastPass
 *   - `data-bwignore`               Bitwarden
 *   - `data-protonpass-ignore`      Proton Pass
 *   - `autocomplete="off"`          the browser (Chrome/Safari/Firefox autofill)
 *
 * Keeping them out is not only cosmetic: several managers *mutate the DOM* to
 * plant their button (Dashlane adds `data-dashlane-rid`), and a mutation that
 * lands between SSR and hydration is a React hydration mismatch.
 */
export const noAutofillProps = {
  autoComplete: 'off',
  'data-form-type': 'other',
  'data-1p-ignore': 'true',
  'data-lpignore': 'true',
  'data-bwignore': 'true',
  'data-protonpass-ignore': 'true',
} as const

/**
 * The opt-out for a wrapper that forwards arbitrary props — this site's `Input`.
 *
 * A field naming a real autofill token (`current-password`, `email`, …) is
 * *asking* for a manager, so it is handed straight back and none of the ignore
 * attributes are emitted. `autoComplete="off"` counts as "no token" — it is the
 * same request, only weaker — so those fields get the full opt-out.
 */
export function noAutofillPropsFor(
  autoComplete: string | undefined,
): Partial<typeof noAutofillProps> {
  return autoComplete && autoComplete !== 'off' ? {} : noAutofillProps
}
