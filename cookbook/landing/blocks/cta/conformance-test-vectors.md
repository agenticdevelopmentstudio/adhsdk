
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cta-001 | renders-children | Children: `<button>Sign Up</button>` | Output contains `<button>Sign Up</button>` |
| cta-002 | renders-children | Children: multiple buttons, links | All children rendered in order |
| cta-003 | renders-children | Children: null, undefined, or none provided | Renders `<div class="lp-cta"></div>` with no visible width or height, since `.lp-cta` has no padding or margin and `gap` produces no space with zero or one child |
| cta-004 | container-class | Any children | The rendered element's `class` attribute is exactly `lp-cta` |
| cta-005 | children-untouched | Button child with `onClick` handler | Child onClick handler fires on click |
| cta-007 | children-untouched | Button child with `aria-label`, `data-testid`, and `className` props | All three props reach the rendered child unchanged: `aria-label` and `data-testid` are present, and the child's own `className` is retained |
| cta-008 | wrapping-centered-row | Any children, with the package stylesheet applied | Computed style of the container has `display: flex`, `flex-wrap: wrap`, `justify-content: center` and a row `flex-direction` (`row`, the default), and children that exceed the container width wrap onto a second row |
