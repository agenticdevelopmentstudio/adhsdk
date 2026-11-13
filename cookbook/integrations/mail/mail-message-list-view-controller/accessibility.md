
- **role**: The list is a standard table, so it carries the platform table role. The source sets no other role.
- **table-identifier**: The table's accessibility identifier is `mail.messages`.
- **row-label**: Each row's accessibility label is the sender and subject joined by a comma and a space. The date, snippet and unread state are not part of it.
- **keyboard-navigation**: The source adds no key handling; keyboard navigation of rows comes from the platform table.
- **unread-state-announcement**: NEEDS REVIEW: Not implemented in source. A row shows unread state only through the dot and the font weight, and the accessibility label does not carry it. A screen-reader pass over the mail window would settle whether the label needs an unread marker.
- **tap-target**: Each row is 68 points tall and spans the table width; the source states no further target size.
- **contrast**: NEEDS REVIEW: Not implemented in source. The colors are system label, secondary label and accent colors; whether the secondary-color date and snippet meet contrast on every selection and appearance state needs a contrast measurement.

