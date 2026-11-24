
Pulse Rule is a horizontal rule drawn in the accent colour that slowly breathes: its opacity rises and falls on a repeating cycle. The source describes it as "the hairline under a hero's name". It renders a single `<hr>` element and takes one optional prop, `className`. All of its look, the gradient, the animation and the reduced-motion behavior, lives in the `.lp-pulse-rule` rule of `blocks.css`; the component only emits the element and its class.

Placement (width, margins) belongs to the caller, which supplies it through `className`; how the rule looks belongs to this component. It is a server component: the breathing is a CSS animation, so no client script is involved, and the client barrel does not re-export it.

