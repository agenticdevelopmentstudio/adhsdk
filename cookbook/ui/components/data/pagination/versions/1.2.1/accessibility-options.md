
The component uses semantic `nav` and `button` elements with standard focus and
keyboard interaction. It does not apply transitions, transforms, or animations, so
there is nothing for Reduce Motion to affect. It does not use color alone to convey
state (disabled buttons use the native `disabled` attribute, not color). Contrast and
Dynamic Type are both inherited: the component sets no font size or color itself
beyond the muted-caption text token, so contrast comes from that token and from the
family `Button`'s styling, and text scaling comes from the browser/OS text-size
setting acting on that same inherited styling.

