
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| element-picker-001 | pick-posts-candidates | Decode `{"kind":"pick","thisItem":"#a","allLikeIt":"div.card","allLikeItCount":3,"pageElementCount":100,"label":"div \"Hi\"","ref":null}` | A candidate with every field set as given |
| element-picker-002 | pick-without-selector-refused | Deliver a `pick` with `thisItem` null | No dialog; the pick callback is not called; a beep; state stays selecting |
| element-picker-003 | loose-selector-disabled | Candidate with `allLikeItCount` 80 and `pageElementCount` 100 | All items like it disabled, tooltip "Matches too much of the page" |
| element-picker-004 | loose-selector-disabled | Candidate with `allLikeIt` null | All items like it disabled, tooltip "No looser selector is available" |
| element-picker-005 | all-like-it-stable-classes | In a webview, pick `<div class="css-1x2y3z ad-card">` among other divs | `allLikeIt` is `div.ad-card` |
| element-picker-006 | all-like-it-stable-classes | Pick `<span id="promo" class="a8f3k2q9 x_9f8e7d">` | `allLikeIt` uses neither the id nor either class (null, or `span` alone if it differs from This item) |
| element-picker-007 | this-item-unique | Pick any element in a fixture page | `document.querySelectorAll(thisItem).length` is 1 and is the picked element |
| element-picker-008 | isolated-content-world | Start the picker; a page-world script reads `window.__adkFinder` and the picker's globals | All `undefined` |
| element-picker-009 | page-clicks-swallowed | Selecting; click a link and a button with an `onclick` | No navigation; the page handler does not run; one `pick` message |
| element-picker-010 | label-format | Pick `<div>   Sponsored stories about … (100 chars) </div>`; pick `<img alt="Logo">`; pick an empty `<hr>` | `div "Sponsored stories about …"` cut at 60 characters; `img "Logo"`; `hr` |
| element-picker-011 | stop-icon-while-selecting, select-enters-selecting-mode | Press the popover's select button | Popover closed; button symbol `stop.circle`, tooltip "Stop selecting" |
| element-picker-012 | stop-ends-selecting, escape-posts-cancel | Selecting; press Esc | State idle; button `eye.slash`, "Hide distracting items" |
| element-picker-013 | pick-pauses-and-opens-dialog, dialog-default-scope | Selecting; accepted pick | State dialog; This item chosen |
| element-picker-014 | dialog-ok-saves | On `https://example.com/a`, OK with This item `#x`, label `div "Ad"` | Store has one user entry: site `example.com/*`, selector `#x`, scope this item, label `div "Ad"`, enabled |
| element-picker-015 | dialog-cancel-saves-nothing, resume-after-dialog | Cancel the dialog | Store unchanged; state selecting |
| element-picker-016 | dialog-preview-live | Check the preview box with This item `#x`, switch to All items like it `div.ad`, then OK | Preview rule set `["#x"]`, then `["div.ad"]`, then none; the saved entry is `div.ad` |
| element-picker-017 | navigation-ends-selecting, stop-cleans-up | Open the dialog with the preview on; the pane commits a navigation | Dialog closed; nothing saved; state idle; preview rule set none; handler removed |
| element-picker-018 | popover-contents, popover-changes-apply-immediately | Two user entries on `example.com/*`; open the popover; uncheck one row | Two rows with labels; the store entry is disabled; the page shows that item again |
| element-picker-019 | popover-contents | Open the popover with no row selected; select a row; press − | − disabled, then enabled; the entry is removed |
| element-picker-020 | first-use-notice | Start selecting mode for the first time, end it, start it again | The notice once; `browser.hidden_items.notice_shown` true; no notice the second time |
| element-picker-021 | one-selecting-mode-per-pane | Start selecting twice on one pane | One picker installed; one message per click |
| element-picker-022 | list-parameter | Run the dialog with the agent list | OK writes an agent-list entry, not a user-list one |
| element-picker-023 | address-bar-button, every-button-has-tooltip | Open a pane on any site; read the address box's trailing button, then open the popover | Button id `browser.hide-items`, tooltip "Hide distracting items", opens the popover; the select button and − carry tooltips |
| element-picker-024 | popover-transient | Open the popover; click on the page | The popover closes |
| element-picker-025 | outline-under-pointer | Selecting; move the pointer from one element to another | The outline covers the first element, then the second |
| element-picker-026 | all-like-it-absent-when-same | Pick `<div class="only">`, the page's only element with that class and tag | `allLikeIt` is null |
| element-picker-027 | dialog-movable-modal | Open the dialog; drag its title bar | The dialog is its own window (not a sheet) and moves; the browser window stays put |
| element-picker-028 | hostless-page-refused | Open a `file:` page, then an `about:blank` page; read the address-bar button; call begin | The button is disabled with its tooltip kept; begin beeps and the state stays idle |
| element-picker-029 | all-like-it-needs-a-class | Candidates with `allLikeIt` `div` (count 2 of 100), and `main.page` (count 1 of 100) | Both have All items like it disabled |
| element-picker-030 | all-like-it-needs-a-class | Pick a `<div>` with no class, then the `<body>` | Neither pick carries an All items like it selector |
| element-picker-031 | popover-transient | Open the popover; the page commits a navigation | The popover closes |
| element-picker-032 | frame-click-picks-frame | Selecting on a page with an `<iframe>` in a `<div>`; click the `<div>` at the frame's centre; stop | The pick's This item matches the `<iframe>`; the frame's pointer events are `none` while selecting and restored after stop |
| element-picker-033 | this-item-not-root | Pick `<body>`, then `<html>`; deliver picks with This item `body`, `html > body` and `:root` for the user and the agent lists | No pick carries a This item selector or reaches the dialog; a beep each time; selecting continues |
