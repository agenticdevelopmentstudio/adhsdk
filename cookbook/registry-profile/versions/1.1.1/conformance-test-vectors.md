
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| profile-001 | render-display-name | `entry.displayName = "Alice"` | Output contains `<h1 class="rp__name">Alice</h1>` |
| profile-002 | render-photo-when-available | `entry.photoAttachmentId = "photo-123"`, `resolveImageUrl("photo-123") = "https://cdn.example.com/photo.jpg"` | Output contains `<img class="rp__photo" src="https://cdn.example.com/photo.jpg" alt="" />` |
| profile-003 | render-photo-alt-empty | `entry.photoAttachmentId = "photo-123"`, `resolveImageUrl` returns URL | Photo element has `alt=""` (empty string) |
| profile-004 | render-summary-when-present | `entry.summary = "Software engineer"` | Output contains `<p class="rp__summary">Software engineer</p>` |
| profile-005 | render-summary-when-present | `entry.summary = ""` (empty string) | Output does not contain `rp__summary` element |
| profile-006 | render-category-when-present | `entry.category = "Engineering"` | Output contains metadata row with label "Category" and value "Engineering" |
| profile-007 | render-category-when-present | `entry.category = null` | Output does not contain category metadata row |
| profile-008 | render-location-when-present | `entry.locationText = "San Francisco"` | Output contains metadata row with label "Location" and value "San Francisco" |
| profile-009 | render-languages-list | `entry.languages = ["English", "Spanish"]` | Output contains metadata row with label "Languages" and value "English, Spanish" |
| profile-010 | render-languages-list | `entry.languages = []` | Output does not contain languages metadata row |
| profile-011 | render-keywords-list | `entry.keywords = ["react", "typescript"]` | Output contains `<li class="rp__keyword">react</li>` and `<li class="rp__keyword">typescript</li>` |
| profile-012 | render-keywords-list | `entry.keywords = []` | Output does not contain `rp__keywords` element |
| profile-013 | render-contact-affordance-conditionally | `entry.contactMode = "dm"`, `contact = <ContactButton />` | Contact container rendered with ContactButton inside |
| profile-014 | render-contact-affordance-conditionally | `entry.contactMode = "email"`, `contact = <ContactButton />` | Contact container is not rendered |
| profile-015 | render-contact-affordance-conditionally | `entry.contactMode = "dm"`, `contact = null` | Contact container is not rendered |
| profile-016 | render-all-fields | `entry.fields = [{key: "email", label: "Email", value: "alice@example.com", visibility: "public"}]` | Output contains field container with data-field-key="email" |
| profile-017 | render-field-visibility-marker | `field.visibility = "authenticated"` | Field label contains span with text "Signed-in members only" |
| profile-018 | render-field-visibility-marker | `field.visibility = "private"` | Field label contains span with text "Private" |
| profile-019 | omit-marker-for-public-fields | `field.visibility = "public"` | Field label does not contain visibility marker span |
| profile-020 | use-resolver-for-image-urls | `resolveImageUrl = (id) => (id === "photo-123" ? "https://cdn.example.com/custom.jpg" : null)`, `entry.imageUrls = { "photo-123": "https://cdn.example.com/from-map.jpg" }`, `entry.photoAttachmentId = "photo-123"` | Output contains `src="https://cdn.example.com/custom.jpg"` (the provided resolver's value), never the `entry.imageUrls` value |
| profile-021 | use-resolver-for-image-urls | `resolveImageUrl` not provided | Component falls back to `entry.imageUrls[id]` |
| profile-022 | render-as-article | any input | Root element is `<article class="rp">` |
| profile-023 | render-links-section | `entry.links = [{url: "https://example.com", label: "Portfolio"}]` | Output contains `<nav class="rp__links" aria-label="Elsewhere">` with link |
| profile-024 | render-links-with-fallback-label | `entry.links = [{url: "https://example.com", label: ""}]` | Link displays the URL as text, not the empty label |
| profile-025 | set-link-security-attributes | `entry.links = [{url: "https://example.com", label: "Site"}]` | Link has `rel="noopener noreferrer nofollow" target="_blank"` |
| profile-026 | render-service-list | `entry.services = [{title: "Consulting", description: "Advice", pricingModel: "hourly", priceMin: 100, priceMax: 100, currency: "USD", unit: "hour", deliveryMode: "virtual"}]` | Output contains a `ServiceList` section listing "Consulting" |
| profile-027 | render-service-list | `entry.services = []` | Output does not contain `rp-services` (ServiceList renders nothing for an empty array) |
| profile-028 | default-resolver-null-for-unmapped-id | `resolveImageUrl` not provided, `entry.photoAttachmentId = "missing-id"`, `entry.imageUrls = {}` | No photo element rendered; contrast with profile-021, where the ID is present in the map |
| profile-029 | accept-null-from-resolver | `resolveImageUrl = () => null`, `entry.photoAttachmentId = "photo-123"` | No photo element rendered; component does not throw or render a broken-image placeholder; contrast with profile-002, where the resolver returns a URL |
| profile-030 | render-location-when-present | `entry.locationText = ""` (empty string) | Output does not contain location metadata row |
| profile-031 | render-links-section | `entry.links = []` | Output does not contain `rp__links` element |
| profile-032 | omit-fields-section-when-empty | `entry.fields = []` | Output does not contain `rp__fields` element; contrast with profile-016, where one field is present |
| profile-033 | render-full-display-name-untruncated | `entry.displayName = "A".repeat(300)` | Output contains the full 300-character string inside `<h1 class="rp__name">`, with no truncation or ellipsis |
| profile-034 | render-metadata-list-unconditionally | `entry.category = ""`, `entry.locationText = ""`, `entry.languages = []` | Output still contains `<dl class="rp__meta">`, with no `rp__meta-row` children inside it |

