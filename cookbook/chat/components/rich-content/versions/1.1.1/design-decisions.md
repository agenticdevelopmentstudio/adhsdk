
**Decision**: Only `http:`, `https:`, `mailto:`, and `tel:` schemes are accepted as link hrefs; every other scheme (`javascript:`, `data:`, `vbscript:`, and any custom scheme) is rejected unconditionally.
**Rationale**: These four schemes perform navigational actions or invoke system services, while the rejected schemes can execute arbitrary code in the page's security context. This mitigates script-execution attacks (such as XSS) that could be delivered through attacker-controlled or prompt-injected link data — it does not mitigate prompt injection itself, which is the delivery mechanism, not the vulnerability this filter closes. This is a security requirement, not a feature choice.
**Approved**: pending

**Decision**: Images are hidden (`display: none`) until their `onLoad` event fires, then revealed.
**Rationale**: Prevents an incomplete or default broken-image placeholder from flashing on screen before the real image is ready. This is not lazy loading (`loading="lazy"`) and does not delay or prevent the underlying network fetch — the image request starts immediately regardless of visibility, so hiding it has no bearing on whether a malicious or oversized response is fetched.
**Approved**: pending

**Decision**: On an image load error, the hidden style is removed the same way as on success ("fail open"), rather than leaving the space collapsed indefinitely.
**Rationale**: A permanently collapsed, invisible image looks like a rendering bug rather than a handled failure. Revealing the element (which shows the browser's default broken-image indicator) makes the failure visible instead of silent. Because no width/height is reserved while hidden, this reveal can itself shift the surrounding layout — the component does not attempt to preserve the exact footprint a successfully loaded image would have occupied.
**Approved**: pending

**Decision**: Links always open in a new browsing context — a new tab/window on web (`target="_blank" rel="noopener noreferrer"`), the system browser or registered handler on native platforms — never in-app or inline navigation.
**Rationale**: Keeps the hosting application's state intact when the user follows an external link. `noopener noreferrer` additionally prevents the linked page from reaching back into the opener's `window` object or reading the referrer header.
**Approved**: pending

**Decision**: Content items with an unrecognized `type` are silently skipped and render nothing.
**Rationale**: Lets the component tolerate schema evolution — new item types introduced by the data source before this component is updated — without throwing or breaking the rendering of sibling items.
**Approved**: pending

**Decision**: Every content-item field (`url`, `src`, `label`, `alt`) is treated as coming from the same untrusted source, with no field singled out as more trustworthy than another.
**Rationale**: The component applies no sanitization beyond the link-protocol allowlist and the rendering framework's standard attribute encoding; every field is rendered only as inert text or an attribute value, or fetched as an image, never interpreted as markup or executable code. Treating one field (such as alt text) as an exception would contradict the Overview's own untrusted-origin framing without changing what the component actually does.
**Approved**: pending

