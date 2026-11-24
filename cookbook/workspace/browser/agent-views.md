---
id: cd862ce2-d93d-4094-be20-0abab33e2fa7
title: "Agent Preview and Agent Source Views"
type: ingredient
version: 0.1.2
status: draft
language: en
created: 2026-11-15
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A three-way view switch in the browser's privacy toolbar that shows a tab as the website, as a sealed preview of exactly what the agent receives, or as that same page's source."
platforms:
  - swift
  - macos
tags:
  - browser
  - agent
  - privacy
  - preview
  - source-view
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/AgentViews/BrowserAgentViewMode.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/AgentViews/BrowserAgentPreviewViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/AgentViews/BrowserAgentSourceViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserPaneViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserContentRules.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPageSource.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/Automation/AgentPage/AgentPage.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/HiddenItems/BrowserHiddenItemsStore.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/UI/WebKit/WKWebView+QuietPresentation.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserAgentViewsTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Agent Preview and Agent Source Views

## Overview

This component lets a user check, with their own eyes, exactly what an
agent is given from a page. It is a three-way icon control in the browser
pane's privacy toolbar that switches what a tab's content area shows:

- **Website** — the page as it is (the default);
- **Agent preview** — the agent's page drawn as a sealed, read-only
  document;
- **Agent source** — the same document as highlighted source text.

Both agent views show the output of the Agent Page Builder (the agent
gatekeeper, see that recipe) and nothing else: the HTML it renders from the
very page value whose snapshot tree and text the tools hand to the agent.
The preview cannot add anything of its own — page scripts are off, every
network load is blocked, and it never navigates past the document it was
given — so what it shows cannot differ from what the agent receives. The
views follow the page: they rebuild after a navigation, after a privacy
setting changes, after the privacy words change, and after the site's
"hide from agent" list changes, with bursts of changes coalesced into one
rebuild.

The mode is per tab and is not saved.

## Behavioral Requirements

- **three-segment-control**: The view switch MUST be a single-selection
  control of three icon segments in the privacy toolbar, in the order
  Website, Agent preview, Agent source.
- **segment-tooltips**: Each segment MUST carry a tooltip: "Website — the
  page as it is", "Agent preview — what the agent can see, with privacy
  filters applied", and "Agent source — the page the agent receives, as
  source".
- **default-website**: A tab MUST start in Website mode.
- **per-tab-not-persisted**: The mode MUST belong to one tab: switching
  tabs MUST show each tab's own mode in the control and its content, and
  the mode MUST NOT be saved, so a tab that is reopened or restored starts
  in Website mode.
- **website-shows-live-page**: In Website mode the tab's content MUST be
  the live page, unchanged by this component.
- **views-show-gatekeeper-output-only**: Both agent views MUST obtain
  their content only from the agent gatekeeper's single page entry point,
  as its HTML rendering, and MUST NOT read the live page any other way.
- **preview-replaces-content-read-only**: In Agent preview mode the tab's
  content MUST be replaced by a read-only web view showing the
  gatekeeper's HTML.
- **preview-javascript-off**: The preview MUST load with page JavaScript
  disabled.
- **preview-blocks-network**: The preview MUST block every network load,
  for every URL and resource type.
- **preview-no-navigation**: The preview MUST cancel every navigation
  other than its own loads of the gatekeeper's HTML, including link
  clicks and every subframe load. Each own load MUST let exactly one
  main-frame load of `about:blank` through, so two loads started in quick
  succession are both answered and the newest page is shown; the
  allowance MUST be cleared when the latest own load finishes or fails,
  so none outlives the newest load, and an own load that starts no
  navigation MUST give its allowance back at once.
- **preview-paints-under-quiet-presentation**: In development builds the
  preview MUST keep painting while its window is reported occluded, so it
  can be photographed under quiet presentation.
- **source-same-html**: In Agent source mode the tab's content MUST be a
  read-only text view whose text is exactly the gatekeeper's HTML.
- **source-highlighted**: The source view MUST highlight tags, attribute
  names, attribute values and text in distinct theme colors, in a
  monospaced font. It MUST show the HTML at once in the text color and
  apply the highlighting when the lex, run off the main thread, lands; a
  lex for HTML no longer shown MUST be discarded, and the same HTML again
  MUST change nothing.
- **unavailable-shown-as-reason**: When the gatekeeper returns an
  unavailable page, both agent views MUST show its reason and no page
  content.
- **refresh-triggers**: An agent view MUST rebuild after the tab finishes
  a navigation, after any agent privacy setting for the pane changes,
  after the privacy words change, and after the site's agent list changes.
- **refresh-coalesced**: Triggers arriving within 250 milliseconds of one
  another MUST produce a single rebuild.
- **website-mode-restores-page**: Switching back to Website mode MUST show
  the live page again, in the state it was in, without reloading it.
- **entering-from-website-blank**: Switching from Website to an agent mode
  MUST show the blank page until the rebuild lands, never the last agent
  page, since the page, its address or its agent list may have changed
  while the Website was shown; switching between the two agent modes MUST
  show the current agent page at once while the rebuild runs.

## Appearance

- **Corner radius**: The system segmented control's own.
- **Padding**: The control sits in the privacy toolbar row with that
  row's existing item spacing.
- **Font**: Not applicable for the control (icons only). The source view
  uses the theme's monospaced text font.
- **Background**: The preview draws its own fixed builder stylesheet
  (Design Decisions) on the theme's window background; the source view
  fills with the background of the theme's source-editor colors (the
  theme's window background), as the app's code editors do.
- **Foreground/Text**: Source highlighting uses four theme roles: tags,
  attribute names, attribute values, and plain text.
- **Border**: Not applicable — neither view draws a border of its own.
- **Shadow**: Not applicable.
- **Min/Max size**: Both views fill the tab's content area exactly as the
  live page does.

Icons: `globe` (Website), `eye` (Agent preview),
`chevron.left.forwardslash.chevron.right` (Agent source).

## States

| State | Appearance change |
|-------|------------------|
| Website (default) | Website segment selected; the live page is shown. |
| Agent preview | Agent preview segment selected; the sealed preview replaces the page. |
| Agent source | Agent source segment selected; the highlighted source replaces the page. |
| Rebuilding | Within the agent modes, the previous content stays shown until the new page is ready, then is replaced in one step; entered from Website, the view is blank until the page is ready. |
| Unavailable | The agent view shows only the gatekeeper's "Agent view unavailable: …" paragraph (preview) or its source (source view). |
| Toolbar hidden | With the privacy toolbar hidden the control is not shown; the tab keeps its mode. |
| Disabled | Not applicable — every segment is always selectable. |

## Accessibility

- **Role/trait**: The control is a native segmented control with
  accessibility identifier `browser.agent-view`; segments carry icons
  only, so each segment's image carries its label (below) as its
  accessibility description, and its tooltip text as its help.
- **Label requirements**: Website, Agent preview, Agent source — the
  segment images' accessibility descriptions.
- **Announce state changes**: The native control reports its selection
  change; the content swap posts no further announcement.
- **Keyboard / assistive-technology navigation**: The control is in the
  key-view loop like the toolbar's other controls; the source view is a
  selectable, read-only text view, and the preview is a read-only web view
  that assistive technology can read.
- **Minimum tap target**: The system segmented control's size.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| agent-views-001 | three-segment-control, segment-tooltips | Open a browser pane with the privacy toolbar shown | The control has three icon segments in the order Website, Agent preview, Agent source, single selection, each with its tooltip text |
| agent-views-002 | default-website, website-shows-live-page | Open a new tab | Website is selected and the live page is shown |
| agent-views-003 | per-tab-not-persisted | Tab A in Agent source, tab B in Website; switch between them | Each tab shows its own mode and content |
| agent-views-004 | per-tab-not-persisted | Put a tab in Agent preview; close and restore the pane | The restored tab is in Website mode |
| agent-views-005 | preview-replaces-content-read-only, views-show-gatekeeper-output-only | Select Agent preview on a page | The content is a web view whose document is the gatekeeper's HTML for that page |
| agent-views-006 | preview-javascript-off | Inspect the preview's configuration | Page JavaScript is disabled |
| agent-views-007 | preview-blocks-network | Preview's content rules; an HTML page containing an image with a source | A block-every-URL rule list is installed; no request leaves the preview, and the gatekeeper's HTML holds no source attribute |
| agent-views-008 | preview-no-navigation | Click a link in the preview | The navigation is cancelled; the preview still shows the same document |
| agent-views-009 | preview-paints-under-quiet-presentation | Development build under quiet presentation; photograph the preview's window | The shot shows the preview's content, not a blank view |
| agent-views-010 | source-same-html | Select Agent source | The text view's text equals the gatekeeper's HTML exactly; it is not editable |
| agent-views-011 | source-highlighted | Source text `<p data-adk-ref="e1">Hi</p>` | The tag, the attribute name, the attribute value and "Hi" carry four distinct colors; the font is monospaced |
| agent-views-012 | unavailable-shown-as-reason | The privacy words cannot be read; select Agent preview, then Agent source | The preview shows only the "Agent view unavailable: …" paragraph; the source is that paragraph's HTML |
| agent-views-013 | refresh-triggers | In Agent preview, add an agent-list entry that hides a heading | The preview rebuilds and the heading is gone |
| agent-views-014 | refresh-triggers | In Agent source, navigate to another page; separately change a privacy word; separately turn Hide Images on | Each change rebuilds the source to match the new gatekeeper output |
| agent-views-015 | refresh-coalesced | Fire five triggers within 100 milliseconds | Exactly one rebuild runs |
| agent-views-016 | website-mode-restores-page | Fill a text field on the page, switch to Agent preview, then back to Website | The live page shows again with the typed text, not reloaded |
| agent-views-017 | preview-no-navigation | Show two pages in the preview back to back, before WebKit asks about the first load | Both loads are allowed and the preview shows the second page; after it finishes, a further `about:blank` navigation is cancelled |
| agent-views-018 | entering-from-website-blank | In Agent preview, switch to Website, navigate to another page, then switch to Agent source | The source shows the blank page until the rebuild lands, then the new page; the earlier page is never shown |
| agent-views-019 | entering-from-website-blank | In Agent preview showing a page, switch to Agent source | The source shows that page's HTML at once, before the rebuild lands |
| agent-views-020 | source-highlighted | Show a large page in Agent source | The text appears at once in the text color; the highlight colors follow when the lex lands; showing the same HTML again changes nothing |

## Edge Cases

- **Null and empty input**: A blank tab shows the gatekeeper's empty page:
  an empty preview and the minimal HTML in the source view.
- **Boundary values**: A very large page's source is shown whole in a
  scrolling text view; a page the walker cannot finish in time is shown as
  the unavailable reason (MUST, `unavailable-shown-as-reason`).
- **Concurrent access**: View work runs on the main thread, except the
  gatekeeper's decode, build and concealment and the source view's lex,
  which run off it and land back on it. A rebuild
  that finishes after a newer one was started is discarded, so the view
  never shows an older page than the latest trigger asked for.
- **Error states**: Every gatekeeper failure is shown as its reason, never
  as the live page (MUST, `unavailable-shown-as-reason`).
- **Offline or disconnected state**: Not applicable — the preview makes
  no network load by design (`preview-blocks-network`), so connectivity
  changes nothing.
- **Missing file or unreachable server**: The block-everything rule list
  failing to compile MUST leave the preview showing nothing rather than an
  unblocked document.
- **Cancellation and timeouts**: Closing the tab or switching it to
  Website mode cancels a pending rebuild; the gatekeeper's walker timeout
  bounds each rebuild.
- **Navigation while an agent view is shown**: The view rebuilds when the
  navigation finishes; until then it keeps the previous page's content.
- **Entering from Website**: The view shows the blank page until its
  rebuild lands; an earlier agent page never passes for the current one
  (MUST, `entering-from-website-blank`). Moving between Agent preview and
  Agent source keeps the current page shown meanwhile.
- **Rebuilds in quick succession**: A second preview load started before
  WebKit asked about the first is still let through, so the preview ends
  on the newest page rather than cancelling it (MUST,
  `preview-no-navigation`).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| mode | Website / Agent preview / Agent source | Website | Per tab, in memory only. |
| refresh coalescing | milliseconds | 250 | Window within which triggers merge into one rebuild. |

The views read no settings of their own; what they show is shaped only by
the settings the gatekeeper reads.

## Deep Linking

Not applicable: the views define no URL scheme or route, and the mode is
not addressable.

## Localization

The three tooltip strings are user-facing and MUST be externalized for
localization. The source text and the gatekeeper's reason are content, not
interface strings.

## Accessibility Options

The source view's highlight colors come from the theme, so Increase
Contrast follows the theme's own contrast handling. Highlighting is an aid,
not the only cue: the source text itself carries all the information.
Reduce Motion: the content swap has no animation.

## Feature Flags

Not applicable: no feature flag. The views exist only in the Safari
(WebKit) pane; the Chrome pane is compiled out and gets no agent views.

## Analytics

Not applicable: no analytics or telemetry event.

## Privacy

The views show the user only what the agent already receives, on the
user's own screen; they store nothing, send nothing, and keep no copy
after a rebuild replaces it. The sealed preview — scripts off, no network,
no navigation — is what guarantees the preview cannot show, or fetch,
anything the gatekeeper did not put in.

## Logging

Not applicable: the design specifies no logging. Any log line added later
MUST NOT carry page content.

## Platform Notes

- **SwiftUI**: Host the AppKit controllers through
  `NSViewControllerRepresentable`; a `Picker` with `.segmented` style and
  `.help(_:)` per item stands in for the control.
- **Compose**: A `SingleChoiceSegmentedButtonRow` with
  `TooltipBox` per segment; the preview is a `WebView` with
  `javaScriptEnabled = false`, `blockNetworkLoads = true`, and a
  `WebViewClient` whose `shouldOverrideUrlLoading` returns true.
- **React/Web**: The preview is an `iframe` with `srcdoc` set to the HTML,
  `sandbox=""` (no scripts, no navigation) and a CSP meta of
  `default-src 'none'` in the document; the source view is a `pre` with
  escaped, highlighted spans.
- **AppKit / UIKit**: The reference home. `BrowserAgentViewMode`
  (`website`, `agentPreview`, `agentSource`); an `NSSegmentedControl`
  (`.selectOne`, images only, `setToolTip(_:forSegment:)`) in
  `WebBrowserPaneViewController`'s privacy strip.
  `BrowserAgentPreviewViewController` owns a `WKWebView` with
  `defaultWebpagePreferences.allowsContentJavaScript = false`, the
  `WKContentRuleList` from `BrowserContentRules.blockEverything()`
  (`[{"trigger":{"url-filter":".*"},"action":{"type":"block"}}]`,
  compiled once), `loadHTMLString(page.html(), baseURL: nil)`, a navigation
  delegate whose `decidePolicyFor` cancels every subframe navigation and
  allows a main-frame `.other` navigation to `about:blank` (or no URL)
  only while `allowedLoads` is above zero, spending one credit per allow
  (each `loadHTMLString` adds one; the end of the latest own
  `WKNavigation`, in `didFinish`, `didFail` or
  `didFailProvisionalNavigation`, zeroes it, and the end of a superseded
  one changes nothing; a `loadHTMLString` that returns no navigation takes
  its credit back). The delegate method only unpacks the action and
  calls the internal `decidePolicy(targetFrameIsMain:url:navigationType:)`
  with `targetFrame?.isMainFrame` (nil when the action has no target frame;
  the seam cancels anything but `true`), which tests call
  directly with plain values, since WebKit does not support subclassing
  its frame and action classes; the pure rule is
  `policy(allowedLoads:url:navigationType:)`. The preview also calls
  `keepPaintingUnderQuietPresentation()` for the Debug occlusion
  workaround. `BrowserAgentSourceViewController` is a non-editable
  `NSTextView` with a small HTML highlighter building
  `NSAttributedString` attributes from the theme: `show(_:)` sets the
  text with no runs, then lexes it with
  `BrowserAgentSourceHighlighter.tokens(in:)` in a `Task.detached`
  (`highlighting`, cancelled by the next `show`) and applies
  `highlight(_:tokens:font:colors:)` only if the HTML is still the one
  shown. `BrowserAgentViews.setMode(_:)` shows `AgentPage.blank` when
  leaving Website and the last page when moving between agent modes,
  then starts the rebuild. Refresh listens for the
  engine's navigation finish, `UserSettings` changes of the privacy keys,
  privacy-word changes and `BrowserHiddenItemsStore.didChangeNotification`,
  and calls `AgentPageSource.read(options:keepingRefs: true)` (a reading
  walk, so the agent's refs stay valid), built by the same
  `AgentPageSource.reading(_:hiddenItems:privacy:hideImages:)` the tools use
  (through `WebBrowserPaneViewController.agentPageSource(engine:)`, which
  passes the pane's effective Hide Images, `agentHidesImages`, and awaits
  the hidden-items store with `BrowserHiddenItemsStore.sharedStore()`,
  since a tab restored into an agent view reads during launch).
  The agent view is laid over the tab's page holder, which is hidden, not
  removed, so the live page keeps its state. Under UIKit,
  `UISegmentedControl` and a read-only `UITextView`; the web view is the
  same.
- **WinUI 3**: A `Segmented` control (Windows Community Toolkit) with
  `ToolTipService.ToolTip` per item; the preview is a WebView2 with
  `IsScriptEnabled = false`, a `WebResourceRequested` filter on `*` that
  answers every request with a blocked response, and `NavigationStarting`
  cancelling all but the `NavigateToString` load; the source view is a
  read-only `RichTextBlock`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/BrowserContentRules.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/BrowserPane/BrowserAgentViewsTests.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/AgentViews/BrowserAgentViewMode.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/AgentViews/BrowserAgentPreviewViewController.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/AgentViews/BrowserAgentSourceViewController.swift` | unverified |

## Design Decisions

**Decision**: The source view uses a small in-house HTML highlighter with
theme colors, not a third-party highlighter or the code editor.
**Rationale**: The HTML is the gatekeeper's own narrow output (a fixed set
of tags and one attribute pattern), so four token kinds cover it; no new
dependency.
**Approved**: pending

**Decision**: Agent views rebuild only while shown; switching a tab into
an agent view always builds afresh.
**Rationale**: A walk per trigger on tabs nobody is looking at would cost
time for nothing, and building on entry still meets `refresh-triggers` for
what the user sees.
**Approved**: pending

**Decision**: The preview is given its own web view rather than reusing
the tab's, and the live page's web view is kept, hidden, while an agent
view is shown.
**Rationale**: A separate, sealed configuration (scripts off, block-all
rules) cannot be applied to the live page; keeping the live view meets
`website-mode-restores-page`.
**Approved**: pending

**Decision**: Rendering an unavailable page uses the gatekeeper's own
HTML rendering of it rather than a separate view.
**Rationale**: The views must show the gatekeeper's output and nothing
else, failures included.
**Approved**: pending

**Decision**: An agent view reads the page with a reading walk that keeps
the agent's ref table, never a snapshot walk.
**Rationale**: Looking at what the agent sees must not change it: a
snapshot walk would renumber the refs the agent holds from its last
snapshot.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | pending | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | pending | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | pending | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | pending | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | pending | Best Practices |

Notes: design-first; every check is pending until the code exists. The
plan's tests are in `BrowserAgentViewsTests`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.2 | 2026-11-16 | Mike Fullerton | Entering from Website blanks the view; source highlighted asynchronously; preview credit give-back; awaits the hidden-items store. |
| 0.1.1 | 2026-11-16 | Mike Fullerton | Preview navigation allows one load per credit, zeroed when the latest own load ends; rebuilds in quick succession; reading(hideImages:) and agentPageSource(engine:). |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
