
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| deck-001 | render-children | `<Deck><span>Content</span></Deck>` | The span is rendered as a child of the root container |
| deck-002 | merges-style-hook | `<Deck/>` | The root container carries only its own base style hook (`lp-deck` on React/Web) |
| deck-003 | merges-style-hook | `<Deck className="custom-class"/>` | The root carries both its base style hook and the consumer's: `lp-deck custom-class` |
| deck-004 | merges-style-hook | `<Deck className={undefined}/>` | The root carries only its base style hook; the falsy value is filtered out |
| deck-005 | focusable-not-tabbable | `<Deck/>` | The root container is focusable (`tabIndex={-1}` on React/Web) but is absent from the default tab order |
| deck-006 | not-a-landmark | `<Deck/>` | The rendered root is a `<div>`, not a `<main>`, and exposes no landmark role |
| deck-007 | render-children | `<Deck>{null}</Deck>` | Deck renders successfully with no child content present (empty, null, or undefined) |
| deck-008 | merges-style-hook | `<Deck className=""/>` | The root carries only its base style hook; the empty-string value contributes nothing |
| deck-009 | merges-style-hook | `<Deck className="a b c"/>` | All three space-separated tokens are preserved alongside the base style hook |
| deck-010 | no-own-scroll | `<Deck/>` | The root container has no height or overflow style constraining its own scroll |
| deck-011 | focusable-not-tabbable | Click inside `<Deck>`, then press ArrowDown or Page Down | Focus lands on the clicked content inside Deck; the subsequent key scrolls the document, not Deck |

