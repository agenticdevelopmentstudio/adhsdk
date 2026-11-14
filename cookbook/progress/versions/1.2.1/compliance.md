
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes for both components: `progress.tsx` (UI) and
`Progress.tsx` (Controls) each take only display props (`value`/`max` or
`indeterminate`) and render markup, with no data fetching or business logic.
`unit-test-coverage` is `partial`: the Controls `Progress` is exercised
directly (`user-settings`'s component test suite renders it determinate and
indeterminate), but no test in the `ui` package renders `progress.tsx`
directly — the only test importing from `blocks/progress-modal` exercises a
different component (`ProgressModal`), not this one.

`semantic-markup` and `reduced-motion` rest on `progress.tsx` (UI): the
`role="progressbar"` + `aria-valuemin`/`aria-valuemax`/`aria-valuenow` attributes, and
the class-based (non-inline, non-`!important`) `transition`/`duration` utility that lets
the shared `accessibility.css` reduce-motion rule zero its duration. `contrast-ratio` is
`partial`: `apt-gold`/`apt-surface-2` resolve per-theme through `--color-primary`/
`--color-surface-container-high`, and while the always-on `adh.css` base resolves them
to `#c4a35a`/`#1c1c24` (a measured ~7.0:1), at least one shipped theme (Monokai,
`#f92672`/`#3a3b33`) resolves the same pairing to ~3.0:1, below the WCAG 1.4.11
non-text 3:1 minimum — so the default pairing is not guaranteed to meet it under every
shipped theme. This check does not apply to the Controls component, which has no
`indicatorClassName`-equivalent tint and fills from `--aws-accent` instead of
`apt-gold`/`apt-surface-2`.

