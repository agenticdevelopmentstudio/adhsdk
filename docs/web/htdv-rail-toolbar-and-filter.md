# HTDV rails: the list toolbar, the filter, and category switching (web)

The web Hierarchical Topic Detail View (`@adh-sdk/ui` blocks `topic-detail.tsx`,
`hierarchical-topic-detail.tsx`, `hierarchical-menu-detail.tsx`) gives every titled
rail a **list toolbar** under its header, and the leftmost tool on it is always the
list's **filter**. This page records what that toolbar does and why it is built this
way. The native Apple HTDV is a separate implementation; see
[`../architecture/htdv.md`](../architecture/htdv.md).

The API reference is the doc comments on `TopicListSearch` and `ListToolButton` in
`packages/web/packages/ui/src/blocks/topic-detail.tsx`. This page covers the
decisions behind them.

## Category switching

Say a subtopic is open under one parent topic. Clicking a *different* topic in that
parent list now **selects it**. It used to only close the open section, so the user
had to click twice. The stack treats a click on a topic that is off the selected
path as a new selection. Only a click on the selected topic itself closes it.
Covered by `hierarchicalTopicDetail.test.tsx` and, in the admin console,
`adh-admin/src/__tests__/categorySwitch.test.tsx`.

## The list toolbar

- **Every titled, expanded rail has it**, because every list has its filter (Mike,
  2026-11-06: "always show the filter button"). An untitled or collapsed rail has
  no toolbar.
- **Order:** the filter (a magnifying glass) is always first, then `+` (the "New …"
  button), then the host's own `titleActions`, right-justified.
- The tools are icon-only `ListToolButton`s. Each one is muted gray, and gold while
  it is acting on the list. Every tool has a required `label`, because the icon is
  all a screen reader or a hovering pointer gets.
- Before this change, the list's filter lived in a page-wide strip above every rail,
  which Mike called "clunky" (2026-09-24). A field squeezed beside other tools in a
  180px rail is worse. So the filter is a button, and it pops a panel *over* the
  toolbar, the same width as the rail, with its own glass exactly where the button
  was.
- `ListHeader` is no longer recommended inside an HTDV `headerSlot`. Its filter
  would duplicate the rail's own. The adhcontent ui-showcase caption says so.

## The filter is an autocomplete

By default the rail's own rows stay whole, and typing drops a list of matching topics
under the field. Matches are on label and sublabel, with the matched letters
underlined.

| Key | Effect |
|---|---|
| Up / Down | Move the highlight, wrapping at both ends (`stepIndex(…, { wrap: true })`) |
| Return | Select the highlighted topic, dismiss the filter, and bring the topic into view |
| Escape, ✕, blur | Dismiss and select nothing |

Three modes, chosen by `TopicListSearch`:

- **Uncontrolled** (omit it, or pass `{}`): the rail holds the query and matches its
  own rows.
- **Controlled** (`query` + `onQueryChange`): the host owns the query and the
  filtering. Use it when rows match on more than they show, or the query is read
  elsewhere. A blur keeps a controlled query, because the host may be combining it
  with filters of its own. `pending: true` says the host's `items` don't reflect the
  query yet. The suggestions then show **"Searching…"** and offer nothing, so Return
  can never choose a row that matched a query the user has typed away from.
- **`live`**: this mode filters the rail's **own rows** on every keystroke, with no
  suggestion list. It is for a surface whose keys go on driving the list from the
  field, such as the feature picker (`ecosystems/FeaturePickerDialog.tsx`). The
  query outlives the panel until ✕ clears it.

A query with no matches says **"Nothing matches"** where the suggestions would
appear, rather than showing nothing.

### Suggestions inside a cascade

`hierarchical-menu-detail.tsx` (the HMDV cascade) clips its menus. The suggestion
list fits and scrolls inside the clipped menu instead of being cut off. Suggestions
size their icons and grow for touch the same way rows do (`touchRows.test.tsx`).

## Auto-fit

A rail sizes itself to its content. The measurement now includes the **toolbar's
tools** (filter, `+`, `titleActions`), so a narrow list never clips its own buttons.
While a query has narrowed the rows, the rail **holds its width**. Otherwise a rail
would shrink to the few matches and then fail to grow back.

## Unsaved-changes guard

`ui/src/components/unsaved-changes-guard.tsx` used to leave a confirm unsettled when
a second confirm replaced it, for example when Back was pressed while the first was
up. The caller's rollback never ran, and the admin console opened a category the user
never reached. A replaced confirm now **settles as Stay** (`unsavedChangesGuard.test.tsx`).
`adh-admin`'s `adminTopics.ts` relies on that settle to undo the category choice.

## Consumers updated with this change

These hosts moved to the rail's own filter, or to the controlled/`live` modes:

- `resource/resource-explorer.tsx` (controlled, with `pending`)
- `features/research/ResearchPane.tsx`
- `features/notebook/NotebookPane.tsx`
- `features/ecosystems/FeaturePickerDialog.tsx` (`live`)
- `features/adh-admin`

## Provenance

- adhsdk PR #39 (branch `htdv-fixes`, merged without squash), range
  `8a439903a..e1f13eb96` on main.
- Code review `2026-11-06-live-claude-default-3dbf` (`/code-review max`, 15
  findings, each fixed in its own commit with a `Review-Finding` trailer).
- Peer repos re-pointed at that main: adhcontent PR #390 (the ui-showcase caption),
  statussite PR #27 and buildersite PR #6 (`websites/external/adhsdk` gitlink bumps
  and re-vendors), and adhubwebsite (gitlink bump on its `htdv-fixes` branch).
