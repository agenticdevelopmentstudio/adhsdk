
- **Reduce Motion**: Not applicable. Dialog appears immediately without fade-in or transition. If `prefers-reduced-motion` is desired, CSS media query can suppress animations. Component itself does not check the setting.
- **Increase Contrast**: Not applicable. Text color and background contrast are stylesheet-driven. Component does not expose a contrast mode setting. Stylesheet can provide high-contrast variant via CSS media query or theme class.
- **Differentiate Without Color**: Visual distinction of the selected result is CSS-driven, via the `awt-search-dialog__result--selected` class, and may rely on color alone in the current stylesheet. The component does not implement a non-color marker itself. Stylesheet SHOULD add a non-color indicator (for example, a border or a checkmark) so the selected result stays visible without relying on color perception.

