
This component is how the user picks page items to hide. It has four
parts that work as one:

1. **The address-bar button** sits at the trailing end of the address box
   on every site, with the tooltip "Hide distracting items". It opens a
   popover anchored to it.
2. **The popover** shows, for the site showing, a checkbox **Hide
   distracting items** bound to the site switch, a button **Select
   distracting items to hide**, a divider, and the site's list of hidden
   items: each row a checkbox that enables or disables the entry and the
   entry's label, under a header with a **−** button that removes the
   selected row.
3. **Selecting mode** starts from that button. The popover closes, the
   address-bar button turns into a stop icon ("Stop selecting"), and a
   picker script, run in its own isolated content world
   (`adk-element-picker`), outlines the element under the pointer and
   swallows the page's clicks. A click posts the element's candidate
   selectors to the `adkitchenPicker` message handler. The stop button or
   Esc ends the mode.
4. **The pick dialog** is a movable modal window, opened when a pick
   arrives, while selecting mode pauses:

   ```
   ( This item | All items like it )
   [ ] Show page with selected element removed
   Remove this from view?                 [Cancel] [OK]
   ```

   The checkbox hides the chosen scope's selector live through the
   rendering component's preview rule set. OK saves an entry; Cancel saves
   nothing; either way selecting mode resumes.

Selectors come from @medv/finder (MIT, vendored as one file). **This item**
is finder's shortest unique selector for the element. **All items like it**
is a looser selector built from the element's tag and its stable-looking
class names, with random-looking classes and ids rejected, together with
how many elements it matches; it is refused as a choice when it would match
too much of the page.

The picker serves both lists. This ingredient describes it with the user list
("Hide distracting items"); the agent list's entry point and wording are
the hide-from-agent recipe's, and they reuse this component with the list
set to agent. The first time the picker is used, a one-time notice says
that items which load again, such as ads, can reappear.

