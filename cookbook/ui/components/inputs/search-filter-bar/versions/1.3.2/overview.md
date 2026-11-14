
A search-and-filter bar in `@adh-sdk/ui` that sits above a list. It combines a
single icon-led search `Input` with a configurable row of filter `Select`s. Every
axis is **fully controlled** by the caller (value + `onChange`), and the option
sets for each select are supplied by the caller — so narrowing the list (which
typically refetches the rows) never empties a dropdown of its own options.

It is the single home for the "search + filters above a list" pattern. First
consumer: the hub `/research` document list (`ResearchFilters` is a thin domain
adapter that maps its `{ q, category, tag }` state onto this component).

