
**Decision**: The body is shown with JavaScript off, a non-persistent data store and every remote load blocked until the user asks for them.
**Rationale**: Opening a message must never tell its sender it was read through tracking pixels, and must never run its scripts.
**Approved**: pending

**Decision**: Remote blocking is done twice: a Content-Security-Policy meta tag at the start of the document and a content rule list.
**Rationale**: The policy is the block itself, not a backup: it holds even if the content rule list fails to compile. The rule list is compiled once per process and the policy needs none.
**Approved**: pending

**Decision**: The policy is placed first in the document, and the document is the sender's HTML as sent.
**Rationale**: The HTML parser places a leading meta tag in the head, and a policy the message brings can only narrow this one.
**Approved**: pending

**Decision**: The rule list uses three rules, one per scheme family, not one rule with alternation.
**Rationale**: WebKit's content-blocker regular expression has no alternation.
**Approved**: pending

**Decision**: "Load Remote Images" applies to the message on screen only and is cleared when a different message opens.
**Rationale**: The block is lifted for the message on screen only, so one trusted message never makes the next one load trackers.
**Approved**: pending

**Decision**: Only a different message id reloads the body; a republished message with the same id updates the header alone.
**Rationale**: A label change (marking read) republishes the message, and reloading only for a different one keeps the scroll position and avoids a flash.
**Approved**: pending

**Decision**: Links open in the system's default handler only for `http`, `https` and `mailto`, and every other scheme is dropped.
**Rationale**: Any other scheme (smb, vnc, ssh, an app's own) would launch its handler from one click with none of the confirmation a browser shows.
**Approved**: pending

**Decision**: Every navigation the message starts by itself (meta refresh, form submit, frame) is cancelled; only the reader's own `about:` page loads.
**Rationale**: Such a navigation would put a sender-chosen page under the real message headers with no address bar, and the policy and rule list block loads, not navigations, and are gone once remote content is allowed.
**Approved**: pending

**Decision**: An in-frame `#section` link to the reader's own page is allowed.
**Rationale**: It scrolls the message in place; it is the one link the reader keeps.
**Approved**: pending

**Decision**: A stale body load is dropped after the rule list compiles.
**Rationale**: The message may have changed while the rules compiled, and an earlier message's body must not replace the later one.
**Approved**: pending

**Decision**: Known gap: the source shows the remote-content bar for an empty-string HTML body, and a failed rule list compile or body load shows no message.
**Rationale**: Technical debt: the source tests only for a nil HTML body (the requirement **remote-bar-shown-for-html** asks for non-empty), and it has no failure handler or log. Pay it down when the reader next changes: fix the bar test first, and add a failure state once the product decides what a failed body load shows.
**Approved**: pending

**Decision**: Known gap: the source's strings are literals, and `init(coder:)` traps.
**Rationale**: Technical debt: the strings cannot be localized without a code change, and the controller cannot be loaded from a nib or storyboard. Pay down the strings when a second locale ships, by moving them to the keys in Localization; the trap stays until a nib-built reader is wanted.
**Approved**: pending

