
```
 rail (TopicDetail)                  pane
+----------------------------+  +------------------------------------------+
| [selector popup]    (slot) |  | focused:  [section header]  (px-6 pt-4)  |
| [topic]                    |  |           [children]                     |
| [topic]                    |  |                                          |
| ...                        |  | all:      [All header]                   |
+----------------------------+  |           [card] [card] [card]           |
                                +------------------------------------------+
```

The card grid has one column by default, two from the `sm` breakpoint and three from `xl`, with a `gap-4` and `px-6` inset. The empty copy is a small muted paragraph under the header.

