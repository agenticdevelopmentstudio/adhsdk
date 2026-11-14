
The browser contributes N rail levels (N = the walked depth + 1) into an
existing
Hierarchical Topic Detail ([adhsdk.recipe.ui.blocks.hierarchical-topic-detail](cookbook:0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8))
stack; it draws no chrome of its own:

```
┌───────────────────────────────────────────────────────────────────────┐
│ … ▸ Work ▸ Q3                                          [?] help        │  ← HTDV's one breadcrumb (not this recipe's)
├──────────┬──────────┬──────────┬───────────────────────────────────────┤
│ Categ. ⚙│ Work    ⚙│ Q3      ⚙│  the item list / detail for "Q3"       │
│ ▸ All    │ ▸ Q3     │  (leaf — no level below; Q3 has no children)     │
│   Uncat. │   Q4     │                                                  │
│ ─────────│          │                                                  │
│   Home   │          │                                                  │
│   Work   │          │                                                  │
│   …      │          │                                                  │
└──────────┴──────────┴──────────┴───────────────────────────────────────┘
   root level   depth-1 level   (Q3 has no children → no depth-2 level;
   (All, Uncat,  (Work's own       the pane below is the leaf's own content,
   then roots)   children)         owned by the host, not this recipe)
```

Narrow-mode drill-down, disclosure, and the breadcrumb are entirely HTDV's — see
Hierarchical Topic Detail ([adhsdk.recipe.ui.blocks.hierarchical-topic-detail](cookbook:0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8))'s
own Layout section.

