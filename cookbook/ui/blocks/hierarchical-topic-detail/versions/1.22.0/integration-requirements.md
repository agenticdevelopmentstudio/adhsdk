
### Hierarchy & deep linking

- **nest-topic-lists**: The view MUST render an ordered stack of topic lists where each list's selection scopes the next; the deepest open level's pane renders the leaf detail.
- **deep-link-every-level**: Every level of the hierarchy MUST be addressable by a URL path segment, so the full selection is shareable and restorable — e.g. `https://{{app_domain}}/{{workspace_slug}}/ecosystems/temporal/applications/notes`.
- **restore-from-url**: On load (and on browser back/forward), the view MUST restore each topic list's selection and the open leaf from the URL path.
- **update-url-on-select**: Selecting an item in any topic list MUST update the URL to that level's path; deeper segments are cleared unless the next level names a `defaultSelectedId`, in which case that default's own selection applies (see **default-select-a-level**) — never a blanket "reset to a default", which would contradict **not-auto-select**.

### Top chrome — breadcrumb + help

- **render-one-breadcrumb-bar**: The view MUST render exactly ONE breadcrumb bar across the full width of the top, spanning all topic lists and the detail pane (not one per rail).
- **show-full-trail**: The breadcrumb MUST show the selected item of every topic list in order (workspace ▸ feature ▸ entity ▸ topic ▸ …); the last crumb is the current location (`aria-current`).
- **navigate-from-crumb**: Clicking an ancestor crumb MUST navigate to that level, deselecting everything deeper (via that level's `onClear`, gated by the unsaved-work guard).
- **render-breadcrumb-help**: The breadcrumb bar MUST carry a right-justified help button that pops up a description of the current view (sourced from the help config).

### Alignment

- **align-list-and-pane-top-edges**: The top edges of every topic list and the detail pane MUST be vertically aligned on one row (directly under the breadcrumb).
- **align-list-and-pane-bottom-edges**: Every topic list and the detail pane MUST fill to the same height, so their bottom edges are vertically aligned.
- **align-first-row**: The first item of every topic list MUST sit at the same vertical position across lists. Alignment comes from the uniform titled header (same height + divider on every titled list), NOT a reserved leading slot — the "new topic" affordance is a header `+`, so the first row sits directly under the header at a consistent top padding (a list with no leading slot reserves no extra space).

### Per-view layout — detail panes

- **left-justify-content**: Content in topic lists and detail panes MUST be left-justified. Centered content is a special-case exception (e.g. an empty-state prompt), not the default.
- **expand-detail-horizontally**: A detail pane MUST expand to fill the available horizontal space, honouring a minimum width.
- **scroll-horizontally-below-min**: When the available space is narrower than the detail pane's minimum width, the pane MUST scroll horizontally rather than crush its content.
- **fill-detail-vertically**: A detail pane MUST fill the available vertical space of its container.
- **avoid-fixed-vertical-scroll**: A detail pane MUST NOT contain fixed-size content that forces a vertical scrollbar where the content could instead grow to fit; vertical scrolling is a last resort.
- **render-detail-action-bar**: A leaf editor detail MUST render its action bar (Save / Cancel / Delete, and the package-injected Back when drilled) as the top of the leaf pane (not hoisted to the top chrome). The full-width breadcrumb names the pane, so a separate centered title is redundant.
- **render-detail-help-icon**: Help for the current view is the right-justified icon on the breadcrumb bar (sourced from the help config); a leaf editor MAY additionally carry a topic-specific help icon on its action bar.

### Per-view layout — topic lists

- **render-icon-name-rows**: Each topic row MUST render as `[icon] [name]`.
- **no-unrequested-sublabels**: A topic row MUST NOT carry a subtitle (`sublabel`, `inlineSublabel`, `preview`) unless the product owner asked for that list to have one. The default row is `[icon] [name]` and nothing under it: an id, slug or path echoed beneath the name is noise that crowds the list and truncates. Whatever it would say belongs in the detail.
- **fix-list-width**: A topic list MUST be a fixed width — slightly wider than its widest topic — with consistent leading and trailing padding.
- **offer-new-topic-button**: A topic list MAY carry a "new topic" (`onNew`) create affordance, rendered as a compact **`+` button right-justified in the list header** (NOT a leading row); activating it MUST open the create MODAL (see **create-in-modal**). The `+` carries its `newLabel` as its accessible name + tooltip, and MAY tint gold (`newActive`) while the modal is open.
- **offer-title-actions**: A topic list MAY carry extra compact controls right-justified in its TITLE row, just ahead of the `+` (`titleActions` — e.g. the status board's Sites list hosts its Auto Configure action there, freeing the `headerSlot` filter field to take the full row width via `ListHeader`'s `search.grow`). Title-row actions render only with a titled, un-collapsed header; keep them one line high.
- **create-in-modal**: A create MUST be a **modal over the stack** — never a blank/"new" leaf in the detail pane, and never an inline row in the list. The stack MUST NOT move while the modal is open: no level is selected or cleared, the breadcrumb is unchanged, and the pane behind it keeps showing whatever was open. On save the modal MUST return the created id, and the owning list MUST then select it — so the detail that opens is the new record's REAL detail. On cancel nothing changed. Reuse the shared `CreateResourceDialog` — the component lives in `@adh-sdk/ui/blocks` (so consumers that vendor only ui, e.g. the self-enclosed status/builds backends, can comply); a resource-feature layer may re-export it with an auth-telemetry seam (`onSaveError`) pre-wired for its own consumers. Guarded close: a dirty draft prompts Save / Discard / keep editing; the backdrop is inert.
- **scope-create-modal-to-placement**: The create modal MUST ask only for what brings the record into existence and PLACES it (a name/title, and the parent/status/column it lands in) — not the record's full editor. Everything else belongs to the detail that opens on save. (New Project = name + description; New Work Item = title, description, status.)
- **delete-row**: A topic row MAY declare `onDelete` to expose a **right-justified trash button, revealed only on hover (and keyboard focus)**; the list's fixed width MUST account for it (the row reserves trailing space so the label never runs under the button). It is NOT shown on the collapsed / covered icon strips.
- **confirm-row-delete**: Activating a row's trash button MUST open a confirmation before anything is destroyed — a destructive [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) modal (red action, keyboard shortcuts off, initial focus on Cancel). `onDelete` runs ONLY on confirm; it MAY be async, and the dialog MUST show a busy spinner (and block dismissal) until it settles.
- **break-connector-around-delete**: In the stack, the selection connector line MUST break (leave a gap) around a selected parent row's trash button rather than crossing it — the overlay paints above the rail, so the break is a computed gap in the path, not occlusion.
- **offer-disclosure-toggle**: A topic list MUST offer a way to disclose/undisclose it. In the `minimized` style each list's own toggle rides its header's upper right, alongside `titleActions`. In the default `covered` style the toggle instead rides the CHILD's header upper-left (leading control slot), covering/uncovering that child's parent — see the Layout section. Disclosing/undisclosing MUST be animated (subject to **respect-reduced-motion**).
- **render-undisclosed-icon-strip**: An undisclosed topic list MUST render as a vertical list of the topics' icons; the header `+` collapses with the header (reachable via the whole-branch reveal when covered).
- **fill-list-vertically**: A topic list MUST fill the available vertical space (pinned to its container's height) and MUST scroll only when its items overflow.
- **resize-by-drag**: A topic list MUST be horizontally resizable by dragging its trailing border. In the `minimized` style this snaps at its extremes (**snap-undisclosed-when-narrow** / **snap-full-when-wide** below); in the default `covered` style there is no icon strip to snap to, so the drag instead resizes FREELY within a fixed readable range — clamped to a 160px minimum and a 640px maximum — and never snaps to undisclosed or back to a content width.
- **snap-undisclosed-when-narrow**: In the `minimized` style, if dragged narrower than 1/3 of the list's full rail width (240px, so an 80px threshold), a topic list MUST animate to undisclosed. This does not apply to the covered style — see **resize-by-drag**.
- **snap-full-when-wide**: In the `minimized` style, if dragged wider than the list's full rail width (240px), a topic list MUST clamp (back) to that width — a fixed rail width, not the list's own content size. This does not apply to the covered style — see **resize-by-drag**.

### Selection — pure intent, package-owned

- **split-select-clear**: A level MUST expose `onSelect(id)` (select this level, clear descendants) and `onClear()` (clear this level + everything below) as PURE navigation; the package decides WHEN each fires.
- **own-unselection**: A click on the already-selected row MUST pop one level: if the clicked level's CHILD currently has a selection, the click MUST clear that child (`child.onClear()`) rather than the clicked row's own level; only once the clicked row is itself the deepest selection does the click clear that level (`onClear()`). A click on any other row MUST select it (`onSelect`). Consumers MUST NOT write toggle logic — the pop-one-level-at-a-time behavior lives in the package's shared `railOnSelect`, used by every stack (minimized, covered, narrow).
- **not-auto-select**: The view MUST NOT auto-select anything of its own accord — landing on a level with no selection shows the list with nothing focused (no resume of a last id, no coerced first item); only the deepest pane that IS selected renders a detail. The ONE exception is a level that explicitly asks for a landing selection (**default-select-a-level**); a level that names none is never chosen for.
- **default-select-a-level**: A level MAY name a `defaultSelectedId` — the item to select the moment that list APPEARS with nothing chosen (i.e. when the parent topic that opens it is picked). It MUST arrive as an ordinary selection, fired through the level's own `onSelect`, so the URL, the breadcrumb, the detail and re-click-to-clear all behave exactly as if the user had clicked the row — with ONE exception, **not-spend-history-on-a-default** below. It MUST arm once per APPEARANCE: clearing the row INSIDE that visit MUST stick (a default that re-fires on every clear makes the row impossible to deselect — a default may choose FOR the user, never argue WITH them), while leaving the parent topic and returning MUST re-apply it. **A list that APPEARS already showing the selection the default names counts as an armed appearance** — the visit is spent whether the default fired or was already satisfied, or a deep link straight to the defaulted item leaves nothing recorded and the first clear reads as a fresh appearance with nothing chosen, so the default re-fires and the row cannot be deselected at all. A default naming an item the list does not (yet) have MUST simply not fire — an async list applies it when its rows land, and a stale default MUST NOT select a phantom row. Use it where the answer is all but certain and an empty pane would just ask a question with one sensible answer (Work Items → List); the default for every other level remains **not-auto-select**.
- **not-spend-history-on-a-default**: An auto-applied default MUST NOT cost a history entry. A choice the package made is not a place the user navigated to, so the default MUST REPLACE the current entry where a click would PUSH — the level's `onSelect` therefore takes an optional `{ replace: true }`, passed on the default path and omitted on a click. Otherwise one click on the parent topic yields TWO entries (the topic, then the default's leaf) and Back lands on the bare topic, where the default immediately re-applies and throws the user forward again — a Back button that visibly does nothing. The bare topic stays reachable by CLEARING the row (**default-select-a-level**), which is a state the user chose; it is not a Back stop. A level whose `onSelect` ignores the option reintroduces the double entry, so a level that names a `defaultSelectedId` MUST honour it.
- **be-one-stack**: Every NAVIGATION list MUST be a level of the single stack — a list is "navigation" when picking a row is how you REACH a record (the row becomes the selection, the URL grows a segment, and the pane beside it becomes that record's detail). An in-pane master/detail of that kind MUST be dismantled into a published list level + a leaf editor. There MUST be exactly one navigator.
- **display-content-as-a-list**: A detail pane holds CONTENT, and content MAY render as a list — a list is one of the ordinary shapes data comes in, beside a board, a table, a timeline, a calendar or a chart. A display MAY carry its own details pane and MAY edit its rows in place ([adhsdk.recipe.ui.blocks.list-with-details-pane](cookbook:6acd3c5f-7bb5-4d6d-8c8d-141e1909cf73) + [adhsdk.ingredient.ui.components.actions.inline-commit-control](cookbook:26df832c-a7f7-4cf6-b3f5-240c61e8bd68)), because none of that is navigation: the stack does not move, no level is selected, and the URL does not grow. "The deepest pane is a detail" constrains the pane's ROLE, not its shape.

### Whole hierarchy — disclosure + off-screen drill-down

- **single-disclosure-controller**: ONE ResizeObserver over the whole row MUST drive disclosure/drill-down for every list (not one observer per list).
- **keep-manual-toggle**: Each list MUST keep its manual disclosure toggle (the `«` that shrinks it to a vertical icon strip); a manually-collapsed list counts as its icon width in the fit math, then slides off-screen if there is still no room.
- **undisclose-before-off-screen**: Shrinking the window is a TWO-PHASE response. Phase 1 — as the window shrinks, the **leftmost** still-full lists MUST first **undisclose** to their icon strips (general → specific) until everything fits or every list is an icon strip. Phase 2 — ONLY once every list is already an icon strip AND those icon strips plus the detail's minimum STILL don't fit may lists begin to slide off-screen. A list MUST NOT slide off-screen while it (or a list to its right) could still be undisclosed instead.
- **drill-off-screen-when-cramped**: In phase 2, the **leftmost** icon-strip lists MUST slide **off the left edge** (hidden: `0`-width column + `inert` + `aria-hidden`), general → specific, until the detail fits at its minimum. On a phone width every list slides off (detail full-width), computed before paint so the first frame is already drilled-down.
- **not-hide-frontier-choosing-list**: The view MUST NOT hide the frontier list while it has no selection (its "detail" is only a landing) — only once that level is selected (the detail is real content) may the frontier list also slide off.
- **disclose-when-room**: When the window widens, hidden lists MUST slide back on (specific → general) as space allows.
- **show-back-when-drilled**: When at least one list is hidden AND something is selected, a **Back** button MUST appear top-left of the leftmost-visible pane (the detail's button bar if the detail is leftmost-visible, else the top-left of the leftmost-visible list).
- **back-clears-one-level**: Back MUST clear exactly the deepest selected level (`onClear`), re-disclosing one parent; repeated Back walks up to root.
- **guard-unsaved-on-exit**: If the leaf editor is dirty (`exitGuard.isDirty()`), any action that would clear OR replace the open detail — Back, re-click-deselect, breadcrumb up-nav, selecting a shallower row, and selecting a **different row in the deepest selected level itself** (a sibling swap that unmounts the open leaf) — MUST first open the shared **2-action Discard / Stay** `UnsavedChangesAlert` — Discard → proceed; Stay → keep editing. It never saves: `exitGuard` (`PaneExitGuard`) exposes only `isDirty()`, with no `save()` for the frame to call. Only a forward drill-down into a not-yet-selected level (no open detail to lose) is unguarded; equivalently, `railOnSelect` guards whenever the target level already has a selection (`level.selectedId != null`).
- **not-redisclose-user-collapsed**: Automatic disclosure MUST NOT re-disclose a list that the user explicitly undisclosed (user intent wins over the layout heuristic).
- **keep-detail-at-minimum-while-lists-yield**: Shrinking MUST take the room from the LISTS, never from the detail: the detail MUST hold `minDetailWidth` through both phases, and MUST only be narrower than it once every list is off-screen and it is the sole view — where it MUST be exactly the container's width.
- **shift-off-screen-by-whole-lists**: In phase 2 the off-screen shift MUST be quantised to WHOLE lists — shift the stack left by exactly the leftmost visible list's width, hiding that list, and repeat. A partial shift (parking a list half off the left edge) is a defect.
- **hide-off-screen-progressively** (v1.17.0): Phase 2 MUST play out ONE list per strip-width of shrink — each further strip-width of narrowing hides exactly the next leftmost strip — and the wide→narrow mode switch MUST NOT preempt it (see **exhaust-wide-before-narrow**). All the collapsed lists disappearing at once as the window shrinks is a defect (the shipped behavior this rule replaces: the old narrow threshold, one full list + the detail minimum, was ABOVE the width where phase 2 begins, so the mode flip swallowed the whole progression).
- **reverse-on-grow**: Widening MUST re-run the same rules on the wider container, so on a larger device leaving narrow mode discloses the lists in reverse order — off-screen lists slide back on (specific → general) and hidden lists re-disclose — but a list MUST re-disclose ONLY when the user has not pinned it shut.
- **log-layout-decisions-outside-production** (v1.17.0): The layout engine MUST trace its decisions to the console — the wide↔narrow mode decision (with the width and floor it was made at), each fit pass's collapse / off-screen outcome, every disclosure toggle, and every narrow push/pop — on EVERY environment except production, where it MUST be off. The switch is host-flipped (`setHtdvLayoutLog`), sitting behind the host's build-inlined environment allowlist so a production bundle ships it dead-code-eliminated; the lines are also kept in a bounded buffer (`__htdvLogDump()`).

### Disclosure toggles — pins and modifier-click

- **disclose-absent-a-pin**: Absent a `«`/`»` pin, a topic list MUST be disclosed: there is no default that hides a parent list ahead of the fit rules below, and the root list's header renders no toggle for one. (A leaf-first `autoHideTopics` default and a root-header toggle for it were designed and shipped for a time, then parked before this version — see the Web platform note; neither ships today.)
- **layer-hide-intent**: Disclosure MUST resolve as two layers where each may only ever HIDE more, never disclose: a user's `«`/`»` pin → width pressure (which MAY take the room back from a list the user pinned open, but MUST NOT disclose one they pinned shut).
- **toggle-all-on-modifier-click**: ⌘-click (macOS) / Ctrl-click (elsewhere) on any `«`/`»` MUST apply that button's action to EVERY list at once — cover all, or uncover all — with the fit rules still applied on top (so "uncover all" only discloses the lists that actually fit).
- **apply-disclosure-toggles-immediately** (v1.13.3): A `«`/`»` pin click MUST settle the stack to the new state on the click itself — which means the click MUST also DROP any open hover reveal. A revealed group renders its members at full width regardless of pins, and these pin controls live on headers that are usually only reachable INSIDE a reveal; without the drop, the click changes state invisibly (the pointer never leaves, so the reveal never closes) and the new layout "turns up later" when the pointer happens to move away — the toggle reads as dead. The pointer has not moved, so no enter event may re-open the reveal on the same click; the next real pointer entry onto a covered peek engages it as usual. (Contrast root-reveal-on-covering-select: a row SELECT deliberately roots a reveal so the clicked list doesn't snap shut under the pointer — the pin toggles are the opposite: settling IS the requested action.)

### View state belongs to the surface, not to the mount

- **keep-view-state-across-a-selection**: Selecting a row is a route change, and a route change REMOUNTS the page subtree — so anything the stack keeps in per-instance state is destroyed by the user's own click. Every piece of VIEW state MUST therefore outlive the mount, held per SURFACE (keyed by the root list) rather than per component: the per-list **pins**, the open **hover branch**, and the record of which levels' **defaults have already been applied**. The bugs this rule exists to forbid all look different and are one bug: a list the user pinned open snapping shut under them; a revealed branch collapsing the instant a row inside it is picked, with the pointer still in it and no event left that could reopen it; and a `defaultSelectedId` re-selecting the row the user just cleared, making it impossible to deselect. A reload MAY reset this state — a fresh load is a deliberate fresh start.
- **portal-modals-out-of-the-stack**: A modal opened from inside the stack (a level's `+` create dialog, a confirmation) MUST be portalled to the document body. Rendering it in place leaves it a DESCENDANT of the pane that opened it, so it inherits that pane's fate — and narrow mode marks every pane that is not on top `inert` + `aria-hidden`, which makes the dialog unusable: the form silently swallows every keystroke and Save never enables. `position: fixed` is not enough; only a different parent is.

### Motion — structure lands in place, width animates, content crossfades

- **land-structure-changes-in-place**: A STRUCTURAL change — a level appearing/disappearing, or any level's selection changing — MUST apply its new layout instantly, in place. The detail pane MUST NOT animate in from the left edge, nor grow, as the lists re-hide behind it, and no list may animate out. The suppression MUST cover the selection's TRAILING commits too (v1.17.0): levels registering and measured widths landing repaint geometry a frame or two after the selection, and restoring the transition properties before the browser has painted the new layout animates it anyway — so the transitions stay off for a settle window after the LAST structural change, not just the render it happened on.
- **crossfade-detail-swaps** (v1.17.0): When a selection REPLACES what the detail pane is showing, the outgoing content MUST dissolve into the incoming content with a brief crossfade (~220ms, both halves, ease-in-out; stretched by the dev slow-animations switch). When nothing was showing yet — the surface's first paint — the content MUST simply appear: no fade, no unasked-for intro. The dissolve MUST survive the remount a route-param selection causes (the outgoing half is an inert DOM snapshot taken before the swap), MUST NOT move or resize the pane (geometry answers to land-structure-changes-in-place), and MUST NOT fire for the mount-time settle cascade (levels registering is not the user swapping details).
- **animate-width-changes**: Width-driven changes — a window resize, a `«`/`»` cover toggle, the hover reveal, a drag — MUST keep animating (subject to **respect-reduced-motion**).

### Covered disclosure — peek, reveal, titles, selection markers

- **default-to-covered**: The hierarchical frame MUST default to the `covered` disclosure style; `minimized` is opt-in via `disclosureStyle="minimized"`.
- **peek-covered-parent**: In the `covered` style, a covered parent list MUST stay partially visible as a fixed 32 px icon-strip peek at its left edge (a stacked-card overlap), not disappear entirely; child lists overlap their parents with increasing z-index and the detail is topmost. The peek MUST show each row's icon and NOTHING after it (v1.17.0 — it was 40px, which reached ~6px into every label and left a column of sliced first letters at the peek's right edge; the covering list now sits those few points further left, covering them).
- **cover-automatically**: A list MUST be covered automatically when there is not room to show it in full alongside the child lists and the detail at its minimum; the **frontier** choosing list (nothing selected yet) MUST NOT be covered, and MUST NOT be slid off-screen by the detail's minimum-width shift — the detail's minimum is the same in every state, the frontier is simply excluded from the lists that collapse or shift, and in the last-resort squeeze an unselected frontier's landing placeholder yields its width before the choosing list narrows.
- **allow-manual-cover**: The user MUST be able to manually cover/uncover a list via its `«`/`»` toggle; a manually-covered list MUST stay covered across resizes (user intent wins), and the auto layer MUST NOT uncover a list the user covered.
- **reveal-all-covered-lists-on-hover** (v1.13.0; supersedes reveal-covered-branch-on-hover): The pointer ENTERING a covered (peeking) list MUST reveal EVERY on-screen list — the hovered list's parents AND children alike — as real rails at full width, with uncovered `[icon] [name]` rows AND their titled headers (title, cover `«`/`»`, New `+`), chained side by side from the left edge as a lifted card (drop-shadows off both outer edges); the DETAIL is pushed right, never covered (push-detail-aside-on-reveal). Revealing less is a defect: the branch-only reveal left the hovered list's own parents covered, so walking the stack leftwards was a list-by-list re-rooting exercise. Off-screen (drilled-down) lists stay out — Back is their affordance. The reveal MUST be ANIMATED: the branch wipes open from the 32px peek to full width (and back), subject to **respect-reduced-motion**. There MUST be no per-row or per-header popover copy. The reveal is POINTER-driven only: it MUST NOT be triggered by focus, because a covered row keeps focus after a click and a focus reveal would leave the branch open — jamming the auto-cover as the window shrinks. (Covered rows stay keyboard-operable via their `aria-label`.)
- **open-branch-in-place**: The branch MUST open IN PLACE — starting at the left edge the hovered list already occupies, laying its members out end to end. The covered peeks and lists underneath keep their geometry; closing the branch animates everything straight back to the layout it came from (the state it was in before the hover).
- **push-detail-aside-on-reveal** (v1.13.1): The reveal MUST NOT cover the detail. While a reveal is open the detail's left edge MUST track the group's right edge — the detail slides RIGHT (animated, subject to respect-reduced-motion) so its content stays visible beside the open lists, clipping at the container's right edge when a deep stack leaves it no room, and slides back when the reveal closes. Only the detail yields; the peeks behind the group are still overlapped (that is what the card shadows mark).
- **keep-branch-open-while-inside-it**: The revealed branch MUST stay open while the pointer is inside ANY of its members — moving from the hovered list into one of its revealed children MUST NOT collapse it. It MUST close (animate back to the previous state) only once the pointer has left every member of the branch. Entering a DIFFERENT covered list that is already a member of the open group MUST change nothing (the whole-stack reveal already opened it); it MUST NOT re-root or narrow the group.
- **grow-the-branch-walking-outward**: Walking the pointer OUTWARD (right → left, into a shallower peek) MUST grow the cascade: the newly entered list joins it as its new root, pushing the already-open lists to the right, and every list that was open STAYS open. Collapsing the cascade because the pointer moved to a list outside the current group throws away everything the user just opened, one step before they get to the top of the stack. Only the pointer leaving the COLUMNS entirely closes it.
- **close-branch-only-on-pointer-exit**: The POINTER — and nothing else — closes the branch. Selecting a row inside it MUST NOT collapse it: the pointer is still in there, and collapsing under the cursor yanks the rows out from under the gesture, so you could never pick a parent and then go on to pick its child in the list that just re-populated beside it — which is what a whole-branch reveal is FOR. The branch (including any deeper list the new selection just added to it) MUST stay open until the pointer leaves every member, and MUST then animate back to the layout the new selection implies.
- **not-expand-parents-on-select** (v1.13.0): A CLICK on a visible row MUST NEVER expand the user's collapsed parent lists. Clicking is navigation, not disclosure: the expand-everything reveal belongs to the pointer deliberately ENTERING a covered strip, and only there. The click-rooted reveal below is bounded at the clicked list.
- **root-reveal-on-covering-select**: A select that COVERS the list it happened in — width pressure covering the clicked list because its child list just appeared, or re-covering it — MUST root a BRANCH reveal (the clicked list and its children ONLY — see not-expand-parents-on-select) at that list on the select itself: the pointer is still inside the list, which is exactly the state the hover reveal serves, but the pointer never moved, so no enter event can engage it. The clicked list MUST stay open in place with its new choosing child revealed beside it, floating over the detail, until the pointer leaves the branch (the covered layout then applies). A select that covers nothing at/below the clicked list MUST leave the resting stack untouched — no z-lift, no floating-card shadows (the blindly rooted reveal is dropped as meaningless). Deep links get no reveal: there is no pointer in the stack to serve.
- **float-branch-as-an-opaque-card**: The revealed branch MUST read as one opaque card floating over the UI. Both of its OUTER edges MUST be edges — a drop-shadow off its trailing edge (over the detail it covers) AND off its leading edge (over the peek stack it slid out of); a peek's own trailing border is clipped away with the rest of its rail, so that leading shadow is the only boundary there, and without it the opened list bleeds into the icon strip behind it. Members INSIDE the branch abut each other, separated by their own rail borders. The branch MUST also be opaque: a rail background that is deliberately translucent against the page (the nav token) MUST be composited over an opaque page-coloured layer while it floats, or the detail's text ghosts through the branch.
- **draw-connectors-over-the-revealed-branch**: The selection connectors MUST stay VISIBLE across the revealed branch — they are the chain the branch exists to show you. The connector overlay MUST therefore be lifted above the branch's own lift: the branch's members float above the detail, so an overlay left at the resting z-order is painted over by the very lists it links, and the selection chain vanishes exactly when the user opens the branch to read it.
- **pure-select-from-reveal**: Clicking a row in a revealed list MUST behave exactly like clicking that row at rest — the same `onSelect`/`onClear` intent as **own-unselection** — removing the deeper lists and showing the chosen item's detail. Re-clicking the already-selected row is NOT a no-op here: it pops one level down, same as anywhere else in the stack.
- **title-each-list**: A level MAY carry a `title`; when present it MUST render left-aligned (aligned with the row text) with a divider beneath it, the disclosure toggle in a fixed leading control slot.
- **mark-selection-without-bar**: In the stack (`selectionStyle="marker"`) the selected row MUST NOT use the topic-detail gold left-bar; the root's selected row MUST show a leading gold dash, and each child's selected row MUST be joined to its selected parent row by a gold elbow connector.
- **connect-selected-rows-only** (v1.13.0): A connector MUST join a selected parent row to a selected CHILD ROW — nothing else. A list that is open with nothing selected MUST get NO line into it (no stub to the list's edge: it lands beside an arbitrary row and reads as a phantom selection). The chain ends at the deepest selected row; the unselected frontier's landing is the select nudge, not a connector.
- **keep-connectors-attached-when-covered**: The selection connectors MUST stay attached to the correct rows when lists are covered/peeking and across the cover/uncover slide (measured from the DOM, re-tracked through the transition).
- **keep-bar-for-standalone**: The standalone `TopicDetail` primitive MUST keep `selectionStyle="bar"` (the gold left-border); the dash/connector markers are a property of the hierarchical stack only.

### Topic overview — the automatic no-selection landing

- **show-select-nudge-at-unselected-frontier** (v1.17.0; supersedes show-topic-overview-at-unselected-frontier): Whenever the frontier list has NO selection, the detail pane MUST stay almost empty, showing the centered select nudge — `TopicSelectHint`: one card (icon chip + headline + optional blurb) built on the `Card` primitive. The headline MUST be as specific as the level allows: `Select a <itemNoun> …`, else `Select an item from <title> …`, else the generic line; `TopicLevel.overviewHelp` renders as the bespoke what-and-why body under it, and with an EMPTY list the blurb MUST show alone (nothing is selectable yet; the rail already shows `emptyLabel`). This is a FRAME behavior: every hierarchical view gets it automatically, with no host wiring — including a leading (e.g. workspaces) level when IT is the unselected frontier.
- **share-one-select-placeholder** (v1.17.0): `TopicSelectHint` is THE "pick something" placeholder platform-wide — every pane that waits on a choice (master/detail leaves with no open row, record-settings panes, explorer landings, feature panes) MUST render it, never a bare paragraph or the dashed `EmptyState`; the dashed `EmptyState` remains the home for genuinely empty / loading / error panes, and a ternary that conflates "loading" with "select something" MUST be split.
- **not-land-a-grid-at-an-unselected-frontier** (v1.19.0; RETIRES opt-in-overview-cards and fit-overview-cards of v1.17.0/v1.14.0): A level MUST NOT be able to replace the nudge with a card grid, or with any other index of its own rows. `TopicLevel.overview` is `boolean` — there is no `"cards"` value to set and no card component to render — because a grid of one card per row repeats the very rows the rail beside it is already showing, i.e. a second navigation surface competing with the rail. A level that needs to explain its rows does it in the nudge's `overviewHelp` blurb; a level with a REAL landing of its own uses the `overview: false` opt-out.
- **hide-overview-once-selected** (v1.13.0): The nudge exists ONLY in the no-selection state. The moment the frontier gains a selection the host's real detail (`children`) MUST show — the nudge MUST NOT render beside or instead of a selected topic's view.
- **opt-out-overview** (v1.13.0): A level whose unselected state has a REAL landing of its own (ResourceExplorer's searchable entity landing with New) MAY opt out via `TopicLevel.overview: false`; the host's `children` then render as before. This is the ONLY opt-out, and it hands the pane to the host — never to another package-drawn index.
- **describe-topics** (v1.13.0; v1.19.0: this view renders it NOWHERE): A `TopicDetailItem` MAY carry a `description` (one or two sentences). It fed the overview card, and with the grid retired no surface in this view shows it — rows render icon + label, described or not. Hosts MAY keep carrying it for surfaces that DO show a blurb (a selected topic's `EmptyState`); to explain a LIST, set the level's `overviewHelp`, which is the copy the nudge renders.
- **render-overview-help** (v1.17.0 shape; the standalone `TopicOverviewHelp` of v1.14.0 is FOLDED INTO `TopicSelectHint`): A level MAY set `TopicLevel.overviewHelp` (a string or nodes) as the nudge's bespoke body — what one of these rows is and why to pick one. It MUST render under the nudge's headline, MUST show alone when the list is empty, and MUST be ignored when `overview` is `false`. Nothing outranks it any more: as of v1.19.0 there is no grid for it to yield to.
- **keep-children-mounted-under-overview** (v1.13.0): While the nudge or overview shows, the host's `children` MUST stay MOUNTED (hidden) beneath it. In the merged one-rail stack the deeper levels are PUBLISHED by components living in `children` (StackLevels); unmounting them unregisters the very frontier level the overview is for, and the stack oscillates between the two states (React max-update-depth).

### Narrow mode — the stack as a navigation controller

- **exhaust-wide-before-narrow** (v1.17.0; supersedes switch-to-narrow-when-only-a-detail-fits): The frame MUST switch to the NARROW layout only once the wide layout's whole shrink sequence is exhausted — every list collapsed, the detail at `minDetailWidth`, every collapsible list slid off-screen. Concretely: narrow begins when the container is narrower than `minDetailWidth` plus ONE collapsed strip (32px covered peek / the minimized icon strip), floored at a flat 480px regardless of selection — the floor MUST NOT vary with the selection (an unselected frontier's "no detail minimum" exemption belongs to the fit math, never to a lower narrow floor). The frame MUST ALSO be narrow — at any width — when the browser is a phone (an iOS / Android phone user agent), so a phone starts and remains in narrow mode; the 480px floor itself guarantees the frame never drops narrower than phone width even when `minDetailWidth` is small. Tablets and desktops are decided by width alone, so a narrow WINDOW behaves exactly like a phone and a wide one does not. The mode MUST be resolved before paint (no flash of the wide layout), and `layoutMode="wide" | "narrow"` MUST force one. The superseded rule (one full topic list + the detail minimum) sat ABOVE the width where off-screen hiding begins, so the mode flip hid every list at once and the progressive drill-down never ran.
- **show-one-full-width-pane**: In narrow mode each topic list and the detail MUST be a FULL-WIDTH pane, and exactly ONE of them is visible: the frontier list while it is still being chosen from, the detail once every level is selected. A landing placeholder MUST NOT be shown in place of the list being chosen from. Peeks, cover toggles, the hover reveal and drag-resize MUST NOT be rendered — they spend room that does not exist.
- **push-and-pop-like-a-navigation-controller**: Selecting MUST PUSH the next pane in from the right edge (animated, subject to **respect-reduced-motion**); the pane behind it MUST parallax and be `inert` + `aria-hidden`, so only the visible pane is reachable by pointer, keyboard or AT. A pane that is being pushed MUST animate in rather than appear in place.
- **fill-the-pane**: A narrow pane IS the screen, so it MUST paint the whole of it: the list inside it MUST FILL the pane rather than size to its rows. A content-height rail leaves everything under the last row transparent — the parallaxed pane behind it shows through, and the page behind that — which reads as a half-drawn screen. (The wide stack's lists are stretched grid cells and correctly size to their column; this is the flex pane's own responsibility.) A full-width pane also MUST NOT draw the rail's trailing border: it separates nothing at the edge of the screen.
- **slide-panes-ease-in-out**: EVERY pane — the topic lists AND the detail — MUST travel on one transition: a horizontal slide, **ease-in-out**, so the push and the pop each accelerate out of rest and settle back into it rather than snapping to a stop. Both directions animate: disclosing (push, in from the right) and undisclosing (pop, back out to the right). The animation MUST survive the REMOUNT the selection causes — the slide's origin is the pane the stack was last painted at, held per surface (**keep-view-state-across-a-selection**), because a pane that mounts already at its final transform has nothing to animate FROM and the push silently degrades to a jump. Under **respect-reduced-motion** the transition is dropped entirely: the panes cut to their new places, identical layout, no travel.
- **offer-back-in-narrow**: Every narrow pane except the root MUST carry a top-left **Back** that POPS one pane — clearing exactly the deepest SELECTED level via the same `onClear` the breadcrumb and the wide Back use, so **guard-unsaved-on-exit** applies identically. Repeated Back MUST walk up to the root, and a popped pane MUST animate OUT to the right rather than vanish.
- **keep-selection-across-modes** (hardened v1.17.0): Switching between wide and narrow (a resize) MUST preserve the selection exactly — the mode is a rendering of the same stack, never a navigation. That includes the DETAIL SUBTREE's own state: the flip MUST NOT remount `children`. In a merged stack the deeper levels are PUBLISHED by components living in `children`, so a remount silently clears the very selections this rule protects (and worse: with the selection-dependent narrow floor of exhaust-wide-before-narrow, the cleared selections lowered the floor the narrow decision was made on, bouncing the frame straight back to wide — the user shrank into narrow mode and landed in a wide layout with their place wiped). Concretely: the frame owns ONE persistent detail host (a `display: contents` portal target) and re-slots it into whichever stack is active, so a flip MOVES the detail's DOM with its React state intact. The same holds for a `disclosureStyle` change (covered ↔ minimized) — any change of stack, not just the mode.
- **mark-narrow-selection-with-bar**: In narrow mode a list's selected row MUST use the primitive's gold `selectionStyle="bar"`: the dash/connector markers need a parent list on screen to connect FROM, and narrow mode never has one.
- **show-row-disclosure-chevron**: In narrow mode every selectable row MUST carry a trailing chevron (›) marking that picking it pushes another pane in — a full-width pane has no peeking sibling column left to hint at that, so the row itself must say so. A `disabled` row MUST NOT show it (it has nowhere to go). The chevron is narrow-only: the wide/covered stack MUST NOT render it — the selection connector line already shows what a choice leads to there.

### Cascading view — motion, ground and the selection chain

Rules specific to `disclosureStyle="cascading"` (the `HierarchicalMenuDetail` vertical menu cascade).
Everything above still applies; these pin the parts that are unique to a nested-menu shape.

**These rules are EXECUTABLE.** Each id below is a test name in
`packages/web/packages/ui/src/__tests__/cascadeRules.test.ts` (pure rules) or `cascadeInteraction.test.ts` (the
DOM wiring), and the decisions themselves live as pure functions in `packages/web/packages/ui/src/blocks/
cascade-rules.ts` rather than as expressions inside the 3000-line component. That is deliberate and
it is the point of this section: every rule here was reported, fixed, and then silently REGRESSED by
a later fix, because nothing named it and nothing could test it. **Before changing the cascade, run
`pnpm --filter @adh-sdk/ui test`; if one of these fails, the fix is not to update the
assertion — someone has just re-broken a reported bug.**

The cascade's GEOMETRY (the rect unions, the connector paths, the measured ground) is not covered by
those tests and cannot be: jsdom has no layout engine, so `getBoundingClientRect` is all zeros. That
gap is exactly why the geometry-dependent rules had to become pure decisions taking measurements as
arguments — the measuring stays in the component, the deciding is tested.

- **draw-one-chain-line**: The selection chain MUST read as ONE line wherever it is drawn. Three
  things draw it — a selected row's gold left bar, the gold rail down an unchosen submenu's left
  edge, and the elbow connectors joining a selected parent row to its child — and they MUST share a
  width (`CHAIN_STROKE_PX`) and a colour token (`apt-gold`). The width is **2**, and it is 2 because
  `topic-detail`'s `border-l-2` row bar is the drawing that has always shipped: the others match IT,
  never the reverse. Matching the WIDTH alone is NOT sufficient and MUST NOT be treated as the fix:
  an anti-aliased SVG stroke spreads its gold across an extra device pixel at partial alpha, so at
  the same nominal width it still reads dimmer and softer than the CSS borders beside it and the pair
  looks like two different golds. The connector overlay MUST therefore render `crispEdges` (every
  path is axis-aligned, so snapping to the pixel grid costs nothing), and the width MUST stay a whole
  number of pixels.
- **bounce-the-entrance**: A submenu disclosed by choosing a row MUST grow out of that row and
  BOUNCE into rest, each swing overshooting less than the last: **+10, −10, +5, −5, 0** percentage
  points around its resting size. Size and travel bounce TOGETHER and by the same figures — the
  transform origin sits on the chosen row's centre, so one `scale` track makes the box proportionally
  bigger and proportionally further from that row in one number. It MUST be a keyframe list, not a
  cubic-bezier: a bezier overshoots once and cannot reverse four times. The duration MUST leave every
  segment at least two frames at 60Hz (which is why it is 460ms, not 300 — five segments in 300ms
  leaves the last two undrawable, making the spec decorative).
- **not-wiggle-the-exit**: The exit MUST NOT wiggle — it shrinks straight back into the row that
  opened it, with no anticipatory swell. The bounce belongs to the GROW only. Specifically the exit
  curve MUST NOT carry a negative control point: the exit was once the entrance's exact mirror, and
  mirroring an overshoot produces an UNDERSHOOT at the start, which is the wiggle. Both control
  points' `y` MUST stay within [0, 1].
- **animate-every-menu-closure**: EVERY click that tears menus down MUST collapse them
  progressively — never vanish them in one frame. That includes selecting a **different** row in a
  level that already has a selection (switching workspace destroys exactly the same menus a re-click
  does), not only the re-click-to-clear. The only click that MUST NOT collapse is a forward drill
  into a level with nothing selected: nothing is open below it to take away. The real navigation
  (`onSelect`/`onClear`) runs as the animation's callback, so a broken animation MUST NOT be able to
  swallow the click.
- **collapse-inward**: When a parent is unselected/replaced, its descendant menus MUST collapse
  in ORDER, deepest first, each a beat after the one it opened, so the stack telescopes back toward
  the root. Deepest-first is what makes it read as inward: a menu retracts into its parent only once
  its own child is gone, so no menu is ever left floating with its opener already gone. Each menu
  shrinks into ITS OWN parent's chosen row, and the selection connectors MUST retract WITH them
  (the entrance run backwards) rather than hanging at full length until the end.
- **hold-the-ground-under-the-pointer**: The GROUND — the root list's right edge, which is also
  the detail's left edge — MUST NOT move while a gesture is engaged. It is load-bearing: the root's
  width and the detail's position both hang off it, so moving it mid-gesture shoves the UI around
  under the pointer. Selecting a row, unselecting one, and opening or closing submenus MUST ALL
  leave it exactly where it is. As of v1.16.0 the mechanism is STORAGE, not interception: the ground
  is a field of the frozen `EngagedBase` the engage transition captures, so while the machine is
  engaged the painted value literally cannot change — it recomputes only at the settle transitions
  (collapse-from-one-pointer-authority). The frozen value lives in the surface store and so
  survives the remount a selection causes (**keep-view-state-across-a-selection**).
- **collapse-from-one-pointer-authority**: The cascade's disclosure MUST be a STORED two-state
  machine per surface (v1.16.0, `CascadeMode` in `cascade-rules.ts`) — `settled` (the resting
  layout computes live) and `engaged` (geometry frozen at the base captured on the way in; columns
  from the reveal root rightward revealed at full width) — never a value re-derived per render and
  defended by interceptors. The COMPLETE set of transitions back to `settled` is: the pointer
  provably leaving the menu region (`pointer-exit`), an explicit `«/»`/auto-hide/immersion toggle
  (`toggle`), and — in auto-collapse mode only — the FINAL CHOICE (v1.15.0,
  auto-collapse-menus-on-final-choice). A rail click is NOT a settling event and MUST stay
  unrepresentable as one: a click can only ENGAGE (capturing the resting base if settled) and
  ratchet the reveal root shallower — which is exactly why no click can ever move or collapse the
  menus, structurally.
  The pointer half MUST be an IDEMPOTENT QUERY, not stream inference: the document-level
  pointermove handler only records coordinates, and the decision is evaluated against SETTLED
  MODEL rects — the lefts/tops the layout assigned plus untransformed layout sizes — never against
  `getBoundingClientRect` of an animating box. Both of v1.15.x's failure windows are instances of
  the same defect class this forbids: the remount null-region window (patched by 1.15.2's evidence
  clause) and the mid-animation shrunk-rect window (the 300–460ms entrance/exit scales contracted
  the painted union, so a real hand's pixel of drift tested "provably outside" and released every
  hold — invisible to synthetic input, which never moves mid-animation). A query that cannot be
  answered (nothing measurable) is simply NOT a transition.
- **hold-the-detail-until-the-final-choice** (v1.15.0, rebuilt v1.16.0 on DECLARED leafness):
  A select is the FINAL CHOICE when the chosen row does not lead to another topic list — the click
  that completes the path, whether it lands in the top (root) menu or any submenu. Until a final
  choice is made, the detail pane MUST NOT change: an INTERMEDIATE select (one that discloses
  another choosing list) leaves the detail showing exactly what it showed before the click — the
  last final choice's content, or the landing/overview the gesture began over — never the newly
  selected topic's overview, a landing placeholder, or a blank. The next thing the detail shows on
  the walk's completion is the final choice's detail: ONE swap, old content → new content. For the
  cascade this overrides show-select-nudge-at-unselected-frontier while the user is choosing
  (a deep link that lands on an unselected frontier still shows the overview — there is no held
  detail and no pointer) and the "showing the chosen item's detail" clause of
  pure-select-from-reveal for intermediate selects. The hold is a DISPLAY hold, not a deferred
  navigation: the intermediate select still fires the level's `onSelect`, still clears the deeper
  selections and still moves the URL — so guard-unsaved-on-exit still runs on the select that
  clears a dirty leaf, and the held content MUST survive the remount that select causes
  (keep-view-state-across-a-selection: held per surface, exactly like the ground).
  Whether a row "leads to another topic list" is a fact of the HOST's DATA and MUST be DECLARED on
  it (v1.16.0): per item (`TopicDetailItem.leadsTo: "list" | "detail"`) or per level
  (`TopicLevel.leadsTo`), resolving item → level → the `"detail"` fail-safe (an undeclared row is a
  final choice, so a missing declaration can only produce an early swap — never a hold without a
  release). The final choice is therefore known AT THE CLICK (`planRailHold`), and the swap lands
  when that click's navigation applies (`planLeafSettle`: the selection chain changed and the path
  is complete — a merged stack's late (un)registration only delays the swap by the commit it
  needs). v1.15.x instead inferred the final choice retrospectively from renders, which required a
  two-render confirmation and had no answer for gestures that never complete — see
  release-the-hold-when-the-gesture-ends.
- **release-the-hold-when-the-gesture-ends** (v1.16.0, T62): The detail hold ends with the
  GESTURE, along exactly three edges — (1) the FINAL CHOICE's landing (the one swap above); (2) any
  UP-NAVIGATION — a re-click clear, the frontier menu's ✕, a breadcrumb — releases it IMMEDIATELY,
  because up-navigation is not a choosing gesture: the pane shows the real frontier state (the
  overview / the host's landing) as the clear lands; (3) the POINTER leaving the menus (the
  `pointer-exit` settle) — an abandoned walk releases, so held content can never outlive the
  gesture that captured it. This rule exists because the v1.15.x hold armed on every rail
  interaction (clears included) but could only release on a COMPLETE path — an unselect makes the
  path incomplete forever, so the hold never released: the stale pane haunted `/home` and every
  partial path the navigation landed on, reading as "unselect doesn't work" and as phantom
  re-selection. An explicit `«/»`/immersion toggle settles GEOMETRY only and does not release the
  hold (the user is still mid-gesture until the pointer leaves or a choice lands).
- **auto-collapse-menus-on-final-choice** (v1.15.0): When the final choice is made in auto-collapse mode (`autoHideTopics` on),
  the menus MUST auto-collapse on the click itself: the open submenus collapse progressively
  (animate-every-menu-closure, collapse-inward) as the final choice's detail shows, WITHOUT
  waiting for the pointer to leave the menu region. This is the ONE click that closes the menus — the
  carve-out named in collapse-from-one-pointer-authority — and it closes them for the same
  reason the disclosure toggles settle the stack (apply-disclosure-toggles-immediately): the
  user has finished choosing, so settling IS the requested action, and menus held open under a
  pointer that is done with them bury the detail the click just asked for. The pointer has not
  moved, so nothing may re-open the menus until it next ENTERS a covered peek or the trigger's
  approach lane — and entering IS how a settled cascade re-opens. As of v1.16.0 EVERY open zone
  (the trigger lane AND the covered peeks/headers) routes through the same edge gate
  (`triggerFires` inside the one pointer authority): only the outside→inside crossing of a zone
  opens, evaluated against settled model rects. The browser's own boundary events are deliberately
  NOT used — Chrome fires `pointerenter` when LAYOUT moves under a stationary pointer, which is
  exactly what the final-choice collapse does, so v1.15.2's covered-column `pointerenter` was
  itself a re-open hole. An INTERMEDIATE select still collapses nothing, and with auto-collapse OFF
  no select collapses anything — the menus stay exactly as the user arranged them (the workspace
  stacks' standing rule, via their `autoHideTopics={false}`).
- **not-move-the-menus-on-an-intermediate-select** (v1.15.1, rebuilt v1.16.0): An INTERMEDIATE
  select MUST NOT move, resize or re-cover ANY list on screen: the clicked list stays exactly where
  it is and the new choosing list simply appears beside it (growing out of the chosen row per
  bounce-the-entrance). The stay-open MUST be STRUCTURAL, not a pointer-reveal side effect.
  The failure this forbids: the select advances the frontier, auto-hide covers every list left of
  the frontier, so the moment the new list appeared the clicked list fell behind the frontier and
  covered itself out from under the pointer. As of v1.16.0 the structure is the stored machine's
  frozen base (collapse-from-one-pointer-authority): a rail click ENGAGES at the clicked list
  (`engageOnRailClick`, capturing the resting layout if the surface was settled) and only ever
  RATCHETS the reveal root shallower — lists the user had covered stay covered
  (not-expand-parents-on-select) — while every already-on-screen column keeps painting from
  the captured lefts/covered flags/ground. Nothing the select causes (the frontier advancing, a
  level registering, pressure recomputing, the route remount — the mode lives in the surface
  store) can move a menu, because engaged geometry is read from a value no click can write.
- **draw-every-detection-frame**: With the "Show Mouse Detection Frames" debug switch on, EVERY
  region MUST be drawn — the menu region (blue) that is the single authority above, and the disclose
  (green) trigger rect — whether or not it is currently ARMED. A disarmed region MUST render dashed and
  labelled, not omitted. Measuring a rect and arming it are separate questions and MUST stay separate in
  the code: "no rect on screen" and "the rect is disarmed, so nothing can trigger it" look identical
  when the answer is to draw nothing, and the second one is the diagnosis. Omitting them is how the
  switch came to look broken — with nothing covered there was nothing to disclose, so the trigger rect
  was null and the switch drew nothing at all. (The blue region is ONE frame now, not the former
  separate "collapse" and "ground held" rects — the unification of collapse-from-one-pointer
  -authority made visible.)

### General

- **respect-reduced-motion**: All animations (disclosure, resize snap, auto-disclosure, the narrow push/pop) MUST be disabled when the user's "reduce animation" preference is set. **SUSPENDED** for both hierarchical views by a standing instruction from the block's owner to ignore `prefers-reduced-motion` until further notice — HTDV's `motion-reduce:` gates were removed so the two views cannot disagree once one flag picks between them. Restore both together when the instruction is lifted. (This is not a claim about anyone's OS configuration.)
- **source-help-from-config**: All help content (the breadcrumb help button and every detail-pane help icon) MUST come from a single unified help config owned by the consuming application, keyed by the route to the detail page + the ui element.

