
- **Role/trait**: Every control is a native checkbox, popup, slider, text
  field or button with its own platform role.
- **Label requirements**: Each control's title is its accessibility label.
  Moved controls keep their accessibility identifiers; new ones are
  `settings.browser.site-data.manage` for the button and a
  `settings.browser.session-privacy.agent-history-access` identifier for the
  agent history popup.
- **Announce state changes**: Not applicable beyond the platform's own
  announcements for native controls.
- **Keyboard / assistive-technology navigation**: Native controls in the
  settings framework's key-view order; the Site Data window takes keyboard
  focus when it opens and closes on Escape as well as Done.
- **Minimum tap target**: Not applicable — pointer-driven desktop controls of
  platform size.

