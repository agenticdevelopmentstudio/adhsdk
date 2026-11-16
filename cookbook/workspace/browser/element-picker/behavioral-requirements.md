
- **address-bar-button**: Every browser pane MUST show a button at the
  trailing end of the address box, on every site, with the tooltip "Hide
  distracting items" and the accessibility identifier `browser.hide-items`;
  clicking it while not selecting MUST open the hidden-items popover
  anchored to it.
- **popover-contents**: The popover MUST show, in order: a checkbox "Hide
  distracting items" bound to the user list's site switch for the page's
  default site pattern; a button "Select distracting items to hide"; a
  divider; and a table of the user list's items for the page, each row a
  checkbox showing and setting the enabled state of the entry its row
  holds when it is clicked (a reload since the row was made may have
  reordered the list), and the entry's label; with a header **−** button (tooltip "Remove Selected Item") that
  removes the selected row and is disabled when no row is selected.
- **popover-changes-apply-immediately**: Toggling the site checkbox or a
  row's checkbox, or removing a row, MUST write the change to the
  hidden-items store at once, so the page re-renders without a reload.
- **popover-transient**: The popover MUST close when the user clicks
  outside it, and MUST close when the pane commits a navigation, the front
  page changes, the tab switches or the pane is discarded, since the site
  it lists and switches may no longer be the one showing.
- **hostless-page-refused**: On a page with no host (`file:`, `about:`,
  `data:`, or no address), whose default site pattern is `*`, the
  address-bar button MUST be disabled, keeping its tooltip, except as the
  stop control of a selecting mode already running; starting selecting
  mode there MUST beep and start nothing, and a pick whose page has no
  host MUST NOT be saved (logged, with a beep), so no entry is ever saved
  for every site.
- **select-enters-selecting-mode**: The popover's select button MUST close
  the popover and start selecting mode on that pane.
- **stop-icon-while-selecting**: While selecting, the address-bar button
  MUST show a stop icon with the tooltip "Stop selecting", and MUST show
  its normal icon and tooltip again when selecting ends.
- **stop-ends-selecting**: Clicking the stop button, or pressing Esc while
  selecting, MUST end selecting mode.
- **isolated-content-world**: The picker script and the vendored finder
  MUST run in a content world of their own named `adk-element-picker`,
  never the page's world or the automation world, so the page's scripts
  cannot see, call or replace them.
- **outline-under-pointer**: While selecting, the element under the
  pointer MUST be outlined, and the outline MUST follow the pointer.
- **page-clicks-swallowed**: While selecting, a click on the page MUST NOT
  reach the page: no link is followed, no button acts, no page handler
  runs for it.
- **pick-posts-candidates**: A click while selecting MUST post one message
  to the handler named `adkitchenPicker`, of kind `pick`, carrying the
  This item selector, the All items like it selector, the number of
  elements the looser selector matches, the number of elements on the
  page, the label, and the element's reference when it has one.
- **escape-posts-cancel**: Esc pressed in the page while selecting MUST post
  a message of kind `cancel`, which ends selecting mode as the stop button
  does.
- **this-item-unique**: The This item selector MUST match exactly one
  element in the page at pick time, the picked one.
- **this-item-not-root**: A pick of the page's root, its `html`, `head` or
  `body` element, MUST carry no This item selector, and a This item
  selector that names only them (`body`, `html > body`, `:root`) MUST be
  refused, for both the distracting-items and the hide-from-agent lists:
  a click on blank space beside a layout hits `<body>`, and saving it
  would hide the whole page. The pick is refused as
  `pick-without-selector-refused` says.
- **all-like-it-stable-classes**: The All items like it selector MUST be
  built from the element's tag and class names only, MUST NOT use ids, and
  MUST NOT use any class name that looks generated: one containing three
  or more digits in a row, one made of six or more letters and digits
  only, one with a `-` or `_` followed by five or more hexadecimal
  characters, or one with a `-` or `_` followed by five or more letters and
  digits that mix both (a CSS-in-JS hash such as `css-1x2y3z`).
- **all-like-it-needs-a-class**: The All items like it selector MUST name
  at least one class: an element with no stable class gets no looser
  selector, since a bare tag such as `div` would hide most of a site. It
  MUST NOT be built for the page's frame, an `html`, `head`, `body` or
  `main` element.
- **all-like-it-absent-when-same**: When the looser selector is the same as
  the This item selector (the same text, or it matches only the picked
  element), or cannot be computed, the pick MUST carry no All items like it
  selector.
- **pick-without-selector-refused**: A pick with no This item selector
  (finder failed or threw, for instance inside a shadow root or an SVG
  `use`) MUST be refused with a beep: no dialog opens and selecting mode
  continues.
- **frame-click-picks-frame**: While selecting, every `iframe` and `frame`
  element MUST take no pointer events, so a click over a frame never
  reaches the frame's document (an ad served in a frame never opens its
  link). That click, and the outline under the pointer, MUST resolve to the
  frame element itself in the main document; `stop` MUST give the frames
  their pointer events back.
- **loose-selector-disabled**: The All items like it choice MUST be
  disabled when there is no looser selector, with the tooltip "No looser
  selector is available", and when it matches more than half of the
  page's elements, has no class, or is for an `html`, `head`, `body` or
  `main` element, with the tooltip "Matches too much of the page".
- **label-format**: The label MUST be the element's lowercase tag name, a
  space, and the first 60 characters of its trimmed text in double quotes,
  where the text is the element's visible text, else its `alt`, else its
  `aria-label`; an element with none of them gets the tag name alone.
- **pick-pauses-and-opens-dialog**: An accepted pick MUST pause selecting
  mode (no outline, no further picks) and open the pick dialog for it.
- **dialog-movable-modal**: The pick dialog MUST be a modal window of its
  own that the user can drag off the page, not a sheet attached to the
  window.
- **dialog-default-scope**: The dialog MUST open with This item chosen.
- **dialog-preview-live**: The "Show page with selected element removed"
  checkbox MUST, while on, hide the currently chosen scope's selector on
  the live page through the preview rule set, MUST follow a change of
  scope at once, and MUST be cleared when the dialog closes, however it
  closes.
- **dialog-ok-saves**: OK MUST add one entry to the picker's list with the
  chosen scope's selector, that scope, the pick's label, enabled, and the
  site pattern derived from the page's address by the shared default rule.
  A save the store refuses MUST be logged and beep.
- **dialog-cancel-saves-nothing**: Cancel, or Esc in the dialog, MUST save
  nothing.
- **resume-after-dialog**: After OK or Cancel, selecting mode MUST resume
  on the same page, so the user can pick another item.
- **navigation-ends-selecting**: A committed navigation, a tab switch, or
  closing the tab or pane while selecting or while the dialog is open MUST
  end selecting mode, close the dialog without saving, clear the preview
  rule set, and remove the picker's outline, listeners and message handler.
- **stop-cleans-up**: Ending selecting mode for any reason MUST remove the
  outline and the picker's listeners from the page, remove the
  `adkitchenPicker` handler, and clear the preview rule set, leaving the
  page as it was before selecting began apart from saved entries.
- **one-selecting-mode-per-pane**: Each pane MUST own at most one selecting
  mode at a time; starting it again while it runs MUST NOT install a
  second picker.
- **first-use-notice**: The first time selecting mode starts, the picker
  MUST show a one-time informational notice "Items that load again (such as
  ads) can reappear.", and MUST record that it was shown in the global
  setting `browser.hidden_items.notice_shown` so it never shows again.
- **list-parameter**: The popover, selecting mode and dialog MUST take the
  list they write to as a parameter, so the same component serves the user
  list and the agent list; with the user list they use the wording given
  here.
- **every-button-has-tooltip**: Every button this component adds (address
  bar button, popover select button, header −) MUST carry a tooltip.

