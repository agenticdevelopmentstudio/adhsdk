
DocMetadata is a stateless display component that renders document frontmatter fields in a right-aligned definition list. Each field is a `DocMetadataField`:

```ts
interface DocMetadataField {
  label: ReactNode
  value: ReactNode
}
```

The component detects `Array.isArray(value)`: array values wrap as a flex group, scalar values render inline. The component renders nothing when the fields array is empty.

