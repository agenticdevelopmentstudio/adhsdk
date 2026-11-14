---
id: 44544cfb-39e5-419d-81b9-8e1c504c6e64
title: "WindowFooterContentViewController"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An AppKit container that stacks a content view controller above a fixed footer bar for window layouts."
platforms:
  - swift
  - macos
tags:
  - window-chrome
  - view-controller
  - layout
depends-on:
  - 3ec6618a-03a4-4740-9655-e6e47c05cf2b
related: []
references: []
approved-by: ""
approved-date: ""
---

# WindowFooterContentViewController

## Overview

A view controller that composes an arbitrary content view controller with a fixed footer bar (`WindowFooterBar`) at the bottom of a window. The footer remains visible and stationary while the content fills the remaining space. This container allows windows to gain a footer without restructuring their content hierarchy—the content view controller is adopted as a child and participates in the responder chain and appearance inheritance as if the window contained it directly.

**Public API**:

| Member | Type | Notes |
|--------|------|-------|
| `init(contentViewController:accessibilityPrefix:)` | `(NSViewController, String) -> WindowFooterContentViewController` | Both parameters are required; neither has a default. |
| `contentViewController` | `NSViewController` (read-only) | What the window is for; adopted as a child in `init`. |
| `footer` | `WindowFooterBar` (read-only) | Exposed directly for footer-specific API (e.g. `trailingAccessories`) beyond `status`. |
| `status` | `String` (computed) | Forwards to `footer.status`. |

## Behavioral Requirements

- **content-child**: The container MUST adopt the provided `contentViewController` as a child view controller, ensuring it participates in the responder chain and inherits appearance settings from the parent window.
- **stacked-layout**: The container MUST position the content view controller's view above the `WindowFooterBar` in the view hierarchy, with the footer anchored to the bottom.
- **content-space-fill**: The content view controller's view MUST expand to fill all available space in the container except the space occupied by the footer bar.
- **footer-bottom-position**: The `WindowFooterBar` MUST be anchored to the bottom edge of the container and stretch to the full width.
- **status-forwarding**: The `status` property MUST forward all getter and setter calls to the footer's `status` property, allowing callers to set the footer's leading status text through a single reference.
- **accessibility-prefix-required**: The initializer MUST require an `accessibilityPrefix` parameter (no default) to namespace the footer's accessibility controls, ensuring that multiple windows with footers do not share accessibility identifiers.
- **nscoder-init-unsupported**: Initialization from an `NSCoder` (e.g., from Interface Builder) MUST NOT be supported and MUST raise a fatal error if attempted.

## Appearance

- **Layout**: Vertical stack with content above, footer below. No intermediate spacing.
- **Footer height**: Defined by `WindowFooterBar`; not customizable in this container.
- **Border, shadow, background**: None at the container level; appearance is determined by the content view controller and footer.
- **Content view frame**: Fills the container's bounds minus the footer's height.

## States

| State | Behavior |
|-------|----------|
| Initialized | Content and footer are laid out; container ready to receive view updates. |

## Accessibility

- **Accessibility inheritance**: The content view controller's accessibility hierarchy is preserved; elements in the content remain discoverable with their original accessibility attributes.
- **Footer accessibility namespacing**: The `accessibilityPrefix` parameter MUST be passed to `WindowFooterBar` to ensure its controls are named under a namespace unique to this window instance (e.g., `project.footer.status`, matching the `<prefix>.status` identifier `WindowFooterBar` assigns to its status label). This prevents conflicts when multiple windows with footers exist in the application.
- **Example prefix usage**: If `accessibilityPrefix` is `"project.footer"`, the footer's status label receives the accessibility identifier `project.footer.status`, per `WindowFooterBar`'s own identifier scheme.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cvc-001 | content-child | Create with valid content VC and prefix | `contentViewController` is accessible; VC is a child of the container |
| cvc-002 | stacked-layout | Render container with content and footer | Content view's top is at container's top; footer view's bottom is at container's bottom |
| cvc-003 | content-space-fill | Set container's frame to 400×300 | Content view's frame height equals 300 minus `WindowFooterBar.height`; footer's frame height equals `WindowFooterBar.height`; both span the full 400pt width |
| cvc-004 | footer-bottom-position | Render and check constraints | Footer's leading and trailing anchors equal container's; footer's bottom anchor equals container's bottom |
| cvc-005 | status-forwarding | Set `container.status = "Ready"` | `container.footer.status` equals `"Ready"` |
| cvc-006 | status-forwarding | Read `container.status` when footer's status is `"Idle"` | Getter returns `"Idle"` |
| cvc-007 | accessibility-prefix-required | Initialize with a content VC and prefix `"test.footer"` | The footer's status label's accessibility identifier equals `"test.footer.status"`, confirming the prefix was threaded through with no default value available |
| cvc-008 | nscoder-init-unsupported | Attempt `init(coder:)` via archival or Interface Builder | Verified by inspection: the initializer is annotated `@available(*, unavailable)`, so any call site fails to compile; the runtime `fatalError` is defense in depth and is not exercised by a normal XCTest process |

## Edge Cases

- **Empty accessibility prefix**: A prefix of empty string (`""`) is syntactically valid; the resulting footer status identifier is `.status` with no namespace segment ahead of it (see `WindowFooterBar`'s `accessibilityID("\(accessibilityPrefix).status")` construction). The component does not validate or reject this input. Callers wanting collision-safe identifiers across multiple windows should supply a non-empty, unique prefix.
- **Content view controller with existing parent**: If the passed `contentViewController` is already a child of another view controller, AppKit's `addChild(_:)` removes it from its previous parent before adding it to this container—the reparenting happens automatically, with no fatal error or undefined behavior. This container does not clean up state the previous parent held about the relationship (e.g., layout constraints the old parent anchored to the child's view); that remains the caller's responsibility.
- **Footer state changes**: The footer (`WindowFooterBar`) may have its own internal state (e.g., button presses, text updates). This container does not modify or constrain the footer's behavior; it only manages layout. Any footer state changes propagate normally through the footer's own interface.
- **Responder chain during initialization**: During `loadView()`, the content view controller's view is added to the hierarchy and the child relationship is established. The responder chain is set up by AppKit's standard view controller adoption mechanics; this container does not alter that flow.

## Configuration

Not applicable. This component has no configuration options; all parameters are required at initialization.

## Deep Linking

Not applicable. This component is a view controller container, not a URL-routable endpoint.

## Localization

Not applicable. This component contains no user-facing strings; localization is handled by the content view controller and `WindowFooterBar` separately.

## Accessibility Options

- **Reduce Motion**: Inherited from the content view controller and footer; this container does not add animations.
- **Increase Contrast**: Inherited from child views; this container does not set colors.
- **Differentiate Without Color**: Inherited from child views; this container is transparent to color-based distinctions.

## Feature Flags

Not applicable. This component is always enabled.

## Analytics

Not applicable. This component performs no analytics tracking.

## Privacy

Not applicable. This component collects no user data.

## Logging

Not applicable. This component performs no logging.

## Platform Notes

- **AppKit / UIKit**: Reference implementation. Located in `SourcesUI/macOS/Chrome/WindowFooterContentViewController.swift` in AgenticDeveloperHubSDK. Uses `NSViewController` adoption via `addChild(_:)` and Auto Layout with `NSLayoutConstraint`. The `@MainActor` annotation ensures thread-safe access to AppKit objects. No UIKit port exists in this codebase; a UIKit implementation would follow the same `addChild(_:)` pattern, anchoring the footer to the safe area's bottom edge instead of the window's bottom edge.
- **SwiftUI**: For a from-scratch SwiftUI implementation, use a `VStack` with the content view above a native footer view below, or `.safeAreaInset(edge: .bottom)` if the footer should stay pinned while content scrolls beneath it; bind `status` to `@State` for dynamic updates. Wrapping this `NSViewController` in an `NSViewControllerRepresentable` conformer is available as an interop fallback for reusing the AppKit implementation as-is, but is not the native SwiftUI idiom.
- **Compose**: Create a vertical `Column` with `Modifier.weight(1f)` on the content area and a fixed-height footer below. The `Column` layout primitive maps to the vertical stacking behavior. Apply `Modifier.testTag("$namespacePrefix.status")` to the footer's status text, mirroring the prefix-based namespacing `WindowFooterBar` uses for its accessibility identifier.
- **React/Web**: Use a vertical flexbox container (`display: flex; flex-direction: column`). Set `flex: 1` on the content element so it expands; set a fixed `height` on the footer. Pass `status` straight through as a prop to the footer component—no ref or state callback is needed, since forwarding a prop down is the plain React equivalent of the property-forwarding behavior.
- **WinUI 3**: Use a `Grid` with two `RowDefinition` entries: one with `Height="*"` (star sizing) for the content and one with `Height="Auto"` for the footer, sized to its content. Place the content in row 0, footer in row 1, using the `Grid.Row="0"` and `Grid.Row="1"` attached properties.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/WindowFooterContentViewController.swift` | unverified |

## Design Decisions

**Decision**: Adopt `contentViewController` as a child view controller rather than simply adding its view.
**Rationale**: This preserves the content controller's participation in the responder chain and appearance propagation, letting it behave as if the window contained it directly. It is a separation of concerns: the window does not know about the footer; the footer is added transparently.
**Approved**: pending

**Decision**: Require the `accessibilityPrefix` parameter, with no default.
**Rationale**: Multiple windows with footers in the same app would otherwise share accessibility identifiers, breaking UI testing and other identifier-based automation. Explicit naming requires developers to think about uniqueness.
**Approved**: pending

**Decision**: Forbid initialization from `NSCoder`.
**Rationale**: The component cannot be configured via Interface Builder—it requires a content view controller reference at runtime, not at build time. A fatal error is more transparent than a silent failure.
**Approved**: pending

**Decision**: Expose `status` on the container itself, forwarding to `footer.status`, while also keeping `footer` public.
**Rationale**: `status` is the single most common thing a host sets, so forwarding it lets callers hold one reference instead of reaching through two layers. `footer` stays public too, because `WindowFooterBar` has its own API surface this container doesn't forward—for example `trailingAccessories`—so callers needing that still have a way in without the container growing a forwarding property for every future addition to `WindowFooterBar`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The first two statuses rest on `init` calling `addChild(contentViewController)` and `loadView()` composing the content and footer views via plain Auto Layout, without intercepting the responder chain or focus order—so the content view controller's own screen-reader exposure and keyboard navigability carry through unchanged. `separation-of-concerns` passes because this controller does one thing — compose a content controller with a fixed footer — and delegates status/accessibility forwarding to the footer bar rather than owning that logic itself. `unit-test-coverage` passes: `PaneDisplayPathTests.swift` instantiates `WindowFooterContentViewController` directly and asserts the host adopts the content controller, forwards the footer's status, and forwards its accessibility namespace to the bar.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Title corrected to match H1 (WindowFooterContentViewController). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; corrected the AppKit `addChild` reparenting and NSCoder-unavailable edge cases; retitled Platform Notes to AppKit / UIKit and fixed factual errors in SwiftUI, Compose, React/Web, and WinUI 3 guidance; reformatted Design Decisions to Decision/Rationale/Approved; added a Compliance table and a public API surface; added the `WindowFooterBar` dependency; fixed frontmatter date quoting |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
