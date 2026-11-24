
`ProjectWindowKeyCommands` declares the keyboard commands of a project window,
one per shelf panel. Each command shows the shelf on that panel with the keyboard
in its filter field, or hides the shelf when that panel is already up. It is a
caseless namespace (an `enum`) on the main actor with two command ids, a section
title and a `section()` factory that returns a `KeyCommandSection` for the app's
key-command registry.

The window is resolved when a command runs, not when the section is built: the
command takes the registry's current command window (the window the keystroke
being performed was sent to, otherwise the key window, and for a child window
the window it is attached to) and acts only when that window's controller is a
project shelf window (a project window or the empty project window). That lets the
section be declared at launch, before any project window exists, and lets the
same chord also serve another window's command (the source says Command-0 may
also be the Conversations window's list), because each command declines unless a
project window is key.

The panels, the shelf and the toggle itself belong to other components
(`ProjectShelfPanel`, the shelf window and its view controller); this component
is the binding between a chord and a panel toggle.

