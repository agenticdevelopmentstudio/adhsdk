---
id: 2d3b1d4b-2293-4dcd-8271-c2081acc88ef
title: "Secrets Window"
type: ingredient
version: 1.0.1
status: draft
language: en
created: 2026-11-18
modified: 2026-11-18
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The one non-modal window where the Mac owner sees and edits their secrets: obscured until they authenticate and whenever it is not in front, autosaved, and locked again on their terms."
platforms:
  - swift
  - macos
tags:
  - workspace
  - privacy
  - secrets
depends-on:
  - d54db476-c847-4ac0-827e-eae336109f38
  - 8a51a893-a170-4cfc-a620-37939ae6b27b
related:
  - 0ca47bff-576f-4e2a-b3f0-5fc0c73ff859
references: []
approved-by: ""
approved-date: ""
---

# Secrets Window

## Overview

`SecretsWindowController` owns the app's one Secrets window, where the Mac owner sees and edits the privacy words every browser pane and private terminal conceals with. It replaces the modal privacy words editor. The window is non-modal and autosaves: there is no OK or Cancel. A source list on the left names its topics, of which there is one, Private Words (`PrivateWordsTopicViewController`): a table of words with Enabled, Real, Alias, Sites and Terminal columns. Sites are the pages a word applies on; Terminal names the private terminals it applies in, as `.gitignore`-style patterns over the directory a terminal started in (`PrivacyTerminalPattern`).

The window opens locked and asks for authentication as soon as it is on screen. Its contents sit in a concealed container under an overlay showing an eye with a slash and an Unlock button; the toolbar stays visible. Unlocking asks the vault to authenticate and only then reads the words into the table. Once unlocked, the contents show only while the window is key and the app is active, and the owner can hide them by hand. Locking empties the table and needs authentication again. `SecretsLockPolicy` locks it when the app goes into the background, when the Mac sleeps or its screen locks, and after a chosen number of minutes without input to the app, each per the Secrets settings (`SecretsSettings`, `SecretsSettingsPanel`). The same settings panel is Settings > Features > Secrets and the window's gear popover.

## Behavioral Requirements

- **single-window**: `SecretsWindowController.show(vault:newWordSite:startingWord:)` MUST open the one Secrets window, or bring the open one forward, never a second.
- **non-modal**: The window MUST be an ordinary resizable window titled "Secrets" with no OK or Cancel buttons.
- **opens-locked**: A newly opened window MUST be locked: the table empty, the contents covered by the overlay, and the overlay's button titled "Unlock Secrets".
- **show-prompts**: `show` MUST put the window on screen locked first and then, while it is locked, ask for authentication at once, so the prompt never appears before the window.
- **unlock-authenticates**: Unlock (the overlay button or the toolbar lock) MUST ask the vault to authenticate with the reason "show your secrets" and MUST read the words into the table only through the grant that authentication returns (`words(with:)`), and save only with it.
- **grant-revoked-locks**: When the vault's `grantGeneration` changes (the store was replaced, as when testing words are turned on or off), the window MUST lock, so words read under the old store's authentication never stay on screen and the new words need a new authentication.
- **unlock-no-stack**: Pressing Unlock while an authentication is on screen MUST do nothing.
- **unlock-reveals**: A successful unlock MUST clear any hide the owner set before the lock, so the words show at once.
- **revealed-rule**: The contents MUST show exactly while the window is unlocked, not hidden by the owner, key, and the app active; otherwise the overlay MUST cover them.
- **overlay-not-toolbar**: The overlay MUST cover the contents only, never the toolbar.
- **overlay-content**: The overlay MUST show, centred, the eye, under it the note "Agents are never allowed to see your secrets", and under that one button titled "Unlock Secrets" while locked and "Show Secrets" while unlocked but hidden.
- **toolbar**: The toolbar MUST hold an eye toggle that hides or shows the contents, a lock button that locks or unlocks, and, right-justified, a gear that shows a transient popover holding the Secrets settings.
- **lock-empties**: Locking MUST stop the lock policy, unload the table, close the gear popover and need authentication again.
- **close-locks**: Closing the window MUST lock it.
- **autosave**: Every committed edit MUST save the enabled, non-empty words through the vault, and MUST NOT save a list identical to the last one saved.
- **terminal-column**: The Terminal column MUST read and write a word's `terminals` as comma-separated patterns.
- **open-on-word**: `show` with `startingWord` MUST, once unlocked, select that word's row, or add one for it on `newWordSite` when it has none.
- **lock-app-inactive**: While unlocked and `secretsLockWhenAppInactive` is on (default on), the app resigning active MUST lock the window.
- **lock-sleep**: While unlocked and `secretsLockOnSleep` is on (default on), the Mac sleeping, its screens sleeping, the session resigning active or the screen locking MUST lock the window.
- **lock-idle**: While unlocked and `secretsLockAfterIdleMinutes` is above zero (default 5), going that many minutes without a key or mouse event in the app MUST lock the window; 0 never locks.
- **settings-panel**: `SecretsSettingsPanel` MUST show a Locking group with the three settings and, only in a Debug build (`#if DEBUG`) that composed testing words, a Testing Words group; it MUST NOT offer a button that opens the Secrets window (Window > Show Secrets Window does).

## Appearance

- **Layout**: A split view: the topic source list on the left, the selected topic on the right. The overlay is centered over both.
- **Overlay**: The `eye.slash` symbol, large, in the secondary label color, above a small button titled "Unlock" while locked and "Show" while unlocked but hidden.
- **Toolbar**: The eye (`eye` when shown, `eye.slash` when hidden) and the lock (`lock` when locked, `lock.open` when unlocked) share a group; a flexible space puts the gear at the trailing edge.

## States

- **Locked**: table empty, overlay with Unlock, lock button shows `lock`.
- **Authenticating**: as locked, with Unlock disabled.
- **Unlocked, revealed**: the words show; the window is excluded from screen capture.
- **Unlocked, not in front**: overlay without a button; contents kept, not shown.
- **Unlocked, hidden by owner**: overlay with Show.

## Accessibility

- **Role/trait**: The toolbar items are buttons with labels ("Hide Secrets" / "Show Secrets", "Lock Secrets" / "Unlock Secrets", "Secrets Settings") and identifiers `secrets.toolbar.visibility`, `secrets.toolbar.lock` and `secrets.toolbar.settings`; the overlay button is `secrets.overlay.action` and the window `secrets.window`.
- **Concealment**: While concealed the contents are absent from the accessibility tree; while revealed they are present, but the window cannot be captured.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| secrets-window-001 | lock-idle | Idle since t, now t + 299 s, 5 minutes | Not idle. |
| secrets-window-002 | lock-idle | Idle since t, now t + 300 s, 5 minutes | Idle. |
| secrets-window-003 | lock-idle | Idle since t, now t + 1 day, 0 minutes | Not idle. |
| secrets-window-004 | settings-panel | Idle labels for 0, 1, 15 | "Never", "1 minute", "15 minutes". |

## Edge Cases

- **Authentication refused**: the window stays locked and logs the refusal (MUST).
- **Store replaced while authenticating**: the words read are the new store's, on the next unlock (MUST).
- **Window closed while authenticating**: the late success opens nothing (MUST).

## Configuration

| Setting | Type | Default | Meaning |
|---------|------|---------|---------|
| `secrets.lock.app_inactive` | Bool | true | Lock when the app goes into the background. |
| `secrets.lock.sleep` | Bool | true | Lock when the Mac sleeps or its screen locks. |
| `secrets.lock.idle_minutes` | Int | 5 | Lock after this many minutes without input; 0 never. |

## Localization

| Key | Value | Context |
|-----|-------|---------|
| (literal) | Secrets | Window title, settings topic |
| (literal) | Private Words | Topic |
| (literal) | Unlock / Show | Overlay button |
| (literal) | show your secrets | Authentication reason |
| (literal) | Open Secrets… | Settings button |

## Privacy

- **Data collected**: The privacy words: real words and their aliases, which can be secrets.
- **Storage**: Nothing on disk of its own; the vault keeps the words in the keychain.
- **Sensitive-data handling**: Shown only after owner authentication, only while in front, never in a screen capture; emptied on lock.

## Logging

One info line when an unlock is refused, carrying the error's description and never a word.

## Platform Notes

- **AppKit**: `NSWindow.sharingType = .none` while revealed (from the concealed container) keeps the words out of screenshots, recording and screen sharing. `com.apple.screenIsLocked` on the distributed notification center is the public signal for a locked screen.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Secrets/SecretsWindowController.swift` | confirmed (1.0.1) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Secrets/SecretsLockPolicy.swift` | confirmed (1.0.1) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Secrets/PrivateWordsTopicViewController.swift` | confirmed (1.0.1) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Secrets/SecretsSettingsPanel.swift` | confirmed (1.0.1) |
| macos | `packages/apple/AgenticDeveloperHubSDK/Core/Privacy/SecretsSettings.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Obscure the words whenever the window is not key or the app is not active, not only when locked.
**Rationale**: A non-modal window can sit behind others while someone else looks at the screen; showing the words only while the owner is working in the window costs nothing.

**Decision**: Autosave rather than OK/Cancel.
**Rationale**: The window is non-modal and may be locked at any moment by the policy; an unsaved edit lost to a lock would surprise the owner.

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

Separation of concerns passes: the window controller owns locking and concealment, `PrivateWordsTopicViewController` owns the table, `SecretsLockPolicy` owns the lock triggers and the vault owns storage and authentication. Unit-test coverage is partial: `SecretsLockPolicyTests` covers the idle rule and its labels (vectors 001–004) and `PrivacyTerminalPatternTests` the Terminal column's patterns, while unlocking and concealment need a real authentication prompt. Secure storage passes because the window keeps nothing on disk and the vault keeps the words in the keychain. No PII in logs passes because the one log line carries only the error's description. No hardcoded strings fails because the titles, labels and reason are English literals.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-18 | Mike Fullerton | Grants: unlock reads and saves through the vault's grant and locks on a revoked one; overlay note and Unlock/Show Secrets titles; settings panel loses Open Secrets and its testing words are Debug-only |
| 1.0.0 | 2026-11-18 | Mike Fullerton | Initial recipe: the Secrets window replaces the privacy words editor. |
