
No logging. `InfoPanel` performs no I/O and emits no log statements of its own —
the flex, padding, and `aria-label` values it computes are pure render output,
not events. The panel does not wrap or filter any logging the host performs
inside the slots it renders.

