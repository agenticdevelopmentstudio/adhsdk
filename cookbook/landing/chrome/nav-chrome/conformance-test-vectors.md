
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| nav-001 | render-bar | Render NavChrome with default props | Bar div with className 'lp-bar' contains a button with className 'lp-burger' |
| nav-002 | render-burger, aria-expand-burger | Render with drawer closed | Burger button has aria-expanded="false" |
| nav-003 | render-burger, aria-expand-burger | Click burger to open drawer | Burger button has aria-expanded="true" |
| nav-004 | drawer-toggle-controls | Render with drawer closed, click burger | Drawer className changes to include 'lp-drawer--open' |
| nav-005 | drawer-toggle-controls | Drawer open, click burger again | No-op: drawer className still includes 'lp-drawer--open' (the burger never closes the drawer) |
| nav-006 | render-scrim, drawer-toggle-controls | Render with drawer open, click scrim | Drawer closes and scrim className no longer includes 'lp-scrim--show' |
| nav-007 | render-optional-brand | Render with brand prop | Brand content appears in bar div with className 'lp-brand' |
| nav-008 | render-optional-brand | Render with brand undefined | No 'lp-brand' div is rendered |
| nav-009 | close-on-link-click | Drawer open, click a navigation link with same-page fragment href | Drawer closes |
| nav-010 | close-on-link-click | Drawer open, click a navigation link with off-page href | Drawer closes |
| nav-011 | navigate-to-fragment-target, prevent-default-navigation-on-fragment-match | Render with link href='#section1', click link | Browser default anchor navigation is prevented; target element is located by id |
| nav-012 | move-focus-to-fragment-target | Click link href='#section1' where section1 exists | Target element receives focus; tabindex="-1" is set on target |
| nav-013 | navigate-to-fragment-target | Render with link href='#section%20one' | fragmentId() correctly decodes percent-encoding and locates element by decoded id |
| nav-014 | handle-encoded-fragments | Render with link href='#%XX' (malformed percent) | fragmentId() catches decodeURIComponent error and uses raw fragment |
| nav-015 | trap-tab-inside-drawer | Drawer open with 3 focusable elements, Tab from last element | Focus wraps to first element |
| nav-016 | trap-tab-inside-drawer | Drawer open, Shift+Tab from first element | Focus wraps to last element |
| nav-017 | trap-tab-inside-drawer | Drawer open, focus moved to the scrim (outside the drawer), press Tab | preventDefault() is called and focus moves to the first focusable element inside the drawer |
| nav-018 | close-on-escape | Drawer open, press Escape key | Drawer closes |
| nav-019 | move-focus-to-close-button | Drawer closed, click burger to open | Close button has focus immediately after open |
| nav-020 | return-focus-to-burger, drawer-toggle-controls | Drawer open, click close button or Escape to close | Focus returns to burger button |
| nav-021 | prevent-focus-steal-on-load | Render page with NavChrome | No element receives unwanted focus on initial render |
| nav-022 | set-inert-when-closed | Drawer closed | Drawer has inert={true} |
| nav-023 | set-inert-when-closed | Drawer open | Drawer has inert={false} |
| nav-024 | render-optional-footer | Render with footer prop | Footer content appears in drawer with className 'lp-foot' |
| nav-025 | render-optional-footer | Render with footer undefined | No 'lp-foot' div is rendered |
| nav-026 | set-nav-label | Render with navLabel='Main Navigation' | Nav has aria-label='Main Navigation' |
| nav-027 | dynamic-focusable-elements | Drawer open, modify focusable elements, press Tab | New focusable elements are included in Tab trap calculation |
| nav-028 | handle-empty-focusables | Render with empty links array and no footer, drawer open | Tab key does not throw error; trap simply has no elements to cycle |
| nav-029 | close-on-link-click | Click link href='/other-page' | Drawer closes; browser navigates to off-page URL |
| nav-030 | aria-hide-scrim | Drawer open | Scrim has aria-hidden="true" |
| nav-031 | fragment-focus-not-overridden-by-close-return | Drawer open, click link href='#section1' (section1 exists) | Focus moves to and stays on #section1; it is not subsequently returned to the burger button by the close→burger focus-return behavior |
| nav-032 | render-drawer | Render with links=[{ href: '#a', label: 'A' }] | Drawer (`.lp-drawer`) contains an `<a>` with text 'A' and href '#a' |

