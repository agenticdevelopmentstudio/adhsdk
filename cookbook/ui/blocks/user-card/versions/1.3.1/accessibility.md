
- Root element is `<article>` with `aria-label="<displayName>'s profile"`.
  `<article>` is not one of the ARIA landmark roles (banner, complementary,
  contentinfo, form, main, navigation, region, search), so screen readers do
  not announce it as a landmark; the `aria-label` is exposed as the
  accessible name of the article element when it's reached, not as a
  landmark heading. A consumer that wants this card reachable via landmark
  navigation should add `role="region"` alongside the existing `aria-label`.
- Social links are native `<a>` elements; `rel="noopener noreferrer"` is set for
  security; they do NOT carry additional `aria-label` because the visible text
  (platform + handle) is already descriptive.
- Email links use `mailto:` scheme; phone links use `tel:` scheme — native
  controls, no custom ARIA needed (see **native-contact-links**).
- Addresses use `<address>` element with `not-italic` (the browser default
  italic style for address is suppressed via CSS).
- `UserCardSkeleton` declares `role="status" aria-busy="true"` so assistive
  technologies announce the loading state.
- All lucide icon imports carry `aria-hidden="true"` since their meaning is
  conveyed by adjacent text.
- Focus ring for interactive elements: `focus-visible:ring-2 focus-visible:ring-apt-gold/40`.

