---
id: 89df0861-df4c-4839-9da2-bf65910ad5dd
title: "Private Terminal View"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A terminal view that reveals privacy-word aliases on every byte sent to the shell and conceals real words on every byte the shell prints, before the parser sees them."
platforms:
  - swift
  - macos
tags:
  - terminal
  - privacy
depends-on:
  - 2cd6ffc0-e9db-425b-99ba-eb826ffff118
  - 88d2aa75-3a9c-404a-8d3f-7db520d1bec1
  - 998864ec-d852-4e92-aa2c-3177130ff21d
related: []
references: []
approved-by: ""
approved-date: ""
---

# Private Terminal View

## Overview

`PrivateTerminalView` is the terminal view a private session uses. It subclasses the themed terminal view ([adhsdk.ingredient.workspace.terminal.terminal-view](cookbook:2cd6ffc0-e9db-425b-99ba-eb826ffff118)), which draws the caret, and adds one job: it runs the terminal behind a set of privacy words, each an alias the user sees paired with the real text the shell sees. Every byte on its way to the shell has aliases replaced by the real text (revealed). Every byte the shell prints has the real text replaced by the alias (concealed) before the terminal engine parses it, so the buffer, the scrollback, the title and the reported working directory all hold the alias and nothing that reads the terminal afterwards can find the real text.

The two choke points are the engine's own. The send entry point carries keystrokes, pastes, the terminal's replies to queries and programmatic input; the data-received entry point carries everything that comes back. Both streams use [adhsdk.ingredient.foundation.privacy.streaming-text-substitution](cookbook:88d2aa75-3a9c-404a-8d3f-7db520d1bec1), which holds a run of bytes that could still become a word until it diverges or completes. The view adds the timer that flushes held output after a moment of quiet, flushes both streams when the words change, and removes itself from the accessibility tree. The words come from a `TextSubstitutionFilter` ([adhsdk.ingredient.foundation.text-substitution-filter](cookbook:998864ec-d852-4e92-aa2c-3177130ff21d)); with no words set the view is a pass-through.

The class is internal, `@MainActor` and `final`. `TerminalSession` creates it instead of the themed view when the session is private and assigns `substitutions` from its `privacyFilter`.

## Behavioral Requirements

- **substitutions-property**: The view MUST expose a `substitutions` value of type `TextSubstitutionFilter` that both streams read, defaulting to the identity filter, which has no pairs.
- **identity-passthrough**: With the identity filter, bytes sent and bytes received MUST pass through unchanged and nothing MUST be held.
- **send-reveals**: Every byte sent toward the shell MUST first pass through the input stream in the revealing direction, so an alias is replaced by its real text.
- **send-single-choke-point**: Keystrokes, pastes, the terminal's replies to queries and programmatic input MUST all take the same send path, so one filter covers them.
- **send-holds-partial**: Input that could still become an alias MUST be held, not sent, until it diverges from every alias or completes one.
- **send-nothing-when-empty**: When the input stream releases no bytes for a send, the view MUST NOT forward a send to the engine.
- **receive-conceals**: Every byte received from the shell MUST pass through the output stream in the concealing direction before the engine parses it.
- **conceal-before-parse**: Concealment MUST happen before parsing, so the buffer, scrollback, title and reported directory contain the alias and not the real text.
- **receive-nothing-when-empty**: When the output stream releases no bytes for a read, the view MUST NOT forward a parse call to the engine.
- **receive-holds-partial**: Output that could still become a real word MUST be held, not shown, until it diverges from every word or completes one.
- **output-quiet-flush**: When output is still held after a read, the view MUST flush it, showing it as it stands, once 0.15 seconds pass with no further read.
- **output-timer-rearm**: Every read MUST cancel any pending flush timer, and the view MUST arm a new 0.15 second one-shot timer only if the output stream is still holding after that read.
- **output-timer-main-actor**: The flush timer MUST be a target-and-selector timer rather than a block timer, because a block is `@Sendable` and passing the view into it is a region-isolation error.
- **input-no-timer**: The view MUST NOT flush the input stream on quiet; held input stays held until the next send, a divergence, a completion or a change of words.
- **replace-words-flush**: When `substitutions` is set to a value that differs from the current one, the view MUST flush both streams under the old words first so no held byte is lost.
- **replace-words-send-pending**: Input flushed by a change of words MUST be sent to the engine as the old words revealed it, when it is not empty.
- **replace-words-show-pending**: Output flushed by a change of words MUST be handed to the parser as the old words concealed it, when it is not empty.
- **replace-words-new-streams**: A change of words MUST replace both streams with fresh ones built from the new words, with the input revealing and the output concealing.
- **equal-words-ignored**: Setting `substitutions` to a value equal to the current one MUST do nothing: no flush and no new streams.
- **timer-lifetime**: The flush timer MUST hold the view for at most 0.15 seconds.
- **accessibility-hidden**: The view MUST NOT be an accessibility element, MUST report no accessibility children, no role, no value and no selected text, so a screen reader and an accessibility client see an empty space where the terminal is.
- **inherits-themed**: The view MUST keep the themed terminal view's caret behavior and terminal-engine behavior it does not override, including the `onDataSent` and `onDataReceived` callbacks, which fire only when the view forwards bytes through the themed view.
- **no-errors**: No operation of the view throws or returns an error.
- **main-actor**: The view and both streams MUST be used only from the main actor.
- **output-flush-not-concealed-twice**: Held output flushed on quiet or on a change of words MUST go to the parser as the stream released it and MUST NOT be fed back through the stream.
- **output-flush-does-not-rearm**: A flush from the timer or from a change of words MUST NOT schedule another flush timer.
- **screen-reader-alternative**: NEEDS REVIEW: Not implemented in source. The view hides the terminal from assistive technology entirely and offers no concealed text, summary or other route for a screen-reader user to read or operate the terminal; evidence that settles it is a product decision on whether private sessions are meant to be unusable with a screen reader and, if not, the design of an alias-only accessibility representation.

## Appearance

Not applicable beyond what the themed terminal view draws: `PrivateTerminalView` adds no drawing, layout, color, font or border of its own. It differs visually from the themed view only in the text shown: aliases in place of the real words. Size, caret and theme come from the inherited view.

## States

| State | Appearance change |
|-------|------------------|
| Default (identity words) | Terminal text appears exactly as the shell printed it; nothing is held. |
| Words set | Real words in output appear as their aliases; aliases typed or pasted reach the shell as the real text. |
| Holding output | A run that could still become a real word is not yet drawn; it is drawn as it stands after 0.15 seconds without further output, or as the alias when the word completes. |
| Holding input | A typed run that could still become an alias is not yet sent to the shell, and no timer releases it. |
| Words changed | Held input and held output are released under the old words, then new words apply from the next byte. |
| Pressed | Not applicable: the class adds no pointer or press handling. |
| Disabled | Not applicable: the class has no enabled flag. |
| Focused | Not applicable: caret and focus behavior come from the inherited themed view and are not overridden. |
| Loading | Not applicable: the class shows no loading indication; the session, not the view, waits for its first words before it starts the shell. |

## Accessibility

- **Role/trait**: None. The view returns false for being an accessibility element and nil for its role, value and selected text.
- **Children**: The view returns an empty list of accessibility children.
- **Label requirements**: None are provided; the source offers no label or description to a screen reader.
- **Announce state changes**: Not applicable: nothing is exposed, so nothing is announced.
- **Minimum tap target**: Not applicable: the view is a macOS terminal surface with no discrete control; its size comes from the hosting layout.
- **Keyboard**: Keyboard input is the terminal's own path through the send entry point; the class adds no key handling of its own.

## Conformance Test Vectors

The repository has no test that names `PrivateTerminalView`. The vectors are derived from the source. Unless stated, the words are one pair, alias `robin` and real `mike`; "send" means a call to the send entry point with ASCII bytes and "receive" means a call to the data-received entry point; the engine's observed input is what reaches the shell and its observed parser input is what is drawn.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| private-terminal-view-001 | substitutions-property, identity-passthrough | New view, no words set; send `ls`, receive `hello mike` | The shell gets `ls`; the parser gets `hello mike`; nothing held. |
| private-terminal-view-002 | send-reveals, send-single-choke-point | Words set; send `cd robin` | The shell gets `cd mike`. |
| private-terminal-view-003 | receive-conceals, conceal-before-parse | Words set; receive `hi mike` | The parser gets `hi robin`; the buffer holds `robin`. |
| private-terminal-view-004 | send-holds-partial, send-nothing-when-empty | Words set; send `rob` | No send reaches the shell; the input stream is holding. |
| private-terminal-view-005 | send-holds-partial | After vector 004, send `in` | The shell gets `mike`. |
| private-terminal-view-006 | receive-holds-partial, receive-nothing-when-empty | Words set; receive `mik` | The parser is not called with those bytes; the output stream is holding. |
| private-terminal-view-007 | output-quiet-flush | After vector 006, wait 0.15 seconds with no further read | The parser gets `mik`. |
| private-terminal-view-008 | output-timer-rearm | Words set; receive `mik`, then 0.1 seconds later receive `e` | The first timer is cancelled; the parser gets `robin` at once; no timer is pending. |
| private-terminal-view-009 | output-timer-rearm | Words set; receive `mi`, then 0.1 seconds later receive `k` | The first timer is cancelled and a new one is armed; the parser gets `mik` only after 0.15 seconds from the second read. |
| private-terminal-view-010 | input-no-timer | Words set; send `rob`; wait 5 seconds | Nothing reaches the shell. |
| private-terminal-view-011 | replace-words-flush, replace-words-send-pending | Words set; send `rob`; set `substitutions` to a different filter | The shell gets `rob`; both streams are rebuilt. |
| private-terminal-view-012 | replace-words-flush, replace-words-show-pending | Words set; receive `mik`; set `substitutions` to a different filter | The parser gets `mik`. |
| private-terminal-view-013 | equal-words-ignored | Words set; send `rob`; set `substitutions` to an equal filter | Nothing is flushed; the input stream is still holding `rob`. |
| private-terminal-view-014 | replace-words-new-streams | Words set to pair one; then set to a filter with alias `sam` and real `lee`; send `sam` | The shell gets `lee`; the first pair no longer applies. |
| private-terminal-view-015 | accessibility-hidden | Query the view's accessibility element flag, role, value, selected text and children | False, nil, nil, nil and an empty list. |
| private-terminal-view-016 | output-flush-does-not-rearm | After the quiet flush in vector 007 | No timer is pending and a further read starts the cycle again. |
| private-terminal-view-017 | no-errors | Receive bytes 0xFF 0x6D with words set | No error; 0xFF reaches the parser and `m` is held. |

## Edge Cases

- **Null / empty input**: A send or a read of zero bytes forwards nothing when the stream releases nothing, and with nothing held does not arm a timer (MUST). Empty words behave as a pass-through (MUST).
- **Boundary values**: A word split at every byte position across sends or reads is still replaced once; the held run is shorter than the longest word (MUST). A change of words while nothing is held flushes empty arrays and forwards nothing (MUST).
- **Concurrent access**: The view and both streams are main-actor only; the streams are values with no locking (MUST). The timer fires on the thread that armed it, which is the main thread, because the view is main-actor.
- **Error states**: No operation throws or reports an error. Invalid UTF-8 passes through unchanged because the streams work on bytes (MUST).
- **Offline / disconnected state**: Not applicable: the view performs no network access; it sits between the engine and a local process.
- **Held input that is never completed**: A partial alias typed and left alone stays held; no timer releases it and only the next send, a divergence, a completion or a change of words does (MUST, per `input-no-timer`). The user sees no echo of the held characters because the shell has not received them.
- **Held output at a prompt**: A prompt ending in a prefix of a real word appears after 0.15 seconds (MUST), then the remainder of a later read is rescanned from the start of the new bytes, so a word split across a flush is shown as typed.
- **Words changed mid-hold**: Bytes held under the old words come out unchanged or replaced under the old words, never under the new words (MUST).
- **Terminal replies**: A reply the terminal sends to a query goes through the same input stream, so an alias in a reply is revealed (MUST, per `send-single-choke-point`).
- **Equal words set again**: Ignored, including when the pairs are the same in the same order (MUST).
- **Timer outliving the view**: The timer holds the view for at most 0.15 seconds, so the view is released within that time of its last read (MUST).
- **Screen reader**: The view reports itself empty to assistive technology (MUST); see the open question on `screen-reader-alternative`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `substitutions` | `TextSubstitutionFilter` | identity (no pairs) | The alias and real pairs both streams use; setting a different value flushes and rebuilds both streams. |
| `outputQuiet` | `TimeInterval` | 0.15 seconds | Private constant: how long held output may sit before it is shown as it stands. Not configurable. |

## Deep Linking

Not applicable: the view defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the view contains no user-facing string; it transforms bytes it is given.

## Accessibility Options

Not applicable: the view responds to no display option (reduce motion, increase contrast, differentiate without color); it reads none and adds no animation.

## Feature Flags

Not applicable: the view contains no feature-flag reference. A session chooses it when the session is private.

## Analytics

Not applicable: the view contains no analytics call. The session that owns it signals input and output activity from the themed view's `onDataSent` and `onDataReceived` callbacks, which this view does not touch; they fire only for bytes the view actually forwards, so held bytes raise no activity until they are released.

## Privacy

- **Data collected**: The bytes of a terminal stream (keystrokes, pastes, replies and program output), which can include secrets, and the privacy words.
- **Storage**: In memory only: the filter, the two streams and their held bytes. The engine's buffer and scrollback hold the concealed text, so the real text of a concealed word is never stored there.
- **Transmission**: None by the view. Revealed input goes to the local shell process; concealed output goes to the parser.
- **Retention**: Held bytes live until the next send or read, the flush timer or a change of words; the filter lives as long as the view or until replaced.
- **Purpose**: Letting the user and anything that reads the terminal from outside see aliases while the shell works with the real text.

## Logging

Not applicable: the view calls no logging API, so neither the stream nor the words are written to a log.

## Platform Notes

- **SwiftUI**: Source is `macOS/Features/TerminalSession/PrivateTerminalView.swift`, an internal AppKit class on SwiftTerm, so a SwiftUI host reaches it only through an `NSViewRepresentable` wrapper around the session's view. A SwiftUI-native rewrite would still need the two choke points and the timer.
- **Compose**: Wrap the terminal emulator's input and output hooks with two byte-stream filters, flush the output one from a coroutine delay of 150 ms cancelled on each read, and mark the composable with `clearAndSetSemantics {}` to match the empty accessibility tree. Keep the filters on one dispatcher.
- **React/Web**: Use xterm.js with its input event and a write wrapper: filter data given to the process in the revealing direction and data from the process in the concealing direction before `write`. Flush with `setTimeout` of 150 ms, cleared on each read; set `aria-hidden="true"` on the terminal container to match the source's hidden tree. Work on `Uint8Array`, not decoded strings.
- **AppKit / UIKit**: The source subclasses `ThemedTerminalView` and overrides `send(source:data:)` and `dataReceived(slice:)`, the engine's own entry points, plus five `NSAccessibility` overrides that return false or nil. The timer is `Timer.scheduledTimer` with a target and selector. On UIKit, SwiftTerm's iOS view has the same two entry points; hide it with `isAccessibilityElement` set to false and `accessibilityElementsHidden` set to true.
- **WinUI 3**: Host a terminal control (for example a ConPTY-backed terminal control) and interpose two byte filters between the control and the pseudo-console: keystroke bytes pass through the revealing filter on their way to the console input, console output bytes through the concealing filter before the control's parser. Drive the quiet flush with a `DispatcherQueueTimer` (`Interval` 150 ms, `IsRepeating = false`) stopped and restarted on each read while the output filter reports held bytes. Remove the control from UI Automation by overriding `OnCreateAutomationPeer` to return null, or by setting `AutomationProperties.AccessibilityView` to `Raw`, which matches the source's empty accessibility tree. A swap of the word set must flush both filters under the old words before replacing them.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/TerminalSession/PrivateTerminalView.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Conceal output before the terminal engine parses it, not when it is drawn.
**Rationale**: The source says concealing before the parser means the buffer, scrollback, title and reported directory all hold the alias, so nothing that reads the terminal afterwards can find the real text.
**Approved**: pending

**Decision**: Hold input and output that could still become a word until it diverges or completes.
**Rationale**: The source says sending half an alias and the rest later would send the alias itself, so a possible partial match is held rather than passed on.
**Approved**: pending

**Decision**: Flush held output after 0.15 seconds of quiet, but never flush held input on a timer.
**Rationale**: The source flushes output so a prompt ending in a word's prefix still appears; input has no timer in the source, so held input waits for the next keystroke or a change of words. This is the actual behavior, not an idealized one.
**Approved**: pending

**Decision**: Use a target-and-selector timer instead of a block timer.
**Rationale**: The source says the block is `@Sendable` and handing the view to it is a region-isolation error; the timer holds the view for at most the quiet interval.
**Approved**: pending

**Decision**: Flush both streams under the old words before swapping in new ones.
**Rationale**: The source says replacing the words flushes what each stream was holding under the old words so nothing is lost.
**Approved**: pending

**Decision**: Make the view invisible to assistive technology.
**Rationale**: The source says nothing in the view is an accessibility element and a screen reader sees an empty space; this keeps real text out of the accessibility tree, at the cost of removing the terminal from screen-reader users, which is the open question on `screen-reader-alternative`.
**Approved**: pending

**Decision**: Subclass the themed terminal view rather than wrap it.
**Rationale**: The source overrides the engine's own send and data-received entry points, which only a subclass can reach, and keeps the themed view's caret behavior unchanged.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | failed | accessibility |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | partial | performance |

Separation of concerns passes: matching and holding live in the streaming substitution type, the pair list in the filter and the caret in the themed view, while this view only wires the two choke points, the timer and the accessibility overrides. Unit-test coverage fails because no test in the repository exercises the view. Screen-reader support fails by design: the view exposes nothing to assistive technology, which keeps real text out of the accessibility tree but leaves screen-reader users with no route; the open question on `screen-reader-alternative` records it. No PII in logs passes because the view calls no logging API. Main-thread freedom is partial: the view is main-actor and does its substitution on the main thread for every read and send, which is simple and bounded by the length of one read, but the source offers no measurement of its cost on large output.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
