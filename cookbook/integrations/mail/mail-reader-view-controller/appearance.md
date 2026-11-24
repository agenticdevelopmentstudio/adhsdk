
- **Corner radius**: Not applicable: the controller draws no rounded shape; the web view and system labels draw themselves.
- **Padding**: The header stack has edge insets of 14 top, 16 left, 10 bottom and 16 right points, 4 points between rows, and 8 points after the subject and after the date line. The remote-content bar has 8 points between its note and button. The text fallback page has a 16px body margin.
- **Font**: Subject 18 point system font, semibold, wrapping. Sender line in the default label font. Recipients line in the default label font. Date line in the small system font size. The remote-content note in the small system font size. The "Load Remote Images" button at small control size. Text fallback body 13px system sans-serif.
- **Background**: Not applicable: no background is set; the window and the web page supply their own.
- **Foreground/Text**: The recipients line, date line and remote-content note use the system secondary label color. The sender and subject use the default label color. The placeholder uses the secondary label color.
- **Border**: A system separator rule between the header and the body, hidden with the header.
- **Shadow**: Not applicable: none set.
- **Min/Max size**: The subject is at most the header width minus 32 points. The placeholder is centered in the pane both ways. The body fills the pane below the separator. The source sets no minimum size; the host's pane minimum (360 points in the mail window) is set outside this component.

Layout from top to bottom: header, separator, body. The remote-content bar is the last row of the header.

