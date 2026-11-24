
`String.shortened(to:)` is a public extension that returns a string unchanged when it fits a character budget, and otherwise cuts it to its first `limit - 3` characters followed by one ellipsis. The default budget is 60. It is one budget in one place: a width-limited card gives a one-line message about sixty characters before it wraps, and that number had been written out at three separate call sites, so tuning any one of them would have left the others saying something a different width.

