
This component is how a user sees and prunes the pages the browser has
remembered. It has three parts, layered so the lower ones know nothing of
the higher ones. The **list model** sits on the browser's history store and
holds the visits currently listed: with an empty filter it lists the most
recent visits, newest first; with a filter it lists the visits whose title
or address contains the trimmed filter text; when the filter changes faster
than the store answers, only the latest filter's answer is ever shown. It
also removes chosen visits and clears all history. The **History panel** is
a reusable view over one list model: a filter field above a list styled
like the Settings sidebar, each row showing a visit's title, address and
when it happened, a remove button for the selected visits, a Clear History
button that asks first, and opening a visit by double-click or Return
through a callback its host supplies. The panel knows nothing of the window
that hosts it, so any host (a window, a shelf, a popover) can embed it. The
**History window** is one such host: a single window with a fixed
identifier, shaped like the projects window — a shelf with a bar of panel
buttons across its top holding one button, History, and the panel beneath
— opened from the Browser menu's Show History command, which opens a
chosen visit in a browser. Visits reach the store only through the
browser's recording gate, which records nothing while a pane is in private
browsing, so private browsing never appears here.

