
```
┌ Card ───────────────────────────┐
│ CardHeader > CardTitle  (title)  │
│ CardContent (description)        │
└──────────────────────────────────┘
```

- Header only when `title` is non-empty; content only when `description` is non-empty.
- Plain text: `<p className="whitespace-pre-wrap text-sm text-apt-text-muted">`.
- Only `apt-*` tokens; no raw hex.
