
- **Container**: Background and spacing are inherited from the parent layout; the pane itself supplies no chrome beyond its content.
- **Header**: A fixed "Details" label sits at the top of the panel, visually distinct from the content below it.
- **Content area**: A single region below the header that holds the topic's rendered fields.
- **Title**: The topic title renders as a distinct, prominent visual element at the top of the content area.
- **Description**: When present, the description renders as a block of text directly below the title.
- **Images**: When present, images render as a group below the description; layout, sizing, and spacing are supplied by the parent stylesheet.
- **Links label**: When links are present, a "Links" label introduces the links list.
- **Links**: Each link renders as a native link element in a list below the links label.
- **Visibility**: The root container has one of two mutually exclusive visual states, visible or hidden — see States. The parent stylesheet defines the visual difference and any transition between them.

