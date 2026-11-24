
**Decision**: A section is one sidebar topic with a vertical topic list inside it, not a row of horizontal tabs.
**Rationale**: A tab bar stacked a second kind of navigation over panels that already had a vertical one, and ran out of width at four tabs.
**Approved**: pending

**Decision**: A section with one panel shows no list.
**Rationale**: One row chooses nothing; a column naming the only thing on screen is noise.
**Approved**: pending

**Decision**: The list shows no header title and no section titles.
**Rationale**: The section's name is already the selected sidebar row, and every panel in the list carries the section's name as its own section.
**Approved**: pending

**Decision**: The first panel is selected on a late arrival only when the view is loaded and nothing is selected.
**Rationale**: A panel arriving after the section is on screen has no appearance event to select it, and an empty detail beside a list looks broken; when the view is not loaded, appearing does the selecting.
**Approved**: pending

**Decision**: The selected row survives a replacement of the panels when its panel is still present.
**Rationale**: A panel added late must never move the reader off the row they were on; the selection test records this.
**Approved**: pending

**Decision**: Rows keep the order they are handed over in; the coordinator alphabetises.
**Rationale**: The section does not impose an order of its own, so one rule sits in one place, the coordinator.
**Approved**: pending

**Decision**: The container contract lives beside this panel, and the window looks through containers instead of naming this type.
**Rationale**: Search, title, help and back and forward all need the panel the reader is looking at; one contract serves all of them.
**Approved**: pending

**Decision**: The panel adds no accessibility behavior of its own.
**Rationale**: The source relies on the shared split and list controllers; the open questions on Role/trait and Announce state changes record what a reviewer should settle.
**Approved**: pending

