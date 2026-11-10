
Three Pane Chat renders no static copy of its own beyond panel headers (handled by its sub-panes' own recipes), but the Accessibility section requires assistive-technology announcements that carry user-visible text and MUST be localized:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `three_pane_chat.topic_activated_announcement` | "{title} details shown" | Announced by assistive technology when a topic becomes active and its detail panel is shown |
| `three_pane_chat.topic_count_announcement` | "{count} topics" | Announced by assistive technology when the topics list changes |

