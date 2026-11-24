
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cta-001 | renders-children | Children: `<button>Sign Up</button>` | Output contains `<button>Sign Up</button>` |
| cta-002 | renders-children | Children: multiple buttons, links | All children rendered in order |
| cta-003 | renders-children | Children: null or undefined | Renders empty container |
| cta-004 | container-class | Any children | Rendered div has `className="lp-cta"` |
| cta-005 | children-untouched | Button child with `onClick` handler | Child onClick handler fires on click |
| cta-006 | renders-children | No children provided | Renders `<div className="lp-cta"></div>` with no visible width or height, since `.lp-cta` has no padding or margin and `gap` produces no space with zero or one child |
| cta-007 | children-untouched | Button child with `aria-label`, `data-testid`, and `className` props | All three props reach the rendered child unchanged: `aria-label` and `data-testid` are present, and the child's own `className` is retained |

