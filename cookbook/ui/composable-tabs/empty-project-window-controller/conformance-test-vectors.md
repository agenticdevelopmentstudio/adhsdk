
No test beside the source exercises the controller (the test bundles contain no reference to it), so these vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| empty-project-window-001 | identify-window-per-group | Call `windowID(for:)` with a group whose `uuidString` is `11111111-2222-3333-4444-555555555555` | The result is `project.window.empty.11111111-2222-3333-4444-555555555555` |
| empty-project-window-002 | title-projects, window-style | Create a controller and load its window | The title is "Projects" and the style mask contains titled, closable, resizable, miniaturizable and full-size-content |
| empty-project-window-003 | default-size, persist-frame | Show a window with no saved frame and no template | The window is 800 by 500 points and centered; its frame is saved under its window id |
| empty-project-window-004 | minimum-size | Drag the window to its smallest size | The content size stops at 400 by 300 points |
| empty-project-window-005 | seamless-titlebar, disallow-tabbing | Load the window | The toolbar style is unified, the title bar is transparent, the separator style is none, the title is hidden and tabbing is disallowed |
| empty-project-window-006 | backdrop-color | Load the window, then change the theme palette | The window background equals the new palette's project pane backdrop color |
| empty-project-window-007 | blank-content-message, blank-content-accessibility-id | Show the window | The text "No project — choose one in the Project Browser." is centered and its accessibility identifier is `project.empty.message` |
| empty-project-window-008 | message-keeps-margin | Resize the window to 400 points wide | The message's leading edge stays at least 20 points from the content's leading edge |
| empty-project-window-009 | place-from-template | Set `placementTemplate` to a 1000 by 700 window, then show a window with no saved frame | The window is 1000 by 700 points and its top-left is offset from the template's top-left by one cascade step |
| empty-project-window-010 | default-placement-without-template | Show a window with no saved frame and no template | The window is placed by the spec's default, centered |
| empty-project-window-011 | toggle-shelf, shelf-toggle-appearance | Call `toggleShelf()` on a window with the shelf hidden | The shelf is visible and the toggle tooltip is "Hide Projects" |
| empty-project-window-012 | toggle-shelf, shelf-toggle-appearance | Call `toggleShelf()` again | The shelf is hidden and the toggle tooltip is "Show Projects" |
| empty-project-window-013 | show-shelf-for-choosing | Call `showShelfForChoosing()` with the shelf hidden | The browser panel is showing, the shelf is visible and, once shown, the filter field is first responder |
| empty-project-window-014 | expose-shelf-layout, land-shelf-slide | Call `landShelfSlide()` mid-slide, read `shelfLayout`, and pass it to `adoptShelfLayout(_:)` on another window | The layout holds the final width, not a half-slid width, and the other window shows the same visibility and width |
| empty-project-window-015 | toggle-shelf-panel | Call `toggleShelfPanel(_:)` with a panel while the shelf is hidden, then again with the same panel | The first call shows that panel, makes the shelf visible and focuses the filter; the second hides the shelf |
| empty-project-window-016 | refresh-toggle-on-change | Show the window, then change the shelf visibility | The toggle appearance is refreshed after each of the show and the visibility change |
| empty-project-window-017 | toolbar-content, toolbar-delegate-retained | Load the window and let every other reference to the toolbar delegate go | The toolbar still holds the shelf items followed by a flexible space and still responds to the toggle |
| empty-project-window-018 | no-coder-init | Call `init(coder:)` | The call traps with the message "init(coder:) is not supported" |

