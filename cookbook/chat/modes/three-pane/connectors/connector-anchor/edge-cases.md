
- **No registry available on mount**: Component returns null and renders nothing. No error is thrown.
- **Element reference missing at effect time**: A defensive guard. If the element reference is absent when the effect runs, no registration occurs. With a registry present the span always renders, so this does not arise in normal operation.
- **Registry dependency changes while registry is null**: Component re-evaluates effect but continues returning null.
- **id prop is empty string**: Component registers with the empty string as an ordinary id. Ids are not validated for non-emptiness. For duplicate ids among mounted anchors, the registry keeps the most recently registered element (last-wins).
- **className is empty string**: Component adds nothing; class attribute is "pc-connector-anchor".
- **className is whitespace**: Component appends the whitespace as given after one separator space; the class string may contain consecutive spaces.
- **Component unmounts immediately after mount**: If registration provides a cleanup function (via return value of `reg.register()`), that function is called on unmount.
- **Rapid id changes**: Registration is synchronous inside the effect; each id change runs the previous registration's cleanup (unregistering the old id) before registering the new id, so no overlap between registrations occurs.

