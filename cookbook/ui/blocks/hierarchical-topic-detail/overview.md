
The **Hierarchical Topic / Detail View** is the general contract for a *stack* of
nested topic/detail rails — the generalisation of the adh.com `/home` nesting
(`[workspaces] | [features] | [entities] | [topics] | [detail]`). Each topic list's
selection scopes the next, so a route reads as a hierarchy: **workspace ▸ feature ▸
entity ▸ topic ▸ leaf**. It supersedes an earlier popup-driven detail pattern
for workspace routes: the entity selector is a first-class *topic list* rail, not a
dropdown.

A **single full-width chrome** spans every rail across the top — one breadcrumb of
the complete selection trail (with a right-justified help button) — and the whole
hierarchy is **deep-linkable**: every level maps to a URL path segment, so the exact
selection is shareable and restorable (back/forward navigates the hierarchy).

The view composes the shared [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f) primitive (one per level) inside an
enclosing frame (`HierarchicalTopicDetail`) that renders the topic lists **and** the
detail pane as **flat sibling columns** in one CSS grid (not nested) — so ONE
ResizeObserver / ONE disclosure controller spans the whole row, and the detail leaf
keeps a stable slot (no remount as the list count changes). The frame owns the
breadcrumb, selection/unselection, disclosure, and drill-down; the workspace shell
makes the outermost lists (workspaces, features) **persistent** around every feature
route so the switcher never disappears.

### One stack, no sublists

There is a **single** hierarchical topic/detail stack. **Every NAVIGATION list is a
level of it**, and the deepest pane is only ever a **detail**. The in-pane
"master/detail" pattern (a list you navigate + the editor it opens, inside one pane) is
**dismantled**: each such list (Applications, Buckets, Access, Users, Team
Members, Personas, Persona Services) is a **stack level**, and its editor is the
**leaf detail**. The deep-link selection (e.g. `…/applications/<appId>`) is just that
level's `selectedId`. App code only **declares** the stack (the `levels` data) — it
never nests views or writes selection logic. Terminology: **stack / topic list (a
level) / detail (the leaf)** — not "rail" / "sublist".

#### Navigation vs. display — the line this rule actually draws

The rule bans a second **navigator**, not a second *list*. The distinction is what the
list is FOR:

- **Navigation** — you pick a row to go *somewhere*: the row becomes the selection, the
  URL grows a segment, and the pane beside it becomes that record's detail. That is the
  stack's whole job, and duplicating it inside the leaf is what "no sublists" forbids.
  Such a list MUST be a level.
- **Display** — the pane is *showing you data*, and a list is one of the ordinary shapes
  data comes in (beside a board, a table, a timeline, a calendar, a chart). A display is
  **content**, and content is exactly what a detail pane holds. A display MAY be a list;
  it MAY carry its own details pane and edit its rows in place. None of that is
  navigation: the stack doesn't move, no level is selected, the URL doesn't grow.

So "the deepest pane is a detail" is a statement about the pane's ROLE, not its shape — a
detail is content, and content may perfectly well *render* as a list. Work Items is the
worked example: its five views (List / Board / Table / Timeline / Calendar) are five
DISPLAYS of one collection, and the List one is a [adhsdk.recipe.ui.blocks.list-with-details-pane](cookbook:6acd3c5f-7bb5-4d6d-8c8d-141e1909cf73) with in-place
row editing. Nothing about it navigates. What WOULD violate the rule is a rail inside the
leaf that you drill *through* to reach a record — that record's list belongs in the stack.

### onSelect / onClear — pure-intent selection

A level's selection is two pure-navigation callbacks:

```ts
interface TopicLevel {
  id: string
  title?: string                   // left-aligned list title (divider under it); reveals when covered
  items: TopicDetailItem[]
  selectedId: string | null
  defaultSelectedId?: string       // OPT-IN landing selection: chosen when this list APPEARS empty
  leadsTo?: "list" | "detail"      // what a row here discloses (the cascade's declared leafness)
  overview?: boolean               // no-selection detail: default = the select nudge; false = the
                                   // host's own landing (the ONLY opt-out; there is no richer mode)
  itemNoun?: string                // singular noun for one row — the nudge says "Select a <noun> …"
  overviewHelp?: ReactNode         // the nudge's bespoke body: WHAT a row is and WHY to pick one
  onSelect: (id: string, options?: { replace?: boolean }) => void   // select THIS level (clears descendants);
                                   // options.replace avoids pushing history (used by an auto-applied
                                   // default — see default-select-a-level). Pure nav: push(`…/<id>`)
  onClear: () => void              // clear THIS level + everything below. Pure nav: push(parentUrl)
  emptyLabel?: string
  onNew?: () => void               // "New…" create affordance → a right-justified "+" in the list header
  newLabel?: string                // accessible name + tooltip for the "+" (e.g. "New Persona")
  newActive?: boolean              // tint the "+" gold while a create is in progress
  titleActions?: ReactNode         // extra compact controls in the TITLE row, just ahead of the "+"
  headerSlot?: ReactNode           // pinned non-scrolling strip between the title header and the rows
                                   // (hosts the shared ListHeader for entity-list levels in the stack)
}
```

Each level's `items` are `TopicDetailItem`s:

```ts
interface TopicDetailItem {
  id: string
  label: string
  labelSuffix?: ReactNode
  sublabel?: string
  inlineSublabel?: boolean
  preview?: string
  previewLines?: number
  description?: string             // no surface in THIS view renders it (the retired overview grid did) —
                                    // see describe-topics
  icon?: ReactNode
  leadsTo?: "list" | "detail"       // what a row discloses (the cascade's declared leafness)
  dividerAfter?: boolean
  spacerAfter?: boolean
  disabled?: boolean
  trailing?: ReactNode
  onDelete?: () => void | Promise<void>
  deleteLabel?: string
  deleteConfirm?: ReactNode
  blocked?: boolean
}
```

The **package** decides which fires — a click on the already-selected row pops one
level: it calls the CHILD level's `onClear()` when that child currently has a
selection, and only the row's own `onClear()` once the clicked row is itself the
deepest selection; a click on any other row calls `onSelect(id)`. **Unselection is
uniform and package-owned**: consumers write no `prev === id ? null : id` toggle — the
pop-one-level-at-a-time behavior lives in the package's `railOnSelect`, shared by every
stack. The package **never auto-selects** — landing on a level with no selection shows the list with
nothing focused (no resume, no coerced first item) — **unless that level asks it to**,
via `defaultSelectedId`: the one item to pick when the list appears with nothing chosen
(Work Items → List). It fires the level's own `onSelect`, so it is a normal selection in
every respect, and it arms once per appearance, so clearing the row inside a visit
sticks. Breadcrumb up-navigation and the drill-down **Back** also clear via `onClear`,
so all three deselect paths are one code path.

### Disclosure — pins, then width pressure (the covering click floats, never snaps)

Absent a `«`/`»` pin, every topic list is DISCLOSED: there is no default that hides ancestors
ahead of the fit rules below, and there is no root-header toggle for one. (A leaf-first default —
hiding every list above the deepest rendered one — and a STATE toggle for it were designed and
shipped for a time, then parked before this version; see the Web platform note.)

The select that pushes a new choosing list covers the list the user clicked in **with the pointer
still inside it** — the exact state the hover reveal answers, except the pointer never moved, so no
enter event will ever fire. In the covered style that select therefore roots the **branch reveal**
at the clicked list itself (`root-reveal-on-covering-select`): the clicked list stays open in
place, the new choosing list slides out beside it **floating over the detail** — exactly as if the
user had moused into their freshly covered parent — and the stack settles into the covered layout
when the pointer leaves the branch. A select that instead completes the path covers nothing
at/below the clicked list, and the blindly rooted reveal is dropped as a no-op. (v1.12.5; v1.12.4
had instead kept a choosing frontier's parent disclosed IN FLOW — suspending auto-collapse rather
than answering it — and before that the parent snapped shut under the cursor on the very click,
with nothing to reopen it.) The minimized style has no floating reveal: a hidden list is an icon
strip, still visible and clickable, so there the parent goes straight to its strip.

Disclosure therefore has two layers, and **each may only ever HIDE more, never disclose**:

1. **pins** — the user's own `«`/`»` intent on one list,
2. **width pressure** — the fit rules below, which may take the room back from a list the user pinned
   open (there is none to give) but never disclose one they pinned shut.

**⌘/Ctrl-click** on any `«`/`»` applies that button's action to **every** list at once — one click to
collapse the whole ancestry, or to open all of it (subject to the fit rules).

### Auto-collapse — how the stack yields room (the authoritative rules)

**The priority is to show the details view as large as possible while also showing
location/context** (the topic lists and the breadcrumb). As the container narrows, the lists yield
in a strict order — collapse the lists, then shrink the detail, then move the lists off-screen —
and only when the wide layout has nothing left to give does the stack become NARROW.

**Shrinking:**

1. **Collapse, bottom (furthest-left) list first.** As the window shrinks, auto-collapse the topic
   lists, starting with the leftmost / most-general one: whenever the detail would otherwise dip
   below `minDetailWidth`, the leftmost still-open list collapses — to its 32px peek (`covered`) /
   its icon strip (`minimized`) — handing the freed width back to the detail. Between collapses
   the detail absorbs the shrink down to its minimum, so it is always as large as the current mix
   of open lists allows.
2. **Then the detail's width.** Once every topic list is collapsed, the detail alone absorbs
   further shrinking — from wherever the last collapse left it, down to `minDetailWidth`.
3. **Then off-screen, one at a time.** When the detail is at its minimum width and all the topic
   lists are collapsed, move the topic lists off the screen's left edge one at a time (leftmost
   first) until they are all hidden — each step shifts the stack by exactly that list's strip
   width, **quantised to whole lists** (a continuous shift would park a list half off the edge,
   which reads as a clipped rail rather than a drilled-down one). This phase is **progressive**:
   one list per strip-width of shrink, never all at once.
4. **Then narrow mode.** When they are all hidden, the HTDV is in **narrow mode** — it now
   operates like a `UINavigationController` in UIKit for iOS: one full-width pane at a time (see
   the narrow section below). The handoff is exact — the wide layout is abandoned only once it has
   nothing left to trade (**exhaust-wide-before-narrow**), never earlier.
5. The **frontier** (a list with nothing selected yet) is never collapsed for width or slid off:
   the detail's minimum is fixed in every state, but the frontier is never counted among the
   lists that collapse or shift, and in the last-resort squeeze an unselected frontier's landing
   placeholder gives up its width before the list narrows, so the list you are choosing from
   always keeps its place. For an unselected frontier the wide layout ends only when
   the container can no longer hold that list itself.

**Growing** is the same rules run again from scratch on the wider container, so on a larger device
it reverses exactly: leaving narrow mode, the topic lists disclose in the reverse order —
off-screen lists slide back on (specific → general), the detail grows back off its minimum, then
collapsed lists re-open — **unless the user pinned one shut**, because a pin is an intent layer
above the fit rules, not a consequence of narrowness.

**On a narrow device (a phone), the HTDV starts and remains in narrow mode** — the detail is the
device's full width there, which is why `minDetailWidth` is a DESKTOP floor: fairly small, but
clearly wider than a phone (default `36rem` / 576px; a desktop detail squeezed to phone width
reads as broken, not compact).

Every decision above is **traced** on non-production builds: the layout log (`htdv-log.ts`,
flipped on by the host everywhere except production) prints the wide↔narrow mode decision, each
fit pass's collapse / off-screen outcome with the width it resolved at, every disclosure toggle,
and every narrow push/pop; `__htdvLogDump()` in the console returns the buffered trace.

### Selection lands in place — no slide-in, content crossfades

Choosing a topic changes the stack's STRUCTURE (a level appears, or the detail flips from a
minimum-less landing to real content that claims `minDetailWidth`, re-hiding the lists behind it).
That re-layout MUST be applied **instantly, in place** — the detail must never animate in from the
left edge, nor grow, as the lists close behind it. Only **width-driven** changes animate: a window
resize, a `«`/`»` cover toggle, the hover reveal, a drag.

The suppression is a settle **window**, not one render: a selection's trailing commits (levels
registering, measured widths landing) repaint geometry a frame or two later, and re-enabling the
transitions before the browser has painted the new layout animates it anyway — the exact slide-in
this rule forbids. Transitions stay off until shortly after the LAST structural change.

The pane's **content**, by contrast, swaps with a **brief crossfade**: when a selection replaces
what the detail is showing, the outgoing pane dissolves into the incoming one (~220ms); when
nothing was showing yet (the surface's first paint), the content simply appears — no fade, no
unasked-for intro. The outgoing half is an inert DOM snapshot, so the dissolve works whether the
selection updates the tree in place or remounts it (a route param nav). Geometry never
participates: the pane does not move or grow while its content fades.

### Disclosure styles — minimized vs covered

The frame supports two `disclosureStyle`s for how parent lists yield room to their children:

- **`minimized`** (the original): the lists are flat grid **columns**; as the window narrows the
  leftmost lists shrink to icon strips, then slide **off the left edge** (the two-phase drill-down
  above). Parents disappear entirely as you drill in.
- **`covered`** (the **default**): the lists are absolute-positioned and **overlap** like a stack of
  cards — each child list partially **covers** its parent, and the covered parent keeps a fixed
  **32 px peek** (a left-aligned icon strip — wide enough for each row's icon and nothing after it,
  so the covering list sits far enough left that no sliced label letters show) at its left edge, so
  the whole ancestry stays glanceable while the child + detail take the room. A list is covered automatically when there isn't room to show
  it in full, and the user can **manually** cover/uncover a list with its `«`/`»` toggle (user intent
  persists across resizes; the auto layer never uncovers a list the user covered). The **frontier** list
  (the one being chosen from, with no selection yet) is never covered. When even the peeks + the child +
  the detail minimum don't fit, covered lists drill off-screen exactly as in `minimized`.

### Whole-stack reveal for covered lists — hover opens everything, a click opens only its branch

Because a covered list shows only icons, the frame makes it **reachable without permanently uncovering
it**: the pointer ENTERING a covered/peeking list opens **every on-screen list — parents and children
alike** — chained side by side at full width from the left edge, **floating over the detail** (a lifted
card with a drop-shadow off its trailing edge). Each revealed list is the real rail: full-width rows
**and** its titled header (title, cover `«`/`»`, the New `+`).

For the HOVER, the unit is the **whole stack** (v1.13.0; it was the hovered list's branch, which left
the hovered list's own parents covered and made walking the stack leftwards a list-by-list re-rooting
exercise). One deliberate mouse-in answers the whole question: the full ancestry as it will look, which
is what the peeks were hiding in the first place. Off-screen (drilled-down) lists stay out of the
reveal — Back is their affordance.

The COVERING CLICK is different (v1.13.0): the reveal a select roots (see disclosure above) opens ONLY
the clicked list and its children — never the user's collapsed parents. A click on a visible row is an
act of navigation, not of disclosure; springing the whole stack open on every leaf click buries the
detail the user just asked for under lists they had deliberately collapsed. The click-rooted reveal
exists solely so the clicked list does not snap shut under the pointer.

The branch opens **in place**: it starts where the hovered list already sits and lays its members out
end to end. The covered peeks behind it don't move — but the **detail is never covered**: it slides
**right** so its content stays visible beside the reveal (v1.13.1; it used to be overlapped, which hid
exactly what the user was reading), clipping at the container's right edge on deep stacks, and slides
back when the cascade closes. It stays open while
the pointer is anywhere **inside the branch** (walking from the hovered list into one of its revealed
children must NOT collapse it — that is the whole point); it closes the moment the pointer leaves every
member of it, or you **click a row**. Entering a *different* covered list already inside the open
group changes nothing — the reveal already opened every on-screen list from the first pointer
entry, so a later enter on another member is a no-op; it never re-roots there.

The reveal is **pointer-driven only** (not focus): a covered row keeps focus after a click, so a focus
reveal would leave the branch open and jam the auto-cover as the window shrinks — covered rows stay
keyboard-operable via their `aria-label`. Because the revealed lists are the real rails (not copies)
they are fully **interactive**: clicking a row behaves exactly like clicking that row at rest — the
same select/clear intent as **own-unselection** (re-clicking the already-selected row pops one level,
it does not no-op) — and the headers' `+`/`«` work in place. There is **no per-row or per-header
popover** — the branch is revealed at once.

### Wide and narrow modes — the stack becomes a navigation controller

The frame has two **layout modes**, chosen automatically (`layoutMode="auto"`):

- **wide** — everything above: the lists sit beside the detail, cover/peek/reveal as room runs out, and
  drill off-screen at the end. This is the layout the whole recipe describes.
- **narrow** — **the wide layout is exhausted**: the shrink sequence above has collapsed every list,
  taken the detail to `minDetailWidth`, and slid every collapsible list off-screen — and the container
  STILL can't fit what remains. The side-by-side model has nothing left to trade — peeks, cover toggles
  and the hover reveal are all pointer affordances spending room that no longer exists (and on a phone
  there is no pointer at all). So the view stops being a row of columns and becomes a **navigation
  stack**, exactly Apple's `UINavigationController`: **one FULL-WIDTH pane at a time**.

Narrow mode is entered when the container is narrower than a fixed floor: the detail's minimum plus
ONE collapsed strip (32px covered peek / the minimized icon strip), floored at a flat 480px regardless
of what is selected — the floor is deliberately selection-independent, so losing a selection never by
itself flips the mode back to wide. It is ALSO entered — at any width — when the browser is a
**phone** (an iOS / Android phone user agent), which is why a phone starts and remains in narrow mode.
Tablets and desktops are decided by width alone — a narrow *window* on a big screen behaves exactly
like a phone, and a wide one doesn't.
`layoutMode="wide" | "narrow"` forces one (a showcase, a test). Deliberately NOT the old rule (one
full topic list + the detail minimum): that flipped the stack to narrow while the wide layout still
had collapsed strips to hide progressively, so every list vanished at once as the window shrank.

In narrow mode:

```
[ Workspaces ]  →  [ Features ]  →  [ Entities ]  →  [ detail ]
      ‹ Back            ‹ Back           ‹ Back
```

- The visible pane is the deepest one the selection reaches: the **frontier list** while it is still
  being chosen from, the **detail** once every level is selected. A landing placeholder is never shown —
  on a phone you are looking at the list you are choosing from, not a pane telling you to choose.
- **Selecting pushes** the next pane in from the right edge; the pane behind it parallaxes left (as iOS
  does) and is `inert` + `aria-hidden`, so only the visible pane is reachable by pointer, keyboard or AT.
- **Back** (top-left of every pane but the root) **pops**: it clears exactly the deepest selected level
  — the same `onClear` the breadcrumb and the wide layout's Back use, so the unsaved-work guard applies
  identically. Repeated Back walks to the root.
- Selection in a list falls back to the primitive's gold **bar** (`selectionStyle="bar"`): the marker
  system's connectors need a parent list on screen to connect FROM, and in narrow mode there is never one.
- The breadcrumb still spans the top — it is the one thing that shows the whole trail when only one pane
  is visible.
- **The flip carries the detail with it, state intact.** The detail's subtree is never remounted by a
  mode (or disclosure-style) change: the frame keeps it mounted once, in a portal host it re-slots into
  whichever stack is active. This is what makes the flip safe on a merged stack, where the deeper levels
  are published from inside the detail — a remount would clear the very selections whose depth put the
  view in narrow mode (see keep-selection-across-modes).

### Create is a modal — the stack's create metaphor

**A create is always a modal over the stack.** The `+` in a list's header opens it; the stack does
not move while it is open (no level selected or cleared, the breadcrumb unchanged, the pane behind it
still showing whatever was there). On save the modal returns the created id and the owning list
**selects** it, so the detail that opens is the new record's real detail. On cancel, nothing changed.

This is not a style preference — it falls out of what the detail pane *is*. **The detail always shows
a real, SELECTED record.** A record that does not exist yet has nothing for the stack to hold onto:
nothing is selected, so the frontier list has no focused row and the connectors have no child to
reach; the breadcrumb has no crumb to name it; and the deep link has no id to carry (a "new" leaf is
un-linkable — reload the URL and the draft is gone). Handing the detail pane to a not-yet-existing
record therefore strands every other part of the view. The modal sidesteps all of it by not touching
the stack at all: the hierarchy stays exactly as it was until there IS an id, and then the normal
selection path takes over.

It follows that the modal asks only for what **places** the record — a name/title, and the parent it
lands under (a status column, a group) — not the record's full editor. The rest belongs to the detail
that opens on save, which is the one place a record's fields are edited. New Project asks for a name
and a description; New Work Item asks for a title, a description, and the status column.

### Per-list titles

Each level MAY carry a `title`, rendered **left-aligned** (aligned with the row text, not the toggle) with
a **divider** beneath it; the disclosure toggle sits in a fixed leading control slot so the title and the
first row share the same left edge.

### Selection markers — dash + connectors (no bar in the stack)

In the stack, selection is shown **without** the topic-detail gold left-bar (`selectionStyle="marker"`):

- the **root** list's selected row carries a leading **gold dash** in front of `[icon] [name]` (with extra
  leading padding), and
- each **child** list's selected row is joined to its selected **parent** row by a gold **elbow connector**
  — a line from the end of the parent row (its label end, or its icon's right edge when the parent is
  covered) to just before the child row's icon. The connectors are measured entirely from the DOM and
  re-tracked across the cover/uncover slide, so they stay attached for covered/peeking lists too.

Connectors join **selected rows only** — the chain ends at the deepest selected row. A list that is
open with **nothing selected** (the frontier being chosen from) gets **no line into it**: a line that
ends at the list's edge lands beside whatever row happens to sit at the parent's height and reads as a
phantom selection (v1.13.0 — a stub into the unselected frontier was tried and rejected). The
unselected frontier's own landing is the select nudge below, not a connector.

Standalone `TopicDetail` (the single two-pane primitive, used by other single-pane
consumers and the showcase) keeps the classic **`selectionStyle="bar"`** gold left-border — the dash/connector markers are a property of
the hierarchical stack, not the primitive.

### The select nudge — the automatic no-selection landing (every HTDV)

Whenever the **frontier** list (the deepest rendered one) has **no selection**, the detail pane is
owned by the package: it stays **almost empty**, showing one quiet, centered **select nudge**
(`TopicSelectHint`, v1.17.0 — replacing the automatic card grid, and since v1.19.0 the only thing
an unselected frontier may show). The nudge is a single centered card — an icon chip, a headline, and an
optional blurb — built on the `Card` primitive, and it is **THE** "pick something" placeholder for
the whole platform: every pane that waits on a choice (the stack's unselected frontier,
master/detail leaves with no open row, explorer landings) renders this one component, never a bare
`<p>` or the dashed `EmptyState` (which stays the home for genuinely empty / loading / error
panes).

The headline is as **specific as the level allows**: `Select a workspace …`
(`TopicLevel.itemNoun`), else `Select an item from Workspaces …` (the level's `title`), else the
fully generic line. `TopicLevel.overviewHelp` is the level's bespoke body — WHAT one of these rows
is and WHY to choose one — rendered under the headline; with an **empty** list the blurb shows
alone (there is nothing to select yet, and the rail already shows `emptyLabel`).

This is a property of the FRAME, not of any host: **every** hierarchical view gets it automatically
— with **no host wiring**. It exists ONLY in the no-selection state: the moment the frontier gains
a selection, the host's real detail (`children`) shows.

Two seams on `TopicLevel`:

- `itemNoun` / `overviewHelp` — the nudge's specificity: the singular noun for one row, and the
  bespoke what-and-why blurb (a string or richer nodes; hosts should source it from the same store
  as the help popovers so copy and help never drift).
- `overview: false` — the opt-out, for a level whose unselected state has a REAL landing of its
  own (ResourceExplorer's searchable entity landing with New). Everything else takes the default.

There is no third seam, and deliberately no richer mode to opt into. A card grid used to be
available here (`overview: "cards"`, v1.17.0–1.18.0) for a level whose grid WAS its landing page;
it is gone as of v1.19.0. A grid of one card per row repeats the very rows the rail beside it is
already showing — a second navigation surface competing with the rail — so an unselected frontier
is the nudge or the host's own landing, and nothing else.

Implementation constraint that is easy to break: the host's `children` MUST stay **mounted (hidden)**
under the nudge. In the merged one-rail stack the deeper levels are PUBLISHED by components living
in `children` (`StackLevels`); unmounting them unregisters the very frontier level the nudge is for,
and the stack oscillates between the two states (React's max-update-depth crash).

