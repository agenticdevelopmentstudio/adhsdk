
- **No registry available on mount**: Component returns null and renders nothing. No error is thrown.
- **Registry available but ref is not ready**: The effect checks `!ref.current` and returns early; no registration occurs until ref is available.
- **Registry dependency changes while registry is null**: Component re-evaluates effect but continues returning null.
- **id prop is empty string**: Component will register with an empty string id. The behavior of duplicate or empty ids is undefined; the source does not validate id uniqueness or non-emptiness.
- **className is empty string**: Component appends the empty string; class attribute becomes "pc-connector-anchor ".
- **className is whitespace**: Component concatenates whitespace; multiple spaces may appear in the class string.
- **Component unmounts immediately after mount**: If registration provides a cleanup function (via return value of `reg.register()`), that function is called on unmount.
- **Rapid id changes**: Registration is synchronous inside the effect; each id change runs the previous registration's cleanup (unregistering the old id) before registering the new id, so no overlap between registrations occurs.

