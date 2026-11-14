
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| resource-card-001 | render-title | `title="My App"` | Title "My App" is rendered as plain text in font-medium. |
| resource-card-002 | accept-href (test: "renders a real anchor for href — the thing ⌘-click and \"copy link\" need") | `href="/principles/simplicity"` | Root is an `a` with `href="/principles/simplicity"`, exposed as a link, not a button, with no `tabindex` and `cursor-pointer` in its class |
| resource-card-003 | accept-onclick, button-focusable (test: "renders a keyboard-operable div[role=button] for onClick") | `onClick={handler}` without href | Root is a `div` with role "button" and `tabindex="0"` |
| resource-card-004 | href-precedence, href-and-onclick-both-fire (test: "fires onClick alongside navigation when the host passes both") | `href="/x"` and `onClick={handler}`; click the link | `handler` called once; root is a link |
| resource-card-005 | use-link-component, link-keeps-card-classes (test: "routes href through the injected LinkComponent, never a hardcoded router") | `href="/x"` and an adapter that renders `<a data-router="yes" href="#/x">` | Root has `data-router="yes"`, `href="#/x"` and the class `rounded-xl` |
| resource-card-006 | fallback-link-component | `href="/app"` without LinkComponent | A native `<a href="/app">` is rendered |
| resource-card-007 | keyboard-activation (test: same as resource-card-003) | role="button"; click, then keydown Enter, then keydown Space | `onClick` called 3 times |
| resource-card-008 | keyboard-activation | role="button"; keydown Space | The event's default action is prevented (no page scroll) |
| resource-card-009 | ignore-other-keys (test: same as resource-card-003) | role="button" after 3 calls; keydown "a" | `onClick` still called 3 times |
| resource-card-010 | inert-root (test: "renders an inert div when the host passes neither href nor onClick") | `title="Ecosystem"` only | Root is a `div`, no role, no `tabindex`, class has no `cursor-pointer` |
| resource-card-011 | optional-identifier | `identifier="com.example.app"` | Identifier is rendered in monospace, text-xs, below the title |
| resource-card-012 | optional-identifier | No identifier prop, or `identifier=""` | No identifier element is rendered |
| resource-card-013 | optional-description (test: "nests the block content inside the anchor — <a> takes flow content") | `href="/x"`, `description="No interleaving of concerns."` | A `p` inside the anchor holds that text |
| resource-card-014 | optional-description | No description prop, or `description=""` | No description element is rendered |
| resource-card-015 | optional-meta (test: same as resource-card-013) | `meta={<span>principles</span>}` with `href` | The anchor's text contains "principles"; the identifier text also appears inside the anchor |
| resource-card-016 | optional-meta | No meta prop | No meta row is rendered |
| resource-card-017 | interactive-styling | `href` or `onClick` provided | Class contains `cursor-pointer`, a hover border and background change, and a focus-visible border |
| resource-card-018 | classname-support, classname-overrides-defaults (test: "lets the host override geometry through className — twMerge, not append") | `href="/x"`, `className="rounded-lg p-4"` | Class contains `rounded-lg` and `p-4` and contains neither `rounded-xl` nor `p-5` |
| resource-card-019 | left-aligned-text | Any props | Text is aligned to the start edge of the reading direction; the web source currently applies the physical `text-left` class, which is the recorded `rtl-layout-support` gap |
| resource-card-020 | meta-no-nested-interactive | `href="/app"` and `meta={<a href="/x">link</a>}` | The caller has broken the requirement; the card does not prevent it, so a conforming caller passes no link or button inside `meta` |
| resource-card-021 | optional-identifier | `identifier={0}` | Failure mode: the numeral `0` is falsy-guarded by `&&`, so React renders the text "0" instead of nothing; callers MUST NOT pass a numeric identifier (see **optional-identifier**) |
| resource-card-022 | optional-description | `description={0}` | Failure mode: renders the text "0" instead of nothing; callers MUST NOT pass a numeric description |
| resource-card-023 | optional-meta | `meta={0}` | Failure mode: renders the text "0" in the meta row instead of nothing; callers MUST NOT pass a numeric meta |
| resource-card-024 | touch-target-size | `title="My App"` only, with `href="/x"`, rendered at default padding | The measured card height is at least 44 CSS px and its width fills the container |
| resource-card-025 | focus-indicator-contrast | Interactive card receives keyboard focus | Border changes to `apt-gold` at 60% opacity and the default outline is removed; the 3:1 contrast is unverified (see **focus-border-contrast**) |

The tests beside the source are `resourceCard.test.tsx`; vectors that name a test come from its assertions and the others derive from the source.

