---
id: 6579e030-0455-453c-81cf-177dae3dd82e
title: "Field Value"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Displays field values in their appropriate format based on type, rendering URLs, images, addresses, and text content safely."
platforms:
  - typescript
  - web
tags:
  - display
  - field-rendering
  - data-presentation
depends-on: []
related:
  - 6c034a7a-3a43-4da6-bc1a-0cbc39f32cc4
  - fe09968a-6575-40d0-b0b8-af6ce52d8efd
references: []
approved-by: ""
approved-date: ""
---

# Field Value

## Overview

FieldValue is a presentational component that renders a field's value in the appropriate format based on its type. It handles multiple field types including text, email, phone, URL, image, address, date, select, boolean, multi-select, markdown, and textarea. The component is designed for displaying registry profile data and uses the optional `resolveImageUrl` prop to convert attachment IDs to URLs, returning nothing when values are empty or unresolvable.

## Behavioral Requirements

- **render-by-type**: Component MUST render different markup for each supported field type: text, date, select, email, phone, url, boolean, multi_select, image, address, markdown, textarea.
- **empty-text-renders-nothing**: Component MUST render nothing when type is text, date, select, or the default case and the value is empty (after converting to a display string).
- **empty-multi-select-renders-nothing**: Component MUST render nothing when type is multi_select and the value is not a non-empty list.
- **empty-address-renders-nothing**: Component MUST render nothing when type is address and all address parts (line1, line2, city, region, postalCode, country) are empty or absent.
- **url-as-link**: Component MUST render type url as an `<a>` element with href set to the value, with class rp-field__link.
- **url-protocol-stripped**: Component MUST display the URL text with the leading protocol (http:// or https://) removed.
- **url-security-attributes**: Component MUST set rel="noopener noreferrer nofollow" and target="_blank" on URL links.
- **email-as-text**: Component MUST render type email as plain text in a span with class rp-field__text, never as a mailto link, regardless of value visibility settings.
- **phone-as-text**: Component MUST render type phone as plain text in a span with class rp-field__text, never as a tel link.
- **empty-email-or-phone-renders-empty-span**: Component MUST render an empty span with class rp-field__text (not nothing) when type is email or phone and the value is empty — unlike text/date/select/default, which render nothing for an empty value.
- **boolean-as-yes-no**: Component MUST render type boolean as "Yes" when the value is truthy and "No" when it is falsy (including an absent value), in a span with class rp-field__text. This is a truthiness test, not a strict boolean check: a truthy non-boolean value such as the string "false" still renders "Yes".
- **multi-select-as-list**: Component MUST render type multi_select as an unordered list with class rp-field__tags containing list items with class rp-field__tag.
- **multi-select-items-stringified**: Component MUST convert each multi_select item to a display string before rendering.
- **image-resolver-used**: Component MUST use the resolveImageUrl prop, when provided, to convert an image attachment ID into a URL.
- **unresolvable-image-renders-nothing**: Component MUST render nothing (not a broken-image placeholder) when the image ID is empty, resolveImageUrl is absent, or resolveImageUrl returns null.
- **image-alt-text**: Component MUST render type image as an img element with src from resolveImageUrl and alt set to field.label.
- **image-class**: Component MUST render the image with class rp-field__image.
- **address-comma-separated**: Component MUST render type address by joining all non-empty address parts (line1, line2, city, region, postalCode, country) with ", ".
- **address-value-as-object**: Component MUST accept the address value as an object with keys line1, line2, city, region, postalCode, country, treating a non-object value as an empty object.
- **markdown-as-text**: Component MUST render type markdown as pre-wrapped text in a paragraph with class rp-field__prose, never as HTML.
- **textarea-as-text**: Component MUST render type textarea as pre-wrapped text in a paragraph with class rp-field__prose, never as HTML.
- **delivery-label-lookup**: Component MUST apply the DELIVERY_LABEL mapping (in_person → "In person", virtual → "Virtual", hybrid → "In person or virtual") to text, date, select, and default types before rendering.
- **unmapped-values-as-is**: Component MUST render the original value as display text if it is not found in the DELIVERY_LABEL mapping.
- **rp-field-text-class**: Component MUST use class rp-field__text for text, email, phone, boolean, and address field types.
- **value-stringified**: Component MUST convert all non-address values to a display string before rendering.
- **nullish-values-as-empty-string**: Component MUST treat an absent (null or undefined) value as an empty string wherever a display string is produced (text, date, select, default, email, phone, url, image, markdown, textarea); boolean and multi_select have their own absent-value handling (see **boolean-as-yes-no** and **empty-multi-select-renders-nothing**).

## Appearance

- **Container**: No container styling applied by component; styling delegated to parent or CSS classes.
- **Text rendering**: Text fields use class rp-field__text for styling.
- **Link rendering**: URL fields use class rp-field__link for styling, displayed as clickable text without visible protocol.
- **List rendering**: multi_select renders as unordered list with rp-field__tags (ul) and rp-field__tag (li) classes.
- **Prose rendering**: markdown and textarea render in paragraph elements with class rp-field__prose, preserving whitespace.
- **Image rendering**: Images use class rp-field__image with alt text from field.label.

## States

| State | Appearance change |
|-------|------------------|
| Rendered (value present) | Field markup displays based on type |
| Empty (no value or empty array) | Component returns nothing; no markup rendered |
| Unresolvable (image ID cannot be resolved) | Component returns nothing; no broken-image indicator shown |

## Accessibility

- Role/trait: Component is a display element, not interactive. Links for URLs are standard, keyboard-accessible `<a>` elements; opening in a new tab via target="_blank" is not itself announced to screen readers (see **url-security-attributes**).
- Label requirements: Image elements use field.label as alt text for screen reader context.
- Text content: All text content is available to assistive technologies; HTML markup in markdown/textarea is rendered as plain text to prevent content injection.
- No interactive controls: Component contains no buttons, form inputs, or keyboard-navigable elements in the default case (URL links are standard navigable elements).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| field-value-001 | url-as-link, url-protocol-stripped, url-security-attributes | `{ type: 'url', value: 'https://example.com', label: 'Website' }` | `<a class="rp-field__link" href="https://example.com" rel="noopener noreferrer nofollow" target="_blank">example.com</a>` |
| field-value-002 | empty-text-renders-nothing | `{ type: 'text', value: '', label: 'Name' }` | `null` |
| field-value-003 | email-as-text | `{ type: 'email', value: 'user@example.com', label: 'Email' }` | `<span class="rp-field__text">user@example.com</span>` |
| field-value-004 | phone-as-text | `{ type: 'phone', value: '+1-555-1234', label: 'Phone' }` | `<span class="rp-field__text">+1-555-1234</span>` |
| field-value-005 | boolean-as-yes-no | `{ type: 'boolean', value: true, label: 'Active' }` | `<span class="rp-field__text">Yes</span>` |
| field-value-006 | boolean-as-yes-no | `{ type: 'boolean', value: false, label: 'Active' }` | `<span class="rp-field__text">No</span>` |
| field-value-007 | multi-select-as-list, multi-select-items-stringified | `{ type: 'multi_select', value: ['Option A', 'Option B'], label: 'Tags' }` | `<ul class="rp-field__tags"><li class="rp-field__tag">Option A</li><li class="rp-field__tag">Option B</li></ul>` |
| field-value-008 | empty-multi-select-renders-nothing | `{ type: 'multi_select', value: [], label: 'Tags' }` | `null` |
| field-value-009 | image-resolver-used, image-alt-text, image-class | `{ type: 'image', value: 'attachment-123', label: 'Profile Photo' }`, resolveImageUrl returns 'https://cdn.example.com/img/attachment-123.jpg' | `<img class="rp-field__image" src="https://cdn.example.com/img/attachment-123.jpg" alt="Profile Photo" />` |
| field-value-010 | unresolvable-image-renders-nothing | `{ type: 'image', value: 'missing-id', label: 'Photo' }`, resolveImageUrl returns null | `null` |
| field-value-011 | address-comma-separated, address-value-as-object | `{ type: 'address', value: { line1: '123 Main St', city: 'Springfield', country: 'USA' }, label: 'Address' }` | `<span class="rp-field__text">123 Main St, Springfield, USA</span>` |
| field-value-012 | empty-address-renders-nothing | `{ type: 'address', value: { line1: '', line2: '', city: '', region: '', postalCode: '', country: '' }, label: 'Address' }` | `null` |
| field-value-013 | markdown-as-text | `{ type: 'markdown', value: '# Hello\nWorld', label: 'Bio' }` | `<p class="rp-field__prose"># Hello\nWorld</p>` |
| field-value-014 | textarea-as-text | `{ type: 'textarea', value: 'Line 1\nLine 2', label: 'Notes' }` | `<p class="rp-field__prose">Line 1\nLine 2</p>` |
| field-value-015 | delivery-label-lookup | `{ type: 'text', value: 'in_person', label: 'Delivery' }` | `<span class="rp-field__text">In person</span>` |
| field-value-016 | delivery-label-lookup, unmapped-values-as-is | `{ type: 'text', value: 'custom-value', label: 'Delivery' }` | `<span class="rp-field__text">custom-value</span>` |
| field-value-017 | nullish-values-as-empty-string | `{ type: 'text', value: null, label: 'Optional' }` | `null` |
| field-value-018 | nullish-values-as-empty-string | `{ type: 'text', value: undefined, label: 'Optional' }` | `null` |
| field-value-019 | render-by-type, unmapped-values-as-is | `{ type: 'date', value: '2026-01-15', label: 'Start Date' }` | `<span class="rp-field__text">2026-01-15</span>` |
| field-value-020 | render-by-type, unmapped-values-as-is | `{ type: 'select', value: 'option-a', label: 'Status' }` | `<span class="rp-field__text">option-a</span>` |
| field-value-021 | url-protocol-stripped | `{ type: 'url', value: 'http://example.com', label: 'Website' }` | `<a class="rp-field__link" href="http://example.com" rel="noopener noreferrer nofollow" target="_blank">example.com</a>` |
| field-value-022 | url-as-link | `{ type: 'url', value: 'example.com/path', label: 'Website' }` | `<a class="rp-field__link" href="example.com/path" rel="noopener noreferrer nofollow" target="_blank">example.com/path</a>` |
| field-value-023 | image-resolver-used, unresolvable-image-renders-nothing | `{ type: 'image', value: 'attachment-1', label: 'Photo' }`, resolveImageUrl not provided | `null` |
| field-value-024 | address-comma-separated | `{ type: 'address', value: { line1: '123 Main St', region: 'CA', postalCode: '90210' }, label: 'Address' }` | `<span class="rp-field__text">123 Main St, CA, 90210</span>` |
| field-value-025 | empty-email-or-phone-renders-empty-span | `{ type: 'email', value: '', label: 'Email' }` | `<span class="rp-field__text"></span>` |
| field-value-026 | empty-email-or-phone-renders-empty-span | `{ type: 'phone', value: null, label: 'Phone' }` | `<span class="rp-field__text"></span>` |
| field-value-027 | markdown-as-text | `{ type: 'markdown', value: '<script>alert(1)</script>', label: 'Bio' }` | `<p class="rp-field__prose">&lt;script&gt;alert(1)&lt;/script&gt;</p>` |
| field-value-028 | boolean-as-yes-no | `{ type: 'boolean', value: 'false', label: 'Active' }` | `<span class="rp-field__text">Yes</span>` |
| field-value-029 | boolean-as-yes-no | `{ type: 'boolean', value: null, label: 'Active' }` | `<span class="rp-field__text">No</span>` |
| field-value-030 | url-as-link | `{ type: 'url', value: 'javascript:alert(1)', label: 'Website' }` | `<a class="rp-field__link" href="javascript:throw new Error('React has blocked a javascript: URL as a security precaution.')" rel="noopener noreferrer nofollow" target="_blank">javascript:alert(1)</a>` |

## Edge Cases

- **Empty value for any type**: When value is empty string, null, or undefined, the component returns nothing for text, date, select, multi_select, address, and the default case; email and phone are the exception, rendering an empty `<span class="rp-field__text"></span>` instead (see **empty-email-or-phone-renders-empty-span**).
- **Non-array value for multi_select**: If value is not an array, it is coerced to an empty array, resulting in null render.
- **Invalid image resolver result**: When resolveImageUrl is provided but returns null, the component renders nothing rather than a broken image.
- **Address as non-object**: If address value is not an object or is null, it defaults to an empty object, resulting in null render.
- **Null resolveImageUrl prop**: When resolveImageUrl prop is not provided, unresolvable IDs are handled using optional chaining (`resolveImageUrl?.(id) ?? null`), resulting in null render.
- **URL with no protocol**: When URL value has no http:// or https:// prefix, the full URL is displayed as-is.
- **Whitespace in multi_select items**: Array items are converted to strings but not trimmed; leading/trailing whitespace is preserved.
- **Non-boolean truthy value for boolean type**: A truthy non-boolean value (for example, the string "false") renders "Yes" because the component performs a truthiness check, not a strict boolean comparison; see **boolean-as-yes-no**.
- **Null or undefined boolean value**: Renders "No" because null and undefined are falsy in the truthiness check.
- **Markdown or textarea containing HTML or script markup**: Rendered as literal, escaped text and never executed, because the component places the string as JSX text content rather than parsing or injecting it as HTML; see **markdown-as-text** and **textarea-as-text**.
- **URL value with a non-http(s) scheme**: The `href` prop is set directly from the value with no scheme check in the component's own code; the component does not validate or restrict the URL scheme, and its protocol prefix is untouched by the http(s) stripping in **url-protocol-stripped**. For most non-http(s) schemes this renders a clickable link with that value verbatim. A `javascript:` value is the one case that renders differently: React 19's `sanitizeURL` intercepts every `javascript:`-scheme `href`/`src`/`action`/`formAction` prop at render time and replaces it with a throwing stub (`javascript:throw new Error('React has blocked a javascript: URL as a security precaution.')`), regardless of what FieldValue itself does — see `field-value-030`. A non-React port has no equivalent sanitizer and would need one to avoid emitting a live `javascript:` link built from untrusted registry data.

## Configuration

Not applicable: FieldValue is a presentational component with no configuration options.

## Deep Linking

Not applicable: FieldValue is a display component with no deep linking behavior.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| delivery.in_person | "In person" | DELIVERY_LABEL mapping for in_person field value |
| delivery.virtual | "Virtual" | DELIVERY_LABEL mapping for virtual field value |
| delivery.hybrid | "In person or virtual" | DELIVERY_LABEL mapping for hybrid field value |
| boolean.yes | "Yes" | Boolean true rendering |
| boolean.no | "No" | Boolean false rendering |

## Accessibility Options

Not applicable: FieldValue responds to no platform accessibility display options as it is a static display component with no interactive states or dynamic rendering modes.

## Feature Flags

Not applicable: FieldValue has no feature flag configuration.

## Analytics

Not applicable: FieldValue is a display component with no user interaction and does not emit analytics events.

## Privacy

- **Data collected**: No data is collected by this component.
- **Storage**: No data is stored.
- **Transmission**: Image URLs are transmitted to CDN endpoints via img src attribute; all other data is rendered inline and not transmitted.
- **Retention**: No data retention; rendering is ephemeral per page load.

## Logging

Not applicable: FieldValue performs no logging.

## Platform Notes

- **React/Web**: Source file is `packages/web/packages/registry-profile/src/FieldValue.tsx`. Uses React with className binding for CSS styling; CSS classes (rp-field__link, rp-field__text, rp-field__tags, rp-field__tag, rp-field__image, rp-field__prose) are applied based on field type. Implements the "empty" and "unresolvable" checks in **empty-text-renders-nothing**, **empty-email-or-phone-renders-empty-span**, and **unresolvable-image-renders-nothing** with JavaScript's nullish coalescing (`??`) and optional chaining (`?.`) operators, and produces display strings with `String()`. The `resolveImageUrl` prop accepts an optional resolver; URL security is enforced with the `rel`/`target` attributes named in **url-security-attributes**.

- **SwiftUI**: Implement as a container view that accepts a `PublicField` and optional image URL resolver. Use a switch statement on `field.type` to render the corresponding SwiftUI view (Text, Link, List, AsyncImage, etc.). For URLs, use `Link(destination:)`; SwiftUI has no direct equivalent to the `rel`/`target` attributes in **url-security-attributes**, since the system's default URL handler owns new-window/tab behavior. For images, load asynchronously via the resolver and render nothing when it returns nil, matching **unresolvable-image-renders-nothing**. Use SwiftUI's native text styling for text types, and layout containers such as `VStack`/`HStack` for address and multi_select lists.

- **Compose**: Implement as a composable function accepting field and a resolveImageUrl lambda. Use a when-expression to branch on field type. Render text types as `Text`. Render URLs as `Text` with a `LinkAnnotation.Url` annotation (`ClickableText` is deprecated) so the link opens the system browser. Render images with `AsyncImage` (Coil) and set the content description from field.label. Render address and multi_select as `Column`/`Row` layouts. Render markdown and textarea as selectable `Text` to avoid unwanted formatting.

- **AppKit / UIKit**: Implement as a view (a display-only component needs no view controller) that configures `NSTextField`/`UILabel`, or `NSImageView`/`UIImageView`, based on field type. For URLs, use an `NSAttributedString`/`NSMutableAttributedString` with a `.link` attribute (`NSAttributedString.Key.link`) and open it via the default browser. For images, load asynchronously via the provided resolver callback. Use Auto Layout for flexible sizing. Handle empty or unresolvable values by hiding or removing the view, matching **empty-text-renders-nothing** and **unresolvable-image-renders-nothing**. Set accessibility labels and traits (link, image) appropriate to each field type.

- **WinUI 3**: Implement as a user control or data template that branches on field.type using XAML data-template selectors or code-behind switch logic. Use `TextBlock` with `TextWrapping="Wrap"` for text types, never `TextTrimming`, which would cut off longer values. Use `Hyperlink.NavigateUri`, or call `Launcher.LaunchUriAsync` from code-behind, to open URLs externally. Use an `Image` control with an async image-source converter for images. Use `ItemsRepeater` or `ListView` for multi_select. Use a plain `TextBlock` with `TextWrapping="Wrap"` for markdown/textarea to display pre-wrapped plain text without HTML parsing — a `RichTextBlock` is unnecessary since no rich formatting is ever rendered. Bind alt text and link attributes to the appropriate control properties.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/registry-profile/src/FieldValue.tsx` | unverified |

## Design Decisions

**Decision**: Return null (render nothing) rather than an empty container when a value is empty, for every type except email and phone (see **empty-email-or-phone-renders-empty-span**).
**Rationale**: An empty profile with missing pictures and unfilled fields reads better than one with visible placeholder UI. Absence of data is cleaner than attempting to gracefully degrade rendering.
**Approved**: pending

**Decision**: Render email and phone as plain text, never as `mailto:`/`tel:` links (see **email-as-text**, **phone-as-text**).
**Rationale**: Whether the value reaches the client at all is a visibility decision made server-side — these types start private, so publishing one is a choice. What a published value becomes in the markup is a separate, client-side question, and the answer is plain text: a linkified address is the one a scraper finds by selector rather than by parsing prose.
**Approved**: pending

**Decision**: Render markdown and textarea as pre-wrapped plain text, never as HTML (see **markdown-as-text**, **textarea-as-text**).
**Rationale**: The component runs on untrusted sites the registry does not control, and safe markdown-to-HTML conversion cannot be guaranteed in that context, so the conservative choice is to render all markup as literal text.
**Approved**: pending

**Decision**: Hardcode the DELIVERY_LABEL mapping in the component rather than accepting it as a prop (see **delivery-label-lookup**).
**Rationale**: It is a fixed enumeration tied to one registry field's semantics ("delivery mode"), not a generic labeling mechanism — a semantic transformation specific to this component's domain rather than a configuration point. The strings it produces ("In person", "Virtual", "In person or virtual") are still user-facing text, so they are catalogued in the Localization table like any other user-facing string this component renders.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

These statuses rest on `FieldValue.tsx`: it sets `href` directly from the value with no scheme check (input-sanitization partial, see **url-as-link**); it renders semantic `<a>`, `<ul>`/`<li>`, and `<img>` elements with `alt` text from `field.label` (screen-reader-support, keyboard-navigable, semantic-markup), but applies no inline color or font size of its own, leaving contrast and dynamic type up to CSS classes this file does not define (both partial); and it hardcodes the `DELIVERY_LABEL` strings and "Yes"/"No" in source rather than reading them from a resource file, while the `date` type is displayed through raw `String()` coercion with no locale-aware formatting (string-externalization, no-hardcoded-strings, and locale-aware-formatting all failed), with Unicode text otherwise passed through untouched by any of the component's `String()` conversions (unicode-support passed). `separation-of-concerns` passes because `FieldValue.tsx` is a single presentational component with no fetching, sanitization, or state logic of its own — it only switches on `field.type` and renders. `unit-test-coverage` is `partial`: there is no dedicated `FieldValue.test.tsx`, but `RegistryProfile.test.tsx` renders real `url`, `boolean`, `multi_select`, `email`, and `phone` fields through `FieldValue` and asserts on its actual output (link `href`, plain-text email/phone, "Yes"/"No"); the `date`, `image`, and `select` type branches are not exercised by any test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed field-value-030 and non-http(s)-scheme edge case: React 19 sanitizes javascript: hrefs. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, added a new empty-email-or-phone requirement and boolean-truthiness clarification, linked related registry-profile and service-list recipes, reformatted Design Decisions to the three-line form and resolved the DELIVERY_LABEL/localization contradiction, filled in the Compliance table, corrected Platform Notes APIs (SwiftUI, Compose, AppKit/UIKit, WinUI 3) and renamed the Web bullet to React/Web, moved JavaScript-specific mechanics out of Behavioral Requirements and into the React/Web note, fixed the field-value-007 test vector's rendered `key` attribute, and added test vectors and edge cases for date/select, protocol stripping and scheme handling, an unset image resolver, additional address parts, empty email/phone, markdown script content, and boolean truthiness |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
