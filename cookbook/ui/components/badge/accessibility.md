
- **Role/trait**: none is set; the element is a plain `span`, so it is read as text in the document flow.
- **Label requirements**: the visible children are the accessible content. The component adds no `aria-label`; a consumer MAY pass one, because all `span` props are spread.
- **State announcements**: Not applicable: Badge has no internal state that changes.
- **Tap target**: Not applicable: Badge is not interactive, so the 44×44pt minimum does not apply.
- **Not focusable**: the element has no `tabindex` and no handlers of its own.
- **contrast**: NEEDS REVIEW: Not implemented in source. The `apt-*` tone colors are drawn at 0.6rem on whatever surface the badge sits on, and the source does not state a contrast ratio; measuring each tone token against the surfaces it is used on would settle whether WCAG 2.1 AA (4.5:1) is met.

