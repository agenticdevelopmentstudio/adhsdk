
A row of icons that picks one of several panels, drawn the way Xcode's navigator selector is: AppKit's own segmented control, a capsule track with the chosen icon on a rounded accent selection. The bar is themed from the semantic palette and sized to its icons rather than to the space it sits in. It shows a choice and reports a click; what is chosen lives with the caller, which sets `selectedID` back. A click does not move the keyboard, because the control refuses first responder, so a caller whose panel has a list to type into moves the keyboard there itself.

The source's one caller is the project shelf, which builds one item per shelf panel and gives the bar the accessibility identifier `project-shelf.panels`.

