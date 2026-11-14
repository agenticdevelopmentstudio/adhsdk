---
id: 6d23735b-3334-43ed-8585-d4c7854a4ac5
title: "Closure Menu Item Target"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Wraps an action closure, an enabled closure and an optional checked closure as a menu item target, so menu items need no per-feature action methods."
platforms:
  - swift
  - macos
tags:
  - ui
  - menus
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Closure Menu Item Target

## Overview

The closure menu item target turns closures into the target and action pair
a native macOS menu item needs. A caller that builds menu items from data,
such as a list of menu contributions, would otherwise need a separate
Objective-C action method for every feature. This component holds three
closures: the action to run, a test for whether the item is enabled, and an
optional test for whether the item is checked. It answers the menu system's
action message and its validation message from them. The host that builds the
menu keeps one target per menu item for as long as the item lives, because a
menu item does not retain its target.

## Behavioral Requirements

- **runs-action-on-selection**: When the menu system sends the perform
  message, the component MUST call the action closure exactly once.
- **ignores-sender**: The component MUST NOT read or use the sender passed
  with the perform message; the sender MAY be absent.
- **action-selector-name**: The perform message MUST be exposed to the menu
  system under the selector name `performMenuAction:`.
- **enabled-from-closure**: When the menu system validates an item, the
  component MUST return the result of the enabled closure.
- **enabled-default-true**: When no enabled closure is supplied, the
  component MUST report every validated item as enabled.
- **enabled-evaluated-each-validation**: The component MUST call the enabled
  closure on every validation and MUST NOT cache its result.
- **checked-sets-state**: When a checked closure is supplied, validation MUST
  set the item's state to on if the closure returns true and to off if it
  returns false.
- **checked-absent-leaves-state**: When no checked closure is supplied,
  validation MUST NOT change the item's state.
- **checked-independent-of-enabled**: Validation MUST apply the checked state
  to the item whether the enabled closure returns true or false.
- **main-actor-only**: The component MUST be used only from the main actor;
  its closures run on the main actor.
- **no-retention-of-item**: The component MUST NOT hold a reference to the
  menu item it validates or serves.
- **host-retains-target**: The host SHOULD keep a strong reference to each
  target for as long as its menu item exists, because the menu item holds its
  target weakly.
- **no-error-path**: The component MUST NOT catch, log or report anything
  from its closures; a closure that fails does so in the caller's context.

## Appearance

Not applicable: the component is a non-visual object. It draws nothing; its
only visual effect is the checked mark it sets on a menu item through the
item's state, and the enabled or disabled look the menu system derives from
the returned enabled value.

## States

| State | Appearance change |
|-------|------------------|
| Default | Item is enabled and its checked mark is untouched (no checked closure) or follows the checked closure. |
| Pressed | Not applicable: the perform message runs the action closure; the component keeps no pressed state. |
| Disabled | Enabled closure returns false: the menu system shows the item disabled and does not send the perform message. |
| Focused | Not applicable: the component is not a view; focus belongs to the menu system. |
| Loading | Not applicable: the component runs synchronously and has no loading state. |
| Checked | Checked closure returns true: the item shows a checkmark (state on). |
| Unchecked | Checked closure returns false: the item shows no checkmark (state off). |

## Accessibility

- The component is not a control and exposes no role. The menu item it serves
  carries the role, title and shortcut; those belong to whoever builds the
  item.
- The checked mark set through the item's state is a native menu item state,
  so assistive technology reads it as the item's checked value.
- The enabled value returned on validation is the native enabled state that
  assistive technology reads from the item.
- Minimum target size: Not applicable: the component is not a hit target; the
  menu system sizes menu rows.
- Keyboard: the component adds no key handling; the item's key equivalent is
  owned by the item that points at it.

## Conformance Test Vectors

No test beside the source exercises the component directly; the vectors below
follow the closure contract in the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| closure-menu-item-target-001 | runs-action-on-selection | Action closure increments a counter; send perform with a menu item as sender | Counter is 1 |
| closure-menu-item-target-002 | ignores-sender | Send perform with no sender | Action closure runs once; no failure |
| closure-menu-item-target-003 | enabled-default-true | Target built with only an action; validate an item | Returns true |
| closure-menu-item-target-004 | enabled-from-closure | Enabled closure returns false; validate an item | Returns false |
| closure-menu-item-target-005 | enabled-evaluated-each-validation | Enabled closure reads a flag; validate, flip the flag, validate again | Returns the flag value each time (true then false) |
| closure-menu-item-target-006 | checked-sets-state | Checked closure returns true; validate an item whose state is off | Item state is on |
| closure-menu-item-target-007 | checked-sets-state | Checked closure returns false; validate an item whose state is on | Item state is off |
| closure-menu-item-target-008 | checked-absent-leaves-state | No checked closure; validate an item whose state is on | Item state stays on |
| closure-menu-item-target-009 | checked-independent-of-enabled | Enabled returns false, checked returns true; validate an item | Returns false and item state is on |
| closure-menu-item-target-010 | action-selector-name | Item action is the selector named `performMenuAction:` with this target | Selecting the item runs the action closure |
| closure-menu-item-target-011 | host-retains-target | Item target is the only reference to a target that nothing else retains | Target is released and selecting the item does nothing; host MUST retain it |
| closure-menu-item-target-012 | no-error-path, main-actor-only, no-retention-of-item | Validate and perform from the main actor with closures that complete normally | No log output, no stored item reference, calls complete on the main actor |

## Edge Cases

- **Null or empty input**: the perform message accepts an absent sender and
  runs the action anyway (MUST). The action closure is required by the
  initializer; the enabled closure defaults to always true and the checked
  closure defaults to absent, and when it is absent the item's state is left
  alone (MUST).
- **Boundary values**: Not applicable: the component takes no numeric input.
- **Concurrent access**: the component is isolated to the main actor, so the
  compiler stops calls from other threads (MUST). The closures are called
  serially on the main thread.
- **Error states**: the component has no error path. A closure that crashes
  crashes the caller; the component does not guard it (MUST NOT catch).
- **Offline or disconnected state**: Not applicable: the component does no
  network or storage work.
- **Item that is disabled**: when the enabled closure returns false the menu
  system does not send the perform message, so the action does not run
  (SHOULD hold for any host that honours validation). Validation still sets the
  checked state first.
- **Released target**: a menu item does not retain its target, so a host that
  drops the target leaves an item that does nothing when chosen (the host
  SHOULD retain it).
- **Reused item**: the component keeps no reference to items, so one target
  validates any item it is asked about; each validation overwrites the state
  when a checked closure exists.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| action | closure taking no arguments and returning nothing | required | Runs when the item is chosen. |
| isEnabled | closure returning a boolean | always true | Evaluated on each validation to decide whether the item is enabled. |
| isChecked | optional closure returning a boolean | absent | When present, evaluated on each validation to set the item's checked mark. |

## Deep Linking

Not applicable: the component is a non-visual menu adapter and has no URL or
destination of its own.

## Localization

Not applicable: the component holds no user-visible strings; the menu item's
title is set by whoever builds the item.

## Accessibility Options

Not applicable: the component draws nothing and animates nothing, so Reduce
Motion, Increase Contrast and Differentiate Without Color have nothing to
change. The checked mark is drawn by the menu system.

## Feature Flags

Not applicable: the component reads no flag; it is always active when used.

## Analytics

Not applicable: the component emits no events.

## Privacy

- **Data collected**: None.
- **Storage**: None; it holds only its three closures in memory.
- **Transmission**: None.
- **Retention**: Lives as long as the host's strong reference to it.

## Logging

Not applicable: the component logs nothing; the source contains no logging
call.

## Platform Notes

- **SwiftUI**: There is no target and selector pair. Use a button in a menu or `CommandMenu` with the action closure directly, `.disabled` driven by the enabled value, and a toggle or a checkmark for the checked value. Nothing needs retaining. When bridging an AppKit menu, the same target class is used unchanged.
- **Compose**: Use `DropdownMenuItem` with an `onClick` lambda and the `enabled` parameter; show the checked value with a leading icon or a `Checkbox`. Both lambdas are re-read on recomposition, which plays the role of validating on every open.
- **React/Web**: Use an element with `role="menuitemcheckbox"` or `role="menuitem"`, an `onClick` handler, and `aria-disabled` and `aria-checked` driven by the same two predicates evaluated on each render or menu open.
- **AppKit / UIKit**: The source is `CoreUI/ClosureMenuItemTarget.swift`, an `NSObject` subclass on the main actor for `NSMenuItem` with `target` and `action` set to the target and the selector `performMenuAction:`. Menu validation reaches it through the `validateMenuItem:` message. The class marks both methods as Objective-C. UIKit has no equivalent; `UIAction` handlers and `UIMenuElement.State` replace it.
- **WinUI 3**: Use `MenuFlyoutItem` with a `Click` handler or an `ICommand` through `Command`; an `XamlUICommand` or `RelayCommand` carries the action closure, and its `CanExecute` supplies the enabled value (the item disables automatically and `CanExecuteChanged` replaces validation on each open, so raise it when state changes). For a checked mark use `ToggleMenuFlyoutItem` and bind `IsChecked` to the checked predicate. Re-evaluate `CanExecute` and `IsChecked` in the flyout's `Opening` event to match the validate-on-every-open behavior. No object needs to be kept alive: the item holds its command strongly.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/CoreUI/ClosureMenuItemTarget.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Wrap closures as a target and selector pair instead of requiring one Objective-C action method per feature.
**Rationale**: The source comment says this lets the menu manager build menu items from menu contributions without any per-feature action plumbing.
**Approved**: pending

**Decision**: Evaluate the enabled and checked closures on every validation instead of caching.
**Rationale**: The validate method calls both closures each time it runs, so a menu always reflects current state when it opens.
**Approved**: pending

**Decision**: The host retains one target per menu item; the component does not retain itself.
**Rationale**: The source comment states the host retains one of these per menu item; a menu item holds its target weakly, so an unretained target would be released.
**Approved**: pending

**Decision**: Apply the checked state before reading the enabled closure and regardless of its result.
**Rationale**: The validate method sets the state first and then returns the enabled value, so a disabled item still shows the correct checked mark.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |

The component does one job, adapting closures to the menu system's target and
selector protocol, and leaves item titles, shortcuts and ownership to the
host, so separation of concerns passes. It builds on native menu items rather
than a custom menu, so native controls are preferred. Unit test coverage is
partial: tests beside the source exercise it only through the menu manager
and callers, and none targets the component directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
