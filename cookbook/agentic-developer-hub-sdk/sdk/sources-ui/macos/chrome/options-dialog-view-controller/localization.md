
The component hardcodes the string `"Done"` as the Done button's title. AppKit does not localize a custom `NSButton` title automatically — a title passed to `NSButton(title:target:action:)` is used verbatim, unlike a small set of system-supplied strings in certain standard dialogs. This component provides no localization hook for that string; a caller that needs a different or localized title has no exposed API to change it. Localization of the heading and row content is entirely the caller's responsibility, since both are supplied by the caller.

