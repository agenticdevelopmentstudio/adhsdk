---
id: 0ca47bff-576f-4e2a-b3f0-5fc0c73ff859
title: "Private Terminal View Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A terminal pane that runs one shell behind privacy words and stays under a privacy screen until the Mac owner authenticates, hidden from accessibility and capture."
platforms:
  - swift
  - macos
tags:
  - terminal
  - privacy
depends-on:
  - d54db476-c847-4ac0-827e-eae336109f38
related: []
references: []
approved-by: ""
approved-date: ""
---

# Private Terminal View Controller

## Overview

`PrivateTerminalViewController` is the pane content for a private terminal. It owns one `TerminalSession` created with `isPrivate` true and the name "Private Terminal", and it places the session's terminal view inside a concealed container beneath a privacy screen. The privacy screen is a themed background with a large crossed-out eye and a one-line message; it is up when the pane is created and goes back up whenever the user asks. Lifting it requires the Mac owner's authentication every time, through the privacy words vault ([adhsdk.ingredient.foundation.privacy.privacy-words-vault](cookbook:d54db476-c847-4ac0-827e-eae336109f38)).

The privacy words are the vault's. The shell starts the first time the pane appears, as any terminal does, using words read from the keychain without a prompt, because those words are what conceal its output and the shell cannot start without them. Starting shows nothing: the screen stays up. Only words still saved under the old user-presence guard make the pane wait for the eye. The shell's output and input are filtered inside the session's terminal view, a private terminal view; the controller reaches the filter only through `TerminalSession.privacyFilter`.

Nothing outside the app can read the terminal. The terminal sits inside a concealed container, so accessibility clients and screen readers find no element there, a scripted view dump stops at it, and while the pane is revealed the hosting window is excluded from screen capture. The class also supplies the pane's eye toggle beside the gear, an Edit Privacy Words option row, the terminal-connectable offer for a chat, the teardown and removal confirmation, and the pane spacing hook. The class is public, `@MainActor` and `final`.

## Behavioral Requirements

- **session-private**: The controller MUST create its session with `isPrivate` true and the name "Private Terminal", with the working directory and environment it was given and an empty environment by default.
- **screen-default-up**: The privacy screen MUST be visible and the terminal view hidden when the pane is first shown, with `isRevealed` false.
- **reveal-authenticates**: `reveal()` MUST ask the vault to authenticate with the reason "show the private terminal" and MUST NOT lift the screen unless that succeeds.
- **reveal-every-time**: Every lift of the privacy screen MUST require a new authentication; the controller keeps no unlocked state across a hide.
- **reveal-no-stack**: `reveal()` MUST do nothing while the pane is already revealed or an authentication is on screen, so a second click does not stack another.
- **reveal-failure-message**: When authentication fails, the screen MUST stay up and the screen message MUST show the error's localized description.
- **reveal-starts-shell**: A successful reveal MUST give the session the vault's filter if one exists, which starts the shell the first time, before setting `isRevealed` true.
- **hide-no-auth**: `hide()` MUST put the privacy screen back up without asking for authentication.
- **reveal-state-views**: When `isRevealed` changes, the privacy screen MUST be hidden exactly when revealed, the terminal view MUST be hidden exactly when not revealed, and the concealed container's reveal flag MUST equal `isRevealed`.
- **reveal-focus**: On reveal the controller MUST make the terminal view the window's first responder on the next main-queue turn.
- **hide-resigns-focus**: On hide, when the window's first responder is a view inside the concealed container, the controller MUST clear the first responder so keystrokes do not go into a terminal nobody can see.
- **screen-message**: The screen message MUST read "Click the eye to show this terminal." when the shell has started and "Click the eye to start this private terminal." when it has not.
- **start-when-visible**: The first time the pane appears and the shell has not started, the controller MUST try once to start it with the words read from the keychain without a prompt.
- **start-silent-miss**: When the silent load yields no words, the pane MUST wait with the screen up and start nothing.
- **start-load-error**: When the silent load throws, the screen message MUST show the error's localized description.
- **start-once-per-appearance**: The silent start MUST be attempted at most once from appearing; later appearances MUST NOT retry it.
- **words-follow-vault**: When the vault publishes a non-nil filter and the shell has started or the pane has asked to start, the controller MUST hand the filter to the session, so a running shell takes new words from the next byte.
- **words-wait-until-asked**: A filter published before the pane has appeared or been asked to start MUST NOT start the shell.
- **started-announces**: When handing a filter starts the shell for the first time, the controller MUST refresh its reveal state and post the terminal-pane-connectable-changed notification with itself as the object.
- **no-notify-on-update**: Handing a filter to a shell already started MUST NOT post that notification.
- **accessory-toggle**: The controller MUST offer one pane accessory button, an eye beside the gear, titled "Hide the private terminal" with the open-eye symbol when revealed and "Show the private terminal" with the crossed-out symbol when not, that reveals or hides on press.
- **accessory-refresh**: Whenever the reveal state changes, the controller MUST ask its parent pane to refresh its accessories.
- **options-edit-words**: The controller MUST offer one option row holding an Edit Privacy Words button and a note that the words are kept in the keychain and opening them asks for authentication.
- **edit-words-authenticates**: Pressing Edit Privacy Words MUST dismiss the options dialog and then ask the vault to authenticate with the reason "edit the privacy words" before presenting the editor on the window.
- **edit-words-no-stack**: Pressing Edit Privacy Words while an authentication is on screen MUST do nothing beyond dismissing the options dialog.
- **edit-words-failure-alert**: When that authentication fails and the pane has a window, the controller MUST show a sheet titled "The privacy words could not be opened." with the error's localized description.
- **connectable-while-running**: The connectable terminal MUST be the session while it is running and nil otherwise.
- **connect-starts-shell**: Starting the connectable terminal MUST mark the pane as asked to start, load the words through the vault's upgrade-if-needed load, give the session the filter if one exists, and return the connectable terminal, without revealing the screen.
- **connect-already-started**: When the shell has already started, starting the connectable terminal MUST return the connectable terminal without loading words.
- **connect-error-propagates**: An error thrown by the vault's upgrade-if-needed load MUST propagate to the caller.
- **teardown-terminates**: When the pane content is about to be discarded the controller MUST terminate the session's process.
- **removal-confirmation**: The removal confirmation message MUST be "This pane has a running private terminal session. Removing the pane ends it." when the session has started and is running, and nil otherwise.
- **conceal-container**: The terminal view MUST sit inside a concealed container and the privacy screen MUST sit outside it, on top, so the eye is reachable by a screen reader.
- **eye-accessible**: The eye on the screen MUST carry the accessibility label "Show the private terminal", the tooltip of the same text and the accessibility identifier `privateTerminal.reveal`.
- **frame-held**: The terminal view MUST be wrapped in a frame-holding view so it is not resized on every frame while a shelf slides beside the pane.
- **appearance-apply**: The controller MUST apply the theme palette to the terminal view on load and again when the theme changes, and MUST re-apply on a change to any setting in the terminal appearance setting keys.
- **padding-from-theme**: The gap between the pane and the terminal view MUST be set on all four edges from the terminal appearance's resolved padding for the theme: the theme's own terminal padding override where it has one, otherwise the pane content spacing setting.
- **pane-spacing-ignored**: Applying pane spacing MUST only re-apply appearance, because the terminal insets its own grid; the passed spacing value MUST NOT be used (the resolved padding still falls back to the global pane content spacing setting).
- **no-scripting-surface**: The controller MUST NOT provide an AppleScript object or a URL that opens the pane.
- **no-coder-init**: The coder initializer MUST be unavailable.
- **main-actor**: The controller MUST be used only from the main actor.
- **auto-hide**: NEEDS REVIEW: Not implemented in source. Nothing puts the privacy screen back up on its own when the window loses focus, goes to the background, the Mac sleeps or a time passes; evidence that settles it is a product decision on whether an idle or lock event should lower the screen.

## Appearance

- **Corner radius**: Not applicable: the pane draws no rounded shape of its own.
- **Padding**: The terminal view is pinned to the concealed container with four constants set from the terminal appearance's resolved padding for the current theme (the theme's terminal padding override, else the pane content spacing setting). The privacy screen is pinned flush to the pane on all four edges.
- **Font**: The screen message uses the secondary text color role with the body text role, centered, wrapping on words, at most 320 points wide.
- **Background**: The pane and the privacy screen use the window background role of the current theme.
- **Foreground/Text**: The message uses the secondary text role. The eye uses the system symbol `eye.slash` at 48 points regular weight, borderless.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: The pane has a default frame of 800 by 600 points before layout. The stack of eye and message is centered, has at least 20 points to the leading edge and 12 points between the eye and the message.

## States

| State | Appearance change |
|-------|------------------|
| Default (screen up, shell not started) | Privacy screen over the pane, crossed-out eye, message "Click the eye to start this private terminal."; terminal view hidden. |
| Screen up, shell started | The same, with the message "Click the eye to show this terminal." |
| Authenticating | No visible change; a second reveal or edit press does nothing until the first ends. |
| Revealed | Privacy screen hidden, terminal view visible and first responder, window excluded from screen capture; the accessory shows an open eye titled "Hide the private terminal". |
| Failed (authentication or silent load) | Screen stays up; the message shows the error description. |
| Shell exited | Terminal remains as it was; the connectable offer is nil because the session is no longer running. |
| Pressed | Not applicable: the eye and the Edit button use the system button press feedback with no custom state. |
| Disabled | Not applicable: no control is disabled by this class. |
| Focused | The terminal view takes focus on reveal; the controller adds no focus ring of its own. |
| Loading | Not applicable: the class shows no loading indication during authentication. |

## Accessibility

- **Role/trait**: The eye and the accessory toggle are buttons with explicit accessibility labels ("Show the private terminal", and "Hide the private terminal" or "Show the private terminal" for the accessory) and the identifiers `privateTerminal.reveal` and `privateTerminal.toggleVisibility`. The options button has the identifier `privateTerminal.options.editWords`.
- **Label requirements**: The eye symbol is created with the accessibility description "Show the private terminal" and the tooltip carries the same text; the accessory button's label and tooltip change with the state.
- **Announce state changes**: Not implemented as an announcement; the accessory title and message change, and no accessibility notification is posted by this class.
- **Terminal contents**: The terminal sits in the concealed container, so no accessibility element, children, visible children or hit-test result below it is exposed. This is deliberate; the open question on `screen-reader-contents` records the consequence.
- **screen-reader-contents**: NEEDS REVIEW: Not implemented in source. A screen-reader user can lift the screen but then finds no readable terminal; evidence that settles it is a product decision on whether private panes are meant to be unusable with a screen reader and, if not, a design for an alias-only accessible rendering.
- **Minimum tap target**: The eye symbol is 48 points; the accessory eye is 13 points with no minimum hit area set in this class, so the 44 by 44 point target is not asserted by the source.
- **Keyboard**: The terminal takes keyboard focus on reveal; the source adds no keyboard shortcut to reveal or hide.

## Conformance Test Vectors

The repository has no test that names `PrivateTerminalViewController`. The vectors are derived from the source. Unless stated, the vault is a test double whose `authenticate` succeeds and whose `load` returns true with a filter.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| private-terminal-view-controller-001 | session-private, screen-default-up | Create a controller; load its view | The session is private and named "Private Terminal"; the screen is visible, the terminal view hidden, `isRevealed` false. |
| private-terminal-view-controller-002 | reveal-authenticates, reveal-starts-shell, reveal-state-views | Call `reveal()` | The vault is asked with the reason "show the private terminal"; on success the session has the filter and has started; `isRevealed` is true, the screen hidden, the terminal view shown. |
| private-terminal-view-controller-003 | reveal-failure-message | `authenticate` throws "Canceled"; call `reveal()` | `isRevealed` stays false; the message reads "Canceled". |
| private-terminal-view-controller-004 | reveal-no-stack | Call `reveal()` twice before the first authentication ends | The vault is asked once. |
| private-terminal-view-controller-005 | hide-no-auth, reveal-every-time | Reveal, call `hide()`, call `reveal()` | `hide()` asks nothing; the second reveal asks the vault again. |
| private-terminal-view-controller-006 | hide-resigns-focus | Reveal, then hide with the terminal as first responder | The window's first responder becomes nil. |
| private-terminal-view-controller-007 | reveal-focus | Reveal | On the next main-queue turn the terminal view is the first responder. |
| private-terminal-view-controller-008 | screen-message | Shell not started, then started | "Click the eye to start this private terminal." then "Click the eye to show this terminal." |
| private-terminal-view-controller-009 | start-when-visible, started-announces | `viewDidAppear` with words available silently | The session starts with the filter; the screen stays up; the connectable-changed notification posts once. |
| private-terminal-view-controller-010 | start-silent-miss | `load` returns false; appear | The shell is not started; the screen is up. |
| private-terminal-view-controller-011 | start-load-error | `load` throws "Keychain locked"; appear | The message reads "Keychain locked". |
| private-terminal-view-controller-012 | start-once-per-appearance | Appear twice with `load` returning false the first time | `load` is called once. |
| private-terminal-view-controller-013 | words-wait-until-asked | Vault publishes a filter before the pane appears | The shell is not started. |
| private-terminal-view-controller-014 | words-follow-vault, no-notify-on-update | Started shell; the vault publishes a new filter | The session's filter is replaced; no second notification posts. |
| private-terminal-view-controller-015 | accessory-toggle, accessory-refresh | Reveal with the pane as parent | One accessory button titled "Hide the private terminal"; the parent was asked to refresh accessories. |
| private-terminal-view-controller-016 | options-edit-words, edit-words-authenticates | Press Edit Privacy Words | The options dialog is dismissed; the vault is asked with "edit the privacy words"; the editor is presented on the window. |
| private-terminal-view-controller-017 | edit-words-failure-alert | `authenticate` throws "Denied" while pressing Edit | A sheet reads "The privacy words could not be opened." with "Denied". |
| private-terminal-view-controller-018 | connectable-while-running | Session not started, then running, then exited | Nil, the session, nil. |
| private-terminal-view-controller-019 | connect-starts-shell, connect-error-propagates | `startConnectableTerminal()` with the upgrading load succeeding, then throwing | Success returns the running session with the screen still up; the throw propagates to the caller. |
| private-terminal-view-controller-020 | connect-already-started | Shell already started; `startConnectableTerminal()` | Returns the connectable terminal; the vault load is not called. |
| private-terminal-view-controller-021 | teardown-terminates, removal-confirmation | A running session; discard the pane content; read the message | The process is terminated; before that the message is "This pane has a running private terminal session. Removing the pane ends it."; with no running session it is nil. |
| private-terminal-view-controller-022 | conceal-container, eye-accessible | Walk the accessibility tree of the pane | The terminal view is not exposed; the eye is, with the label "Show the private terminal" and identifier `privateTerminal.reveal`. |
| private-terminal-view-controller-023 | appearance-apply, padding-from-theme, pane-spacing-ignored | Change a terminal appearance setting, then apply pane spacing | Padding constants equal the resolved padding; spacing is not read; appearance is applied again each time. |
| private-terminal-view-controller-024 | no-scripting-surface, no-coder-init | Search the pane for an AppleScript object and a URL route; call the coder initializer | None exists; the coder initializer is unavailable. |

## Edge Cases

- **Null / empty input**: A vault with no filter hands the session nothing; the reveal still lifts the screen with the shell not started (MUST). A nil window while editing words makes the editor and the failure alert silently not appear (MUST NOT show anything).
- **Boundary values**: Revealing a pane already revealed does nothing (MUST). Hiding a pane already hidden sets the same state again and re-applies reveal state with no authentication (MUST NOT ask).
- **Concurrent access**: Main-actor only. An authentication guard stops a second authentication from reveal or edit while one is on screen (MUST). The guard is shared, so a reveal press during an edit authentication does nothing (MUST).
- **Error states**: A failed reveal leaves the screen up with the message set; a failed silent load sets the message; a failed edit authentication shows an alert; a throwing connect propagates (MUST each). A failed reveal does not alert.
- **Offline / disconnected state**: Not applicable: the pane does not touch the network; the shell is a local process.
- **Shell exit while revealed**: The terminal stays visible and `isRunning` becomes false, so the connectable offer becomes nil (MUST); the controller adds no exit handling.
- **Words changed by another pane**: A published filter reaches a running shell from the next byte, and a pane that has not appeared waits (MUST).
- **Words under the old guard**: The silent load yields nothing, the pane waits for the eye or a connecting chat, and authenticating rewrites them without the old guard (MUST).
- **Screen capture**: While revealed the window is excluded from capture; leaving the window or hiding returns it to readable unless another revealed concealed view remains (MUST).
- **Pane removal**: A running session asks for confirmation; discarding ends the process (MUST).
- **Auto-hide**: See the open question on `auto-hide`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `vault` | `PrivacyWordsVault` | none (required) | The keychain-backed words and the authentication. |
| `workingDirectory` | `String?` | none (required) | The shell's starting directory. |
| `environment` | `[String: String]` | `[:]` | Extra environment for the shell. |
| `isRevealed` | `Bool`, read-only outside | `false` | Whether the contents are on screen. |

## Deep Linking

Not applicable: the source says there is no URL that opens the pane and no AppleScript object for it.

## Localization

All user-facing text is a literal string in the source; none goes through a localization lookup.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (literal) | Show the private terminal | Eye label, tooltip, accessory when hidden, authentication reason base |
| (literal) | Hide the private terminal | Accessory title when revealed |
| (literal) | Click the eye to show this terminal. | Screen message, shell started |
| (literal) | Click the eye to start this private terminal. | Screen message, shell not started |
| (literal) | Edit Privacy Words… | Options button |
| (literal) | The words this terminal shows in place of the real ones. Kept in the keychain; opening them asks you to authenticate. | Options note |
| (literal) | The privacy words could not be opened. | Alert title |
| (literal) | show the private terminal / edit the privacy words | Authentication reasons |
| (literal) | This pane has a running private terminal session. Removing the pane ends it. | Removal confirmation |

- **string-externalization**: Every string above is a hard-coded English literal; the source does no localization lookup and has no localization table.
## Accessibility Options

Not applicable: the controller reads no display option (reduce motion, increase contrast, differentiate without color) and adds no animation; the theme palette supplies colors.

## Feature Flags

Not applicable: the controller contains no feature-flag reference.

## Analytics

Not applicable: the controller contains no analytics call.

## Privacy

- **Data collected**: The shell's keystrokes and output, the privacy words and the authentication result; the words are the real text and the alias, which can be secrets.
- **Storage**: The controller stores nothing on disk. The words are kept by the vault in the keychain; the controller holds the loaded filter only through the vault and the session.
- **Transmission**: None by the controller; the window is excluded from screen capture while revealed, and there is no scripting or URL surface.
- **Retention**: The filter lives as long as the vault and the session; the process ends when the pane content is discarded.
- **Purpose**: Keeping a terminal's contents unreadable by anything outside the app and by anyone at the screen until the Mac owner authenticates, with output shown under aliases.

## Logging

Not applicable: the controller calls no logging API, so words and stream contents are never written to a log.

## Platform Notes

- **SwiftUI**: Source is `macOS/Features/TerminalSession/PrivateTerminalViewController.swift`, an AppKit view controller; a SwiftUI host would use `NSViewControllerRepresentable`, or rebuild the screen as a `ZStack` of the terminal wrapped with `accessibilityHidden(true)` under an overlay with a `Button` holding an `Image(systemName: "eye.slash")`.
- **Compose**: A composable with a `Box` of the terminal under a full-size scrim with an `IconButton`; hide the terminal from semantics with `clearAndSetSemantics {}`, use `BiometricPrompt` for each reveal, and set `WindowManager.LayoutParams.FLAG_SECURE` while revealed to match the capture exclusion.
- **React/Web**: A container with a terminal widget under an overlay `button` with an `aria-label`; mark the terminal `aria-hidden="true"`, gate reveal on a WebAuthn user-verification call each time, and note the web cannot exclude a window from capture.
- **AppKit / UIKit**: The source uses `NSViewController` with `ThemedBackgroundView`, `ThemedLabel`, `ConcealedContainerView`, `FrameHoldingView`, `NSStackView` and Combine subscriptions for the vault and settings, and conforms to the pane protocols for accessories, options, connecting, teardown, removal confirmation and spacing. On UIKit use `LAContext` for authentication, `accessibilityElementsHidden` for the terminal, and hide the content with a blur view; excluding capture needs `UIScreen.isCaptured` observation.
- **WinUI 3**: Use a `UserControl` with a `Grid` holding the terminal control and an overlay `Grid` whose `Visibility` is bound to `IsRevealed`, containing a `Button` with a `FontIcon` (glyph for a hidden eye) and a `TextBlock` with `TextWrapping="Wrap"` and `MaxWidth="320"`. Authenticate each reveal with `Windows.Security.Credentials.UI.UserConsentVerifier.RequestVerificationAsync`, mapping a non-verified result to the message text. Keep the terminal out of UI Automation by returning null from `OnCreateAutomationPeer` or setting `AutomationProperties.AccessibilityView="Raw"` on its container while leaving the eye `Content` with an `AutomationProperties.Name`. Exclude the window from capture with `SetWindowDisplayAffinity` and `WDA_EXCLUDEFROMCAPTURE` while revealed. Move focus to the terminal with `Focus(FocusState.Programmatic)` on the next dispatcher turn (`DispatcherQueue.TryEnqueue`) and clear focus on hide with `FocusManager`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/PrivateTerminalViewController.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Authenticate on every reveal and never on hide.
**Rationale**: The source says lifting the screen takes the owner's authentication every time and hiding is always allowed.
**Approved**: pending

**Decision**: Start the shell when the pane first appears, with words read without a prompt, and show nothing.
**Rationale**: The source says the words are what conceal the shell's output, so it cannot start without them, and starting shows nothing; only words under the old user-presence guard make it wait.
**Approved**: pending

**Decision**: Put the privacy screen outside the concealed container.
**Rationale**: The source says the screen hides nothing worth hiding from a screen reader and its eye has to be reachable by one to be pressed.
**Approved**: pending

**Decision**: Hold the terminal view still while a shelf slides beside the pane.
**Rationale**: The source says resizing on every frame redraws the whole grid and resizes the shell's tty each time.
**Approved**: pending

**Decision**: Ignore pane spacing and leave the gap to the terminal's own padding.
**Rationale**: The source says the terminal insets its own grid and a theme may override that padding, so the pane pins it flush.
**Approved**: pending

**Decision**: Show an authentication failure as the screen message on reveal, but as an alert sheet when editing words.
**Rationale**: The source does it this way; the screen is the pane's only surface when the terminal is hidden, while the editor opens from a dialog that was dismissed first. A failed reveal gives no alert.
**Approved**: pending

**Decision**: Exclude the window from screen capture only while the pane is revealed.
**Rationale**: The source delegates this to the concealed container, which blanks the window while any concealed view in it is revealed and restores it afterward.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | privacy-and-data |

Separation of concerns is partial: authentication and word storage live in the vault, the stream filtering in the terminal view and the concealment in the container, but this one class also builds the screen, owns the reveal flow, the options row, the connect path and the appearance application. Unit-test coverage fails because no test in the repository exercises it. Screen-reader support is partial: the eye and accessory carry labels and identifiers, but the terminal is deliberately invisible to assistive technology, which is the open question on `screen-reader-contents`. No hardcoded strings fails because every user-facing string is a literal (`string-externalization`). Secure data storage passes for this class because it stores nothing itself and takes the words from the keychain through the vault, authenticating each reveal.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
