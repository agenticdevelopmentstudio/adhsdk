
BarList is a ranked breakdown: a vertical list in which each row carries an item's name and its value together on one line, with a thin horizontal bar under them whose length is the value relative to the largest value in the list. It is built for long names (the source comment lists paths, referrers and hostnames): a label column beside the bar would leave such names truncated to nothing or crowding the bars out at phone width, so the name and value sit together from the left and the bar sits below. Nothing is hidden for good: a long name wraps, and rows past a limit open in place behind a "Show all N" button.

The list is plain text by default. When the host passes `onSelect`, every row becomes a button that reports the row's name and shows a pressed state against the host-supplied `selected` name, dimming the other rows. The host owns the data, the ordering, the selection and the value formatting; the component owns only the expanded or collapsed state of the overflow.

