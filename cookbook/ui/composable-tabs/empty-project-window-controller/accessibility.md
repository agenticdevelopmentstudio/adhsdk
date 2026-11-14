
- **Role/trait**: The toggle is a standard button in the window toolbar; the message is a themed text label.
- **Label requirements**: The message carries the accessibility identifier `project.empty.message`. The toggle uses the tooltips "Show Projects" and "Hide Projects", set by the shared disclosure appearance helper.
- **Announce state changes**: NEEDS REVIEW: Not implemented in source. The shared disclosure helper keeps the toggle's accessible name stable (the image's accessibility description set from the toolbar item's label) and changes only the tooltip, tint and symbol with the shelf's visibility; neither it nor this controller sets an accessibility value that follows the shelf. A VoiceOver pass over the toggle in both states would settle whether the tooltip change is announced.
- **Minimum tap target**: Not specified by this controller; the toggle's size comes from the shared toolbar builder.

