
**Decision**: The item is readable without a prompt by apps in its access group while the Mac is unlocked.
**Rationale**: The source doc comment explains a private terminal needs the words from its first byte, because they conceal its output, so starting one must not ask. The prompt moves to the app, which authenticates before showing a private terminal, opening the words and saving them.
**Approved**: pending

**Decision**: The item is `WhenUnlockedThisDeviceOnly` and never synchronizable.
**Rationale**: The source says the words name the user and stay on the Mac they were typed on.
**Approved**: pending

**Decision**: The access group is a constructor argument, not a constant.
**Rationale**: Which group applies belongs to the app's entitlements; the source cites its `dependency-injection` rule. The data-protection keychain is always used, so the entitlement is needed either way.
**Approved**: pending

**Decision**: `save` is delete then add, and an empty list means delete only.
**Rationale**: One path rewrites any older guarded item without that guard and removes the item when the list is empty. The cost is that a failure after the delete leaves no item; the failure is thrown.
**Approved**: pending

**Decision**: The store reports an item still guarded by `userPresence` as `needsAuthentication` instead of prompting.
**Rationale**: The silent context makes `load` non-interactive, so migration of older items is explicit: authenticate, `load(context:)`, then `save`.
**Approved**: pending

