
The closure menu item target turns closures into the target and action pair
a native macOS menu item needs. A caller that builds menu items from data,
such as a list of menu contributions, would otherwise need a separate
Objective-C action method for every feature. This component holds three
closures: the action to run, a test for whether the item is enabled, and an
optional test for whether the item is checked. It answers the menu system's
action message and its validation message from them. The host that builds the
menu keeps one target per menu item for as long as the item lives, because a
menu item does not retain its target.

