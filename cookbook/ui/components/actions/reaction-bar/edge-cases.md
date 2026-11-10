
- **A count reaching zero is the consumer's problem.** The bar renders what it is given; a
  tally that drops to zero should be dropped from `reactions` by the caller, not rendered as
  "👍 0".
- **An emoji not in `choices`.** A subject can carry an emoji the palette does not offer (an
  older palette, another client). It renders and toggles normally — `choices` governs what can
  be *added*, not what can be shown.
- **A repeat press.** The bar does not debounce; a caller that can have two writes in flight
  passes `busy` while one is running.
- **Signed out.** `disabled` keeps the counts (they are public) and removes the way in, rather
  than hiding the bar — a subject with reactions still shows them.
- **A long set.** The row wraps (`flex-wrap`). A palette long enough to need a grid is a
  different component (a picker), which is why `DEFAULT_REACTIONS` is deliberately short.
- **Duplicate emoji in `reactions`.** Not deduplicated here — React would warn on the repeated
  key. The fold that produces the tallies owns uniqueness.

