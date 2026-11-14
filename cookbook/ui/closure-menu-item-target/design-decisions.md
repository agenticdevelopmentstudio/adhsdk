
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

