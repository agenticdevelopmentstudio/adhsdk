
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | toggle-on-header-click | click the header | children show, then hide |
| T2 | support-uncontrolled | `defaultOpen` only, no `onOpenChange`; click the header twice | children show after the first click and hide after the second |
| T3 | support-controlled | `open={false}` and an `onOpenChange` that ignores the call; click the header | callback fires once; children stay unmounted and `aria-expanded` stays `"false"` |
| T4 | rotate-chevron | open it | chevron gains `rotate-90` |
| T5 | actions-exempt-from-toggle | click a button in `actions` | disclosure state unchanged |
| T6 | mount-children-only-when-open | collapsed | children absent from the DOM |
| T7 | toggle-on-header-click | Enter/Space on the focused header | children show, then hide |
| T8 | expose-expanded-state | inspect the toggle button after opening and closing | `aria-expanded` matches the current open state |
| T9 | support-uncontrolled | `defaultOpen={true}` | children are mounted on first render and `aria-expanded` is `"true"` |
| T10 | support-controlled | `open={true}` with an `onOpenChange` that ignores the call | children are mounted and `aria-expanded` is `"true"` |
| T11 | on-open-change-uncontrolled | uncontrolled with an `onOpenChange` spy; click the header twice | spy is called with `true`, then `false`; children follow |
| T12 | link-toggle-to-body | open the disclosure | the toggle's `aria-controls` equals the body's `id` |
| T13 | rtl-chevron | render under `dir="rtl"`, collapsed | the chevron points left (it carries `rtl:rotate-180`); open, it points down (it carries `rotate-90`) |
| T14 | respect-reduced-motion | toggle the disclosure and inspect the chevron's classes (jsdom evaluates no media query) | the chevron carries `motion-reduce:transition-none`, so its transition is dropped under reduced motion |
