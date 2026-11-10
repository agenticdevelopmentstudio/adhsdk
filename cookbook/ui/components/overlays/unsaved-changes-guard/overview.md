
A navigation guard that prevents accidental data loss by blocking page navigation and unload events when the guard is armed (`when` is true). It intercepts four classes of navigation: hard navigation (reload, tab close, external link), in-app anchor clicks, programmatic router navigation, and browser Back/Forward button presses. When a blocked navigation is triggered, the guard displays a confirmation modal; the user must explicitly choose to discard changes or stay on the page.

