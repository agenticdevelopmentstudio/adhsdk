
- **role**: The sidebar is a standard outline, so it carries the platform outline role. The source sets no other role.
- **outline-identifier**: The outline's accessibility identifier is `mail.sidebar`.
- **row-label**: A mailbox row's accessibility label is the mailbox title. The unread count is not part of it. The mailbox symbol is created with no accessibility description.
- **keyboard-navigation**: The source adds no key handling; arrow-key navigation, expand and collapse come from the platform outline. Group rows are not selectable, so keyboard selection lands only on mailbox rows.
- **unread-count-announcement**: NEEDS REVIEW: Not implemented in source. The unread count is drawn as visible text but the row's accessibility label is only the title, so a screen reader may not announce it. A screen-reader pass over the mail window would settle whether the label needs the count.
- **account-row-label**: The account group row sets no accessibility label of its own; it exposes the email text of its text field, and the source adds no role or description marking it as an account.
- **tap-target**: The source states no target size; rows use the source list's default row height.
- **contrast**: NEEDS REVIEW: Not implemented in source. Account email and counts use the system secondary label color; whether it meets contrast on the sidebar material in every appearance and selection state needs a contrast measurement.

