
- **Empty input**: an empty array MUST give all-zero figures and an empty `top`.
- **No verdicts at all**: every row without `active` MUST land in `backlog`; `active` MUST be 0 and
  `top` empty.
- **Fewer than five active rows**: `top` MUST hold all of them, loudest first, with no padding.
- **More than five active rows**: only the five with the highest `count` MUST appear; the rest are
  still counted in `active` and `events`.
- **Equal counts at the cap boundary**: the earlier rows in input order MUST win the last slots of
  `top`, because ties keep input order.
- **Falsy `count`**: contributes 0 to `events`. The sort compares `b.count - a.count` without the falsy guard used by
  `events`, so the order of `top` is only defined when every active row has a numeric `count`;
  `ErrorDTO.count` is typed `number`, which is the documented precondition.
- **Backlog volume**: backlog rows add to `events` but MUST NOT appear in `top`.
- **Concurrent access**: not applicable; the function is synchronous and shares no state, so calls
  cannot interleave.
- **Network or offline**: not applicable; the function performs no I/O. A frozen feed
  (`errorsFrozen`) is the caller's concern; the rows it passes are summarized as given.

