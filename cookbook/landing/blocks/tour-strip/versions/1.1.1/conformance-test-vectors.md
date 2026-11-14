
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tour-001 | render-eyebrow | `eyebrow: "Masterbrand Overview"`, `position: { step: 1, total: 3 }` | Eyebrow text reads "Step 1 of 3 · Masterbrand Overview" |
| tour-002 | render-promise | `promise: "Welcome to the tour"` | Promise text renders inside a `<p>` with class `lp-tour__promise` |
| tour-003 | render-as-tour-screen | All required props provided | Component renders within `Screen` with `id="tour"` and class `lp-tour` |
| tour-004 | render-pillars-when-provided | `pillars: [{ title: "Design", body: "..." }, { title: "Code", body: "..." }, { title: "Ship", body: "..." }]` | Three cards render under `lp-tour__pillars` div, each with title in `h3` and body in `p` |
| tour-005 | omit-navigation-when-absent, steps-container-always-renders | `back: undefined`, `next: undefined` | No navigation links render; `lp-tour__steps` div is still present but contains no links |
| tour-006 | render-back-navigation | `back: { href: "/tour/prev", label: "Previous", note: "See how it started" }` | Link renders with class `lp-tour__step--back`, left arrow with `aria-hidden="true"`, label in `<b>`, note in `<em>` |
| tour-007 | render-next-navigation | `next: { href: "/tour/next", label: "Next", note: "Continue deeper" }` | Link renders with class `lp-tour__step--next`, right arrow with `aria-hidden="true"`, label in `<b>`, note in `<em>` |
| tour-008 | accept-note-on-navigation-steps | `back: { href: "...", label: "...", note: undefined }` | Note element does not render when `note` is undefined; link still renders with label and arrow |
| tour-009 | hide-arrow-from-assistive-tech | Navigation links present | Both arrow `<span>` elements have `aria-hidden="true"` attribute |
| tour-010 | accept-react-node-promise | `promise: <>Multiline <strong>promise</strong> with fragments</>` | Fragment and child elements render correctly within promise paragraph |
| tour-011 | render-pillars-when-provided | `pillars: []` | Pillars section (`lp-tour__pillars` div) does not render |
| tour-012 | render-pillars-when-provided | `pillars: undefined` | Pillars section does not render; no `lp-tour__pillars` div in output |
| tour-013 | omit-navigation-when-absent | `back: { href: "/tour/prev", label: "Previous" }`, `next: undefined` | Only the back link renders inside `lp-tour__steps`; no next link is present (Last step state) |

