
This component is the one gatekeeper between a web page and an agent. It
decides everything an agent receives from a page: the accessibility-tree
snapshot, the page text, the results of finding elements, the references
that click, type, fill, select and hover resolve, the text a wait condition
is checked against, and — through its string path — page titles, dialog
messages, focused-element descriptions and browsing history. The same
result is what the Agent preview and Agent source views show (see the
Agent Preview and Agent Source Views recipe), so a user in a
privacy-critical situation can check with their own eyes exactly what an
agent is given.

It works in two halves. A walker running in the page's isolated automation
context visits the document and emits a neutral list of nodes: only node
kinds and attributes on an allowlist, never markup it did not construct,
skipping hidden content and anything on the site's "hide from agent" list.
The host side receives that list, re-validates every node and every
attribute against the same allowlist (defined once on the host side and
handed to the walker), applies every privacy setting to each piece as it is
added, and produces one immutable page value. Three renderings come from
that one value: the snapshot tree in today's format, the plain text, and
an HTML document for the views.

The page is *built up*; it is never the live document with parts trimmed
away. Whenever anything is uncertain or fails, content is stripped rather
than let through: an unknown node kind or attribute is dropped, and a
walker error, a timeout, a malformed payload or an unreadable privacy-word
vault yields an empty page carrying a reason. The component always runs —
there is no branch on privacy settings choosing whether to use it; settings
only change what it filters.

