
- **link-role-label**: The link is a button whose accessibility label is its current title, which names the connected pane when there is one.
- **link-value**: The link exposes "connected" or "not connected" as its accessibility value.
- **link-identifiers**: The link and the connect row carry the stable identifiers "terminalChat.link" and "terminalChat.options.connect".
- **link-keyboard-path**: The link and the connect row are standard buttons; the source adds no key equivalents or custom focus handling, and Connect to Terminal is also reachable from the pane's Settings sheet.
- **status-announcement**: NEEDS REVIEW: Not implemented in source. The controller changes the status line text through the chat view's status line, which sets only its label text and tooltip, and never posts an accessibility announcement for connection changes, including a failed start; evidence that settles it is whether VoiceOver users are told of a changed status line some other way, such as a live-region role on the label.

