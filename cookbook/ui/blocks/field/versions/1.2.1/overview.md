
The shared `Field` in `@adh-sdk/ui` — the family's standard form row. It stacks
an uppercase-mono caption above whatever control it wraps (`Input`, `Select`,
`Switch`, `Textarea`, or any other primitive passed as `children`), and it renders
the whole row inside the shared `Label` so the caption is **implicitly associated**
with the control: clicking the caption focuses the input, with no `htmlFor`/`id`
wiring at the call site.

Below the control, `Field` renders one line of supporting text: a dim-mono `hint`
by default, or a red-mono `error` that takes the hint's place when present. This is
the one place inline field errors live, so forms across the platform stop
re-implementing (and re-styling) their own error text.

`Field` is presentation-only: it owns no value, no validation, and no state. The
caller supplies the control, the `hint`, and the `error`; `Field` only decides the
layout and which supporting line to show.

